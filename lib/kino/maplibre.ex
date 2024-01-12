defmodule Kino.MapLibre do
  @moduledoc """
  This Kino allows rendering a regular MapLibre map and then adds an initial support for the
  [Evented](https://maplibre.org/maplibre-gl-js-docs/api/events/#evented) API to update the map
  with event capabilities.

  There are two types of maps: static and dynamic. Essentially, a dynamic map can be updated on
  the fly without having to be re-evaluated. To make a map dynamic you need to wrap it in `Kino.MapLibre.new/1`

  All functions are available for both map types.

  ## Examples

      map =
        Ml.new(center: {-68.13734351262877, 45.137451890638886}, zoom: 3)
        # This makes the map dynamic
        |> Kino.MapLibre.new()

      # These markers will be added with no need to re-evaluate the map
      Kino.MapLibre.add_marker(map, {-68, 45}, color: "red", draggable: true)
      Kino.MapLibre.add_marker(map, {-69, 50})

      # This is a static map and the markers will be added on evaluation
      Ml.new(center: {-68.13734351262877, 45.137451890638886}, zoom: 3)
      |> Kino.MapLibre.add_marker({-68, 45}, color: "red", draggable: true)
      |> Kino.MapLibre.add_marker({-69, 50})
  """

  use Kino.JS, assets_path: "lib/assets/maplibre"
  use Kino.JS.Live

  defstruct spec: %{}, events: %{}

  @type t :: Kino.JS.Live.t()

  @type location :: {number(), number()}

  @type maplibre :: t() | MapLibre.t() | Kino.JS.Live.t()

  @doc """
  Creates a new kino with the given MapLibre style.
  """
  @spec new(MapLibre.t()) :: t()
  def new(%MapLibre{} = ml) do
    ml = %{spec: ml.spec, events: %{}}
    Kino.JS.Live.new(__MODULE__, ml)
  end

  def new(%__MODULE__{} = ml) do
    Kino.JS.Live.new(__MODULE__, ml)
  end

  @doc false
  def static(%__MODULE__{} = ml) do
    data = %{spec: ml.spec, events: ml.events}

    Kino.JS.new(__MODULE__, data,
      export: fn data -> {"maplibre", data} end,
      # TODO: remove legacy export attribute once we require Kino v0.11.0
      export_info_string: "maplibre"
    )
  end

  def static(%MapLibre{} = ml) do
    data = %{spec: ml.spec, events: %{}}

    Kino.JS.new(__MODULE__, data,
      export: fn data -> {"maplibre", data} end,
      # TODO: remove legacy export attribute once we require Kino v0.11.0
      export_info_string: "maplibre"
    )
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
  @spec add_marker(maplibre(), location(), keyword()) ::
          :ok | %__MODULE__{}
  def add_marker(map, location, opts \\ []) do
    marker = %{location: normalize_location(location), options: normalize_opts(opts)}
    update_events(map, :markers, marker)
  end

  @doc """
  Receives a list of markers and adds them to the map

  ## Examples

      markers = [
        [{0, 0}, color: "red", draggable: true],
        [{-32, 2}, color: "green"],
        [{-45, 23}]
      ]

      Ml.new(center: {-68.13734351262877, 45.137451890638886}, zoom: 3)
      |> Kino.MapLibre.add_markers(markers)
  """
  @spec add_markers(maplibre(), list()) :: :ok | %__MODULE__{}
  def add_markers(map, []), do: map

  def add_markers(map, markers) do
    markers =
      Enum.map(markers, fn [location | opts] ->
        %{location: normalize_location(location), options: normalize_opts(opts)}
      end)

    update_events(map, :markers, markers)
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
  @spec add_nav_controls(maplibre(), keyword()) :: :ok | %__MODULE__{}
  def add_nav_controls(map, opts \\ []) do
    {position, opts} = Keyword.pop(opts, :position, "top-right")
    control = %{position: position, options: normalize_opts(opts)}
    update_events(map, :controls, control)
  end

  @doc """
  Adds a geolocate control to the map.

  A geolocate control provides a button that uses the browser's
  geolocation API to locate the user on the map.

  ## Options

    * `:track_user_location` - If true, the geolocate control acts as a toggle button that when
    active the user's location is actively monitored for changes. Default: `false`

    * `:high_accuracy` - Uses a more accurate position if the device is able to. Default: `false`

    * `:show_user_location` - A dot will be shown on the map at the user's location. Default: `true`

    * `:show_accuracy_circle` - By default, if `:show_user_location` is `true`, a transparent
    circle will be drawn around the user location indicating the accuracy (95% confidence level)
    of the user's location. Default: `true`

  ## Examples

        Kino.MapLibre.add_locate(map)
        Kino.MapLibre.add_locate(map, high_accuracy: true, track_user_location: true)
  """
  @spec add_locate(maplibre(), keyword()) :: :ok | %__MODULE__{}
  def add_locate(map, opts \\ []) do
    {high_accuracy, opts} = Keyword.pop(opts, :high_accuracy, false)
    locate = %{high_accuracy: high_accuracy, options: normalize_opts(opts)}
    update_events(map, :locate, locate)
  end

  @doc """
  Adds a terrain control to the map for turning the terrain on and off.

  ## Examples

        Kino.MapLibre.add_terrain(map)
  """
  @spec add_terrain(maplibre()) :: :ok | %__MODULE__{}
  def add_terrain(map) do
    update_events(map, :terrain, %{})
  end

  @doc """
  Adds a geocoder control to the map to handle Nominatim queries

  ## Examples

        Kino.MapLibre.add_geocode(map)
  """
  @spec add_geocode(maplibre()) :: :ok | %__MODULE__{}
  def add_geocode(map) do
    update_events(map, :geocode, %{})
  end

  @doc """
  A helper function to allow inspect a cluster on click. Receives the ID of the clusters layer
  ## Examples

        Kino.MapLibre.clusters_expansion(map, "earthquakes-clusters")
  """
  @spec clusters_expansion(maplibre(), String.t()) :: :ok | %__MODULE__{}
  def clusters_expansion(map, clusters_id) do
    update_events(map, :clusters, clusters_id)
  end

  @doc """
  A helper function to create a per feature hover effect. Receives the ID of the layer where the
  effect should be enabled. It uses events and feature states to create the effect.

  ## Examples

        Kino.MapLibre.add_hover(map, "state-fills")

  See [the docs](https://maplibre.org/maplibre-gl-js-docs/api/map/#map#setfeaturestate) for more
  details.
  """
  @spec add_hover(maplibre(), String.t()) :: :ok | %__MODULE__{}
  def add_hover(map, layer_id) do
    update_events(map, :hover, layer_id)
  end

  @doc """
  A helper function that adds the event of centering to coordinates when clicking on a symbol.
  Receives the ID of the symbols layer and adds the event to all the symbols present in that layer
  """
  @spec center_on_click(maplibre(), String.t()) :: :ok | %__MODULE__{}
  def center_on_click(map, symbols_id) do
    update_events(map, :center, symbols_id)
  end

  @doc """
  A helper function that adds the event to show the information of a given property on click.
  Receives the layer ID and the name of the property to show.
  """
  @spec info_on_click(maplibre(), String.t(), String.t()) :: :ok | %__MODULE__{}
  def info_on_click(map, layer_id, property) do
    info = %{layer: layer_id, property: property}
    update_events(map, :info, info)
  end

  @doc """
  Adds an image to the style. This image can be displayed on the map like any other icon in the
  style's sprite using its ID
  """
  @spec add_custom_image(maplibre(), String.t(), String.t()) ::
          :ok | %__MODULE__{}
  def add_custom_image(map, image_name, image_url, opts \\ []) do
    image = %{name: image_name, url: image_url, options: normalize_opts(opts)}
    update_events(map, :images, image)
  end

  @doc """
  Jumps to a given location using an animated transition
  """
  @spec jump_to(t(), location(), keyword()) :: :ok
  def jump_to(map, location, opts \\ []) do
    jump = %{location: location, options: normalize_opts(opts)}
    update_events(map, :jumps, jump)
  end

  @doc """
  Fits the map to the rectangle given by the 2 vertices in `bounds`
  """
  def fit_bounds(map, bounds, opts \\ []) do
    fit_bounds = %{bounds: bounds, options: normalize_opts(opts)}
    update_events(map, :fit_bounds, fit_bounds)
  end

  @impl true
  def init(ml, ctx) do
    {:ok, assign(ctx, spec: ml.spec, events: ml.events)}
  end

  @impl true
  def handle_connect(ctx) do
    data = %{spec: ctx.assigns.spec, events: ctx.assigns.events}
    {:ok, data, ctx}
  end

  @impl true
  def handle_cast({:markers, markers}, ctx) when is_list(markers) do
    broadcast_event(ctx, "add_markers", markers)
    ctx = update_assigned_events(ctx, :markers, markers)
    {:noreply, ctx}
  end

  def handle_cast({:markers, marker}, ctx) do
    broadcast_event(ctx, "add_marker", marker)
    ctx = update_assigned_events(ctx, :markers, marker)
    {:noreply, ctx}
  end

  def handle_cast({:clusters, clusters}, ctx) do
    broadcast_event(ctx, "clusters_expansion", clusters)
    ctx = update_assigned_events(ctx, :clusters, clusters)
    {:noreply, ctx}
  end

  def handle_cast({:controls, control}, ctx) do
    broadcast_event(ctx, "add_nav_controls", control)
    ctx = update_assigned_events(ctx, :controls, control)
    {:noreply, ctx}
  end

  def handle_cast({:locate, locate}, ctx) do
    broadcast_event(ctx, "add_locate", locate)
    ctx = update_assigned_events(ctx, :locate, locate)
    {:noreply, ctx}
  end

  def handle_cast({:terrain, terrain}, ctx) do
    broadcast_event(ctx, "add_terrain", terrain)
    ctx = update_assigned_events(ctx, :terrain, terrain)
    {:noreply, ctx}
  end

  def handle_cast({:geocode, geocode}, ctx) do
    broadcast_event(ctx, "add_geocode", geocode)
    ctx = update_assigned_events(ctx, :geocode, geocode)
    {:noreply, ctx}
  end

  def handle_cast({:hover, layer}, ctx) do
    broadcast_event(ctx, "add_hover", layer)
    ctx = update_assigned_events(ctx, :hover, layer)
    {:noreply, ctx}
  end

  def handle_cast({:center, symbols}, ctx) do
    broadcast_event(ctx, "center_on_click", symbols)
    ctx = update_assigned_events(ctx, :center, symbols)
    {:noreply, ctx}
  end

  def handle_cast({:info, info}, ctx) do
    broadcast_event(ctx, "info_on_click", info)
    ctx = update_assigned_events(ctx, :info, info)
    {:noreply, ctx}
  end

  def handle_cast({:images, image}, ctx) do
    broadcast_event(ctx, "add_custom_image", image)
    ctx = update_assigned_events(ctx, :images, image)
    {:noreply, ctx}
  end

  def handle_cast({:jumps, jump}, ctx) do
    broadcast_event(ctx, "jump_to", jump)
    ctx = update_assigned_events(ctx, :jumps, jump)
    {:noreply, ctx}
  end

  def handle_cast({:fit_bounds, bounds}, ctx) do
    broadcast_event(ctx, "fit_bounds", bounds)
    ctx = update_assigned_events(ctx, :fit_bounds, bounds)
    {:noreply, ctx}
  end

  defp update_events(%MapLibre{} = ml, key, value) do
    update_events(%__MODULE__{spec: ml.spec}, key, value)
  end

  defp update_events(%__MODULE__{} = ml, key, value) do
    update_in(ml.events, fn events ->
      Map.update(events, key, List.flatten([value]), &List.flatten([value | &1]))
    end)
  end

  defp update_events(kino, key, value) do
    Kino.JS.Live.cast(kino, {key, value})
  end

  defp update_assigned_events(ctx, key, value) do
    update_in(ctx.assigns.events, fn events ->
      Map.update(events, key, List.flatten([value]), &List.flatten([value | &1]))
    end)
  end

  defp normalize_location({lng, lat}), do: [lng, lat]

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
