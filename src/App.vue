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
          <v-list-item
            prepend-icon="mdi-view-dashboard-outline"
            title="Dashboard"
            :active="activeSection === 'dashboard'"
            @click="setActiveSection('dashboard')"
          />
          <v-list-item
            prepend-icon="mdi-archive-search-outline"
            title="Catalog"
            :active="activeSection === 'catalog'"
            @click="setActiveSection('catalog')"
          />
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
              <h1>{{ sectionTitle }}</h1>
              <p>{{ sectionSubtitle }}</p>
            </div>
            <div class="topbar-actions">
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

          <section v-if="activeSection === 'dashboard'" class="search-band">
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

          <section v-if="activeSection === 'dashboard'" class="metric-grid">
            <v-card v-for="metric in metrics" :key="metric.label" variant="flat" class="metric-card">
              <v-icon :icon="metric.icon" size="30" />
              <div>
                <div class="metric-value">{{ metric.value }}</div>
                <div class="metric-label">{{ metric.label }}</div>
              </div>
            </v-card>
          </section>

          <section v-if="activeSection === 'dashboard'" class="content-grid">
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
                    <v-tooltip text="Table view">
                      <template #activator="{ props }">
                        <v-btn v-bind="props" value="table" icon="mdi-table" aria-label="Table view" />
                      </template>
                    </v-tooltip>
                    <v-tooltip text="List view">
                      <template #activator="{ props }">
                        <v-btn v-bind="props" value="list" icon="mdi-format-list-bulleted" aria-label="List view" />
                      </template>
                    </v-tooltip>
                  </v-btn-toggle>
                  <v-btn icon="mdi-arrow-right" variant="text" aria-label="Open catalog" @click="setActiveSection('catalog')" />
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
                    <tr
                      v-for="item in recentItems"
                      :key="item.id"
                      class="clickable-row"
                      @click="openCatalogItem(item.id)"
                    >
                      <td>{{ item.title }}</td>
                      <td>{{ item.type }}</td>
                      <td>{{ item.topic }}</td>
                      <td>{{ item.location }}</td>
                    </tr>
                  </tbody>
                </v-table>
              </div>
              <div v-else class="mobile-item-list">
                <button
                  v-for="item in recentItems"
                  :key="item.id"
                  class="mobile-item-card"
                  type="button"
                  @click="openCatalogItem(item.id)"
                >
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

          <section v-else-if="activeSection === 'catalog'" class="catalog-section">
            <v-card variant="flat" class="panel-card">
              <div class="panel-heading panel-heading-responsive">
                <h2>Catalog Items</h2>
                <div class="panel-actions">
                  <v-btn-toggle
                    v-model="catalogViewMode"
                    mandatory
                    divided
                    density="comfortable"
                    variant="outlined"
                    aria-label="Catalog view mode"
                  >
                    <v-tooltip text="Table view">
                      <template #activator="{ props }">
                        <v-btn v-bind="props" value="table" icon="mdi-table" aria-label="Table view" />
                      </template>
                    </v-tooltip>
                    <v-tooltip text="List view">
                      <template #activator="{ props }">
                        <v-btn v-bind="props" value="list" icon="mdi-format-list-bulleted" aria-label="List view" />
                      </template>
                    </v-tooltip>
                  </v-btn-toggle>
                  <v-btn color="primary" prepend-icon="mdi-plus" @click="openAddItemDialog">Add Item</v-btn>
                </div>
              </div>

              <div class="catalog-filters">
                <v-text-field
                  v-model="catalogSearch"
                  prepend-inner-icon="mdi-magnify"
                  label="Search catalog"
                  variant="outlined"
                  density="comfortable"
                  hide-details
                />
                <v-select
                  v-model="catalogTypeFilter"
                  label="Type"
                  :items="catalogTypeFilterOptions"
                  item-title="label"
                  item-value="value"
                  variant="outlined"
                  density="comfortable"
                  hide-details
                />
                <v-select
                  v-model="catalogSortMode"
                  label="Sort"
                  :items="catalogSortOptions"
                  item-title="label"
                  item-value="value"
                  variant="outlined"
                  density="comfortable"
                  hide-details
                />
              </div>

              <v-alert v-if="catalogError" type="error" variant="tonal" class="panel-alert">
                {{ catalogError }}
              </v-alert>
              <v-empty-state
                v-else-if="!catalogLoading && catalogRows.length === 0"
                icon="mdi-archive-plus-outline"
                title="No matching catalog items"
                text="Add an item or adjust the filters."
              />
              <v-skeleton-loader v-else-if="catalogLoading" type="table" />
              <div v-else-if="catalogViewMode === 'table'" class="table-scroll">
                <v-table>
                  <thead>
                    <tr>
                      <th>Title</th>
                      <th>Type</th>
                      <th>Topic</th>
                      <th>Visibility</th>
                      <th>Created</th>
                      <th class="actions-column">Actions</th>
                    </tr>
                  </thead>
                  <tbody>
                    <tr
                      v-for="item in catalogRows"
                      :key="item.id"
                      class="clickable-row"
                      :class="{ 'selected-row': selectedCatalogItemId === item.id }"
                      @click="selectCatalogItem(item.id)"
                    >
                      <td>{{ item.title }}</td>
                      <td>{{ item.type }}</td>
                      <td>{{ item.topic }}</td>
                      <td>{{ item.visibility }}</td>
                      <td>{{ item.created }}</td>
                      <td class="actions-column">
                        <v-tooltip text="Edit item">
                          <template #activator="{ props }">
                            <v-btn
                              v-bind="props"
                              icon="mdi-pencil-outline"
                              variant="text"
                              aria-label="Edit item"
                              @click.stop="openEditItemDialog(item)"
                            />
                          </template>
                        </v-tooltip>
                      </td>
                    </tr>
                  </tbody>
                </v-table>
              </div>
              <div v-else class="mobile-item-list">
                <button
                  v-for="item in catalogRows"
                  :key="item.id"
                  class="mobile-item-card"
                  :class="{ 'selected-item-card': selectedCatalogItemId === item.id }"
                  type="button"
                  @click="selectCatalogItem(item.id)"
                >
                  <span class="mobile-item-card-main">
                    <span class="mobile-item-title">{{ item.title }}</span>
                    <span class="mobile-item-meta">{{ item.type }} - {{ item.topic }}</span>
                    <span class="mobile-item-location">
                      <v-icon icon="mdi-eye-outline" size="18" />
                      {{ item.visibility }}
                    </span>
                  </span>
                  <span class="mobile-item-actions">
                    <v-tooltip text="Edit item">
                      <template #activator="{ props }">
                        <v-btn
                          v-bind="props"
                          icon="mdi-pencil-outline"
                          variant="text"
                          aria-label="Edit item"
                          @click.stop="openEditItemDialog(item)"
                        />
                      </template>
                    </v-tooltip>
                  </span>
                </button>
              </div>
            </v-card>

            <v-card v-if="selectedCatalogItem" variant="flat" class="panel-card detail-panel">
              <div class="panel-heading">
                <h2>{{ selectedCatalogItem.title }}</h2>
                <v-btn icon="mdi-close" variant="text" aria-label="Close item detail" @click="clearSelectedCatalogItem" />
              </div>

              <div class="detail-meta-grid">
                <div>
                  <span class="detail-label">Type</span>
                  <strong>{{ selectedCatalogItem.type }}</strong>
                </div>
                <div>
                  <span class="detail-label">Topic</span>
                  <strong>{{ selectedCatalogItem.topic }}</strong>
                </div>
                <div>
                  <span class="detail-label">Visibility</span>
                  <strong>{{ selectedCatalogItem.visibility }}</strong>
                </div>
                <div>
                  <span class="detail-label">Created</span>
                  <strong>{{ selectedCatalogItem.created }}</strong>
                </div>
              </div>

              <div class="detail-description">
                <span class="detail-label">Description</span>
                <p>{{ selectedCatalogItem.description || 'No description yet.' }}</p>
              </div>

              <div class="detail-actions">
                <v-btn prepend-icon="mdi-pencil-outline" variant="outlined" @click="openEditItemDialog(selectedCatalogItem)">
                  Edit
                </v-btn>
                <v-btn prepend-icon="mdi-folder-marker-outline" variant="outlined">Add Location</v-btn>
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
        <v-card-title>{{ itemDialogTitle }}</v-card-title>
        <v-card-text>
          <v-alert v-if="itemError" type="error" variant="tonal" class="panel-alert">
            {{ itemError }}
          </v-alert>

          <v-form @submit.prevent="saveCatalogItem">
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
                {{ itemSaveButtonLabel }}
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
const activeSection = ref('dashboard')
const catalogSearch = ref('')
const catalogTypeFilter = ref('any')
const catalogSortMode = ref('newest')
const selectedCatalogItemId = ref(null)
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
const editingItemId = ref(null)

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
  catalogRows.value.slice(0, 8).map((item) => ({
    id: item.id,
    title: item.title,
    type: item.type,
    topic: item.topic,
    location: 'No location yet',
  }))
)

