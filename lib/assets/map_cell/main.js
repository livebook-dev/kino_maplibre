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
          <span>earthquake = %{"coordinates" => ["32.3646, 101.8781"], "mag" => [5.9]}</span>
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
              :hasLayers="hasLayers"
            >
              <template v-slot:title>
                <BaseInput
                  name="layer_id"
                  label="Layer"
                  :index="index"
                  type="text"
                  placeholder="Layer name"
                  v-model="layer.layer_id"
                  :disabled="noSourceVariable"
                  :required
                  class="inline-field"
                />
              </template>
              <template v-slot:content>
                <div class="row">
                  <BaseSelect
                    name="layer_source"
                    label="Layer source"
                    :index="index"
                    v-model="layer.layer_source"
                    :options="sourceVariables"
                    :disabled="noSourceVariable"
                    :required
                  />
                  <div class="row row--sm" v-if="layer.source_type === 'table'" >
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
                    <div class="row" v-else>
                      <BaseSelect
                        name="source_longitude"
                        label="Longitude (lng)"
                        :index="index"
                        v-model="layer.source_longitude"
                        :options="sourceOptions(layer)"
                        :required
                      />
                      <BaseSelect
                        name="source_latitude"
                        label="Latitude (lat)"
                        :index="index"
                        v-model="layer.source_latitude"
                        :options="sourceOptions(layer)"
                        :required
                      />
                    </div>
                  </div>
                </div>
                <div class="row">
                  <BaseSelect
                    name="layer_type"
                    label="Type"
                    :index="index"
                    v-model="layer.layer_type"
                    :options="typeOptions"
                    :disabled="noSourceVariable"
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
                    :disabled="noSourceVariable"
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
              <template>
            </Accordion>
          </div>
          <div class="add-layer">
            <button class="button button--dashed" type="button" :disabled="noSources" @click="addLayer()">
              <svg width="10" height="10" viewBox="0 0 10 10" fill="currentColor" xmlns="http://www.w3.org/2000/svg">
                <path d="M4.41699 4.41602V0.916016H5.58366V4.41602H9.08366V5.58268H5.58366V9.08268H4.41699V5.58268H0.916992V4.41602H4.41699Z"/>
              </svg>
              Add layer
            </button>
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
          required: {
            type: Boolean,
            default: false,
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
              :class="{ required: !modelValue && required }"
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
              :class="{ required: !modelValue && required }"
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
          hasLayers: {
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
            >
              <span><slot name="title" /></span>
              <span></span>
              <span v-show="hasLayers || (!isOpen && !hasLayers)">
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
                    fill="currentColor"
                    stroke="currentColor"
                    xmlns="http://www.w3.org/2000/svg"
                    viewBox="0 0 16 10"
                    aria-hidden="true"
                  >
                    <path
                      d="M15 1.2l-7 7-7-7"
                    />
                  </svg>
                </button>
                <button
                  class="button button--sm"
                  @click="$emit('removeLayer')"
                  type="button"
                  v-show="hasLayers"
                >
                  <svg
                    class="button-svg"
                    fill="currentColor"
                    stroke="none"
                    xmlns="http://www.w3.org/2000/svg"
                    viewBox="0 0 16 16"
                    aria-hidden="true"
                  >
                    <path
                      d="M11.75 3.5H15.5V5H14V14.75C14 14.9489 13.921 15.1397 13.7803 15.2803C13.6397 15.421 13.4489
                       15.5 13.25 15.5H2.75C2.55109 15.5 2.36032 15.421 2.21967 15.2803C2.07902 15.1397 2 14.9489 2
                       14.75V5H0.5V3.5H4.25V1.25C4.25 1.05109 4.32902 0.860322 4.46967 0.71967C4.61032 0.579018 4.80109
                       0.5 5 0.5H11C11.1989 0.5 11.3897 0.579018 11.5303 0.71967C11.671 0.860322 11.75 1.05109 11.75
                       1.25V3.5ZM12.5 5H3.5V14H12.5V5ZM5.75 7.25H7.25V11.75H5.75V7.25ZM8.75
                       7.25H10.25V11.75H8.75V7.25ZM5.75 2V3.5H10.25V2H5.75Z"
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
