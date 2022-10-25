import "https://unpkg.com/maplibre-gl@2.1.9/dist/maplibre-gl.js";
// TODO: point to npm when released
import "https://cdn.jsdelivr.net/gh/jimmyrocks/maplibre-gl-vector-text-protocol@73c5dc8f2bc3331298273e8800d6c5db4cdfffab/dist/maplibre-gl-vector-text-protocol.min.js";

export function init(ctx, data) {
  ctx.importCSS("https://unpkg.com/maplibre-gl@2.1.9/dist/maplibre-gl.css");

  ctx.root.innerHTML = `
    <div id='map' style='width: 896px; height: 400px;'></div>
  `;

  const container = "map";
  const style = data.spec;
  const {
    markers = [],
    clusters = [],
    controls = [],
    hover = [],
    center = [],
    info = [],
    images = [],
    jumps = [],
    fit_bounds = [],
    filters = []
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
    hover.forEach((layer) => {
      addHover(layer);
    });
    center.forEach((symbols) => {
      centerOnClick(symbols);
    });
    info.forEach(({ layer, property }) => {
      infoOnClick({ layer, property });
    });
    images.forEach(({ name, url }) => {
      loadImage({ name, url });
    });
    jumps.forEach(({ location, options }) => {
      map.easeTo({ center: location, ...options });
    });
    fit_bounds.forEach(({ bounds, options }) => {
      map.fitBounds(bounds, options);
    });
    filters.forEach(({filters, field }) => {
      map.setFilter(field, filters);
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

  ctx.handleEvent("add_custom_image", ({ name, url }) => {
    loadImage({ name, url });
  });

  ctx.handleEvent("jump_to", ({ location, options }) => {
    map.easeTo({ center: location, ...options });
  });

  ctx.handleEvent("fit_bounds", ({ bounds, options }) => {
    map.fitBounds(bounds, options);
  });

  ctx.handleEvent("set_filter", ({ filters, field }) => {
    map.setFilter(field, filters)
  });

  function addMarker({ location, options }) {
    new maplibregl.Marker(options).setLngLat(location).addTo(map);
  }

  function addNavControls({ position, options }) {
    const nav = new maplibregl.NavigationControl(options);
    map.addControl(nav, position);
  }

  function loadImage({ name, url }) {
    map.loadImage(url, (error, image) => {
      if (error) throw error;
      map.addImage(name, image);
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
}