const catalogTypeFilterOptions = computed(() => [
  { label: 'Any', value: 'any' },
  ...itemTypes,
])

const catalogSortOptions = [
  { label: 'Newest first', value: 'newest' },
  { label: 'Oldest first', value: 'oldest' },
  { label: 'Title A-Z', value: 'title' },
  { label: 'Type A-Z', value: 'type' },
  { label: 'Topic A-Z', value: 'topic' },
]

const catalogRows = computed(() => {
  const search = catalogSearch.value.trim().toLowerCase()

  return catalogItems.value
    .map(toCatalogRow)
    .filter((item) => catalogTypeFilter.value === 'any' || item.item_type === catalogTypeFilter.value)
    .filter((item) => {
      if (!search) return true
      return [item.title, item.type, item.topic, item.description].some((value) =>
        value.toLowerCase().includes(search)
      )
    })
    .sort(sortCatalogRows)
})

const selectedCatalogItem = computed(() =>
  catalogRows.value.find((item) => item.id === selectedCatalogItemId.value) || null
)

const metrics = computed(() => [
  { label: 'Catalog items', value: String(catalogItems.value.length), icon: 'mdi-archive-outline' },
  { label: 'Known locations', value: '0', icon: 'mdi-folder-marker-outline' },
  { label: 'Creators', value: '0', icon: 'mdi-account-group-outline' },
  { label: 'Tags', value: String(tags.value.length), icon: 'mdi-tag-outline' },
])

