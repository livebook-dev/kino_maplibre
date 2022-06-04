defmodule KinoMapLibre.MapCellTest do
  use ExUnit.Case, async: true

  import Kino.Test

  alias KinoMapLibre.MapCell

  @root %{"style" => nil, "center" => nil, "zoom" => 0, "ml_alias" => MapLibre}
  @source %{"source_id" => nil, "source_data" => nil}
  @layer %{
    "layer_id" => nil,
    "layer_source" => nil,
    "layer_type" => "fill",
    "layer_color" => "black",
    "layer_opacity" => 1
  }

  describe "code generation" do
    test "source for a default empty map" do
      attrs = Map.merge(@root, %{"sources" => [@source], "layers" => [@layer]})

      assert MapCell.to_source(attrs) == """
             MapLibre.new()\
             """
    end

    test "source for a default map with root values" do
      attrs =
        @root
        |> Map.merge(%{"zoom" => 3, "center" => "-74.5, 40"})
        |> Map.merge(%{"sources" => [@source], "layers" => [@layer]})

      assert MapCell.to_source(attrs) == """
             MapLibre.new(center: {-74.5, 40.0}, zoom: 3)\
             """
    end

    test "source for a map with one source and one layer" do
      source = %{
        "source_id" => "urban-areas",
        "source_data" =>
          "https://d2ad6b4ur7yvpq.cloudfront.net/naturalearth-3.3.0/ne_50m_urban_areas.geojson"
      }

      layer = %{
        "layer_id" => "urban-areas-fill",
        "layer_source" => "urban-areas",
        "layer_type" => "fill",
        "layer_color" => "green",
        "layer_opacity" => 0.5
      }

      attrs = Map.merge(@root, %{"sources" => [source], "layers" => [layer]})

      assert MapCell.to_source(attrs) == """
             MapLibre.new()
             |> MapLibre.add_source("urban-areas",
               type: :geojson,
               data:
                 "https://d2ad6b4ur7yvpq.cloudfront.net/naturalearth-3.3.0/ne_50m_urban_areas.geojson"
             )
             |> MapLibre.add_layer(
               id: "urban-areas-fill",
               source: "urban-areas",
               type: :fill,
               paint: [fill_color: "green", fill_opacity: 0.5]
             )\
             """
    end

    test "source for a map with two sources and two layers" do
      source_urban = %{
        "source_id" => "urban-areas",
        "source_data" =>
          "https://d2ad6b4ur7yvpq.cloudfront.net/naturalearth-3.3.0/ne_50m_urban_areas.geojson"
      }

      source_rwanda = %{
        "source_id" => "rwanda-provinces",
        "source_data" =>
          "https://maplibre.org/maplibre-gl-js-docs/assets/rwanda-provinces.geojson"
      }

      layer_urban = %{
        "layer_id" => "urban-areas-fill",
        "layer_source" => "urban-areas",
        "layer_type" => "fill",
        "layer_color" => "green",
        "layer_opacity" => 0.5
      }

      layer_rwanda = %{
        "layer_id" => "rwanda-provinces-fill",
        "layer_source" => "rwanda-provinces",
        "layer_type" => "fill",
        "layer_color" => "magenta",
        "layer_opacity" => 1
      }

      attrs =
        Map.merge(@root, %{
          "sources" => [source_urban, source_rwanda],
          "layers" => [layer_urban, layer_rwanda]
        })

      assert MapCell.to_source(attrs) == """
             MapLibre.new()
             |> MapLibre.add_source("urban-areas",
               type: :geojson,
               data:
                 "https://d2ad6b4ur7yvpq.cloudfront.net/naturalearth-3.3.0/ne_50m_urban_areas.geojson"
             )
             |> MapLibre.add_source("rwanda-provinces",
               type: :geojson,
               data: "https://maplibre.org/maplibre-gl-js-docs/assets/rwanda-provinces.geojson"
             )
             |> MapLibre.add_layer(
               id: "urban-areas-fill",
               source: "urban-areas",
               type: :fill,
               paint: [fill_color: "green", fill_opacity: 0.5]
             )
             |> MapLibre.add_layer(
               id: "rwanda-provinces-fill",
               source: "rwanda-provinces",
               type: :fill,
               paint: [fill_color: "magenta", fill_opacity: 1]
             )\
             """
    end
  end
end
