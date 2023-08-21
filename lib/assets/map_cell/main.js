export async function init(ctx, payload) {
  await importJS(
    "https://cdn.jsdelivr.net/npm/vue@3.2.37/dist/vue.global.prod.js"
  );
  await importJS(
    "https://cdn.jsdelivr.net/npm/vue-dndrop@1.2.13/dist/vue-dndrop.min.js"
  );
  ctx.importCSS("main.css");
  ctx.importCSS(
    "https://fonts.googleapis.com/css2?family=Inter:wght@400;500&display=swap"
  );

  const BaseInput = {
    props: {
      label: {
        type: String,
        default: "",
      },
      inputClass: {
        type: String,
        default: "input",
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
            :class="[inputClass, { required: !modelValue && required }]"
          >
        </div>
      `,
  };

  const BaseSelect = {
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
        return value
          ? options.some((option) => option === value || option.value === value)
          : true;
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
              :value="option.value || option"
              :selected="option.value === modelValue || option === modelValue"
            >{{ option.label || option }}</option>
            <option
              v-if="!available(modelValue, options)"
              class="unavailable-option"
              :value="modelValue"
            >{{ modelValue }}</option>
          </select>
        </div>
      `,
  };

  const Accordion = {
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
        <div class="layer-wrapper" :class="{'card': hasLayers}">
          <div
            class="accordion-control"
            :class="{'expanded': isOpen}"
            :aria-expanded="isOpen"
            :aria-controls="id"
            v-show="hasLayers"
          >
            <span>
              <button
                class="button button--toggle"
                @click="toggleAccordion()"
                type="button"
              >
                <svg
                  class="button-svg"
                  :class="{
                    'rotate-0': isOpen,
                    'rotate--90': !isOpen,
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
                <span class="accordion-title">
                  <slot name="title" />
                  <slot name="subtitle" v-if="!isOpen"/>
                </span>
              </button>
            </span>
            <span></span>
            <div class="layer-controls">
              <slot name="toggle" />
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
            </div>
          </div>
          <div class="accordion-body" :class="{'expanded': !hasLayers}" v-show="isOpen || !hasLayers">
            <slot name="content" />
          </div>
        </div>
      `,
  };

  const FieldGroup = {
    props: {
      modelValue: {
        type: Array,
        required: true,
      },
      inputType: {
        type: String,
        default: "text",
      },
    },
    methods: {
      updateModel(idx, value) {
        this.modelValue[idx] = value;
        this.$emit("groupChange");
      },
    },
    template: `
        <div v-for="(value, index) in modelValue" class="field" v-bind="$attrs">
          <input
            :type="inputType"
            :value="value"
            v-bind="$attrs"
            class="input"
            @change="updateModel(index, $event.target.value)"
          >
        </div>
      `,
  };

  const BaseSwitch = {
    props: {
      label: {
        type: String,
        default: "",
      },
      modelValue: {
        type: Boolean,
      },
      fieldClass: {
        type: String,
        default: "field",
      },
      switchClass: {
        type: String,
        default: "",
      },
    },
    template: `
        <div :class="[inner ? 'inner-field' : fieldClass]">
          <label class="input-label"> {{ label }} </label>
          <div class="input-container">
            <label class="switch-button">
              <input
                :checked="modelValue"
                type="checkbox"
                @input="$emit('update:modelValue', $event.target.checked)"
                v-bind="$attrs"
                :class="['switch-button-checkbox', switchClass]"
              >
              <div :class="['switch-button-bg', switchClass]" />
            </label>
          </div>
        </div>
      `,
  };

  const BaseSecret = {
    name: "BaseSecret",

    components: {
      BaseInput: BaseInput,
    },

    props: {
      textInputName: {
        type: String,
        default: "",
      },
      secretInputName: {
        type: String,
        default: "",
      },
      toggleInputName: {
        type: String,
        default: "",
      },
      label: {
        type: String,
        default: "",
      },
      toggleInputValue: {
        type: [String, Number],
        default: "",
      },
      secretInputValue: {
        type: [String, Number],
        default: "",
      },
      textInputValue: {
        type: [String, Number],
        default: "",
      },
      modalTitle: {
        type: String,
        default: "Select secret",
      },
      required: {
        type: Boolean,
        default: false,
      },
    },

    methods: {
      selectSecret() {
        const preselectName = this.secretInputValue || "";
        ctx.selectSecret(
          (secretName) => {
            ctx.pushEvent("update_field", {
              field: this.secretInputName,
              value: secretName,
              idx: null,
            });
          },
          preselectName,
          { title: this.modalTitle }
        );
      },
    },

    template: `
      <div class="input-icon-container grow">
        <BaseInput
          v-if="toggleInputValue"
          :name="secretInputName"
          :label="label"
          :value="secretInputValue"
          inputClass="input input-icon"
          :grow
          readonly
          @click="selectSecret"
          @input="$emit('update:secretInputValue', $event.target.value)"
          :required="!secretInputValue && required"
        />
        <BaseInput
          v-else
          :name="textInputName"
          :label="label"
          type="text"
          :value="textInputValue"
          inputClass="input input-icon-text"
          :grow
          @input="$emit('update:textInputValue', $event.target.value)"
          :required="!textInputValue && required"
        />
        <div class="icon-container">
          <label class="hidden-checkbox">
            <input
              type="checkbox"
              :name="toggleInputName"
              :checked="toggleInputValue"
              @input="$emit('update:toggleInputValue', $event.target.checked)"
              class="hidden-checkbox-input"
            />
            <svg v-if="toggleInputValue" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"
                  width="22" height="22">
              <path fill="none" d="M0 0h24v24H0z"/>
              <path d="M18 8h2a1 1 0 0 1 1 1v12a1 1 0 0 1-1 1H4a1 1 0 0 1-1-1V9a1 1 0 0 1 1-1h2V7a6 6 0 1 1 12 0v1zM5
                10v10h14V10H5zm6 4h2v2h-2v-2zm-4 0h2v2H7v-2zm8 0h2v2h-2v-2zm1-6V7a4 4 0 1 0-8 0v1h8z" fill="#000"/>
            </svg>
            <svg v-else xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24" height="24">
              <path fill="none" d="M0 0h24v24H0z"/>
              <path d="M21 3v18H3V3h18zm-8.001 3h-2L6.6 17h2.154l1.199-3h4.09l1.201 3h2.155l-4.4-11zm-1 2.885L13.244
                12h-2.492l1.247-3.115z" fill="#445668"/>
            </svg>
          </label>
        </div>
      </div>
    `,
  };

  const app = Vue.createApp({
    components: {
      BaseSelect,
      BaseInput,
      Accordion,
      FieldGroup,
      BaseSwitch,
      BaseSecret,
      Container: VueDndrop.Container,
      Draggable: VueDndrop.Draggable,
    },
    template: `
      <div class="app">
        <!-- Info Messages -->
        <div class="box box-warning" v-if="missingDep">
          <p>To successfully build maps, you need to add the following dependency:</p>
          <pre><code>{{ missingDep }}</code></pre>
        </div>
        <div class="box box-warning" v-if="noSourceVariable">
          <p>To successfully plot maps, you need at least one source available.</p>
          <p>A source can be a geojson url:</p>
          <pre><code>earthquakes = "https://maplibre.org/maplibre-gl-js/docs/assets/earthquakes.geojson"</code></pre>
          <p>a Geo struct:</p>
          <pre><code>conference = %Geo.Point{coordinates: {100.4933, 13.7551}, properties: %{year: 2004}}</code></pre>
          <p>or tabular data containing points along with its coordinates:</p>
          <pre><code>earthquake = %{"latitude" => [32.3646], "longitude" => [101.8781], "mag" => [5.9]}</code></pre>
          <pre><code>earthquake = %{"coordinates" => ["32.3646, 101.8781"], "mag" => [5.9]}</code></pre>
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
            <div class="zoom-wrapper">
              <BaseInput
                name="zoom"
                label="Zoom"
                type="range"
                v-model="rootFields.zoom"
                class="root-field range"
                :min="0"
                :max="24"
              />
              <span class="zoom-value">{{ rootFields.zoom }}</span>
            </div>
          </div>
          <div class="add-key" v-if="commercial">
            <BaseSecret
              textInputName="maptiler_key"
              secretInputName="maptiler_key_secret"
              toggleInputName="use_maptiler_key_secret"
              label="Maptiler Key"
              v-model:textInputValue="rootFields.maptiler_key"
              v-model:secretInputValue="rootFields.maptiler_key_secret"
              v-model:toggleInputValue="rootFields.use_maptiler_key_secret"
              modalTitle="Set maptiler key"
              :required
            />
          </div>
          <div class="layers">
            <Container @drop="handleItemDrop" lock-axis="y" non-drag-area-selector=".accordion-body">
              <Draggable v-for="(layer, index) in layers">
              <Accordion
                class="layer-wrapper"
                @remove-layer="removeLayer(index)"
                :hasLayers="hasLayers"
              >
                <template v-slot:title><span>Layer {{ index + 1 }}</span></template>
                <template v-slot:subtitle>
                  <span v-if="layer.source_type === 'query' && layer.layer_source_query">
                    {{ layer.layer_source }}: {{ layer.layer_source_query }} - {{ layer.layer_type }}
                  </span>
                  <span v-else>{{ layer.layer_source }} - {{ layer.layer_type }}</span>
                </template>
                <template v-slot:toggle>
                  <BaseSwitch
                    name="active"
                    :index="index"
                    v-model="layer.active"
                    :disabled="noSourceVariable"
                    fieldClass="switch-sm"
                  />
                </template>
                <template v-slot:content>
                  <div class="row">
                    <BaseSelect
                      name="layer_source"
                      label="Source"
                      :index="index"
                      v-model="layer.layer_source"
                      :options="sourceVariables"
                      :disabled="noSourceVariable"
                      :required
                    />
                    <template v-if="layer.source_type === 'table'" >
                      <BaseSelect
                        name="coordinates_format"
                        label="Coordinates format"
                        :index="index"
                        v-model="layer.coordinates_format"
                        :labels="coordinateLabels"
                        :options="coordinateOptions"
                        :required
                      />
                      <BaseSelect
                        v-if="layer.coordinates_format !== 'columns'"
                        name="source_coordinates"
                        label="Coordinates column"
                        :index="index"
                        v-model="layer.source_coordinates"
                        :options="sourceOptions(layer)"
                        :required
                      />
                      <template v-else>
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
                      </template>
                    </template>
                    <template v-if="layer.source_type === 'query'" >
                      <BaseInput
                        name="layer_source_query"
                        label="Geocode"
                        placeholder="Type a city, state, or country"
                        :index="index"
                        type="text"
                        v-model="layer.layer_source_query"
                        :required
                        class="special-field"
                      />
                      <BaseSelect
                        name="layer_source_query_strict"
                        label="Strict"
                        :index="index"
                        v-model="layer.layer_source_query_strict"
                        :options="queryOptions"
                        :disabled="!layer.layer_source_query"
                      />
                    </template>
                  </div>
                  <div class="row">
                    <BaseSelect
                      name="layer_type"
                      label="Type"
                      :index="index"
                      v-model="layer.layer_type"
                      :options="layer.source_type === 'query' ? geocodeOptions : typeOptions"
                      :disabled="noSourceVariable"
                      :required
                    />
                    <div class="field range-wrapper" v-if="layer.layer_type === 'heatmap'">
                      <span class="range-value">{{ layerRadius(index) }}</span>
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
                    <BaseInput
                      v-if="layer.layer_type !== 'cluster' && layer.layer_type !== 'heatmap'"
                      name="layer_color"
                      type="color"
                      label="Color"
                      :index="index"
                      v-model="layer.layer_color"
                      :disabled="noSourceVariable"
                      :required
                      class="input-color input-color--xl"
                    />
                    <div class="field range-wrapper" v-if="layer.layer_type === 'circle'">
                      <span class="range-value">{{ layerRadius(index) }}</span>
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
                    <div class="field range-wrapper" v-if="layer.layer_type !== 'cluster'">
                      <span class="range-value">{{ layerOpacity(index) }}</span>
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
                    <template v-if="layer.layer_type === 'cluster'">
                      <BaseInput
                        name="cluster_min"
                        label="Min"
                        :index="index"
                        type="number"
                        placeholder="Cluster min"
                        v-model="layer.cluster_min"
                        :disabled="noSourceVariable"
                        :required
                        class="input-number"
                      />
                      <BaseInput
                        name="cluster_max"
                        label="Max"
                        :index="index"
                        type="number"
                        placeholder="Cluster max"
                        v-model="layer.cluster_max"
                        :disabled="noSourceVariable"
                        :required
                        class="input-number"
                      />
                      <div class="group">
                        <span class="group-label">Colors (min - mid - max)</span>
                        <div class="group-fields">
                          <FieldGroup
                            v-model="layer.cluster_colors"
                            :index="index"
                            inputType="color"
                            class="input-color"
                            @group-change="handleGroupChange(index, 'cluster_colors', layer.cluster_colors)"
                          />
                        </div>
                      </div>
                    </template>
                  </div>
                <template>
              </Accordion>
              </Draggable>
            </Container>
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
        typeOptions: ["circle", "fill", "line", "heatmap", "cluster"],
        geocodeOptions: ["fill", "line", "circle"],
        styles: [
          "default",
          "street (non-commercial)",
          "terrain (non-commercial)",
          "street (commercial)",
          "terrain (commercial)",
        ],
        sourceVariables: payload.source_variables.map((data) => data.variable),
        coordinateOptions: [
          { label: "Two columns", value: "columns" },
          { label: "Single: lng, lat", value: "lng_lat" },
          { label: "Single: lat, lng", value: "lat_lng" },
        ],
        queryOptions: ["country", "state", "city", "county", "street"],
      };
    },

    computed: {
      hasLayers() {
        return this.layers.length > 1;
      },
      noSourceVariable() {
        return !this.layers[0].layer_source;
      },
      commercial() {
        return this.rootFields.style.includes("(commercial)");
      }
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
      layerRadius(layer) {
        return `Radius: ${this.layers[layer].layer_radius}`;
      },
      handleFieldChange(event) {
        const field = event.target.name;
        const idx = event.target.getAttribute("index");
        const value = idx
          ? this.layers[idx][field]
          : this.rootFields[field];
        field === "center"
          ? updateCenter(value)
          : field && updateField(idx, field, value);
      },
      handleGroupChange(idx, group, value) {
        updateField(idx, group, Vue.toRaw(value));
      },
      addLayer() {
        ctx.pushEvent("add_layer");
      },
      removeLayer(idx) {
        ctx.pushEvent("remove_layer", { layer: idx });
      },
      handleItemDrop({ removedIndex, addedIndex }) {
        if (removedIndex === addedIndex) return;
        ctx.pushEvent("move_layer", { removedIndex, addedIndex });
      }
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
    setLayerValues(0, fields);
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

  function updateField(idx, name, value) {
    ctx.pushEvent("update_field", {
      field: name,
      value,
      idx: idx && parseInt(idx),
    });
  }

  function updateCenter(value) {
    const coordinates = value.match(/(-?\d+\.?\d*),\s*(-?\d+\.?\d*)/);
    if (value && !coordinates) {
      const request = `https://nominatim.openstreetmap.org/search?q=${value}&format=json&limit=1`;
      fetch(request)
        .then((response) => response.json())
        .then((data) => {
          const center = data[0] && `${data[0].lon}, ${data[0].lat}`;
          updateField(null, "center", center || value);
        });
    } else {
      updateField(null, "center", value);
    }
  }
}

// Imports a JS script globally using a <script> tag
function importJS(url) {
  return new Promise((resolve, reject) => {
    const scriptEl = document.createElement("script");
    scriptEl.addEventListener(
      "load",
      (event) => {
        resolve();
      },
      { once: true }
    );
    scriptEl.src = url;
    document.head.appendChild(scriptEl);
  });
}
