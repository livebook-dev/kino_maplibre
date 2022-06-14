defmodule KinoMapLibre.MapCellTest do
  use ExUnit.Case, async: true

  alias KinoMapLibre.MapCell

  @root %{"style" => nil, "center" => nil, "zoom" => 0, "ml_alias" => MapLibre}
  @layer %{
    "layer_id" => nil,
    "layer_source" => nil,
    "layer_type" => "circle",
    "layer_color" => "black",
    "layer_opacity" => 1,
    "layer_radius" => 10
  }

  describe "code generation" do
    test "source for a default empty map" do
      attrs = Map.merge(@root, %{"layers" => [@layer]})

      assert MapCell.to_source(attrs) == """
             MapLibre.new()\
             """
    end

    test "source for a default map with root values" do
      attrs =
        @root
        |> Map.merge(%{"zoom" => 3, "center" => "-74.5, 40"})
        |> Map.merge(%{"layers" => [@layer]})

      assert MapCell.to_source(attrs) == """
             MapLibre.new(center: {-74.5, 40.0}, zoom: 3)\
             """
    end

    test "source for a map with one source and one layer" do
      layer = %{
        "layer_id" => "urban-areas-fill",
        "layer_source" => "urban_areas",
        "layer_type" => "fill",
        "layer_color" => "green",
        "layer_opacity" => 0.5,
        "layer_radius" => 10
      }

      attrs = Map.merge(@root, %{"layers" => [layer]})

      assert MapCell.to_source(attrs) == """
             MapLibre.new()
             |> MapLibre.add_source("urban_areas", type: :geojson, data: urban_areas)
             |> MapLibre.add_layer(
               id: "urban-areas-fill",
               source: "urban_areas",
               type: :fill,
               paint: [fill_color: "green", fill_opacity: 0.5]
             )\
             """
    end

    test "source for a map with two sources and two layers" do
      layer_urban = %{
        "layer_id" => "urban-areas-fill",
        "layer_source" => "urban_areas",
        "layer_type" => "fill",
        "layer_color" => "green",
        "layer_opacity" => 0.5,
        "layer_radius" => 10
      }

      layer_rwanda = %{
        "layer_id" => "rwanda-provinces-fill",
        "layer_source" => "rwanda_provinces",
        "layer_type" => "fill",
        "layer_color" => "magenta",
        "layer_opacity" => 1,
        "layer_radius" => 10
      }

      attrs = Map.merge(@root, %{"layers" => [layer_urban, layer_rwanda]})

      assert MapCell.to_source(attrs) == """
             MapLibre.new()
             |> MapLibre.add_source("urban_areas", type: :geojson, data: urban_areas)
             |> MapLibre.add_source("rwanda_provinces", type: :geojson, data: rwanda_provinces)
             |> MapLibre.add_layer(
               id: "urban-areas-fill",
               source: "urban_areas",
               type: :fill,
               paint: [fill_color: "green", fill_opacity: 0.5]
             )
             |> MapLibre.add_layer(
               id: "rwanda-provinces-fill",
               source: "rwanda_provinces",
               type: :fill,
               paint: [fill_color: "magenta", fill_opacity: 1]
             )\
             """
    end

    test "source for a map with a layer with radius" do
      layer = %{
        "layer_id" => "earthquakes-heatmap",
        "layer_source" => "earthquakes",
        "layer_type" => "heatmap",
        "layer_color" => "black",
        "layer_opacity" => 0.5,
        "layer_radius" => 5
      }

      attrs = Map.merge(@root, %{"layers" => [layer]})

      assert MapCell.to_source(attrs) == """
             MapLibre.new()
             |> MapLibre.add_source("earthquakes", type: :geojson, data: earthquakes)
             |> MapLibre.add_layer(
               id: "earthquakes-heatmap",
               source: "earthquakes",
               type: :heatmap,
               paint: [heatmap_radius: 5, heatmap_opacity: 0.5]
             )\
             """
    end

    test "source for a map with a geo source type" do
      layer = %{
        "layer_id" => "earthquakes-heatmap",
        "layer_source" => "earthquakes",
        "layer_source_type" => :geo,
        "layer_type" => "circle",
        "layer_color" => "green",
        "layer_opacity" => 0.7,
        "layer_radius" => 10
      }

      attrs = Map.merge(@root, %{"layers" => [layer]})

      assert MapCell.to_source(attrs) == """
             MapLibre.new()
             |> MapLibre.add_source("earthquakes", earthquakes)
             |> MapLibre.add_layer(
               id: "earthquakes-heatmap",
               source: "earthquakes",
               type: :circle,
               paint: [circle_color: "green", circle_opacity: 0.7]
             )\
             """
    end
  end
end
