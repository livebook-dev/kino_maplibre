import * as maplibregl from "maplibre-gl";
import VectorTextProtocol from "maplibre-gl-vector-text-protocol";
import MaplibreGeocoder from "@maplibre/maplibre-gl-geocoder";
import * as MaplibreExportControl from "@watergis/maplibre-gl-export";

import "@maplibre/maplibre-gl-geocoder/dist/maplibre-gl-geocoder.css";
import "maplibre-gl/dist/maplibre-gl.css";
import "@watergis/maplibre-gl-export/dist/maplibre-gl-export.css";

export function init(ctx, data) {
  ctx.importCSS("main.css");

  ctx.root.innerHTML = `
    <div id='map' style='width: 896px; height: 400px;'></div>
  `;

  const container = "map";
  const style = data.spec;
  const {
    markers = [],
    clusters = [],
    controls = [],
    locate = [],
    terrain = [],
    geocode = [],
    fullscreen = [],
    scale = [],
    export_map = [],
    hover = [],
    center = [],
    info = [],
    images = [],
    jumps = [],
    fit_bounds = [],
  } = data.events;

  const map = new maplibregl.Map({ container: container, style: style });
  VectorTextProtocol.addProtocols(maplibregl);

  map.on("load", function () {
    markers.forEach(({ location, options }) => {
      addMarker({ location, options });
    });
    clusters.forEach((clusters) => {
      inspectClusters(clusters);
    });
    controls.forEach(({ position, options }) => {
      addNavControls({ position, options });
    });
    locate.forEach(({ high_accuracy, options }) => {
      addLocate({ high_accuracy, options });
    });
    terrain.forEach(() => {
      addTerrain();
    });
    geocode.forEach(() => {
      addGeocode();
    });
    fullscreen.forEach(() => {
      addFullScreen();
    });
    scale.forEach((options) => {
      addScale(options);
    });
    export_map.forEach((options) => {
      addExportMap(options);
    });
    hover.forEach((layer) => {
      addHover(layer);
    });
    center.forEach((symbols) => {
      centerOnClick(symbols);
    });
    info.forEach(({ layer, property }) => {
      infoOnClick({ layer, property });
    });
    images.forEach(({ name, url, options }) => {
      loadImage({ name, url, options });
    });
    jumps.forEach(({ location, options }) => {
      map.easeTo({ center: location, ...options });
    });
    fit_bounds.forEach(({ bounds, options }) => {
      map.fitBounds(bounds, options);
    });
  });

  ctx.handleEvent("add_markers", (markers) => {
    markers.forEach(({ location, options }) => {
      addMarker({ location, options });
    });
  });

  ctx.handleEvent("add_marker", ({ location, options }) => {
    addMarker({ location, options });
  });

  ctx.handleEvent("add_nav_controls", ({ position, options }) => {
    addNavControls({ position, options });
  });

  ctx.handleEvent("add_locate", ({ high_accuracy, options }) => {
    addLocate({ high_accuracy, options });
  });

  ctx.handleEvent("add_terrain", () => {
    addTerrain();
  });

  ctx.handleEvent("add_geocode", () => {
    addGeocode();
  });

  ctx.handleEvent("add_fullscreen", () => {
    addFullScreen();
  });

  ctx.handleEvent("add_scale", (options) => {
    addScale(options);
  });

  ctx.handleEvent("add_export_map", (options) => {
    addExportMap(options);
  });

  ctx.handleEvent("clusters_expansion", (clusters) => {
    inspectClusters(clusters);
  });

  ctx.handleEvent("add_hover", (layer) => {
    addHover(layer);
  });

  ctx.handleEvent("center_on_click", (symbols) => {
    centerOnClick(symbols);
  });

  ctx.handleEvent("info_on_click", ({ layer, property }) => {
    infoOnClick({ layer, property });
  });

  ctx.handleEvent("add_custom_image", ({ name, url, options }) => {
    loadImage({ name, url, options });
  });

  ctx.handleEvent("jump_to", ({ location, options }) => {
    map.easeTo({ center: location, ...options });
  });

  ctx.handleEvent("fit_bounds", ({ bounds, options }) => {
    map.fitBounds(bounds, options);
  });

  function addMarker({ location, options }) {
    new maplibregl.Marker(options).setLngLat(location).addTo(map);
  }

  function addNavControls({ position, options }) {
    const nav = new maplibregl.NavigationControl(options);
    map.addControl(nav, position);
  }

  function addLocate({ high_accuracy, options }) {
    const locate = new maplibregl.GeolocateControl({
      positionOptions: {
        enableHighAccuracy: high_accuracy,
        maximumAge: 0,
        timeout: 6000,
      },
      ...options,
    });
    map.addControl(locate);
  }

  function addTerrain() {
    const source = map.getTerrain();
    const terrain = new maplibregl.TerrainControl(source);
    map.addControl(terrain);
  }

  function addGeocode() {
    map.addControl(geocoder());
  }

  function addFullScreen() {
    const fullscreen = new maplibregl.FullscreenControl();
    map.addControl(fullscreen);
  }

  function addScale(options) {
    const scale = new maplibregl.ScaleControl(options);
    map.addControl(scale);
  }

  function addExportMap({ filename, options }) {
    const export_map = new MaplibreExportControl.MaplibreExportControl({
      Filename: filename,
      ...options,
    });
    map.addControl(export_map);
  }

  function loadImage({ name, url, options }) {
    map.loadImage(url, (error, image) => {
      if (error) throw error;
      map.addImage(name, image, options);
    });
  }

  function centerOnClick(symbols) {
    map.on("click", symbols, (e) => {
      const center = e.features[0].geometry.coordinates;
      map.easeTo({ center: center });
    });
  }

  function infoOnClick({ layer, property }) {
    map.on("click", layer, (e) => {
      new maplibregl.Popup()
        .setLngLat(e.lngLat)
        .setHTML(e.features[0].properties[property])
        .addTo(map);
    });
    changeCursor(layer);
  }

  function addHover(layer) {
    let hoveredId = null;
    const source = map.getLayer(layer).source;
    map.on("mousemove", layer, (e) => {
      if (e.features.length > 0) {
        if (hoveredId) {
          map.setFeatureState(
            { source: source, id: hoveredId },
            { hover: false }
          );
        }
        hoveredId = e.features[0].id;
        map.setFeatureState({ source: source, id: hoveredId }, { hover: true });
      }
    });
    map.on("mouseleave", layer, () => {
      if (hoveredId) {
        map.setFeatureState(
          { source: source, id: hoveredId },
          { hover: false }
        );
      }
      hoveredId = null;
    });
  }

  function inspectClusters(clusters) {
    // inspect a cluster on click
    map.on("click", clusters, (e) => {
      const source = map.getLayer(clusters).source;
      const features = map.queryRenderedFeatures(e.point, {
        layers: [clusters],
      });
      const clusterId = features[0].properties.cluster_id;
      map.getSource(source).getClusterExpansionZoom(clusterId, (err, zoom) => {
        if (err) return;
        map.easeTo({
          center: features[0].geometry.coordinates,
          zoom: zoom,
        });
      });
    });
    changeCursor(clusters);
  }

  function changeCursor(layer) {
    map.on("mouseenter", layer, () => {
      map.getCanvas().style.cursor = "pointer";
    });
    map.on("mouseleave", layer, () => {
      map.getCanvas().style.cursor = "";
    });
  }

  function geocoder() {
    const geocoderApi = {
      forwardGeocode: async (config) => {
        const features = [];
        try {
          const request = `https://nominatim.openstreetmap.org/search?q=${config.query}&format=geojson&polygon_geojson=1&addressdetails=1`;
          const response = await fetch(request);
          const geojson = await response.json();
          for (const feature of geojson.features) {
            const center = [
              feature.bbox[0] + (feature.bbox[2] - feature.bbox[0]) / 2,
              feature.bbox[1] + (feature.bbox[3] - feature.bbox[1]) / 2,
            ];
            const point = {
              type: "Feature",
              geometry: {
                type: "Point",
                coordinates: center,
              },
              place_name: feature.properties.display_name,
              properties: feature.properties,
              text: feature.properties.display_name,
              place_type: ["place"],
              center,
            };
            features.push(point);
          }
        } catch (e) {
          console.error(`Failed to forwardGeocode with error: ${e}`);
        }

        return {
          features,
        };
      },
    };

    return new MaplibreGeocoder(geocoderApi, { maplibregl });
  }
}
