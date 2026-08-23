<template>
  <v-app>
    <v-layout>
      <v-app-bar v-if="mobile" color="surface" elevation="0" height="64" class="mobile-app-bar">
        <v-app-bar-nav-icon aria-label="Open navigation" @click="drawerOpen = true" />
        <div class="mobile-brand">
          <div class="brand-mark brand-mark-small">Q</div>
          <div class="brand-title">Quartermaster</div>
        </div>
        <v-spacer />
        <v-btn
          v-if="session"
          icon="mdi-plus"
          color="primary"
          variant="tonal"
          aria-label="Add item"
          @click="openAddItemDialog"
        />
      </v-app-bar>

      <v-navigation-drawer
        v-model="drawerOpen"
        :permanent="!mobile"
        :temporary="mobile"
        :width="mobile ? 260 : 280"
      >
        <div class="brand-panel">
          <div class="brand-mark">Q</div>
          <div>
            <div class="brand-title">Quartermaster</div>
            <div class="brand-subtitle">Collection command</div>
          </div>
        </div>

        <v-list nav density="comfortable">
          <v-list-item prepend-icon="mdi-view-dashboard-outline" title="Dashboard" active />
          <v-list-item prepend-icon="mdi-archive-search-outline" title="Catalog" />
          <v-list-item prepend-icon="mdi-bookshelf" title="Library" />
          <v-list-item prepend-icon="mdi-tag-multiple-outline" title="Tags" />
          <v-list-item prepend-icon="mdi-map-search-outline" title="Research" />
        </v-list>

        <template #append>
          <div class="drawer-account">
            <div v-if="session" class="account-summary">
              <v-icon icon="mdi-account-circle-outline" size="28" />
              <div>
                <div class="account-label">Signed in</div>
                <div class="account-email">{{ session.user.email }}</div>
              </div>
            </div>
            <v-btn
              v-if="session"
              block
              prepend-icon="mdi-logout"
              variant="outlined"
              :loading="authLoading"
              @click="signOut"
            >
              Sign Out
            </v-btn>
            <v-btn v-else block color="primary" prepend-icon="mdi-login" @click="authDialogOpen = true">
              Sign In
            </v-btn>
          </div>
        </template>
      </v-navigation-drawer>

      <v-main>
        <v-container v-if="!session" fluid class="auth-shell">
          <section class="auth-hero">
            <div class="auth-hero-copy">
              <div class="brand-mark">Q</div>
              <h1>Quartermaster</h1>
              <p>Sign in to manage your historical research, wargaming assets, books, files, and locations.</p>
            </div>

            <v-card variant="flat" class="auth-panel">
              <h2>Sign In</h2>
              <p class="auth-copy">
                Enter your email and Supabase will send a magic link for Quartermaster.
              </p>
              <v-form @submit.prevent="sendMagicLink">
                <v-text-field
                  v-model="email"
                  label="Email"
                  type="email"
                  prepend-inner-icon="mdi-email-outline"
                  variant="outlined"
                  autocomplete="email"
                  :disabled="authLoading"
                />
                <v-btn
                  block
                  color="primary"
                  prepend-icon="mdi-email-fast-outline"
                  type="submit"
                  :loading="authLoading"
                >
                  Send Magic Link
                </v-btn>
              </v-form>
              <v-alert v-if="authMessage" class="auth-alert-inline" :type="authMessageType" variant="tonal">
                {{ authMessage }}
              </v-alert>
            </v-card>
          </section>
        </v-container>

        <v-container v-else fluid class="app-shell">
          <section class="topbar">
            <div>
              <h1>Quartermaster</h1>
              <p>Track what you have, what it describes, and where your copy lives.</p>
            </div>
            <div class="topbar-actions">
              <v-chip v-if="session" prepend-icon="mdi-account-circle-outline" variant="tonal" color="primary">
                {{ session.user.email }}
              </v-chip>
              <v-btn
                v-else
                variant="outlined"
                prepend-icon="mdi-login"
                class="desktop-action"
                @click="authDialogOpen = true"
              >
                Sign In
              </v-btn>
              <v-btn
                v-if="session"
                color="primary"
                prepend-icon="mdi-plus"
                class="desktop-action"
                @click="openAddItemDialog"
              >
                Add Item
              </v-btn>
            </div>
          </section>

          <v-alert v-if="authMessage" class="auth-alert" :type="authMessageType" variant="tonal" closable>
            {{ authMessage }}
          </v-alert>

          <section class="search-band">
            <v-text-field
              prepend-inner-icon="mdi-magnify"
              label="Search assets, books, documents, packages, creators, tags"
              variant="outlined"
              density="comfortable"
              hide-details
            />
            <v-select
              label="Type"
              :items="['Any', 'Book', 'Document', 'STL model', 'Package', 'Map', 'Photo']"
              variant="outlined"
              density="comfortable"
              hide-details
            />
            <v-select
              label="Period"
              :items="['Any', 'Vietnam War', 'Cold War', 'Second World War', 'Napoleonic']"
              variant="outlined"
              density="comfortable"
              hide-details
            />
          </section>

          <section class="metric-grid">
            <v-card v-for="metric in metrics" :key="metric.label" variant="flat" class="metric-card">
              <v-icon :icon="metric.icon" size="30" />
              <div>
                <div class="metric-value">{{ metric.value }}</div>
                <div class="metric-label">{{ metric.label }}</div>
              </div>
            </v-card>
          </section>

          <section class="content-grid">
            <v-card variant="flat" class="panel-card recent-panel">
              <div class="panel-heading panel-heading-responsive">
                <h2>Recent Catalog Items</h2>
                <div class="panel-actions">
                  <v-btn-toggle
                    v-model="catalogViewMode"
                    mandatory
                    divided
                    density="comfortable"
                    variant="outlined"
                    aria-label="Catalog view mode"
                  >
                    <v-btn value="table" icon="mdi-table" aria-label="Table view" />
                    <v-btn value="list" icon="mdi-format-list-bulleted" aria-label="List view" />
                  </v-btn-toggle>
                  <v-btn icon="mdi-arrow-right" variant="text" aria-label="Open catalog" />
                </div>
              </div>
              <v-alert v-if="catalogError" type="error" variant="tonal" class="panel-alert">
                {{ catalogError }}
              </v-alert>
              <v-empty-state
                v-else-if="!catalogLoading && recentItems.length === 0"
                icon="mdi-archive-plus-outline"
                title="No catalog items yet"
                text="Add the first book, document, package, model, map, or reference item."
              >
                <template #actions>
                  <v-btn color="primary" prepend-icon="mdi-plus" @click="openAddItemDialog">Add Item</v-btn>
                </template>
              </v-empty-state>
              <v-skeleton-loader v-else-if="catalogLoading" type="table" />
              <div v-else-if="catalogViewMode === 'table'" class="table-scroll">
                <v-table>
                  <thead>
                    <tr>
                      <th>Title</th>
                      <th>Type</th>
                      <th>Topic</th>
                      <th>Location</th>
                    </tr>
                  </thead>
                  <tbody>
                    <tr v-for="item in recentItems" :key="item.title">
                      <td>{{ item.title }}</td>
                      <td>{{ item.type }}</td>
                      <td>{{ item.topic }}</td>
                      <td>{{ item.location }}</td>
                    </tr>
                  </tbody>
                </v-table>
              </div>
              <div v-else class="mobile-item-list">
                <button v-for="item in recentItems" :key="item.title" class="mobile-item-card" type="button">
                  <span class="mobile-item-title">{{ item.title }}</span>
                  <span class="mobile-item-meta">{{ item.type }} - {{ item.topic }}</span>
                  <span class="mobile-item-location">
                    <v-icon icon="mdi-folder-marker-outline" size="18" />
                    {{ item.location }}
                  </span>
                </button>
              </div>
            </v-card>

            <v-card variant="flat" class="panel-card">
              <div class="panel-heading">
                <h2>Tags To Prove Out</h2>
                <v-btn icon="mdi-tune" variant="text" aria-label="Manage tags" />
              </div>
              <v-alert v-if="tagsError" type="error" variant="tonal" class="panel-alert">
                {{ tagsError }}
              </v-alert>
              <v-skeleton-loader v-else-if="tagsLoading" type="chip, chip, chip, chip" />
              <div class="tag-cloud">
                <v-chip v-for="tag in tags" :key="tag" variant="tonal" color="primary">{{ tag }}</v-chip>
              </div>
            </v-card>
          </section>
        </v-container>
      </v-main>
    </v-layout>

    <v-dialog v-model="authDialogOpen" max-width="460">
      <v-card class="auth-card">
        <v-card-title>Sign In</v-card-title>
        <v-card-text>
          <p class="auth-copy">
            Enter your email and Supabase will send a magic link for Quartermaster.
          </p>
          <v-form @submit.prevent="sendMagicLink">
            <v-text-field
              v-model="email"
              label="Email"
              type="email"
              prepend-inner-icon="mdi-email-outline"
              variant="outlined"
              autocomplete="email"
              :disabled="authLoading"
            />
            <v-btn
              block
              color="primary"
              prepend-icon="mdi-email-fast-outline"
              type="submit"
              :loading="authLoading"
            >
              Send Magic Link
            </v-btn>
          </v-form>
        </v-card-text>
      </v-card>
    </v-dialog>

    <v-dialog v-model="itemDialogOpen" max-width="720">
      <v-card class="item-dialog-card">
        <v-card-title>Add Catalog Item</v-card-title>
        <v-card-text>
          <v-alert v-if="itemError" type="error" variant="tonal" class="panel-alert">
            {{ itemError }}
          </v-alert>

          <v-form @submit.prevent="createCatalogItem">
            <div class="item-form-grid">
              <v-text-field
                v-model="itemForm.title"
                label="Title"
                prepend-inner-icon="mdi-format-title"
                variant="outlined"
                :disabled="itemSaving"
                required
              />
              <v-select
                v-model="itemForm.item_type"
                label="Type"
                :items="itemTypes"
                item-title="label"
                item-value="value"
                prepend-inner-icon="mdi-shape-outline"
                variant="outlined"
                :disabled="itemSaving"
              />
              <v-select
                v-model="itemForm.historical_period_id"
                label="Period"
                :items="periodOptions"
                item-title="name"
                item-value="id"
                prepend-inner-icon="mdi-timeline-clock-outline"
                variant="outlined"
                clearable
                :disabled="itemSaving || taxonomyLoading"
              />
              <v-select
                v-model="itemForm.conflict_id"
                label="Conflict"
                :items="conflictOptions"
                item-title="name"
                item-value="id"
                prepend-inner-icon="mdi-map-marker-distance"
                variant="outlined"
                clearable
                :disabled="itemSaving || taxonomyLoading"
              />
              <v-select
                v-model="itemForm.visibility"
                label="Visibility"
                :items="visibilityOptions"
                item-title="label"
                item-value="value"
                prepend-inner-icon="mdi-eye-outline"
                variant="outlined"
                :disabled="itemSaving"
              />
            </div>
            <v-textarea
              v-model="itemForm.description"
              label="Description"
              prepend-inner-icon="mdi-text-box-outline"
              variant="outlined"
              rows="4"
              auto-grow
              :disabled="itemSaving"
            />
            <div class="dialog-actions">
              <v-btn variant="text" :disabled="itemSaving" @click="itemDialogOpen = false">Cancel</v-btn>
              <v-btn color="primary" prepend-icon="mdi-content-save-outline" type="submit" :loading="itemSaving">
                Save Item
              </v-btn>
            </div>
          </v-form>
        </v-card-text>
      </v-card>
    </v-dialog>
  </v-app>
