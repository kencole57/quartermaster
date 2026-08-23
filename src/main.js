import '@mdi/font/css/materialdesignicons.css'
import 'vuetify/styles'

import { createApp } from 'vue'
import { createVuetify } from 'vuetify'
import * as components from 'vuetify/components'
import * as directives from 'vuetify/directives'

import App from './App.vue'
import './styles.css'

const vuetify = createVuetify({
  components,
  directives,
  theme: {
    defaultTheme: 'quartermaster',
    themes: {
      quartermaster: {
        dark: false,
        colors: {
          background: '#f7f6f2',
          surface: '#ffffff',
          primary: '#294c60',
          secondary: '#7a9e7e',
          accent: '#c28e4b',
          error: '#b00020',
          info: '#2f6f8f',
          success: '#3f7d58',
          warning: '#b7791f',
        },
      },
    },
  },
})

createApp(App).use(vuetify).mount('#app')
