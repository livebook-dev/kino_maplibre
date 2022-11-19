defmodule Kino.MapLibreTest do
  use ExUnit.Case, async: true

  import Kino.Test

  alias MapLibre, as: Ml

  setup :configure_livebook_bridge

  @markers [
    [{0, 0}, color: "red", draggable: true],
    [{-32, 2}, color: "green"],
    [{-45, 23}]
  ]

  describe "add_marker/3" do
    test "adds a marker to a static map" do
      ml = Ml.new() |> Kino.MapLibre.add_marker({0, 0})
      assert ml.events.markers == [%{location: [0, 0], options: %{}}]
    end

    test "adds a marker to a dynamic map" do
      ml = Ml.new() |> Kino.MapLibre.new()
      Kino.MapLibre.add_marker(ml, {0, 0}, color: "red")
      data = connect(ml)

      assert data.events.markers == [%{location: [0, 0], options: %{"color" => "red"}}]
      assert_broadcast_event(ml, "add_marker", %{location: [0, 0], options: %{"color" => "red"}})
    end

    test "adds a maker to a converted map" do
      ml = Ml.new() |> Kino.MapLibre.add_marker({0, 0}, color: "green") |> Kino.MapLibre.new()
      Kino.MapLibre.add_marker(ml, {-45, 15}, color: "purple")
      data = connect(ml)

      assert data.events.markers == [
               %{location: [-45, 15], options: %{"color" => "purple"}},
               %{location: [0, 0], options: %{"color" => "green"}}
             ]

      assert_broadcast_event(ml, "add_marker", %{
        location: [-45, 15],
        options: %{"color" => "purple"}
      })
    end
  end

  describe "add_markers/2" do
    test "adds a list of markers to a static map" do
      ml = Ml.new() |> Kino.MapLibre.add_markers(@markers)

      assert ml.events.markers == [
               %{location: [0, 0], options: %{"color" => "red", "draggable" => true}},
               %{location: [-32, 2], options: %{"color" => "green"}},
               %{location: [-45, 23], options: %{}}
             ]
    end

    test "adds a list of markers to a static map that already has a marker" do
      ml =
        Ml.new()
        |> Kino.MapLibre.add_marker({90, 0}, color: "purple")
        |> Kino.MapLibre.add_markers(@markers)

      assert ml.events.markers == [
               %{location: [0, 0], options: %{"color" => "red", "draggable" => true}},
               %{location: [-32, 2], options: %{"color" => "green"}},
               %{location: [-45, 23], options: %{}},
               %{location: [90, 0], options: %{"color" => "purple"}}
             ]
    end

    test "adds a list of markers to a dynamic map" do
      ml = Ml.new() |> Kino.MapLibre.new()
      Kino.MapLibre.add_markers(ml, @markers)
      data = connect(ml)

      assert data.events.markers == [
               %{location: [0, 0], options: %{"color" => "red", "draggable" => true}},
               %{location: [-32, 2], options: %{"color" => "green"}},
               %{location: [-45, 23], options: %{}}
             ]

      assert_broadcast_event(ml, "add_markers", [
        %{location: [0, 0], options: %{"color" => "red", "draggable" => true}},
        %{location: [-32, 2], options: %{"color" => "green"}},
        %{location: [-45, 23], options: %{}}
      ])
    end

    test "adds a list of markers to a dynamic map that already has a marker" do
      ml = Ml.new() |> Kino.MapLibre.new()
      Kino.MapLibre.add_marker(ml, {90, 0}, color: "purple")
      Kino.MapLibre.add_markers(ml, @markers)
      data = connect(ml)

      assert data.events.markers == [
               %{location: [0, 0], options: %{"color" => "red", "draggable" => true}},
               %{location: [-32, 2], options: %{"color" => "green"}},
               %{location: [-45, 23], options: %{}},
               %{location: [90, 0], options: %{"color" => "purple"}}
             ]

      assert_broadcast_event(ml, "add_markers", [
        %{location: [0, 0], options: %{"color" => "red", "draggable" => true}},
        %{location: [-32, 2], options: %{"color" => "green"}},
        %{location: [-45, 23], options: %{}}
      ])
    end

    test "adds a list of makers to a converted map" do
      markers = [
        [{90, 0}, color: "purple"],
        [{-40, 20}, color: "pink"]
      ]

      ml = Ml.new() |> Kino.MapLibre.add_markers(markers) |> Kino.MapLibre.new()

      Kino.MapLibre.add_markers(ml, @markers)
      data = connect(ml)

      assert data.events.markers == [
               %{location: [0, 0], options: %{"color" => "red", "draggable" => true}},
               %{location: [-32, 2], options: %{"color" => "green"}},
               %{location: [-45, 23], options: %{}},
               %{location: [90, 0], options: %{"color" => "purple"}},
               %{location: [-40, 20], options: %{"color" => "pink"}}
             ]

      assert_broadcast_event(ml, "add_markers", [
        %{location: [0, 0], options: %{"color" => "red", "draggable" => true}},
        %{location: [-32, 2], options: %{"color" => "green"}},
        %{location: [-45, 23], options: %{}}
      ])
    end

    test "returns the map unchanged if an empty list is given" do
      ml = Ml.new() |> Kino.MapLibre.add_markers([])
      kml = Kino.MapLibre.new(ml)
      Kino.MapLibre.add_markers(kml, [])
      data = connect(kml)

      assert is_struct(ml, MapLibre)
      refute Map.has_key?(ml, :events)
      assert data.events == %{}
    end
  end

  describe "add_nav_controls/3" do
    test "adds a nav control to a static map" do
      ml = Ml.new() |> Kino.MapLibre.add_nav_controls()
      assert ml.events.controls == [%{options: %{}, position: "top-right"}]
    end

    test "adds a nav control to a dynamic map" do
      ml = Ml.new() |> Kino.MapLibre.new()
      Kino.MapLibre.add_nav_controls(ml, show_compass: false)
      data = connect(ml)

      assert data.events.controls == [
               %{options: %{"showCompass" => false}, position: "top-right"}
             ]

      assert_broadcast_event(ml, "add_nav_controls", %{
        options: %{"showCompass" => false},
        position: "top-right"
      })
    end

    test "adds a nav control to a converted map" do
      ml = Ml.new() |> Kino.MapLibre.add_nav_controls(show_compass: false) |> Kino.MapLibre.new()
      Kino.MapLibre.add_nav_controls(ml, show_zoom: false, position: "top-left")
      data = connect(ml)

      assert data.events.controls == [
               %{options: %{"position" => "top-left", "showZoom" => false}, position: "top-left"},
               %{options: %{"showCompass" => false}, position: "top-right"}
             ]

      assert_broadcast_event(ml, "add_nav_controls", %{
        options: %{"position" => "top-left", "showZoom" => false},
        position: "top-left"
      })
    end
  end

  describe "clusters_expansion/2" do
    test "adds a cluster expansion to a static map" do
      ml = Ml.new() |> Kino.MapLibre.clusters_expansion("clusters")
      assert ml.events.clusters == ["clusters"]
    end

    test "adds a cluster expansion to a dynamic map" do
      ml = Ml.new() |> Kino.MapLibre.new()
      Kino.MapLibre.clusters_expansion(ml, "clusters")
      data = connect(ml)

      assert data.events.clusters == ["clusters"]
      assert_broadcast_event(ml, "clusters_expansion", "clusters")
    end

    test "adds a cluster expansion to a converted map" do
      ml = Ml.new() |> Kino.MapLibre.clusters_expansion("clusters") |> Kino.MapLibre.new()
      Kino.MapLibre.clusters_expansion(ml, "another_clusters")
      data = connect(ml)

      assert data.events.clusters == ["another_clusters", "clusters"]
      assert_broadcast_event(ml, "clusters_expansion", "another_clusters")
    end
  end

  describe "add_hover/2" do
    test "adds an hover effect to a static map" do
      ml = Ml.new() |> Kino.MapLibre.add_hover("hover")
      assert ml.events.hover == ["hover"]
    end

    test "adds an hover effect to a dynamic map" do
      ml = Ml.new() |> Kino.MapLibre.new()
      Kino.MapLibre.add_hover(ml, "hover")
      data = connect(ml)

      assert data.events.hover == ["hover"]
      assert_broadcast_event(ml, "add_hover", "hover")
    end

    test "adds an hover effect to a converted map" do
      ml = Ml.new() |> Kino.MapLibre.add_hover("hover") |> Kino.MapLibre.new()
      Kino.MapLibre.add_hover(ml, "another_hover")
      data = connect(ml)

      assert data.events.hover == ["another_hover", "hover"]
      assert_broadcast_event(ml, "add_hover", "another_hover")
    end
  end

  describe "center_on_click/2" do
    test "adds a center on click to a static map" do
      ml = Ml.new() |> Kino.MapLibre.center_on_click("center")
      assert ml.events.center == ["center"]
    end

    test "adds a center on click to a dynamic map" do
      ml = Ml.new() |> Kino.MapLibre.new()
      Kino.MapLibre.center_on_click(ml, "center")
      data = connect(ml)

      assert data.events.center == ["center"]
      assert_broadcast_event(ml, "center_on_click", "center")
    end

    test "adds a center on click to a converted map" do
      ml = Ml.new() |> Kino.MapLibre.center_on_click("center") |> Kino.MapLibre.new()
      Kino.MapLibre.center_on_click(ml, "another_center")
      data = connect(ml)

      assert data.events.center == ["another_center", "center"]
      assert_broadcast_event(ml, "center_on_click", "another_center")
    end
  end

  describe "info_on_click/3" do
    test "adds an info on click to a static map" do
      ml = Ml.new() |> Kino.MapLibre.info_on_click("states", "name")
      assert ml.events.info == [%{layer: "states", property: "name"}]
    end

    test "adds an info on click to a dynamic map" do
      ml = Ml.new() |> Kino.MapLibre.new()
      Kino.MapLibre.info_on_click(ml, "states", "name")
      data = connect(ml)

      assert data.events.info == [%{layer: "states", property: "name"}]
      assert_broadcast_event(ml, "info_on_click", %{layer: "states", property: "name"})
    end

    test "adds an info on click to a converted map" do
      ml = Ml.new() |> Kino.MapLibre.info_on_click("states", "region") |> Kino.MapLibre.new()
      Kino.MapLibre.info_on_click(ml, "streets", "name")
      data = connect(ml)

      assert data.events.info == [
               %{layer: "streets", property: "name"},
               %{layer: "states", property: "region"}
             ]

      assert_broadcast_event(ml, "info_on_click", %{layer: "streets", property: "name"})
    end
  end

  describe "add_custom_image/3" do
    test "adds a custom image to a static map" do
      ml = Ml.new() |> Kino.MapLibre.add_custom_image("kitten", "kitten_url")
      assert ml.events.images == [%{name: "kitten", url: "kitten_url", options: %{}}]
    end

    test "adds a custom image to a dynamic map" do
      ml = Ml.new() |> Kino.MapLibre.new()
      Kino.MapLibre.add_custom_image(ml, "kitten", "kitten_url")
      data = connect(ml)

      assert data.events.images == [%{name: "kitten", url: "kitten_url", options: %{}}]

      assert_broadcast_event(ml, "add_custom_image", %{
        name: "kitten",
        url: "kitten_url",
        options: %{}
      })
    end

    test "adds a custom image to a converted map" do
      ml =
        Ml.new() |> Kino.MapLibre.add_custom_image("kitten", "kitten_url") |> Kino.MapLibre.new()

      Kino.MapLibre.add_custom_image(ml, "another_kitten", "another_kitten_url")
      data = connect(ml)

      assert data.events.images == [
               %{name: "another_kitten", url: "another_kitten_url", options: %{}},
               %{name: "kitten", url: "kitten_url", options: %{}}
             ]

      assert_broadcast_event(ml, "add_custom_image", %{
        name: "another_kitten",
        url: "another_kitten_url"
      })
    end

    test "broadcasts options as well" do
      ml = Ml.new() |> Kino.MapLibre.add_custom_image("kitten", "kitten_url", sdf: true)
      assert ml.events.images == [%{name: "kitten", url: "kitten_url", options: %{"sdf" => true}}]
    end
  end

  describe "jump_to/3" do
    test "adds a jump effect to a static map" do
      ml = Ml.new() |> Kino.MapLibre.jump_to({0, 0})
      assert ml.events.jumps == [%{location: {0, 0}, options: %{}}]
    end

    test "adds a jump effect to a dynamic" do
      ml = Ml.new() |> Kino.MapLibre.new()
      Kino.MapLibre.jump_to(ml, {0, 0}, zoom: 6)
      data = connect(ml)

      assert data.events.jumps == [%{location: {0, 0}, options: %{"zoom" => 6}}]
      assert_broadcast_event(ml, "jumps", %{location: {0, 0}, options: %{"zoom" => 6}})
    end

    test "adds a jump effect to a converted map" do
      ml = Ml.new() |> Kino.MapLibre.jump_to({0, 0}) |> Kino.MapLibre.new()
      Kino.MapLibre.jump_to(ml, {-40, 20}, zoom: 6)
      data = connect(ml)

      assert data.events.jumps == [
               %{location: {-40, 20}, options: %{"zoom" => 6}},
               %{location: {0, 0}, options: %{}}
             ]

      assert_broadcast_event(ml, "jumps", %{location: {-40, 20}, options: %{"zoom" => 6}})
    end
  end
end