</template>

<script setup>
import { computed, onMounted, ref, watch } from 'vue'
import { useDisplay } from 'vuetify'
import { supabase } from './lib/supabase'

const { mdAndDown } = useDisplay()
const mobile = computed(() => mdAndDown.value)
const drawerOpen = ref(!mobile.value)
const catalogViewMode = ref(mobile.value ? 'list' : 'table')
const authDialogOpen = ref(false)
const authLoading = ref(false)
const authMessage = ref('')
const authMessageType = ref('info')
const email = ref('')
const session = ref(null)
const catalogItems = ref([])
const tags = ref([])
const catalogLoading = ref(false)
const tagsLoading = ref(false)
const catalogError = ref('')
const tagsError = ref('')
const taxonomyTerms = ref([])
const taxonomyLoading = ref(false)
const itemDialogOpen = ref(false)
const itemSaving = ref(false)
const itemError = ref('')
const itemForm = ref(createEmptyItemForm())

const itemTypes = [
  { label: 'Package', value: 'package' },
  { label: 'Book', value: 'book' },
  { label: 'Document', value: 'document' },
  { label: 'STL model', value: 'stl_model' },
  { label: 'CAD model', value: 'cad_model' },
  { label: 'Map', value: 'map' },
  { label: 'Photo', value: 'photo' },
  { label: 'Rules', value: 'rules' },
  { label: 'Scenario', value: 'scenario' },
  { label: 'Reference', value: 'reference' },
  { label: 'Other', value: 'other' },
]

