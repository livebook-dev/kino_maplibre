defmodule Kino.MapLibre do
  @moduledoc """
  This kino allows rendering a regular MapLibre map and then adds an initial support for the
  [Evented](https://maplibre.org/maplibre-gl-js-docs/api/events/#evented) API to update the map
  with event capabilities.

  ## Examples

      map =
        Ml.new(center: {-68.13734351262877, 45.137451890638886}, zoom: 3)
        |> Kino.MapLibre.new()

      Kino.MapLibre.add_marker(map, {-68, 45}, color: "red", draggable: true)
      Kino.MapLibre.add_nav_controls(map, show_compass: false)
  """

  use Kino.JS, assets_path: "lib/assets/maplibre"
  use Kino.JS.Live

  defstruct spec: %{}, events: %{}

  @type t :: Kino.JS.Live.t()

  @type location :: {number(), number()}

  @doc """
  Creates a new kino with the given MapLibre style.
  """
  @spec new(MapLibre.t()) :: t()
  def new(%MapLibre{} = ml) do
    Kino.JS.Live.new(__MODULE__, ml)
  end

  @doc false
  def static(%__MODULE__{} = ml) do
    data = %{spec: ml.spec} |> Map.merge(ml.events)

    Kino.JS.new(__MODULE__, data, export_info_string: "maplibre")
  end

  def static(%MapLibre{} = ml) do
    data = %{spec: MapLibre.to_spec(ml)}

    Kino.JS.new(__MODULE__, data, export_info_string: "maplibre", export_key: :spec)
  end

  @doc """
  Adds a marker to the map at the given location

  ## Options

    * `:element` - DOM element to use as a marker. The default is a light blue, droplet-shaped SVG
      marker.

    * `:anchor` - A string indicating the part of the Marker that should be positioned closest to
      the coordinate set via Marker#setLngLat. Options are  "center",  "top", "bottom",  "left",
      "right",  "top-left",  "top-right",  "bottom-left" and  "bottom-right". Default: "center"

    * `:offset` - The offset in pixels as a
      [PointLike](https://maplibre.org/maplibre-gl-js-docs/api/geography/#pointlike) object to
      apply relative to the element"s center. Negatives indicate left and up.

    * `:color` - The color to use for the default marker if `:element` is not provided. The
      default is light blue. Default: "#3FB1CE"

    * `:scale` - The scale to use for the default marker if `:element` is not provided. The
      default scale corresponds to a height of 41px and a width of 27px. Default: 1

    * `:draggable` - A boolean indicating whether or not a marker is able to be dragged to a new
      position on the map. Default: `false`

    * `:click_tolerance` - The max number of pixels a user can shift the mouse pointer during a
      click on the marker for it to be considered a valid click (as opposed to a marker drag). The
      default is to inherit map"s `:click_tolerance`. Default: 0

    * `:rotation` - The rotation angle of the marker in degrees, relative to its respective
      `:rotation_alignment` setting. A positive value will rotate the marker clockwise. Default: 0

    * `:pitch_alignment` - "map" aligns the marker to the plane of the map. "viewport" aligns the
      marker to the plane of the viewport. "auto" automatically matches the value of
      `:rotation_alignment`. Default: "auto"

    * `:rotation_alignment` - "map" aligns the  marker"s rotation relative to the map, maintaining
      a bearing as the map rotates. "viewport" aligns the  marker"s rotation relative to the
      viewport, agnostic to map rotations. "auto" is equivalent to viewport. Default: "auto"

    See [the docs](https://maplibre.org/maplibre-gl-js-docs/api/markers/#marker) for more details.
  """
  @spec add_marker(t() | MapLibre.t() | %__MODULE__{}, location(), keyword()) ::
          :ok | %__MODULE__{}
  def add_marker(map, location, opts \\ [])

  def add_marker(%Kino.JS.Live{} = kino, location, opts) do
    Kino.JS.Live.cast(kino, {:add_marker, normalize_location(location), normalize_opts(opts)})
  end

  def add_marker(%_{} = ml, location, opts) do
    marker = %{location: normalize_location(location), options: normalize_opts(opts)}
    update_events(ml, "markers", marker)
  end

  @doc """
  Adds a navigation control to the map. A navigation control contains zoom buttons and a compass.

  ## Options

    * `:show_compass` - If true the compass button is included. Default: `true`

    * `:show_zoom` - If true the zoom-in and zoom-out buttons are included. Default: `true`

    * `:visualize_pitch` - If true the pitch is visualized by rotating X-axis of compass. Default:
      `false`

    * `:position` - The position on the map to which the control will be added. Valid values are
      "top-left" , "top-right" ,  "bottom-left" , and  "bottom-right" . Defaults to  "top-right".
      Default: "top-right"

    You can add multiple controls separately to have granular options over positioning and
    appearance

  ## Examples

        Kino.MapLibre.add_nav_controls(map, show_compass: false)
        Kino.MapLibre.add_nav_controls(map, show_zoom: false, position: "top-left")
  """
  @spec add_nav_controls(t() | MapLibre.t() | %__MODULE__{}, keyword()) :: :ok | %__MODULE__{}
  def add_nav_controls(map, opts \\ [])

  def add_nav_controls(%Kino.JS.Live{} = kino, opts) do
    position = Keyword.get(opts, :position, "top-right")
    Kino.JS.Live.cast(kino, {:add_nav_controls, position, normalize_opts(opts)})
  end

  def add_nav_controls(%_{} = ml, opts) do
    position = Keyword.get(opts, :position, "top-right")
    control = %{position: position, options: normalize_opts(opts)}
    update_events(ml, "controls", control)
  end

  @doc """
  A helper function to allow inspect a cluster on click. Receives the ID of the clusters layer
  ## Examples

        Kino.MapLibre.clusters_expansion(map, "earthquakes-clusters")
  """
  @spec(clusters_expansion(t() | MapLibre.t() | %__MODULE__{}, String.t()) :: :ok, %__MODULE__{})
  def clusters_expansion(%Kino.JS.Live{} = kino, clusters_id) do
    Kino.JS.Live.cast(kino, {:clusters_expansion, clusters_id})
  end

  def clusters_expansion(%MapLibre{} = ml, clusters_id) do
    update_events(ml, "clusters", clusters_id)
  end

  @doc """
  A helper function to create a per feature hover effect. Receives the ID of the layer where the
  effect should be enabled. It uses events and feature states to create the effect.

  ## Examples

        Kino.MapLibre.add_hover(map, "state-fills")

  See [the docs](https://maplibre.org/maplibre-gl-js-docs/api/map/#map#setfeaturestate) for more
  details.
  """
  @spec add_hover(t() | MapLibre.t() | %__MODULE__{}, String.t()) :: :ok | %__MODULE__{}
  def add_hover(%Kino.JS.Live{} = kino, layer_id) do
    Kino.JS.Live.cast(kino, {:add_hover, layer_id})
  end

  def add_hover(%_{} = ml, layer_id) do
    update_events(ml, "hover", layer_id)
  end

  @doc """
  A helper function that adds the event of centering to coordinates when clicking on a symbol.
  Receives the ID of the symbols layer and adds the event to all the symbols present in that layer
  """
  @spec center_on_click(t() | MapLibre.t() | %__MODULE__{}, String.t()) :: :ok | %__MODULE__{}
  def center_on_click(%Kino.JS.Live{} = kino, symbols_id) do
    Kino.JS.Live.cast(kino, {:center_on_click, symbols_id})
  end

  def center_on_click(%_{} = ml, symbols_id) do
    update_events(ml, "center", symbols_id)
  end

  @doc """
  Adds an image to the style. This image can be displayed on the map like any other icon in the
  style's sprite using its ID
  """
  @spec add_custom_image(t() | MapLibre.t() | %__MODULE__{}, String.t(), String.t()) ::
          :ok | %__MODULE__{}
  def add_custom_image(%Kino.JS.Live{} = kino, image_url, image_name) do
    Kino.JS.Live.cast(kino, {:add_custom_image, image_url, image_name})
  end

  def add_custom_image(%_{} = ml, image_url, image_name) do
    image = %{url: image_url, name: image_name}
    update_events(ml, "images", image)
  end

  @doc """
  Jumps to a given location using an animated transition
  """
  @spec jump_to(t(), location(), keyword()) :: :ok
  def jump_to(kino, location, opts \\ []) do
    Kino.JS.Live.cast(kino, {:jump_to, normalize_location(location), normalize_opts(opts)})
  end

  @impl true
  def init(ml, ctx) do
    {:ok,
     assign(ctx,
       ml: ml,
       markers: [],
       clusters: [],
       controls: [],
       hover: [],
       center: [],
       images: []
     )}
  end

  @impl true
  def handle_connect(ctx) do
    data = %{
      spec: MapLibre.to_spec(ctx.assigns.ml),
      markers: ctx.assigns.markers,
      clusters: ctx.assigns.clusters,
      controls: ctx.assigns.controls,
      hover: ctx.assigns.hover,
      center: ctx.assigns.center,
      images: ctx.assigns.images
    }

    {:ok, data, ctx}
  end

  @impl true
  def handle_cast({:add_marker, location, opts}, ctx) do
    marker = %{location: location, options: opts}
    broadcast_event(ctx, "add_marker", marker)
    ctx = update(ctx, :markers, &[marker | &1])
    {:noreply, ctx}
  end

  def handle_cast({:clusters_expansion, clusters}, ctx) do
    broadcast_event(ctx, "clusters_expansion", clusters)
    ctx = update(ctx, :clusters, &[clusters | &1])
    {:noreply, ctx}
  end

  def handle_cast({:add_nav_controls, position, opts}, ctx) do
    nav = %{position: position, options: opts}
    broadcast_event(ctx, "add_nav_controls", nav)
    ctx = update(ctx, :controls, &[nav | &1])
    {:noreply, ctx}
  end

  def handle_cast({:add_hover, layer}, ctx) do
    broadcast_event(ctx, "add_hover", layer)
    ctx = update(ctx, :hover, &[layer | &1])
    {:noreply, ctx}
  end

  def handle_cast({:center_on_click, symbols}, ctx) do
    broadcast_event(ctx, "center_on_click", symbols)
    ctx = update(ctx, :center, &[symbols | &1])
    {:noreply, ctx}
  end

  def handle_cast({:add_custom_image, image_url, image_name}, ctx) do
    image = %{url: image_url, name: image_name}
    broadcast_event(ctx, "add_custom_image", image)
    ctx = update(ctx, :images, &[image | &1])
    {:noreply, ctx}
  end

  def handle_cast({:jump_to, location, opts}, ctx) do
    jump_to = %{location: location, options: opts}
    broadcast_event(ctx, "jump_to", jump_to)
    {:noreply, ctx}
  end

  defp update_events(%MapLibre{} = ml, key, value) do
    ml = struct(__MODULE__, Map.from_struct(ml))
    update_in(ml.events, fn events -> Map.update(events, key, [value], &[value | &1]) end)
  end

  defp update_events(%__MODULE__{} = ml, key, value) do
    update_in(ml.events, fn events -> Map.update(events, key, [value], &[value | &1]) end)
  end

  defp normalize_location({lag, lng}), do: [lag, lng]

  defp normalize_opts(opts) do
    Map.new(opts, fn {key, value} ->
      {snake_to_camel(key), value}
    end)
  end

  defp snake_to_camel(atom) do
    string = Atom.to_string(atom)
    [part | parts] = String.split(string, "_")
    Enum.join([String.downcase(part, :ascii) | Enum.map(parts, &String.capitalize(&1, :ascii))])
  end
end
