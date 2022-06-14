defmodule KinoMapLibre.MapCell do
  @moduledoc false

  use Kino.JS, assets_path: "lib/assets/map_cell"
  use Kino.JS.Live
  use Kino.SmartCell, name: "Map"

  @as_int ["zoom", "layer_radius"]
  @as_atom ["layer_type"]
  @as_float ["layer_opacity"]
  @geometries [Geo.Point, Geo.LineString, Geo.Polygon, Geo.GeometryCollection]

  @impl true
  def init(attrs, ctx) do
    root_fields = %{
      "style" => attrs["style"] || "default",
      "center" => attrs["center"],
      "zoom" => attrs["zoom"] || 0
    }

    layers = attrs["layers"] || new_layer()

    ctx =
      assign(ctx,
        root_fields: root_fields,
        layers: layers,
        ml_alias: nil,
        source_variables: [],
        missing_dep: missing_dep()
      )

    {:ok, ctx, reevaluate_on_change: true}
  end

  @impl true
  def scan_binding(pid, binding, env) do
    source_variables =
      for {key, val} <- binding,
          is_geometry(val),
          do: %{variable: Atom.to_string(key), type: source_type(val)}

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
    ctx = assign(ctx, ml_alias: ml_alias, source_variables: source_variables)

    first_layer = List.first(ctx.assigns.layers)

    updated_layer =
      case {first_layer["layer_source"], source_variables} do
        {nil, [%{variable: source_variable, type: source_type} | _]} ->
          %{first_layer | "layer_source" => source_variable, "layer_source_type" => source_type}

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

    [layer_source_type] =
      get_in(ctx.assigns.source_variables, [Access.filter(&(&1.variable == value)), :type])

    updated_layer = %{layer | "layer_source" => value, "layer_source_type" => layer_source_type}
    updated_layers = List.replace_at(ctx.assigns.layers, idx, updated_layer)
    ctx = %{ctx | assigns: %{ctx.assigns | layers: updated_layers}}

    broadcast_event(ctx, "update_layer", %{"idx" => idx, "fields" => %{"layer_source" => value}})

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
    %{"layer_source" => layer_source, "layer_source_type" => source_type} =
      List.first(ctx.assigns.layers)

    updated_layers = ctx.assigns.layers ++ new_layer(layer_source, source_type)
    ctx = update_in(ctx.assigns, fn assigns -> Map.put(assigns, :layers, updated_layers) end)
    broadcast_event(ctx, "set_layers", %{"layers" => updated_layers})

    {:noreply, ctx}
  end

  def handle_event("remove_layer", %{"layer" => idx}, ctx) do
    updated_layers = List.delete_at(ctx.assigns.layers, idx)
    ctx = update_in(ctx.assigns, fn assigns -> Map.put(assigns, :layers, updated_layers) end)
    broadcast_event(ctx, "set_layers", %{"layers" => updated_layers})

    {:noreply, ctx}
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
        {:center, {lng, lat}}

      _ ->
        {:center, nil}
    end
  end

  defp convert_field("zoom", 0), do: {:zoom, nil}

  defp convert_field("style", "default"), do: {:style, nil}

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
    |> Map.put("variables", ctx.assigns.source_variables)
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
            name: :add_source,
            module: attrs.ml_alias,
            args: build_arg_source(source.source_id, source.source_data, source.source_type)
          }

    layers =
      for layer <- layers,
          layer = Map.new(layer, fn {k, v} -> convert_field(k, v) end),
          do: %{
            field: :layer,
            name: :add_layer,
            module: attrs.ml_alias,
            args:
              build_arg_layer(
                layer.layer_id,
                layer.layer_source,
                layer.layer_type,
                {layer.layer_color, layer.layer_radius, layer.layer_opacity}
              )
          }

    nodes = sources ++ layers

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

  defp build_arg_source(nil, _, _), do: nil
  defp build_arg_source(_, nil, _), do: nil

  defp build_arg_source(id, data, :geo),
    do: [id, Macro.var(String.to_atom(data), nil)]

  defp build_arg_source(id, data, _),
    do: [id, [type: :geojson, data: Macro.var(String.to_atom(data), nil)]]

  defp build_arg_layer(nil, _, _, _), do: nil
  defp build_arg_layer(_, nil, _, _), do: nil

  defp build_arg_layer(id, source, type, {color, radius, opacity}) do
    [[id: id, source: source, type: type, paint: build_arg_paint(type, {color, radius, opacity})]]
  end

  defp build_arg_paint(:heatmap, {_color, radius, opacity}) do
    [heatmap_radius: radius, heatmap_opacity: opacity]
  end

  defp build_arg_paint(type, {color, _radius, opacity}) do
    ["#{type}_color": color, "#{type}_opacity": opacity]
  end

  defp build_sources(layers) do
    for layer <- layers,
        do: %{
          "source_id" => layer["layer_source"],
          "source_data" => layer["layer_source"],
          "source_type" => layer["layer_source_type"]
        },
        uniq: true
  end

  defp missing_dep() do
    unless Code.ensure_loaded?(MapLibre) do
      ~s/{:maplibre, "~> 0.1.0"}/
    end
  end

  defp new_layer(layer_source \\ nil, layer_source_type \\ nil) do
    [
      %{
        "layer_id" => nil,
        "layer_source" => layer_source,
        "layer_source_type" => layer_source_type,
        "layer_type" => "circle",
        "layer_color" => "black",
        "layer_opacity" => 1,
        "layer_radius" => 10
      }
    ]
  end

  defp is_geometry(%module{}) when module in @geometries, do: true
  defp is_geometry("http" <> url), do: url |> String.split(".") |> List.last() == "geojson"
  defp is_geometry(_), do: false

  defp source_type(source), do: if(is_struct(source), do: :geo)
end