const visibilityOptions = [
  { label: 'Private', value: 'private' },
  { label: 'Shared', value: 'shared' },
  { label: 'Public candidate', value: 'public_candidate' },
]

const periodOptions = computed(() => taxonomyTerms.value.filter((term) => term.term_type === 'historical_period'))
const conflictOptions = computed(() => taxonomyTerms.value.filter((term) => term.term_type === 'conflict'))

const recentItems = computed(() =>
  catalogItems.value.map((item) => ({
    title: item.title,
    type: formatItemType(item.item_type),
    topic: item.conflict?.name || item.historical_period?.name || 'Unassigned',
    location: 'No location yet',
  }))
)

const metrics = computed(() => [
  { label: 'Catalog items', value: String(catalogItems.value.length), icon: 'mdi-archive-outline' },
  { label: 'Known locations', value: '0', icon: 'mdi-folder-marker-outline' },
  { label: 'Creators', value: '0', icon: 'mdi-account-group-outline' },
  { label: 'Tags', value: String(tags.value.length), icon: 'mdi-tag-outline' },
])

watch(mobile, (isMobile) => {
  drawerOpen.value = !isMobile
})

onMounted(async () => {
  const { data } = await supabase.auth.getSession()
  session.value = data.session
  if (data.session) {
    await loadDashboardData()
  }

  supabase.auth.onAuthStateChange((_event, newSession) => {
    session.value = newSession
    authDialogOpen.value = false
    if (newSession) {
      loadDashboardData()
    } else {
      catalogItems.value = []
      tags.value = []
    }
  })
})

