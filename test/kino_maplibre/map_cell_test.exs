defmodule KinoMapLibre.MapCellTest do
  use ExUnit.Case, async: true

  alias KinoMapLibre.MapCell

  @root %{"style" => nil, "center" => nil, "zoom" => 0, "ml_alias" => MapLibre}
  @variables [
    %{type: "geo", variable: "conferences"},
    %{type: "url", variable: "earthquakes"},
    %{type: "url", variable: "urban_areas"},
    %{type: "url", variable: "rwanda_provinces"}
  ]
  @layer %{
    "layer_id" => nil,
    "layer_source" => nil,
    "layer_type" => "fill",
    "layer_color" => "black",
    "layer_opacity" => 1,
    "layer_radius" => 10
  }

  describe "code generation" do
    test "source for a default empty map" do
      attrs = Map.merge(@root, %{"variables" => @variables, "layers" => [@layer]})

      assert MapCell.to_source(attrs) == """
             MapLibre.new()\
             """
    end

    test "source for a default map with root values" do
      attrs =
        @root
        |> Map.merge(%{"zoom" => 3, "center" => "-74.5, 40"})
        |> Map.merge(%{"variables" => @variables, "layers" => [@layer]})

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

      attrs = Map.merge(@root, %{"variables" => @variables, "layers" => [layer]})

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

      attrs =
        Map.merge(@root, %{
          "variables" => @variables,
          "layers" => [layer_urban, layer_rwanda]
        })

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

      attrs = Map.merge(@root, %{"variables" => @variables, "layers" => [layer]})

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
  end
end
