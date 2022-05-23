import * as Vue from "https://cdn.jsdelivr.net/npm/vue@3.2.26/dist/vue.esm-browser.prod.js";

export function init(ctx, payload) {
  ctx.importCSS("main.css");
  ctx.importCSS("https://fonts.googleapis.com/css2?family=Inter:wght@400;500&display=swap");

  const app = Vue.createApp({
    template: `
      <div class="app">
        <form @change="handleFieldChange">
        <div class="container">
          <div class="root">
            <BaseInput
              name="style"
              label="Mapping"
              type="text"
              placeholder="Style"
              v-model="fields.style"
              class="input--md"
            />
            <BaseInput
              name="center"
              label="Center"
              type="text"
              v-model="fields.center"
              class="input--xs"
            />
            <BaseInput
              name="zoom"
              label="Zoom"
              type="number"
              v-model="fields.zoom"
              class="input--xs"
            />
          </div>
          <div class="row">
            <BaseInput
              name="source_id"
              label="Source id"
              type="text"
              placeholder="Source id"
              v-model="fields.source_id"
              class="input--md"
            />
            <BaseInput
              name="source_data"
              label="Source data"
              type="text"
              placeholder="Source data (GeoJson url)"
              v-model="fields.source_data"
              class="input--xl"
            />
          </div>
          <div class="row">
            <BaseInput
              name="layer_id"
              label="Layer id"
              type="text"
              placeholder="Layer id"
              v-model="fields.layer_id"
              class="input--sm"
            />
            <BaseSelect
              name="layer_source"
              label="Layer source"
              v-model="fields.layer_source"
              :options="sources"
              :required
              :disabled="noSources"
            />
            <BaseSelect
              name="layer_type"
              label="Layer type"
              v-model="fields.layer_type"
              :options="typeOptions"
              :required
              :disabled="noSources"
            />
            <BaseSelect
              name="layer_color"
              label="Color"
              v-model="fields.layer_color"
              :options="colors"
              :required
              :disabled="noSources"
            />
            <div>
              <span id="rangeValue">{{ layerOpacity }}</span>
              <BaseInput
                name="layer_opacity"
                type="range"
                v-model="fields.layer_opacity"
                class="range"
                min="0.1"
                max="1.0"
                step="0.1"
              />
            </div>
          </div>
        </div>
        </form>
      </div>
    `,

    data() {
      return {
        fields: payload.fields,
        missingDep: payload.missing_dep,
        typeOptions: ["fill", "line", "circle"],
        sources: [payload.fields.source_id],
        colors: ["black", "green", "blue", "red", "orange", "magenta", "cyan"]
      };
    },

    computed: {
      noSources() {
        return !this.sources;
      },
      layerOpacity() {
        return `Opacity: ${this.fields.layer_opacity}`;
      },
    },

    methods: {
      handleFieldChange(event) {
        const { name, value } = event.target;
        ctx.pushEvent("update_field", { field: name, value });
      },
    },

    components: {
      BaseInput: {
        props: {
          label: {
            type: String,
            default: ''
          },
          modelValue: {
            type: [String, Number],
            default: ''
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
        `
      },
      BaseSelect: {
        props: {
          label: {
            type: String,
            default: ''
          },
          modelValue: {
            type: [String, Number],
            default: ''
          },
          options: {
            type: Array,
            default: [],
            required: true
          },
          required: {
            type: Boolean,
            default: false
          },
        },
        methods: {
          available(value, options) {
            return value ? options.includes(value) : true;
          },
          optionLabel(value) {
            return value === "__count__" ? "COUNT(*)" : value;
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
              >{{ optionLabel(option) }}</option>
              <option
                v-if="!available(modelValue, options)"
                class="unavailable-option"
                :value="modelValue"
              >{{ optionLabel(modelValue) }}</option>
            </select>
          </div>
        `
      },
    }
  }).mount(ctx.root);

  ctx.handleEvent("update", ({ fields }) => {
    setValues(fields);
  });

  ctx.handleEvent("missing_dep", ({ dep }) => {
    app.missingDep = dep;
  });

  ctx.handleSync(() => {
    // Synchronously invokes change listeners
    document.activeElement &&
      document.activeElement.dispatchEvent(new Event("change", { bubbles: true }));
  });

  function setValues(fields) {
    for (const field in fields) {
      app.fields[field] = fields[field];
    }
  }
}