async function loadDashboardData() {
  await Promise.all([loadCatalogItems(), loadTags(), loadTaxonomyTerms()])
}

async function loadCatalogItems() {
  catalogLoading.value = true
  catalogError.value = ''

  const { data, error } = await supabase
    .schema('catalog')
    .from('items')
    .select(`
      id,
      title,
      item_type,
      created_at,
      historical_period:historical_period_id(name),
      conflict:conflict_id(name)
    `)
    .order('created_at', { ascending: false })
    .limit(8)

  catalogLoading.value = false

  if (error) {
    catalogError.value = error.message
    return
  }

  catalogItems.value = data || []
}

async function loadTags() {
  tagsLoading.value = true
  tagsError.value = ''

  const { data, error } = await supabase
    .schema('catalog')
    .from('tags')
    .select('name')
    .order('name', { ascending: true })

  tagsLoading.value = false

  if (error) {
    tagsError.value = error.message
    return
  }

  tags.value = (data || []).map((tag) => tag.name)
}

async function loadTaxonomyTerms() {
  taxonomyLoading.value = true

  const { data, error } = await supabase
    .schema('catalog')
    .from('taxonomy_terms')
    .select('id, term_type, name')
    .in('term_type', ['historical_period', 'conflict'])
    .order('term_type', { ascending: true })
    .order('name', { ascending: true })

  taxonomyLoading.value = false

  if (error) {
    itemError.value = error.message
    return
  }

  taxonomyTerms.value = data || []
}

function openAddItemDialog() {
  itemForm.value = createEmptyItemForm()
  itemError.value = ''
  itemDialogOpen.value = true
}

async function createCatalogItem() {
  if (!itemForm.value.title.trim()) {
    itemError.value = 'Title is required.'
    return
  }

  itemSaving.value = true
  itemError.value = ''

  const payload = {
    title: itemForm.value.title.trim(),
    item_type: itemForm.value.item_type,
    description: itemForm.value.description.trim() || null,
    historical_period_id: itemForm.value.historical_period_id || null,
    conflict_id: itemForm.value.conflict_id || null,
    visibility: itemForm.value.visibility,
    created_by: session.value.user.id,
  }

  const { error } = await supabase.schema('catalog').from('items').insert(payload)

  itemSaving.value = false

  if (error) {
    itemError.value = error.message
    return
  }

  itemDialogOpen.value = false
  authMessageType.value = 'success'
  authMessage.value = 'Catalog item added.'
  await loadCatalogItems()
}

async function sendMagicLink() {
  authLoading.value = true
  authMessage.value = ''

  const { error } = await supabase.auth.signInWithOtp({
    email: email.value,
    options: {
      emailRedirectTo: window.location.origin,
    },
  })

  authLoading.value = false

  if (error) {
    authMessageType.value = 'error'
    authMessage.value = error.message
    return
  }

  authMessageType.value = 'success'
  authMessage.value = 'Magic link sent. Check your email to finish signing in.'
}

async function signOut() {
  authLoading.value = true
  const { error } = await supabase.auth.signOut()
  authLoading.value = false

  if (error) {
    authMessageType.value = 'error'
    authMessage.value = error.message
    return
  }

  authMessageType.value = 'info'
  authMessage.value = 'Signed out.'
}

function formatItemType(value) {
  return value
    .split('_')
    .map((part) => part.charAt(0).toUpperCase() + part.slice(1))
    .join(' ')
}

function createEmptyItemForm() {
  return {
    title: '',
    item_type: 'document',
    description: '',
    historical_period_id: null,
    conflict_id: null,
    visibility: 'private',
  }
}
</script>




