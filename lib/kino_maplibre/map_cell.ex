defmodule KinoMapLibre.MapCell do
  @moduledoc false

  use Kino.JS, assets_path: "lib/assets/map_cell"
  use Kino.JS.Live
  use Kino.SmartCell, name: "Map"

  @as_int ["zoom"]
  @as_atom ["layer_type"]
  @as_float ["layer_opacity"]

  @impl true
  def init(attrs, ctx) do
    layer = if attrs["layers"], do: List.first(attrs["layers"]), else: nil

    fields = %{
      "style" => attrs["style"],
      "center" => attrs["center"],
      "zoom" => attrs["zoom"] || 0,
      "source_id" => layer["source_id"],
      "source_data" => layer["source_data"],
      "layer_id" => layer["layer_id"],
      "layer_source" => layer["layer_source"],
      "layer_type" => layer["layer_type"] || "fill",
      "layer_color" => layer["layer_color"] || "black",
      "layer_opacity" => layer["layer_opacity"] || 1
    }

    ctx = assign(ctx, fields: fields, ml_alias: nil, missing_dep: missing_dep())
    {:ok, ctx, reevaluate_on_change: true}
  end

  @impl true
  def scan_binding(pid, _binding, env) do
    ml_alias = ml_alias(env)
    send(pid, {:scan_binding_result, ml_alias})
  end

  @impl true
  def handle_connect(ctx) do
    payload = %{
      fields: ctx.assigns.fields,
      missing_dep: ctx.assigns.missing_dep
    }

    {:ok, payload, ctx}
  end

  @impl true
  def handle_info({:scan_binding_result, ml_alias}, ctx) do
    ctx = assign(ctx, ml_alias: ml_alias)
    {:noreply, ctx}
  end

  @impl true
  def handle_event("update_field", %{"field" => field, "value" => value}, ctx) do
    parsed_value = parse_value(field, value)
    ctx = update(ctx, :fields, &Map.put(&1, field, parsed_value))
    broadcast_event(ctx, "update", %{"fields" => %{field => parsed_value}})
    {:noreply, ctx}
  end

  defp parse_value(_field, ""), do: nil
  defp parse_value(field, value) when field in @as_int, do: String.to_integer(value)
  defp parse_value(field, value) when field in @as_float, do: value |> Float.parse() |> elem(0)
  defp parse_value(_field, value), do: value

  defp convert_field(field, nil), do: {String.to_atom(field), nil}

  # TODO: Needs improvements
  defp convert_field("center", center) do
    [lng, lat] = center |> String.replace(" ", "") |> String.split(",")
    {lng, _} = Float.parse(lng)
    {lat, _} = Float.parse(lat)
    {:center, {lng, lat}}
  end

  defp convert_field("zoom", 0), do: {:zoom, nil}

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
    ctx.assigns.fields
    |> add_layer()
    |> Map.put("ml_alias", ctx.assigns.ml_alias)
  end

  @impl true
  def to_source(attrs) do
    attrs
    |> extract_layer()
    |> to_quoted()
    |> Kino.SmartCell.quoted_to_string()
  end

  defp to_quoted(attrs) do
    attrs = Map.new(attrs, fn {k, v} -> convert_field(k, v) end)

    [root | nodes] = [
      %{
        field: nil,
        name: :new,
        module: attrs.ml_alias,
        args: build_arg_root(style: attrs.style, center: attrs.center, zoom: attrs.zoom)
      },
      %{
        field: :source,
        name: :add_source,
        module: attrs.ml_alias,
        args: build_arg_source(attrs.source_id, attrs.source_data)
      },
      %{
        field: :layer,
        name: :add_layer,
        module: attrs.ml_alias,
        args:
          build_arg_layer(
            attrs.layer_id,
            attrs.layer_source,
            attrs.layer_type,
            {attrs.layer_color, attrs.layer_opacity}
          )
      }
    ]

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

  defp build_arg_source(nil, _), do: nil
  defp build_arg_source(_, nil), do: nil
  defp build_arg_source(id, data), do: [id, [type: :geojson, data: data]]

  defp build_arg_layer(nil, _, _, _), do: nil
  defp build_arg_layer(_, nil, _, _), do: nil

  defp build_arg_layer(id, source, type, {color, opacity}) do
    [[id: id, source: source, type: type, paint: build_arg_paint(type, {color, opacity})]]
  end

  defp build_arg_paint(type, {color, opacity}) do
    ["#{type}_color": color, "#{type}_opacity": opacity]
  end

  defp missing_dep() do
    unless Code.ensure_loaded?(MapLibre) do
      ~s/{:maplibre, "~> 0.1.0"}/
    end
  end

  defp add_layer(attrs) do
    {root, layer} = Map.split(attrs, ["style", "center", "zoom"])
    Map.put(root, "layers", [layer])
  end

  defp extract_layer(%{"layers" => [layer]} = attrs) do
    attrs
    |> Map.delete("layers")
    |> Map.merge(layer)
  end
end
