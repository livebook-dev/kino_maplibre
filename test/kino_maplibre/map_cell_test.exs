defmodule KinoMapLibre.MapCellTest do
  use ExUnit.Case, async: true

  import Kino.Test

  alias KinoMapLibre.MapCell

  setup :configure_livebook_bridge

  @root %{
    "style" => "default",
    "center" => nil,
    "zoom" => 0,
    "maptiler_key" => nil,
    "use_maptiler_key_secret" => true,
    "maptiler_key_secret" => nil,
    "ml_alias" => MapLibre
  }
  @default_layer %{
    "layer_source" => nil,
    "layer_source_query" => nil,
    "layer_source_query_strict" => nil,
    "source_type" => nil,
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

  test "finds supported data in binding and sends new options to the client" do
    {kino, _source} = start_smart_cell!(MapCell, %{})

    earthquakes = %{
      "latitude" => [32.3646, 32.3357, -9.0665, 52.0779, -57.7326],
      "longitude" => [101.8781, 101.8413, -71.2103, 178.2851, 148.6945],
      "mag" => [5.9, 5.6, 6.5, 6.3, 6.4]
    }

    conferences = %{
      "coordinates" => ["100.4933, 13.7551", "6.6523, 46.5535", "-123.3596, 48.4268"],
      "year" => [2004, 2005, 2007]
    }

    point = %Geo.Point{coordinates: {100.4933, 13.7551}, properties: %{year: 2004}}
    quakes = "https://maplibre.org/maplibre-gl-js/docs/assets/earthquakes.geojson"

    binding = [earthquakes: earthquakes, conferences: conferences, point: point, quakes: quakes]
    # TODO: Use Code.env_for_eval on Elixir v1.14+
    env = :elixir.env_for_eval([])
    MapCell.scan_binding(kino.pid, binding, env)

    data_options = [
      %{columns: ["latitude", "longitude", "mag"], type: "table", variable: "earthquakes"},
      %{columns: ["coordinates", "year"], type: "table", variable: "conferences"},
      %{columns: nil, type: "geo", variable: "point"},
      %{columns: nil, type: nil, variable: "quakes"},
      %{columns: nil, type: "query", variable: "🌎 Geocoding"}
    ]

    assert_broadcast_event(kino, "set_source_variables", %{
      "source_variables" => ^data_options,
      "fields" => %{
        "layer_source" => "earthquakes",
        "source_type" => "table"
      }
    })
  end

  test "returns the defaults map when starting fresh with no data" do
    {_kino, source} = start_smart_cell!(MapCell, %{})

    assert source == "MapLibre.new()"
  end

  test "initializes properly when layer attributes are incomplete" do
    {_kino, source} =
      start_smart_cell!(MapCell, %{
        "layers" => [
          %{"layer_type" => "fill", "layer_source" => "urban_areas"}
        ]
      })

    assert source == """
           MapLibre.new()
           |> MapLibre.add_source("urban_areas", type: :geojson, data: urban_areas)
           |> MapLibre.add_layer(
             id: "urban_areas_fill_1",
             source: "urban_areas",
             type: :fill,
             paint: [fill_color: "#000000", fill_opacity: 1]
           )\
           """
  end

  describe "code generation" do
    test "source for a default empty map" do
      attrs = Map.merge(@root, %{"layers" => [@default_layer]})

      assert MapCell.to_source(attrs) == """
             MapLibre.new()\
             """
    end

    test "source for a default map with root values" do
      attrs =
        @root
        |> Map.merge(%{"zoom" => 3, "center" => "-74.5, 40"})
        |> Map.merge(%{"layers" => [@default_layer]})

      assert MapCell.to_source(attrs) == """
             MapLibre.new(center: {-74.5, 40.0}, zoom: 3)\
             """
    end

    test "source for a map with one source and one layer" do
      layer = %{
        "layer_source" => "urban_areas",
        "layer_type" => "fill",
        "layer_color" => "#00f900",
        "layer_opacity" => 0.5
      }

      attrs = build_attrs(layer)

      assert MapCell.to_source(attrs) == """
             MapLibre.new()
             |> MapLibre.add_source("urban_areas", type: :geojson, data: urban_areas)
             |> MapLibre.add_layer(
               id: "urban_areas_fill_1",
               source: "urban_areas",
               type: :fill,
               paint: [fill_color: "#00f900", fill_opacity: 0.5]
             )\
             """
    end

    test "source for a map with two sources and two layers" do
      layer_urban = %{
        "layer_source" => "urban_areas",
        "layer_type" => "fill",
        "layer_color" => "#00f900",
        "layer_opacity" => 0.5,
        "layer_radius" => 10
      }

      layer_rwanda = %{
        "layer_source" => "rwanda_provinces",
        "layer_type" => "fill",
        "layer_color" => "#ff40ff",
        "layer_opacity" => 1,
        "layer_radius" => 10
      }

      attrs = build_layers_attrs([layer_urban, layer_rwanda])

      assert MapCell.to_source(attrs) == """
             MapLibre.new()
             |> MapLibre.add_source("urban_areas", type: :geojson, data: urban_areas)
             |> MapLibre.add_source("rwanda_provinces", type: :geojson, data: rwanda_provinces)
             |> MapLibre.add_layer(
               id: "urban_areas_fill_1",
               source: "urban_areas",
               type: :fill,
               paint: [fill_color: "#00f900", fill_opacity: 0.5]
             )
             |> MapLibre.add_layer(
               id: "rwanda_provinces_fill_2",
               source: "rwanda_provinces",
               type: :fill,
               paint: [fill_color: "#ff40ff", fill_opacity: 1]
             )\
             """
    end

    test "source for a map with a layer with radius" do
      layer = %{
        "layer_source" => "earthquakes",
        "layer_type" => "heatmap",
        "layer_opacity" => 0.5,
        "layer_radius" => 5
      }

      attrs = build_attrs(layer)

      assert MapCell.to_source(attrs) == """
             MapLibre.new()
             |> MapLibre.add_source("earthquakes", type: :geojson, data: earthquakes)
             |> MapLibre.add_layer(
               id: "earthquakes_heatmap_1",
               source: "earthquakes",
               type: :heatmap,
               paint: [heatmap_radius: 5, heatmap_opacity: 0.5]
             )\
             """
    end

    test "source for a map with a geo source type" do
      layer = %{
        "layer_source" => "earthquakes",
        "source_type" => "geo",
        "layer_color" => "#00f900",
        "layer_opacity" => 0.7
      }

      attrs = build_attrs(layer)

      assert MapCell.to_source(attrs) == """
             MapLibre.new()
             |> MapLibre.add_geo_source("earthquakes", earthquakes)
             |> MapLibre.add_layer(
               id: "earthquakes_circle_1",
               source: "earthquakes",
               type: :circle,
               paint: [circle_color: "#00f900", circle_radius: 5, circle_opacity: 0.7]
             )\
             """
    end

    test "source for a map with tabular source type" do
      layer = %{
        "layer_source" => "earthquakes",
        "source_type" => "table",
        "layer_color" => "#00f900",
        "layer_opacity" => 0.7,
        "source_coordinates" => "coordinates",
        "coordinates_format" => "lat_lng"
      }

      attrs = build_attrs(layer)

      assert MapCell.to_source(attrs) == """
             MapLibre.new()
             |> MapLibre.add_table_source("earthquakes", earthquakes, {:lat_lng, "coordinates"})
             |> MapLibre.add_layer(
               id: "earthquakes_circle_1",
               source: "earthquakes",
               type: :circle,
               paint: [circle_color: "#00f900", circle_radius: 5, circle_opacity: 0.7]
             )\
             """
    end

    test "source for a map with clustered data" do
      layer = %{
        "layer_source" => "airports",
        "source_type" => "table",
        "layer_type" => "cluster",
        "source_coordinates" => "coordinates",
        "coordinates_format" => "lat_lng",
        "cluster_max" => 2000,
        "cluster_colors" => ["#77bb41", "#008cb4", "#f28cb1"]
      }

      attrs = build_attrs(layer)

      assert MapCell.to_source(attrs) == """
             MapLibre.new()
             |> MapLibre.add_table_source("airports_clustered", airports, {:lat_lng, "coordinates"},
               cluster: true
             )
             |> MapLibre.add_layer(
               id: "airports_clustered_cluster_1",
               source: "airports_clustered",
               type: :circle,
               paint: [
                 circle_color: [
                   "step",
                   ["get", "point_count"],
                   "#77bb41",
                   100,
                   "#008cb4",
                   2000,
                   "#f28cb1"
                 ],
                 circle_radius: ["step", ["get", "point_count"], 20, 100, 30, 2000, 40]
               ]
             )
             |> MapLibre.add_layer(
               id: "airports_count",
               source: "airports_clustered",
               type: :symbol,
               layout: [text_field: "{point_count_abbreviated}", text_size: 10],
               paint: [text_color: "black"]
             )\
             """
    end

    test "source for a map with one geocode source" do
      layer = %{
        "layer_source_query" => "brazil",
        "source_type" => "query",
        "layer_type" => "fill",
        "layer_color" => "#00f900",
        "layer_opacity" => 0.5
      }

      attrs = build_attrs(layer)

      assert MapCell.to_source(attrs) == """
             MapLibre.new()
             |> MapLibre.add_geocode_source("brazil", "brazil")
             |> MapLibre.add_layer(
               id: "brazil_fill_1",
               source: "brazil",
               type: :fill,
               paint: [fill_color: "#00f900", fill_opacity: 0.5]
             )\
             """
    end

    test "source for a map with one postal code geocode source" do
      layer = %{
        "layer_source_query" => "95819",
        "source_type" => "query",
        "layer_type" => "circle"
      }

      attrs = build_attrs(layer)

      assert MapCell.to_source(attrs) == """
             MapLibre.new()
             |> MapLibre.add_geocode_source("postalcode_95819", "95819")
             |> MapLibre.add_layer(
               id: "postalcode_95819_circle_1",
               source: "postalcode_95819",
               type: :circle,
               paint: [circle_color: "#000000", circle_radius: 5, circle_opacity: 1]
             )\
             """
    end

    test "source for a map with one strict geocode source" do
      layer = %{
        "layer_source_query" => "sao paulo",
        "layer_source_query_strict" => "state",
        "source_type" => "query",
        "layer_type" => "fill",
        "layer_color" => "#00f900",
        "layer_opacity" => 0.5
      }

      attrs = build_attrs(layer)

      assert MapCell.to_source(attrs) == """
             MapLibre.new()
             |> MapLibre.add_geocode_source("sao_paulo_state", "sao paulo", :state)
             |> MapLibre.add_layer(
               id: "sao_paulo_state_fill_1",
               source: "sao_paulo_state",
               type: :fill,
               paint: [fill_color: "#00f900", fill_opacity: 0.5]
             )\
             """
    end

    test "source for a map with external maptiler key" do
      root = %{
        "style" => "street (commercial)",
        "maptiler_key" => "maptiler_key_here",
        "use_maptiler_key_secret" => false
      }

      layer = %{
        "layer_source_query" => "brazil",
        "source_type" => "query",
        "layer_type" => "fill",
        "layer_color" => "#00f900",
        "layer_opacity" => 0.5
      }

      attrs = build_attrs(root, layer)

      assert MapCell.to_source(attrs) == """
             MapLibre.new(style: :street, key: "maptiler_key_here")
             |> MapLibre.add_geocode_source("brazil", "brazil")
             |> MapLibre.add_layer(
               id: "brazil_fill_1",
               source: "brazil",
               type: :fill,
               paint: [fill_color: "#00f900", fill_opacity: 0.5]
             )\
             """
    end
  end

  defp build_attrs(root_attrs \\ %{}, layer_attrs) do
    root_attrs = Map.merge(@root, root_attrs)
    layer_attrs = Map.merge(@default_layer, layer_attrs)
    Map.put(root_attrs, "layers", [layer_attrs])
  end

  defp build_layers_attrs(root_attrs \\ %{}, layer_attrs) do
    root_attrs = Map.merge(@root, root_attrs)
    layer_attrs = Enum.map(layer_attrs, &Map.merge(@default_layer, &1))
    Map.put(root_attrs, "layers", layer_attrs)
  end
end
