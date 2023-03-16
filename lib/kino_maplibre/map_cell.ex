defmodule KinoMapLibre.MapCell do
  @moduledoc false

  use Kino.JS, assets_path: "lib/assets/map_cell"
  use Kino.JS.Live
  use Kino.SmartCell, name: "Map"

  @as_int ["zoom", "layer_radius", "cluster_min", "cluster_max"]
  @as_atom ["layer_type", "source_type", "symbol_type"]
  @as_float ["layer_opacity"]
  @geometries [Geo.Point, Geo.LineString, Geo.Polygon, Geo.GeometryCollection]
  @styles %{"street (non-commercial)" => :street, "terrain (non-commercial)" => :terrain}
  @geocode_options ["fill", "line", "circle"]

  @query_source %{columns: nil, type: "query", variable: "🌎 Geocoding"}

  @impl true
  def init(attrs, ctx) do
    root_fields = %{
      "style" => attrs["style"] || "default",
      "center" => attrs["center"],
      "zoom" => attrs["zoom"] || 0
    }

    layers =
      if attrs["layers"],
        do: Enum.map(attrs["layers"], &Map.merge(default_layer(), &1)),
        else: [default_layer()]

    ctx =
      assign(ctx,
        root_fields: root_fields,
        layers: layers,
        ml_alias: MapLibre,
        source_variables: [],
        missing_dep: missing_dep()
      )

    {:ok, ctx, reevaluate_on_change: true}
  end

  @impl true
  def scan_binding(pid, binding, env) do
    source_variables =
      for {key, val} <- binding,
          is_geometry?(val) || is_table?(val),
          do: %{variable: Atom.to_string(key), type: source_type(val), columns: columns_for(val)}

    ml_alias = ml_alias(env)
    send(pid, {:scan_binding_result, source_variables, ml_alias})
  end

  @impl true
  def handle_connect(ctx) do
    payload = %{
      root_fields: ctx.assigns.root_fields,
      layers: ctx.assigns.layers,
      source_variables: ctx.assigns.source_variables,
      missing_dep: ctx.assigns.missing_dep
    }

    {:ok, payload, ctx}
  end

  @impl true
  def handle_info({:scan_binding_result, source_variables, ml_alias}, ctx) do
    source_variables = source_variables ++ [@query_source]
    ctx = assign(ctx, ml_alias: ml_alias, source_variables: source_variables)
    first_layer = List.first(ctx.assigns.layers)

    updated_layer =
      case {first_layer["layer_source"], source_variables} do
        {nil, [%{variable: source_variable, type: source_type} | _]} ->
          %{first_layer | "layer_source" => source_variable, "source_type" => source_type}

        _ ->
          %{}
      end

    ctx =
      if updated_layer == %{},
        do: ctx,
        else: %{ctx | assigns: %{ctx.assigns | layers: [updated_layer]}}

    broadcast_event(ctx, "set_source_variables", %{
      "source_variables" => source_variables,
      "fields" => updated_layer
    })

    {:noreply, ctx}
  end

  @impl true
  def handle_event("update_field", %{"field" => field, "value" => value, "idx" => nil}, ctx) do
    parsed_value = parse_value(field, value)
    ctx = update(ctx, :root_fields, &Map.put(&1, field, parsed_value))
    broadcast_event(ctx, "update_root", %{"fields" => %{field => parsed_value}})
    {:noreply, ctx}
  end

  def handle_event(
        "update_field",
        %{"field" => "layer_source", "value" => value, "idx" => idx},
        ctx
      ) do
    layer = get_in(ctx.assigns.layers, [Access.at(idx)])

    [source_type] =
      get_in(ctx.assigns.source_variables, [Access.filter(&(&1.variable == value)), :type])

    updated_source = prefill_source_options(ctx.assigns.layers, value)

    layer_type =
      if source_type == "query" and layer["layer_type"] not in @geocode_options,
        do: "fill",
        else: layer["layer_type"]

    updated_fields =
      Map.merge(
        %{"layer_source" => value, "source_type" => source_type, "layer_type" => layer_type},
        updated_source
      )

    updated_layer = Map.merge(layer, updated_fields)
    updated_layers = List.replace_at(ctx.assigns.layers, idx, updated_layer)
    ctx = %{ctx | assigns: %{ctx.assigns | layers: updated_layers}}

    broadcast_event(ctx, "update_layer", %{"idx" => idx, "fields" => updated_fields})

    {:noreply, ctx}
  end

  def handle_event("update_field", %{"field" => field, "value" => value, "idx" => idx}, ctx) do
    parsed_value = parse_value(field, value)
    updated_layers = put_in(ctx.assigns.layers, [Access.at(idx), field], parsed_value)
    ctx = %{ctx | assigns: %{ctx.assigns | layers: updated_layers}}
    broadcast_event(ctx, "update_layer", %{"idx" => idx, "fields" => %{field => parsed_value}})

    {:noreply, ctx}
  end

  def handle_event("add_layer", _, ctx) do
    %{"layer_source" => layer_source, "source_type" => source_type} =
      List.first(ctx.assigns.layers)

    updated_source = prefill_source_options(ctx.assigns.layers, layer_source)
    updated_layer = Map.merge(default_layer(layer_source, source_type), updated_source)

    updated_layers = ctx.assigns.layers ++ [updated_layer]
    ctx = %{ctx | assigns: %{ctx.assigns | layers: updated_layers}}
    broadcast_event(ctx, "set_layers", %{"layers" => updated_layers})

    {:noreply, ctx}
  end

  def handle_event("remove_layer", %{"layer" => idx}, ctx) do
    updated_layers = List.delete_at(ctx.assigns.layers, idx) |> maybe_reactivate_layer()
    ctx = %{ctx | assigns: %{ctx.assigns | layers: updated_layers}}
    broadcast_event(ctx, "set_layers", %{"layers" => updated_layers})

    {:noreply, ctx}
  end

  def handle_event("move_layer", %{"removedIndex" => remove, "addedIndex" => add}, ctx) do
    {layer, layers} = List.pop_at(ctx.assigns.layers, remove)
    updated_layers = List.insert_at(layers, add, layer)
    ctx = %{ctx | assigns: %{ctx.assigns | layers: updated_layers}}
    broadcast_event(ctx, "set_layers", %{"layers" => updated_layers})

    {:noreply, ctx}
  end

  def maybe_reactivate_layer([layer]) do
    if layer["active"], do: [layer], else: [%{layer | "active" => true}]
  end

  def maybe_reactivate_layer(layers), do: layers

  defp prefill_source_options(layers, value) do
    source = Enum.find(layers, &(&1["layer_source"] == value))

    if source,
      do:
        Map.take(source, [
          "coordinates_format",
          "source_coordinates",
          "source_latitude",
          "source_longitude"
        ]),
      else: %{
        "coordinates_format" => "lng_lat",
        "source_coordinates" => nil,
        "source_longitude" => nil,
        "source_latitude" => nil
      }
  end

  defp parse_value(_field, ""), do: nil
  defp parse_value(field, value) when field in @as_int, do: String.to_integer(value)
  defp parse_value(field, value) when field in @as_float, do: value |> Float.parse() |> elem(0)
  defp parse_value(_field, value), do: value

  defp convert_field(field, nil), do: {String.to_atom(field), nil}

  defp convert_field("center", center) do
    Regex.named_captures(~r/(?<lng>-?\d+\.?\d*),\s*(?<lat>-?\d+\.?\d*)/, center)
    |> case do
      %{"lat" => lat, "lng" => lng} ->
        {{lng, _}, {lat, _}} = {Float.parse(lng), Float.parse(lat)}
        {:center, validate_coords({lng, lat})}

      _ ->
        {:center, nil}
    end
  end

  defp convert_field("zoom", 0), do: {:zoom, nil}
  defp convert_field("style", value), do: {:style, Map.get(@styles, value)}

  defp convert_field(field, value) when field in @as_atom do
    {String.to_atom(field), String.to_atom(value)}
  end

  defp convert_field(field, value), do: {String.to_atom(field), value}

  defp ml_alias(%Macro.Env{aliases: aliases}) do
    case List.keyfind(aliases, MapLibre, 1) do
      {ml_alias, _} -> ml_alias
      nil -> MapLibre
    end
  end

  @impl true
  def to_attrs(ctx) do
    ctx.assigns.root_fields
    |> Map.put("layers", ctx.assigns.layers)
    |> Map.put("ml_alias", ctx.assigns.ml_alias)
  end

  @impl true
  def to_source(attrs) do
    attrs
    |> to_quoted()
    |> Kino.SmartCell.quoted_to_string()
  end

  defp to_quoted(attrs) do
    layers = attrs["layers"]
    sources = build_sources(layers)
    symbols = build_symbols(layers)

    attrs =
      Map.take(attrs, ["style", "center", "zoom", "ml_alias"])
      |> Map.new(fn {k, v} -> convert_field(k, v) end)

    root = %{
      field: nil,
      name: :new,
      module: attrs.ml_alias,
      args: build_arg_root(style: attrs.style, center: attrs.center, zoom: attrs.zoom)
    }

    sources =
      for source <- sources,
          source = Map.new(source, fn {k, v} -> convert_field(k, v) end),
          do: %{
            field: :source,
            name: add_source_function(source.source_type),
            module: attrs.ml_alias,
            args:
              build_arg_source(
                source.source_id,
                source.source_data,
                source.source_type,
                source.source_coordinates,
                source.source_options
              )
          }

    valid_sources = Enum.map(sources, &if(&1.args, do: hd(&1.args)))

    layers =
      for {layer, idx} <- Enum.with_index(layers),
          layer = Map.new(layer, fn {k, v} -> convert_field(k, v) end),
          layer_source = build_layer_source(layer),
          layer_id = "#{layer_source}_#{layer.layer_type}_#{idx + 1}",
          layer.active,
          layer_source in valid_sources,
          do: %{
            field: :layer,
            name: :add_layer,
            module: attrs.ml_alias,
            args:
              build_arg_layer(
                layer_id,
                layer_source,
                layer.layer_type,
                {layer.layer_color, layer.layer_radius, layer.layer_opacity},
                {layer.cluster_min, layer.cluster_max, layer.cluster_colors}
              )
          }

    symbols =
      for symbol <- symbols,
          symbol = Map.new(symbol, fn {k, v} -> convert_field(k, v) end),
          symbol.symbol_source in valid_sources,
          do: %{
            field: :layer,
            name: :add_layer,
            module: attrs.ml_alias,
            args: build_arg_symbol(symbol.symbol_id, symbol.symbol_source, symbol.symbol_type)
          }

    used_sources = Enum.map(layers, &if(&1.args, do: hd(&1.args)[:source]))
    sources = Enum.filter(sources, &(&1.args && hd(&1.args) in used_sources))
    symbols = Enum.filter(symbols, &(&1.args && hd(&1.args)[:source] in used_sources))

    nodes = sources ++ layers ++ symbols

    root = build_root(root)
    Enum.reduce(nodes, root, &apply_node/2)
  end

  defp build_root(root) do
    quote do
      unquote(root.module).unquote(root.name)(unquote_splicing(root.args))
    end
  end

  defp apply_node(%{args: nil}, acc), do: acc

  defp apply_node(%{field: _field, name: function, module: module, args: args}, acc) do
    args = Enum.reject(args, &(&1 == []))

    quote do
      unquote(acc) |> unquote(module).unquote(function)(unquote_splicing(args))
    end
  end

  defp build_arg_root(opts) do
    opts
    |> Enum.filter(&elem(&1, 1))
    |> case do
      [] -> []
      opts -> [opts]
    end
  end

  defp build_arg_source(nil, _, _, _, _), do: nil
  defp build_arg_source(_, nil, _, _, _), do: nil
  defp build_arg_source(_, _, :table, {_, nil}, _), do: nil
  defp build_arg_source(_, _, :table, {_, [nil, _]}, _), do: nil
  defp build_arg_source(_, _, :table, {_, [_, nil]}, _), do: nil

  defp build_arg_source(id, data, :geo, _, opts),
    do: [id, Macro.var(String.to_atom(data), nil), opts]

  defp build_arg_source(id, data, :table, coordinates, opts),
    do: [id, Macro.var(String.to_atom(data), nil), coordinates, opts]

  defp build_arg_source(id, {data, nil}, :query, _, _),
    do: [id, data]

  defp build_arg_source(id, {data, strict}, :query, _, _),
    do: [id, data, String.to_atom(strict)]

  defp build_arg_source(id, data, _, _, opts) do
    args = [type: :geojson, data: Macro.var(String.to_atom(data), nil)]
    args = if opts, do: Keyword.merge(args, opts), else: args
    [id, args]
  end

  defp build_arg_layer(_, nil, _, _, _), do: nil

  defp build_arg_layer(id, source, :cluster, _, cluster_options) do
    [[id: id, source: source, type: :circle, paint: build_arg_paint(:cluster, cluster_options)]]
  end

  defp build_arg_layer(id, source, type, {color, radius, opacity}, _) do
    [[id: id, source: source, type: type, paint: build_arg_paint(type, {color, radius, opacity})]]
  end

  defp build_arg_paint(:cluster, {min, max, [color_min, color_mid, color_max]}) do
    [
      circle_color: ["step", ["get", "point_count"], color_min, min, color_mid, max, color_max],
      circle_radius: ["step", ["get", "point_count"], 20, min, 30, max, 40]
    ]
  end

  defp build_arg_paint(:heatmap, {_color, radius, opacity}) do
    [heatmap_radius: radius, heatmap_opacity: opacity]
  end

  defp build_arg_paint(:circle, {color, radius, opacity}) do
    [circle_color: color, circle_radius: radius, circle_opacity: opacity]
  end

  defp build_arg_paint(type, {color, _radius, opacity}) do
    ["#{type}_color": color, "#{type}_opacity": opacity]
  end

  defp build_arg_symbol(id, source, :cluster) do
    [
      [
        id: id,
        source: source,
        type: :symbol,
        layout: [text_field: "{point_count_abbreviated}", text_size: 10],
        paint: [text_color: "black"]
      ]
    ]
  end

  defp build_sources(layers) do
    for layer <- layers,
        do: %{
          "source_id" => source_id(layer),
          "source_data" => source_data(layer),
          "source_type" => layer["source_type"],
          "source_coordinates" => source_coordinates(layer),
          "source_options" => source_options(layer)
        },
        uniq: true
  end

  defp build_symbols(layers) do
    for layer <- layers,
        layer["layer_type"] == "cluster",
        do: %{
          "symbol_id" => "#{layer["layer_source"]}_count",
          "symbol_source" => "#{layer["layer_source"]}_clustered",
          "symbol_type" => "cluster"
        }
  end

  defp build_layer_source(%{layer_type: :cluster} = layer), do: "#{layer.layer_source}_clustered"
  defp build_layer_source(%{source_type: :query, layer_source_query: nil}), do: nil

  defp build_layer_source(%{source_type: :query} = layer) do
    query = normalize_geocode_id(layer.layer_source_query)
    strict = layer.layer_source_query_strict
    if strict, do: "#{query}_#{strict}", else: query
  end

  defp build_layer_source(layer), do: layer.layer_source

  defp source_id(%{"source_type" => "query", "layer_source_query" => nil}), do: nil

  defp source_id(%{"source_type" => "query"} = layer) do
    query = normalize_geocode_id(layer["layer_source_query"])
    strict = layer["layer_source_query_strict"]
    if strict, do: "#{query}_#{strict}", else: query
  end

  defp source_id(%{"layer_type" => "cluster"} = layer), do: "#{layer["layer_source"]}_clustered"

  defp source_id(layer), do: layer["layer_source"]

  defp source_coordinates(%{"source_type" => "table", "coordinates_format" => "columns"} = layer) do
    {:lng_lat, [layer["source_longitude"], layer["source_latitude"]]}
  end

  defp source_coordinates(%{"source_type" => "table"} = layer) do
    {String.to_atom(layer["coordinates_format"]), layer["source_coordinates"]}
  end

  defp source_coordinates(_), do: nil

  defp source_options(%{"layer_type" => "cluster"}), do: [cluster: true]
  defp source_options(_), do: []

  defp source_data(%{"source_type" => "query"} = layer) do
    {layer["layer_source_query"], layer["layer_source_query_strict"]}
  end

  defp source_data(layer), do: layer["layer_source"]

  defp add_source_function(:geo), do: :add_geo_source
  defp add_source_function(:table), do: :add_table_source
  defp add_source_function(:query), do: :add_geocode_source
  defp add_source_function(_), do: :add_source

  defp missing_dep() do
    unless Code.ensure_loaded?(MapLibre) do
      ~s/{:maplibre, "~> 0.1.0"}/
    end
  end

  defp default_layer(layer_source \\ nil, source_type \\ nil) do
    %{
      "layer_source" => layer_source,
      "layer_source_query" => nil,
      "layer_source_query_strict" => nil,
      "source_type" => source_type,
      "layer_type" => "circle",
      "layer_color" => "#000000",
      "layer_opacity" => 1,
      "layer_radius" => 5,
      "coordinates_format" => "lng_lat",
      "source_coordinates" => nil,
      "source_longitude" => nil,
      "source_latitude" => nil,
      "cluster_min" => 100,
      "cluster_max" => 750,
      "cluster_colors" => ["#51bbd6", "#f1f075", "#f28cb1"],
      "active" => true
    }
  end

  defp is_geometry?(%module{}) when module in @geometries, do: true
  defp is_geometry?(url) when is_binary(url), do: URI.parse(url).scheme in ~w(http https topojson)
  defp is_geometry?(_), do: false

  defp is_table?(val), do: implements?(Table.Reader, val)

  defp source_type(%module{}) when module in @geometries, do: "geo"
  defp source_type(val), do: if(is_table?(val), do: "table")

  defp columns_for(data) do
    with true <- implements?(Table.Reader, data),
         {_, %{columns: columns}, _} <- Table.Reader.init(data),
         true <- Enum.all?(columns, &implements?(String.Chars, &1)) do
      Enum.map(columns, &to_string/1)
    else
      _ -> nil
    end
  end

  defp implements?(protocol, value), do: protocol.impl_for(value) != nil

  defp validate_coords({lng, lat}) do
    valid_lng? = lng >= -180 and lng <= 180
    valid_lat? = lat >= -90 and lat <= 90
    if valid_lng? and valid_lat?, do: {lng, lat}
  end

  defp normalize_geocode_id(query) do
    if Regex.match?(~r/^[\d-]*$/, query) do
      "postalcode_#{String.replace(query, ~r/\D+/, "")}"
    else
      query
      |> String.downcase()
      |> String.normalize(:nfd)
      |> String.replace(~r/[^a-zA-Z\s]/u, "")
      |> String.replace(~r/\W+/, "_")
    end
  end
end
