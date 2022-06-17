import * as Vue from "https://cdn.jsdelivr.net/npm/vue@3.2.26/dist/vue.esm-browser.prod.js";

export function init(ctx, payload) {
  ctx.importCSS("main.css");
  ctx.importCSS(
    "https://fonts.googleapis.com/css2?family=Inter:wght@400;500&display=swap"
  );

  const app = Vue.createApp({
    template: `
      <div class="app">
        <!-- Info Messages -->
        <div id="info-box" class="info-box" v-if="missingDep">
          <p>To successfully build maps, you need to add the following dependency:</p>
          <span>{{ missingDep }}</span>
        </div>
        <div id="data-info-box" class="info-box" v-if="noSourceVariable">
          <p>To successfully plot maps, you need at least one source available.</p>
          <p>A source can be a geojson url:</p>
          <span>earthquakes = "https://maplibre.org/maplibre-gl-js-docs/assets/earthquakes.geojson"</span>
          <p>a Geo struct:</p>
          <span>conference = %Geo.Point{coordinates: {100.4933, 13.7551}, properties: %{year: 2004}}</span>
          <p>or tabular data containing points along with its coordinates:</p>
          <span>earthquake = %{"latitude" => [32.3646], "longitude" => [101.8781], "mag" => [5.9]}</span>
          <br>
          <span>earthquake = %{"coordinates" => [32.3646, 101.8781], "mag" => [5.9]}</span>
        </div>

        <!-- Map Form -->
        <form @change="handleFieldChange">
        <div class="container">
          <div class="root">
            <BaseSelect
              name="style"
              label="Map Style"
              v-model="rootFields.style"
              :options="styles"
              :required
              class="root-field"
            />
            <BaseInput
              name="center"
              label="Center"
              type="text"
              v-model="rootFields.center"
              class="root-field"
              placeholder="longitude, latitude"
            />
            <BaseInput
              name="zoom"
              label="Zoom"
              type="range"
              v-model="rootFields.zoom"
              class="root-field range"
              :min="0"
              :max="24"
            />
            <span class="zoomValue">{{ rootFields.zoom }}</span>
          </div>
          <div class="layers">
            <Accordion
              class="layer-wrapper"
              v-for="(layer, index) in layers"
              @remove-layer="removeLayer(index)"
              :showDelete="hasLayers"
            >
              <template v-slot:title>
                <span>
                  Layer: <span class="highlight">{{ layer.source_id }}</span>
                </span>
              </template>
              <template v-slot:content>
                <div class="row">
                <BaseSelect
                    name="layer_source"
                    label="Layer source"
                    :index="index"
                    v-model="layer.layer_source"
                    :options="sourceVariables"
                    :required
                  />
                  <BaseInput
                    name="layer_id"
                    label="Name"
                    :index="index"
                    type="text"
                    placeholder="Layer name"
                    v-model="layer.layer_id"
                  />
                  <BaseSelect
                    name="layer_type"
                    label="Type"
                    :index="index"
                    v-model="layer.layer_type"
                    :options="typeOptions"
                    :required
                  />
                  <div class="field range-wrapper" v-if="layer.layer_type === 'heatmap'">
                    <span class="rangeValue">{{ heatmapRadius(index) }}</span>
                    <BaseInput
                      name="layer_radius"
                      :index="index"
                      type="range"
                      v-model="layer.layer_radius"
                      class="range--md range"
                      min="1"
                      max="20"
                      step="1"
                    />
                  </div>
                  <BaseSelect
                    v-else
                    name="layer_color"
                    label="Color"
                    :index="index"
                    v-model="layer.layer_color"
                    :options="colors"
                    :required
                  />
                  <div class="field range-wrapper">
                    <span class="rangeValue">{{ layerOpacity(index) }}</span>
                    <BaseInput
                      name="layer_opacity"
                      :index="index"
                      type="range"
                      v-model="layer.layer_opacity"
                      class="range--md range"
                      min="0.1"
                      max="1.0"
                      step="0.1"
                    />
                  </div>
                </div>
                <div v-if="layer.source_type === 'table'" class="row">
                <BaseSelect
                    name="coordinates_format"
                    label="Coordinates format"
                    :index="index"
                    v-model="layer.coordinates_format"
                    :options="coordinateOptions"
                    :required
                  />
                  <BaseSelect
                    v-if="layer.coordinates_format !== 'columns'"
                    name="source_coordinates"
                    label="Coordinates"
                    :index="index"
                    v-model="layer.source_coordinates"
                    :options="sourceOptions(layer)"
                    :required
                  />
                  <BaseSelect
                    v-if="layer.coordinates_format === 'columns'"
                    name="source_longitude"
                    label="Longitude (lng)"
                    :index="index"
                    v-model="layer.source_longitude"
                    :options="sourceOptions(layer)"
                    :required
                  />
                  <BaseSelect
                    v-if="layer.coordinates_format === 'columns'"
                    name="source_latitude"
                    label="Latitude (lat)"
                    :index="index"
                    v-model="layer.source_latitude"
                    :options="sourceOptions(layer)"
                    :required
                  />
                </div>
              <template>
            </Accordion>
          </div>
          <div class="add-layer">
            <button class="button" type="button" :disabled="noSources" @click="addLayer()">Add layer</button>
          </div>
        </div>
        </form>
      </div>
    `,

    data() {
      return {
        rootFields: payload.root_fields,
        layers: payload.layers,
        dataOptions: payload.source_variables,
        missingDep: payload.missing_dep,
        typeOptions: ["circle", "fill", "line", "heatmap"],
        colors: ["black", "green", "blue", "red", "orange", "magenta", "cyan"],
        styles: ["default", "street (non-commercial)", "terrain (non-commercial)"],
        sourceVariables: payload.source_variables.map((data) => data.variable),
        coordinateOptions: ["lng_lat", "lat_lng", "columns"]
      };
    },

    computed: {
      hasLayers() {
        return this.layers.length > 1;
      },
      noSourceVariable() {
        return !this.layers[0].layer_source;
      },
    },

    methods: {
      sourceOptions(layer) {
        const dataVariable = layer.layer_source;
        const dataOptions = this.dataOptions.find(
          (data) => data["variable"] === dataVariable
        );
        return dataOptions ? dataOptions["columns"] : [];
      },
      layerOpacity(layer) {
        return `Opacity: ${this.layers[layer].layer_opacity}`;
      },
      heatmapRadius(layer) {
        return `Radius: ${this.layers[layer].layer_radius}`;
      },
      handleFieldChange(event) {
        const { name, value } = event.target;
        const idx = event.target.getAttribute("index");
        ctx.pushEvent("update_field", {
          field: name,
          value,
          idx: idx && parseInt(idx),
        });
      },
      addLayer() {
        ctx.pushEvent("add_layer");
      },
      removeLayer(idx) {
        ctx.pushEvent("remove_layer", { layer: idx });
      },
    },

    components: {
      BaseInput: {
        props: {
          label: {
            type: String,
            default: "",
          },
          modelValue: {
            type: [String, Number],
            default: "",
          },
        },
        template: `
          <div class="field">
            <label class="input-label">{{ label }}</label>
            <input
              :value="modelValue"
              @input="$emit('update:modelValue', $event.target.value)"
              v-bind="$attrs"
              class="input"
            >
          </div>
        `,
      },
      BaseSelect: {
        props: {
          label: {
            type: String,
            default: "",
          },
          modelValue: {
            type: [String, Number],
            default: "",
          },
          options: {
            type: Array,
            default: [],
            required: true,
          },
          required: {
            type: Boolean,
            default: false,
          },
        },
        methods: {
          available(value, options) {
            return value ? options.includes(value) : true;
          },
        },
        template: `
          <div class="field">
            <label class="input-label">{{ label }}</label>
            <select
              :value="modelValue"
              v-bind="$attrs"
              @change="$emit('update:modelValue', $event.target.value)"
              class="input"
              :class="{ unavailable: !available(modelValue, options) }"
            >
              <option v-if="!required && available(modelValue, options)"></option>
              <option
                v-for="option in options"
                :value="option"
                :key="option"
                :selected="option === modelValue"
              >{{ option }}</option>
              <option
                v-if="!available(modelValue, options)"
                class="unavailable-option"
                :value="modelValue"
              >{{ modelValue }}</option>
            </select>
          </div>
        `,
      },
      Accordion: {
        data() {
          return {
            isOpen: payload.layers.length <= 3,
          };
        },
        props: {
          showDelete: {
            type: Boolean,
            required: true,
          },
        },
        methods: {
          toggleAccordion() {
            this.isOpen = !this.isOpen;
          },
        },
        template: `
          <div class="wrapper" :class="{'wrapper--closed': !isOpen}">
            <div
              class="accordion-control"
              :aria-expanded="isOpen"
              :aria-controls="id"
              :class="{'control--sm': isOpen}"
            >
              <span v-show="!isOpen"><slot name="title" /></span>
              <span></span>
              <span>
                <button
                  class="button button--sm"
                  v-show=showDelete
                  @click="$emit('removeLayer')"
                  type="button"
                >
                  <svg
                    class="button-svg"
                    fill="currentColor"
                    stroke="none"
                    xmlns="http://www.w3.org/2000/svg"
                    viewBox="0 0 14 14"
                    aria-hidden="true"
                  >
                    <path
                      d="M7.00023 5.58574L11.9502 0.635742L13.3642 2.04974L8.41423 6.99974L13.3642 11.9497L11.9502
                      13.3637L7.00023 8.41374L2.05023 13.3637L0.63623 11.9497L5.58623 6.99974L0.63623 2.04974L2.05023
                      0.635742L7.00023 5.58574Z"
                    />
                  </svg>
                </button>
                <button
                  class="button button--sm"
                  @click="toggleAccordion()"
                  type="button"
                >
                  <svg
                    class="button-svg"
                    :class="{
                      'rotate-180': isOpen,
                      'rotate-0': !isOpen,
                    }"
                    fill="none"
                    stroke="currentColor"
                    xmlns="http://www.w3.org/2000/svg"
                    viewBox="0 0 16 10"
                    aria-hidden="true"
                  >
                    <path
                      d="M15 1.2l-7 7-7-7"
                      stroke-width="2"
                      stroke-linecap="round"
                      stroke-linejoin="round"
                    />
                  </svg>
                </button>
              </span>
            </div>
            <div v-show="isOpen">
              <slot name="content" />
            </div>
          </div>
        `,
      },
    },
  }).mount(ctx.root);

  ctx.handleEvent("update_root", ({ fields }) => {
    setRootValues(fields);
  });

  ctx.handleEvent("update_layer", ({ idx, fields }) => {
    setLayerValues(idx, fields);
  });

  ctx.handleEvent("set_layers", ({ layers }) => {
    app.layers = layers;
  });

  ctx.handleEvent("missing_dep", ({ dep }) => {
    app.missingDep = dep;
  });

  ctx.handleEvent("set_source_variables", ({ source_variables, fields }) => {
    app.sourceVariables = source_variables.map((data) => data.variable);
    app.dataOptions = source_variables;
    setLayerValues(0, fields)
  });

  ctx.handleSync(() => {
    // Synchronously invokes change listeners
    document.activeElement &&
      document.activeElement.dispatchEvent(
        new Event("change", { bubbles: true })
      );
  });

  function setRootValues(fields) {
    for (const field in fields) {
      app.rootFields[field] = fields[field];
    }
  }

  function setLayerValues(idx, fields) {
    for (const field in fields) {
      app.layers[idx][field] = fields[field];
    }
  }
}