const sectionTitle = computed(() => (activeSection.value === 'catalog' ? 'Catalog' : 'Quartermaster'))
const sectionSubtitle = computed(() =>
  activeSection.value === 'catalog'
    ? 'Browse and filter books, documents, packages, models, maps, and references.'
    : 'Track what you have, what it describes, and where your copy lives.'
)
const itemDialogTitle = computed(() => (editingItemId.value ? 'Edit Catalog Item' : 'Add Catalog Item'))
const itemSaveButtonLabel = computed(() => (editingItemId.value ? 'Update Item' : 'Save Item'))

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
      description,
      item_type,
      historical_period_id,
      conflict_id,
      visibility,
      created_at,
      historical_period:historical_period_id(name),
      conflict:conflict_id(name)
    `)
    .order('created_at', { ascending: false })

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
  editingItemId.value = null
  itemForm.value = createEmptyItemForm()
  itemError.value = ''
  itemDialogOpen.value = true
}

function openEditItemDialog(item) {
  editingItemId.value = item.id
  itemForm.value = {
    title: item.title,
    item_type: item.item_type,
    description: item.description,
    historical_period_id: item.historical_period_id,
    conflict_id: item.conflict_id,
    visibility: item.visibility_value,
  }
  itemError.value = ''
  itemDialogOpen.value = true
}

function setActiveSection(section) {
  activeSection.value = section
  if (mobile.value) {
    drawerOpen.value = false
  }
}

function selectCatalogItem(itemId) {
  selectedCatalogItemId.value = itemId
}

function openCatalogItem(itemId) {
  activeSection.value = 'catalog'
  selectedCatalogItemId.value = itemId
}

function clearSelectedCatalogItem() {
  selectedCatalogItemId.value = null
}

async function saveCatalogItem() {
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

  const query = supabase.schema('catalog').from('items')
  const { error } = editingItemId.value
    ? await query.update(payload).eq('id', editingItemId.value)
    : await query.insert(payload)

  itemSaving.value = false

  if (error) {
    itemError.value = error.message
    return
  }

  itemDialogOpen.value = false
  authMessageType.value = 'success'
  authMessage.value = editingItemId.value ? 'Catalog item updated.' : 'Catalog item added.'
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

function toCatalogRow(item) {
  return {
    id: item.id,
    title: item.title,
    description: item.description || '',
    item_type: item.item_type,
    type: formatItemType(item.item_type),
    historical_period_id: item.historical_period_id,
    conflict_id: item.conflict_id,
    topic: item.conflict?.name || item.historical_period?.name || 'Unassigned',
    visibility_value: item.visibility,
    visibility: formatItemType(item.visibility),
    created: new Intl.DateTimeFormat(undefined, { dateStyle: 'medium' }).format(new Date(item.created_at)),
    created_at: item.created_at,
  }
}

function sortCatalogRows(first, second) {
  if (catalogSortMode.value === 'oldest') {
    return new Date(first.created_at) - new Date(second.created_at)
  }

  if (catalogSortMode.value === 'title') {
    return first.title.localeCompare(second.title)
  }

  if (catalogSortMode.value === 'type') {
    return first.type.localeCompare(second.type) || first.title.localeCompare(second.title)
  }

  if (catalogSortMode.value === 'topic') {
    return first.topic.localeCompare(second.topic) || first.title.localeCompare(second.title)
  }

  return new Date(second.created_at) - new Date(first.created_at)
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




