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
              class="input--lg"
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
              placeholder="Source data"
              v-model="fields.source_data"
              class="input--md"
            />
          </div>
        </div>
        </form>
      </div>
    `,

    data() {
      return {
        fields: payload.fields,
        missingDep: payload.missing_dep,
      };
    },

    computed: {

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
