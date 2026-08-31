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

            <v-card variant="flat" class="panel-card">
              <div class="panel-heading">
                <h2>Location Roots</h2>
                <v-tooltip text="Add location root">
                  <template #activator="{ props }">
                    <v-btn
                      v-bind="props"
                      icon="mdi-plus"
                      variant="text"
                      aria-label="Add location root"
                      @click="openLocationRootDialog()"
                    />
                  </template>
                </v-tooltip>
              </div>
              <v-skeleton-loader v-if="locationRootsLoading" type="list-item-two-line, list-item-two-line" />
              <div v-else-if="locationRoots.length" class="creator-list">
                <div v-for="root in locationRoots" :key="root.id" class="creator-row">
                  <span>
                    <strong>{{ root.label }}</strong>
                    <small>{{ root.base_path || locationTypeName(root.location_type_id) }}</small>
                  </span>
                  <span class="creator-actions">
                    <v-tooltip text="Edit location root">
                      <template #activator="{ props }">
                        <v-btn
                          v-bind="props"
                          icon="mdi-pencil-outline"
                          variant="text"
                          aria-label="Edit location root"
                          @click="openLocationRootDialog(root)"
                        />
                      </template>
                    </v-tooltip>
                    <v-tooltip text="Delete location root">
                      <template #activator="{ props }">
                        <v-btn
                          v-bind="props"
                          icon="mdi-delete-outline"
                          variant="text"
                          aria-label="Delete location root"
                          @click="deleteLocationRoot(root)"
                        />
                      </template>
                    </v-tooltip>
                  </span>
                </div>
              </div>
              <v-alert v-else type="info" variant="tonal" class="panel-alert">
                Add reusable roots for common drives, shelves, NAS shares, and cloud folders.
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

          <section v-if="activeSection === 'dashboard'" class="metric-grid">
            <v-card v-for="metric in metrics" :key="metric.label" variant="flat" class="metric-card">
              <v-icon :icon="metric.icon" size="30" />
              <div>
                <div class="metric-value">{{ metric.value }}</div>
                <div class="metric-label">{{ metric.label }}</div>
              </div>
            </v-card>
          </section>

          <section v-if="activeSection === 'dashboard'" class="search-band">
            <v-text-field
              v-model="catalogSearch"
              prepend-inner-icon="mdi-magnify"
              placeholder="Search assets, books, documents, packages, creators, tags"
              aria-label="Search catalog"
              variant="outlined"
              density="comfortable"
              hide-details
              single-line
              @keyup.enter="showCatalogResults"
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
              v-model="catalogPeriodFilter"
              label="Period"
              :items="catalogPeriodFilterOptions"
              item-title="label"
              item-value="value"
              variant="outlined"
              density="comfortable"
              hide-details
            />
            <v-btn color="primary" prepend-icon="mdi-magnify" @click="showCatalogResults">
              Search
            </v-btn>
          </section>

          <section v-if="activeSection === 'dashboard'" class="content-grid">
            <v-card variant="flat" class="panel-card recent-panel">
              <div class="panel-heading panel-heading-responsive">
                <h2>{{ dashboardCatalogTitle }}</h2>
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
                v-else-if="!catalogLoading && dashboardCatalogItems.length === 0"
                icon="mdi-archive-plus-outline"
                :title="hasCatalogSearchOrFilters ? 'No matching catalog items' : 'No catalog items yet'"
                :text="hasCatalogSearchOrFilters ? 'Try a different search or clear the filters.' : 'Add the first book, document, package, model, map, or reference item.'"
              >
                <template #actions>
                  <v-btn color="primary" prepend-icon="mdi-plus" @click="openAddItemDialog">Add Item</v-btn>
                </template>
              </v-empty-state>
              <v-skeleton-loader v-else-if="catalogLoading" type="table" />
              <div v-else class="catalog-results-summary">
                {{ catalogResultSummary }}
              </div>
              <div v-if="!catalogLoading && catalogRows.length && catalogViewMode === 'table'" class="table-scroll">
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
                      v-for="item in dashboardCatalogItems"
                      :key="item.id"
                      class="clickable-row"
                      @click="openCatalogItem(item.id)"
                    >
                      <td>{{ item.displayTitle }}</td>
                      <td>{{ item.type }}</td>
                      <td>{{ item.topic }}</td>
                      <td>{{ item.location }}</td>
                    </tr>
                  </tbody>
                </v-table>
              </div>
              <div v-else-if="!catalogLoading && catalogRows.length" class="mobile-item-list">
                <button
                  v-for="item in dashboardCatalogItems"
                  :key="item.id"
                  class="mobile-item-card"
                  type="button"
                  @click="openCatalogItem(item.id)"
                >
                  <span class="mobile-item-title">{{ item.displayTitle }}</span>
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
                <v-chip v-for="tag in tags" :key="tag.id" variant="tonal" color="primary">{{ tag.name }}</v-chip>
              </div>
            </v-card>

            <v-card variant="flat" class="panel-card">
              <div class="panel-heading">
                <h2>Creators</h2>
                <v-tooltip text="Add creator">
                  <template #activator="{ props }">
                    <v-btn
                      v-bind="props"
                      icon="mdi-plus"
                      variant="text"
                      aria-label="Add creator"
                      @click="openCreatorDialog()"
                    />
                  </template>
                </v-tooltip>
              </div>
              <v-alert v-if="creatorsError" type="error" variant="tonal" class="panel-alert">
                {{ creatorsError }}
              </v-alert>
              <v-skeleton-loader v-else-if="creatorsLoading" type="list-item-two-line, list-item-two-line" />
              <div v-else-if="creators.length" class="creator-list">
                <div v-for="creator in creators" :key="creator.id" class="creator-row">
                  <span>
                    <strong>{{ creator.name }}</strong>
                    <small>{{ creator.website_url || 'No website yet' }}</small>
                  </span>
                  <span class="creator-actions">
                    <v-tooltip text="Edit creator">
                      <template #activator="{ props }">
                        <v-btn
                          v-bind="props"
                          icon="mdi-pencil-outline"
                          variant="text"
                          aria-label="Edit creator"
                          @click="openCreatorDialog(creator)"
                        />
                      </template>
                    </v-tooltip>
                    <v-tooltip text="Delete creator">
                      <template #activator="{ props }">
                        <v-btn
                          v-bind="props"
                          icon="mdi-delete-outline"
                          variant="text"
                          aria-label="Delete creator"
                          @click="deleteCreator(creator)"
                        />
                      </template>
                    </v-tooltip>
                  </span>
                </div>
              </div>
              <v-alert v-else type="info" variant="tonal" class="panel-alert">
                Add creators for studios, publishers, marketplaces, and archives.
              </v-alert>
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
                  placeholder="Search catalog"
                  aria-label="Search catalog"
                  variant="outlined"
                  density="comfortable"
                  hide-details
                  single-line
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
                  v-model="catalogCreatorFilter"
                  label="Creator"
                  :items="catalogCreatorFilterOptions"
                  item-title="label"
                  item-value="value"
                  variant="outlined"
                  density="comfortable"
                  hide-details
                />
                <v-select
                  v-model="catalogPeriodFilter"
                  label="Period"
                  :items="catalogPeriodFilterOptions"
                  item-title="label"
                  item-value="value"
                  variant="outlined"
                  density="comfortable"
                  hide-details
                />
                <v-select
                  v-model="catalogConflictFilter"
                  label="Conflict"
                  :items="catalogConflictFilterOptions"
                  item-title="label"
                  item-value="value"
                  variant="outlined"
                  density="comfortable"
                  hide-details
                />
                <v-select
                  v-model="catalogTheatreFilter"
                  label="Theatre"
                  :items="catalogTheatreFilterOptions"
                  item-title="label"
                  item-value="value"
                  variant="outlined"
                  density="comfortable"
                  hide-details
                />
                <v-select
                  v-model="catalogFactionFilter"
                  label="Faction"
                  :items="catalogFactionFilterOptions"
                  item-title="label"
                  item-value="value"
                  variant="outlined"
                  density="comfortable"
                  hide-details
                />
                <v-select
                  v-model="catalogTagFilter"
                  label="Tag"
                  :items="catalogTagFilterOptions"
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
                <v-btn prepend-icon="mdi-filter-remove-outline" variant="outlined" @click="clearCatalogFilters">
                  Clear
                </v-btn>
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
                      <th>Creator</th>
                      <th>Parent</th>
                      <th>Topic</th>
                      <th>Location</th>
                      <th>Tags</th>
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
                      <td>{{ item.displayTitle }}</td>
                      <td>{{ item.type }}</td>
                      <td>{{ tableCellValue(item.creatorName) }}</td>
                      <td>{{ tableCellValue(item.parentTitle || childCountLabel(item)) }}</td>
                      <td>{{ item.topic }}</td>
                      <td>{{ itemLocationSummary(item.id) }}</td>
                      <td>{{ tableCellValue(tagListLabel(item.tags)) }}</td>
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
                    <span class="mobile-item-title">{{ item.displayTitle }}</span>
                    <span class="mobile-item-meta">{{ item.type }} - {{ item.topic }}</span>
                    <span v-if="item.location !== 'No location yet'" class="mobile-item-location">
                      <v-icon icon="mdi-folder-marker-outline" size="18" />
                      {{ item.location }}
                    </span>
                    <span v-if="item.creatorName" class="mobile-item-location">
                      <v-icon icon="mdi-account-edit-outline" size="18" />
                      {{ item.creatorName }}
                    </span>
                    <span v-if="item.parentTitle || item.childCount" class="mobile-item-location">
                      <v-icon icon="mdi-family-tree" size="18" />
                      {{ item.parentTitle || childCountLabel(item) }}
                    </span>
                    <span v-if="item.tags.length" class="mobile-item-location">
                      <v-icon icon="mdi-tag-multiple-outline" size="18" />
                      {{ tagListLabel(item.tags) }}
                    </span>
                    <span class="mobile-item-location">
                      <v-icon icon="mdi-eye-outline" size="18" />
                      {{ item.visibility }} - {{ item.created }}
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
                <h2>{{ selectedCatalogItem.displayTitle }}</h2>
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
                <div v-if="selectedCatalogItem.creatorName">
                  <span class="detail-label">Creator</span>
                  <strong>{{ selectedCatalogItem.creatorName }}</strong>
                </div>
                <div v-if="selectedCatalogItem.parentTitle">
                  <span class="detail-label">Parent</span>
                  <strong>{{ selectedCatalogItem.parentTitle }}</strong>
                </div>
                <div v-if="selectedCatalogItem.childCount">
                  <span class="detail-label">Child items</span>
                  <strong>{{ childCountLabel(selectedCatalogItem) }}</strong>
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

              <div v-if="selectedCatalogItem.tags.length" class="detail-tag-list">
                <span class="detail-label">Tags</span>
                <v-chip v-for="tag in selectedCatalogItem.tags" :key="tag.id" variant="tonal" color="primary">
                  {{ tag.name }}
                </v-chip>
              </div>

              <div v-if="selectedCatalogItem.publicationDetails.length" class="publication-detail-list">
                <span class="detail-label">Publication Details</span>
                <div class="publication-detail-grid">
                  <div v-for="detail in selectedCatalogItem.publicationDetails" :key="detail.label">
                    <span class="detail-label">{{ detail.label }}</span>
                    <strong>{{ detail.value }}</strong>
                  </div>
                </div>
              </div>

              <div v-if="selectedChildItems.length" class="child-item-list">
                <span class="detail-label">Contents</span>
                <button
                  v-for="child in selectedChildItems"
                  :key="child.id"
                  class="child-item-row"
                  type="button"
                  @click="selectCatalogItem(child.id)"
                >
                  <span>
                    <strong>{{ child.displayTitle }}</strong>
                    <small>{{ child.type }} - {{ child.topic }}</small>
                  </span>
                  <v-icon icon="mdi-chevron-right" size="20" />
                </button>
              </div>

              <div v-if="selectedCatalogItem.files.length" class="file-list">
                <span class="detail-label">Files</span>
                <div v-for="file in selectedCatalogItem.files" :key="file.id" class="file-row">
                  <span class="file-row-main">
                    <strong>{{ file.filename }}</strong>
                    <small>{{ fileMetaLabel(file) }}</small>
                    <span v-if="fileLocationsForFile(file.id).length" class="file-location-list">
                      <span v-for="location in fileLocationsForFile(file.id)" :key="location.id" class="file-location-row">
                        <small>{{ fileLocationLabel(location) }}</small>
                        <span class="file-location-actions">
                          <v-tooltip text="Edit file location">
                            <template #activator="{ props }">
                              <v-btn
                                v-bind="props"
                                icon="mdi-pencil-outline"
                                size="x-small"
                                variant="text"
                                aria-label="Edit file location"
                                @click="openFileLocationDialog(file, location)"
                              />
                            </template>
                          </v-tooltip>
                          <v-tooltip text="Delete file location">
                            <template #activator="{ props }">
                              <v-btn
                                v-bind="props"
                                icon="mdi-delete-outline"
                                size="x-small"
                                variant="text"
                                aria-label="Delete file location"
                                @click="deleteFileLocation(location)"
                              />
                            </template>
                          </v-tooltip>
                        </span>
                      </span>
                    </span>
                  </span>
                  <span class="file-actions">
                    <v-tooltip text="Add file location">
                      <template #activator="{ props }">
                        <v-btn
                          v-bind="props"
                          icon="mdi-folder-marker-outline"
                          variant="text"
                          aria-label="Add file location"
                          @click="openFileLocationDialog(file)"
                        />
                      </template>
                    </v-tooltip>
                    <v-tooltip text="Edit file">
                      <template #activator="{ props }">
                        <v-btn
                          v-bind="props"
                          icon="mdi-pencil-outline"
                          variant="text"
                          aria-label="Edit file"
                          @click="openFileDialog(file)"
                        />
                      </template>
                    </v-tooltip>
                    <v-tooltip text="Delete file">
                      <template #activator="{ props }">
                        <v-btn
                          v-bind="props"
                          icon="mdi-delete-outline"
                          variant="text"
                          aria-label="Delete file"
                          @click="deleteFile(file)"
                        />
                      </template>
                    </v-tooltip>
                  </span>
                </div>
              </div>

              <div v-if="selectedItemLocations.length" class="location-list">
                <span class="detail-label">Locations</span>
                <div v-for="location in selectedItemLocations" :key="location.id" class="location-card">
                  <div>
                    <strong>{{ location.location_label }}</strong>
                    <span>{{ location.locationTypeName }}</span>
                  </div>
                  <p>{{ location.path_or_detail || location.notes || 'No detail recorded.' }}</p>
                  <span class="location-actions">
                    <v-tooltip text="Edit location">
                      <template #activator="{ props }">
                        <v-btn
                          v-bind="props"
                          icon="mdi-pencil-outline"
                          size="small"
                          variant="text"
                          aria-label="Edit location"
                          @click="openLocationDialog(selectedCatalogItem, location)"
                        />
                      </template>
                    </v-tooltip>
                    <v-tooltip text="Delete location">
                      <template #activator="{ props }">
                        <v-btn
                          v-bind="props"
                          icon="mdi-delete-outline"
                          size="small"
                          variant="text"
                          aria-label="Delete location"
                          @click="deleteItemLocation(location)"
                        />
                      </template>
                    </v-tooltip>
                  </span>
                </div>
              </div>

              <div v-if="selectedItemNotes.length" class="note-list">
                <span class="detail-label">Personal Notes</span>
                <div v-for="note in selectedItemNotes" :key="note.id" class="note-card">
                  <p>{{ note.body }}</p>
                  <span class="note-actions">
                    <small>{{ formatDateTime(note.updated_at || note.created_at) }}</small>
                    <span>
                      <v-tooltip text="Edit note">
                        <template #activator="{ props }">
                          <v-btn
                            v-bind="props"
                            icon="mdi-pencil-outline"
                            size="small"
                            variant="text"
                            aria-label="Edit note"
                            @click="openNoteDialog(note)"
                          />
                        </template>
                      </v-tooltip>
                      <v-tooltip text="Delete note">
                        <template #activator="{ props }">
                          <v-btn
                            v-bind="props"
                            icon="mdi-delete-outline"
                            size="small"
                            variant="text"
                            aria-label="Delete note"
                            @click="deleteNote(note)"
                          />
                        </template>
                      </v-tooltip>
                    </span>
                  </span>
                </div>
              </div>

              <div class="detail-actions">
                <v-btn prepend-icon="mdi-pencil-outline" variant="outlined" @click="openEditItemDialog(selectedCatalogItem)">
                  Edit
                </v-btn>
                <v-btn prepend-icon="mdi-family-tree" variant="outlined" @click="openAddChildItemDialog(selectedCatalogItem)">
                  Add Child Item
                </v-btn>
                <v-btn prepend-icon="mdi-file-plus-outline" variant="outlined" @click="openFileDialog()">
                  Add File
                </v-btn>
                <v-btn prepend-icon="mdi-folder-marker-outline" variant="outlined" @click="openLocationDialog(selectedCatalogItem)">
                  Add Location
                </v-btn>
                <v-btn prepend-icon="mdi-note-plus-outline" variant="outlined" @click="openNoteDialog()">
                  Add Note
                </v-btn>
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
              <v-autocomplete
                v-model="itemForm.parent_item_id"
                label="Parent item"
                :items="parentItemOptions"
                item-title="label"
                item-value="id"
                prepend-inner-icon="mdi-family-tree"
                variant="outlined"
                clearable
                :disabled="itemSaving"
              />
              <div class="inline-create-field">
                <v-autocomplete
                  v-model="itemForm.creator_id"
                  :label="creatorFieldLabel"
                  :items="creatorOptions"
                  item-title="name"
                  item-value="id"
                  prepend-inner-icon="mdi-account-edit-outline"
                  variant="outlined"
                  clearable
                  hide-details
                  :disabled="itemSaving || creatorsLoading"
                />
                <v-tooltip text="Add creator">
                  <template #activator="{ props }">
                    <v-btn
                      v-bind="props"
                      icon="mdi-plus"
                      variant="tonal"
                      aria-label="Add creator"
                      :disabled="itemSaving"
                      @click="openCreatorDialog()"
                    />
                  </template>
                </v-tooltip>
              </div>
              <div class="inline-create-field">
                <v-select
                  v-model="itemForm.historical_period_id"
                  label="Period"
                  :items="periodOptions"
                  item-title="name"
                  item-value="id"
                  prepend-inner-icon="mdi-timeline-clock-outline"
                  variant="outlined"
                  clearable
                  hide-details
                  :disabled="itemSaving || taxonomyLoading"
                />
                <v-tooltip text="Add period">
                  <template #activator="{ props }">
                    <v-btn
                      v-bind="props"
                      icon="mdi-plus"
                      variant="tonal"
                      aria-label="Add period"
                      :disabled="itemSaving"
                      @click="openTaxonomyDialog('historical_period')"
                    />
                  </template>
                </v-tooltip>
              </div>
              <div class="inline-create-field">
                <v-select
                  v-model="itemForm.conflict_id"
                  label="Conflict"
                  :items="conflictOptions"
                  item-title="name"
                  item-value="id"
                  prepend-inner-icon="mdi-map-marker-distance"
                  variant="outlined"
                  clearable
                  hide-details
                  :disabled="itemSaving || taxonomyLoading"
                />
                <v-tooltip text="Add conflict">
                  <template #activator="{ props }">
                    <v-btn
                      v-bind="props"
                      icon="mdi-plus"
                      variant="tonal"
                      aria-label="Add conflict"
                      :disabled="itemSaving"
                      @click="openTaxonomyDialog('conflict')"
                    />
                  </template>
                </v-tooltip>
              </div>
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
            <div class="inline-create-field">
              <v-autocomplete
                v-model="itemForm.tag_ids"
                label="Tags"
                :items="tagOptions"
                item-title="name"
                item-value="id"
                prepend-inner-icon="mdi-tag-multiple-outline"
                variant="outlined"
                multiple
                chips
                closable-chips
                hide-details
                :disabled="itemSaving || tagsLoading"
              />
              <v-tooltip text="Add tag">
                <template #activator="{ props }">
                  <v-btn
                    v-bind="props"
                    icon="mdi-plus"
                    variant="tonal"
                    aria-label="Add tag"
                    :disabled="itemSaving"
                    @click="openTagDialog"
                  />
                </template>
              </v-tooltip>
            </div>
            <div class="tag-picker">
              <v-text-field
                v-model="tagPickerSearch"
                prepend-inner-icon="mdi-magnify"
                placeholder="Filter available tags"
                aria-label="Filter available tags"
                variant="outlined"
                density="compact"
                hide-details
                clearable
                single-line
                :disabled="itemSaving || tagsLoading"
              />
              <v-skeleton-loader v-if="tagsLoading" type="chip, chip, chip" />
              <div v-else-if="filteredTagOptions.length" class="tag-picker-chips" aria-label="Available tags">
                <v-chip
                  v-for="tag in filteredTagOptions"
                  :key="tag.id"
                  :color="isItemTagSelected(tag.id) ? 'primary' : undefined"
                  :prepend-icon="isItemTagSelected(tag.id) ? 'mdi-check' : 'mdi-tag-outline'"
                  :variant="isItemTagSelected(tag.id) ? 'flat' : 'tonal'"
                  :disabled="itemSaving"
                  role="button"
                  @click="toggleItemTag(tag.id)"
                >
                  {{ tag.name }}
                </v-chip>
              </div>
              <v-alert v-else type="info" variant="tonal" density="compact">
                No tags match that filter.
              </v-alert>
            </div>
            <section v-if="showPublicationFields" class="publication-fields">
              <h3>Publication Details</h3>
              <div class="item-form-grid">
                <v-combobox
                  v-if="showPublisherField"
                  v-model="itemForm.publisher"
                  label="Publisher"
                  :items="publisherOptions"
                  prepend-inner-icon="mdi-domain"
                  variant="outlined"
                  clearable
                  hide-no-data
                  :disabled="itemSaving"
                />
                <v-text-field
                  v-if="showIssnField"
                  v-model="itemForm.issn"
                  label="ISSN"
                  prepend-inner-icon="mdi-barcode"
                  variant="outlined"
                  :disabled="itemSaving"
                  @blur="formatIsbnField('isbn_10')"
                />
                <v-text-field
                  v-if="showIsbnFields"
                  v-model="itemForm.isbn_10"
                  label="ISBN-10"
                  prepend-inner-icon="mdi-barcode"
                  variant="outlined"
                  :disabled="itemSaving"
                  @blur="formatIsbnField('isbn_13')"
                />
                <v-text-field
                  v-if="showIsbnFields"
                  v-model="itemForm.isbn_13"
                  label="ISBN-13"
                  prepend-inner-icon="mdi-barcode"
                  variant="outlined"
                  :disabled="itemSaving"
                />
                <v-text-field
                  v-if="showSeriesFields"
                  v-model="itemForm.series_title"
                  label="Series title"
                  prepend-inner-icon="mdi-bookshelf"
                  variant="outlined"
                  :disabled="itemSaving"
                />
                <v-text-field
                  v-if="showIssueFields"
                  v-model="itemForm.issue_number"
                  label="Issue number"
                  prepend-inner-icon="mdi-pound"
                  variant="outlined"
                  :disabled="itemSaving"
                />
                <v-text-field
                  v-if="showSeriesFields"
                  v-model="itemForm.volume_number"
                  label="Volume number"
                  prepend-inner-icon="mdi-counter"
                  variant="outlined"
                  :disabled="itemSaving"
                />
                <v-text-field
                  v-if="showIssueFields"
                  v-model="itemForm.issue_date"
                  label="Issue date"
                  type="date"
                  prepend-inner-icon="mdi-calendar-month-outline"
                  variant="outlined"
                  :disabled="itemSaving"
                />
                <v-text-field
                  v-model.number="itemForm.page_count"
                  label="Page count"
                  type="number"
                  min="1"
                  prepend-inner-icon="mdi-file-document-multiple-outline"
                  variant="outlined"
                  :disabled="itemSaving"
                />
                <v-text-field
                  v-model="itemForm.format"
                  label="Format"
                  prepend-inner-icon="mdi-book-open-page-variant-outline"
                  variant="outlined"
                  :disabled="itemSaving"
                />
              </div>
            </section>
            <section class="item-dialog-section">
              <div class="item-dialog-section-heading">
                <h3>Locations</h3>
                <v-btn
                  v-if="editingItemId"
                  prepend-icon="mdi-folder-marker-outline"
                  variant="outlined"
                  size="small"
                  :disabled="itemSaving"
                  @click="openLocationDialog({ id: editingItemId })"
                >
                  Add Location
                </v-btn>
              </div>
              <v-alert v-if="!editingItemId" type="info" variant="tonal" density="compact">
                Save the catalog item before adding personal locations.
              </v-alert>
              <div v-else-if="editingItemLocations.length" class="compact-location-list">
                <div v-for="location in editingItemLocations" :key="location.id" class="compact-location-row">
                  <span>
                    <strong>{{ location.location_label }}</strong>
                    <small>{{ [location.locationTypeName, location.path_or_detail].filter(Boolean).join(' - ') || 'No detail recorded.' }}</small>
                  </span>
                  <span class="location-actions">
                    <v-tooltip text="Edit location">
                      <template #activator="{ props }">
                        <v-btn
                          v-bind="props"
                          icon="mdi-pencil-outline"
                          size="small"
                          variant="text"
                          aria-label="Edit location"
                          @click="openLocationDialog({ id: editingItemId }, location)"
                        />
                      </template>
                    </v-tooltip>
                    <v-tooltip text="Delete location">
                      <template #activator="{ props }">
                        <v-btn
                          v-bind="props"
                          icon="mdi-delete-outline"
                          size="small"
                          variant="text"
                          aria-label="Delete location"
                          @click="deleteItemLocation(location)"
                        />
                      </template>
                    </v-tooltip>
                  </span>
                </div>
              </div>
              <v-alert v-else type="info" variant="tonal" density="compact">
                No personal locations recorded yet.
              </v-alert>
            </section>
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

    <v-dialog v-model="locationDialogOpen" max-width="680">
      <v-card class="item-dialog-card">
        <v-card-title>{{ editingLocationId ? 'Edit Location' : 'Add Location' }}</v-card-title>
        <v-card-text>
          <v-alert v-if="locationError" type="error" variant="tonal" class="panel-alert">
            {{ locationError }}
          </v-alert>

          <v-form class="location-dialog-form" @submit.prevent="saveItemLocation">
            <div class="inline-create-field">
              <v-select
                v-model="locationForm.location_root_id"
                label="Location root"
                :items="locationRootOptions"
                item-title="label"
                item-value="value"
                prepend-inner-icon="mdi-source-branch"
                variant="outlined"
                clearable
                hide-details
                :disabled="locationSaving || locationRootsLoading"
                @update:model-value="applyLocationRootToItemLocation"
              />
              <v-tooltip text="Add location root">
                <template #activator="{ props }">
                  <v-btn
                    v-bind="props"
                    icon="mdi-plus"
                    variant="tonal"
                    aria-label="Add location root"
                    :disabled="locationSaving"
                    @click="openLocationRootDialog"
                  />
                </template>
              </v-tooltip>
            </div>
            <div class="location-form-grid">
              <v-select
                v-model="locationForm.ownership_status"
                label="Ownership status"
                :items="ownershipStatusOptions"
                item-title="label"
                item-value="value"
                prepend-inner-icon="mdi-check-circle-outline"
                variant="outlined"
                :disabled="locationSaving"
              />
              <v-select
                v-model="locationForm.location_type_id"
                label="Location type"
                :items="locationTypeOptions"
                item-title="name"
                item-value="value"
                prepend-inner-icon="mdi-folder-marker-outline"
                variant="outlined"
                :disabled="locationSaving || locationTypesLoading"
              />
              <v-tooltip text="Add location type">
                <template #activator="{ props }">
                  <v-btn
                    v-bind="props"
                    icon="mdi-plus"
                    variant="tonal"
                    aria-label="Add location type"
                    :disabled="locationSaving"
                    @click="openLocationTypeDialog"
                  />
                </template>
              </v-tooltip>
            </div>
            <v-combobox
              v-model="locationForm.location_label"
              label="Location label"
              :items="priorLocationLabels"
              placeholder="Type a new label, for example NAS, Bookshelf, Main PC"
              prepend-inner-icon="mdi-label-outline"
              variant="outlined"
              clearable
              persistent-placeholder
              :disabled="locationSaving"
              required
            />
            <v-combobox
              v-model="locationForm.path_or_detail"
              label="Path or detail"
              :items="priorLocationPaths"
              placeholder="Type a path, shelf, box, folder, or other detail"
              prepend-inner-icon="mdi-file-tree-outline"
              variant="outlined"
              clearable
              persistent-placeholder
              :disabled="locationSaving"
            />
            <v-textarea
              v-model="locationForm.notes"
              label="Notes"
              prepend-inner-icon="mdi-note-text-outline"
              variant="outlined"
              rows="3"
              auto-grow
              :disabled="locationSaving"
            />
            <div class="dialog-actions">
              <v-btn variant="text" :disabled="locationSaving" @click="locationDialogOpen = false">Cancel</v-btn>
              <v-btn color="primary" prepend-icon="mdi-content-save-outline" type="submit" :loading="locationSaving">
                Save Location
              </v-btn>
            </div>
          </v-form>
        </v-card-text>
      </v-card>
    </v-dialog>

    <v-dialog v-model="locationRootDialogOpen" max-width="560">
      <v-card class="item-dialog-card">
        <v-card-title>{{ editingLocationRootId ? 'Edit Location Root' : 'Add Location Root' }}</v-card-title>
        <v-card-text>
          <v-alert v-if="locationRootError" type="error" variant="tonal" class="panel-alert">
            {{ locationRootError }}
          </v-alert>

          <v-form @submit.prevent="saveLocationRoot">
            <div class="item-form-grid">
              <v-select
                v-model="locationRootForm.location_type_id"
                label="Location type"
                :items="locationTypeOptions"
                item-title="name"
                item-value="value"
                prepend-inner-icon="mdi-folder-marker-outline"
                variant="outlined"
                :disabled="locationRootSaving || locationTypesLoading"
              />
              <v-text-field
                v-model="locationRootForm.label"
                label="Label"
                prepend-inner-icon="mdi-label-outline"
                variant="outlined"
                :disabled="locationRootSaving"
                required
              />
              <v-text-field
                v-model="locationRootForm.base_path"
                label="Base path"
                prepend-inner-icon="mdi-file-tree-outline"
                variant="outlined"
                :disabled="locationRootSaving"
              />
            </div>
            <v-textarea
              v-model="locationRootForm.notes"
              label="Notes"
              prepend-inner-icon="mdi-note-text-outline"
              variant="outlined"
              rows="3"
              auto-grow
              :disabled="locationRootSaving"
            />
            <div class="dialog-actions">
              <v-btn variant="text" :disabled="locationRootSaving" @click="locationRootDialogOpen = false">Cancel</v-btn>
              <v-btn color="primary" prepend-icon="mdi-content-save-outline" type="submit" :loading="locationRootSaving">
                Save Location Root
              </v-btn>
            </div>
          </v-form>
        </v-card-text>
      </v-card>
    </v-dialog>

    <v-dialog v-model="locationTypeDialogOpen" max-width="460">
      <v-card class="item-dialog-card">
        <v-card-title>Add Location Type</v-card-title>
        <v-card-text>
          <v-alert v-if="locationTypeError" type="error" variant="tonal" class="panel-alert">
            {{ locationTypeError }}
          </v-alert>

          <v-form @submit.prevent="saveLocationType">
            <v-text-field
              v-model="locationTypeForm.name"
              label="Name"
              prepend-inner-icon="mdi-folder-marker-outline"
              variant="outlined"
              :disabled="locationTypeSaving"
              required
            />
            <v-textarea
              v-model="locationTypeForm.description"
              label="Description"
              prepend-inner-icon="mdi-text-box-outline"
              variant="outlined"
              rows="3"
              auto-grow
              :disabled="locationTypeSaving"
            />
            <div class="dialog-actions">
              <v-btn variant="text" :disabled="locationTypeSaving" @click="locationTypeDialogOpen = false">Cancel</v-btn>
              <v-btn color="primary" prepend-icon="mdi-content-save-outline" type="submit" :loading="locationTypeSaving">
                Save Location Type
              </v-btn>
            </div>
          </v-form>
        </v-card-text>
      </v-card>
    </v-dialog>

    <v-dialog v-model="taxonomyDialogOpen" max-width="460">
      <v-card class="item-dialog-card">
        <v-card-title>Add {{ taxonomyDialogLabel }}</v-card-title>
        <v-card-text>
          <v-alert v-if="taxonomyError" type="error" variant="tonal" class="panel-alert">
            {{ taxonomyError }}
          </v-alert>

          <v-form @submit.prevent="saveTaxonomyTerm">
            <v-text-field
              v-model="taxonomyForm.name"
              :label="taxonomyDialogLabel"
              prepend-inner-icon="mdi-tag-plus-outline"
              variant="outlined"
              :disabled="taxonomySaving"
              required
            />
            <v-textarea
              v-model="taxonomyForm.description"
              label="Description"
              prepend-inner-icon="mdi-text-box-outline"
              variant="outlined"
              rows="3"
              auto-grow
              :disabled="taxonomySaving"
            />
            <div class="dialog-actions">
              <v-btn variant="text" :disabled="taxonomySaving" @click="taxonomyDialogOpen = false">Cancel</v-btn>
              <v-btn color="primary" prepend-icon="mdi-content-save-outline" type="submit" :loading="taxonomySaving">
                Save {{ taxonomyDialogLabel }}
              </v-btn>
            </div>
          </v-form>
        </v-card-text>
      </v-card>
    </v-dialog>

    <v-dialog v-model="noteDialogOpen" max-width="560">
      <v-card class="item-dialog-card">
        <v-card-title>{{ editingNoteId ? 'Edit Note' : 'Add Note' }}</v-card-title>
        <v-card-text>
          <v-alert v-if="noteError" type="error" variant="tonal" class="panel-alert">
            {{ noteError }}
          </v-alert>

          <v-form @submit.prevent="saveNote">
            <v-textarea
              v-model="noteForm.body"
              label="Note"
              prepend-inner-icon="mdi-note-text-outline"
              variant="outlined"
              rows="5"
              auto-grow
              :disabled="noteSaving"
              required
            />
            <div class="dialog-actions">
              <v-btn variant="text" :disabled="noteSaving" @click="noteDialogOpen = false">Cancel</v-btn>
              <v-btn color="primary" prepend-icon="mdi-content-save-outline" type="submit" :loading="noteSaving">
                Save Note
              </v-btn>
            </div>
          </v-form>
        </v-card-text>
      </v-card>
    </v-dialog>

    <v-dialog v-model="fileLocationDialogOpen" max-width="680">
      <v-card class="item-dialog-card">
        <v-card-title>{{ editingFileLocationId ? 'Edit File Location' : 'Add File Location' }}</v-card-title>
        <v-card-text>
          <v-alert v-if="fileLocationError" type="error" variant="tonal" class="panel-alert">
            {{ fileLocationError }}
          </v-alert>

          <v-form @submit.prevent="saveFileLocation">
            <div class="inline-create-field">
              <v-select
                v-model="fileLocationForm.location_root_id"
                label="Location root"
                :items="locationRootOptions"
                item-title="label"
                item-value="value"
                prepend-inner-icon="mdi-source-branch"
                variant="outlined"
                clearable
                hide-details
                :disabled="fileLocationSaving || locationRootsLoading"
                @update:model-value="applyLocationRootToFileLocation"
              />
              <v-tooltip text="Add location root">
                <template #activator="{ props }">
                  <v-btn
                    v-bind="props"
                    icon="mdi-plus"
                    variant="tonal"
                    aria-label="Add location root"
                    :disabled="fileLocationSaving"
                    @click="openLocationRootDialog"
                  />
                </template>
              </v-tooltip>
            </div>
            <div class="location-form-grid">
              <v-select
                v-model="fileLocationForm.location_type_id"
                label="Location type"
                :items="locationTypeOptions"
                item-title="name"
                item-value="value"
                prepend-inner-icon="mdi-folder-marker-outline"
                variant="outlined"
                :disabled="fileLocationSaving || locationTypesLoading"
              />
              <v-tooltip text="Add location type">
                <template #activator="{ props }">
                  <v-btn
                    v-bind="props"
                    icon="mdi-plus"
                    variant="tonal"
                    aria-label="Add location type"
                    :disabled="fileLocationSaving"
                    @click="openLocationTypeDialog"
                  />
                </template>
              </v-tooltip>
            </div>
            <v-text-field
              v-model="fileLocationForm.root_label"
              label="Root label"
              placeholder="Type a root, for example NAS, Archive Drive, OneDrive"
              prepend-inner-icon="mdi-harddisk"
              variant="outlined"
              clearable
              persistent-placeholder
              :disabled="fileLocationSaving"
              required
            />
            <v-text-field
              v-model="fileLocationForm.path_text"
              label="Path"
              placeholder="Type the file path or folder path"
              prepend-inner-icon="mdi-file-tree-outline"
              variant="outlined"
              clearable
              persistent-placeholder
              :disabled="fileLocationSaving"
              required
            />
            <v-textarea
              v-model="fileLocationForm.notes"
              label="Notes"
              prepend-inner-icon="mdi-note-text-outline"
              variant="outlined"
              rows="3"
              auto-grow
              :disabled="fileLocationSaving"
            />
            <div class="dialog-actions">
              <v-btn variant="text" :disabled="fileLocationSaving" @click="fileLocationDialogOpen = false">Cancel</v-btn>
              <v-btn color="primary" prepend-icon="mdi-content-save-outline" type="submit" :loading="fileLocationSaving">
                Save File Location
              </v-btn>
            </div>
          </v-form>
        </v-card-text>
      </v-card>
    </v-dialog>

    <v-dialog v-model="fileDialogOpen" max-width="560">
      <v-card class="item-dialog-card">
        <v-card-title>{{ editingFileId ? 'Edit File' : 'Add File' }}</v-card-title>
        <v-card-text>
          <v-alert v-if="fileError" type="error" variant="tonal" class="panel-alert">
            {{ fileError }}
          </v-alert>

          <v-form @submit.prevent="saveFile">
            <div class="item-form-grid">
              <v-text-field
                v-model="fileForm.filename"
                label="Filename"
                prepend-inner-icon="mdi-file-outline"
                variant="outlined"
                :disabled="fileSaving"
                required
              />
              <v-text-field
                v-model="fileForm.file_kind"
                label="File kind"
                prepend-inner-icon="mdi-file-cog-outline"
                variant="outlined"
                :disabled="fileSaving"
              />
              <v-text-field
                v-model.number="fileForm.expected_size_bytes"
                label="Expected size bytes"
                type="number"
                min="1"
                prepend-inner-icon="mdi-weight"
                variant="outlined"
                :disabled="fileSaving"
              />
              <v-text-field
                v-model="fileForm.checksum_sha256"
                label="SHA-256 checksum"
                prepend-inner-icon="mdi-fingerprint"
                variant="outlined"
                :disabled="fileSaving"
              />
            </div>
            <v-textarea
              v-model="fileForm.notes"
              label="Notes"
              prepend-inner-icon="mdi-note-text-outline"
              variant="outlined"
              rows="3"
              auto-grow
              :disabled="fileSaving"
            />
            <div class="dialog-actions">
              <v-btn variant="text" :disabled="fileSaving" @click="fileDialogOpen = false">Cancel</v-btn>
              <v-btn color="primary" prepend-icon="mdi-content-save-outline" type="submit" :loading="fileSaving">
                Save File
              </v-btn>
            </div>
          </v-form>
        </v-card-text>
      </v-card>
    </v-dialog>

    <v-dialog v-model="creatorDialogOpen" max-width="520">
      <v-card class="item-dialog-card">
        <v-card-title>{{ editingCreatorId ? 'Edit Creator' : 'Add Creator' }}</v-card-title>
        <v-card-text>
          <v-alert v-if="creatorError" type="error" variant="tonal" class="panel-alert">
            {{ creatorError }}
          </v-alert>

          <v-form @submit.prevent="saveCreator">
            <v-text-field
              v-model="creatorForm.name"
              label="Name"
              prepend-inner-icon="mdi-account-edit-outline"
              variant="outlined"
              :disabled="creatorSaving"
              required
            />
            <v-text-field
              v-model="creatorForm.website_url"
              label="Website URL"
              prepend-inner-icon="mdi-web"
              variant="outlined"
              :disabled="creatorSaving"
            />
            <v-select
              v-model="creatorForm.visibility"
              label="Visibility"
              :items="visibilityOptions"
              item-title="label"
              item-value="value"
              prepend-inner-icon="mdi-eye-outline"
              variant="outlined"
              :disabled="creatorSaving"
            />
            <v-textarea
              v-model="creatorForm.notes"
              label="Notes"
              prepend-inner-icon="mdi-note-text-outline"
              variant="outlined"
              rows="3"
              auto-grow
              :disabled="creatorSaving"
            />
            <div class="dialog-actions">
              <v-btn variant="text" :disabled="creatorSaving" @click="creatorDialogOpen = false">Cancel</v-btn>
              <v-btn color="primary" prepend-icon="mdi-content-save-outline" type="submit" :loading="creatorSaving">
                Save Creator
              </v-btn>
            </div>
          </v-form>
        </v-card-text>
      </v-card>
    </v-dialog>

    <v-dialog v-model="confirmDialogOpen" max-width="420">
      <v-card class="item-dialog-card">
        <v-card-title>{{ confirmDialog.title }}</v-card-title>
        <v-card-text>
          <p class="confirm-dialog-message">{{ confirmDialog.message }}</p>
          <div class="dialog-actions">
            <v-btn variant="text" :disabled="confirmDialog.loading" @click="closeConfirmDialog">Cancel</v-btn>
            <v-btn color="error" prepend-icon="mdi-delete-outline" :loading="confirmDialog.loading" @click="runConfirmAction">
              {{ confirmDialog.confirmLabel }}
            </v-btn>
          </div>
        </v-card-text>
      </v-card>
    </v-dialog>

    <v-dialog v-model="tagDialogOpen" max-width="460">
      <v-card class="item-dialog-card">
        <v-card-title>Add Tag</v-card-title>
        <v-card-text>
          <v-alert v-if="tagError" type="error" variant="tonal" class="panel-alert">
            {{ tagError }}
          </v-alert>

          <v-form @submit.prevent="saveTag">
            <v-text-field
              v-model="tagForm.name"
              label="Tag name"
              prepend-inner-icon="mdi-tag-plus-outline"
              variant="outlined"
              :disabled="tagSaving"
              required
            />
            <v-textarea
              v-model="tagForm.description"
              label="Description"
              prepend-inner-icon="mdi-text-box-outline"
              variant="outlined"
              rows="3"
              auto-grow
              :disabled="tagSaving"
            />
            <div class="dialog-actions">
              <v-btn variant="text" :disabled="tagSaving" @click="tagDialogOpen = false">Cancel</v-btn>
              <v-btn color="primary" prepend-icon="mdi-content-save-outline" type="submit" :loading="tagSaving">
                Save Tag
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
const catalogCreatorFilter = ref('any')
const catalogPeriodFilter = ref('any')
const catalogConflictFilter = ref('any')
const catalogTheatreFilter = ref('any')
const catalogFactionFilter = ref('any')
const catalogTagFilter = ref('any')
const catalogSortMode = ref('newest')
const selectedCatalogItemId = ref(null)
const authDialogOpen = ref(false)
const authLoading = ref(false)
const authMessage = ref('')
const authMessageType = ref('info')
const email = ref('')
const session = ref(null)
const catalogItems = ref([])
const userItemLocations = ref([])
const userFileLocations = ref([])
const notes = ref([])
const tags = ref([])
const creators = ref([])
const locationTypes = ref([])
const locationRoots = ref([])
const catalogLoading = ref(false)
const tagsLoading = ref(false)
const creatorsLoading = ref(false)
const locationTypesLoading = ref(false)
const locationRootsLoading = ref(false)
const catalogError = ref('')
const tagsError = ref('')
const creatorsError = ref('')
const taxonomyTerms = ref([])
const taxonomyLoading = ref(false)
const creatorDialogOpen = ref(false)
const creatorSaving = ref(false)
const creatorError = ref('')
const creatorForm = ref(createEmptyCreatorForm())
const editingCreatorId = ref(null)
const tagDialogOpen = ref(false)
const tagSaving = ref(false)
const tagError = ref('')
const tagForm = ref(createEmptyTagForm())
const tagPickerSearch = ref('')
const taxonomyDialogOpen = ref(false)
const taxonomySaving = ref(false)
const taxonomyError = ref('')
const taxonomyForm = ref(createEmptyTaxonomyForm())
const itemDialogOpen = ref(false)
const itemSaving = ref(false)
const itemError = ref('')
const itemForm = ref(createEmptyItemForm())
const editingItemId = ref(null)
const noteDialogOpen = ref(false)
const noteSaving = ref(false)
const noteError = ref('')
const noteForm = ref(createEmptyNoteForm())
const editingNoteId = ref(null)
const fileDialogOpen = ref(false)
const fileSaving = ref(false)
const fileError = ref('')
const fileForm = ref(createEmptyFileForm())
const editingFileId = ref(null)
const fileLocationDialogOpen = ref(false)
const fileLocationSaving = ref(false)
const fileLocationError = ref('')
const fileLocationForm = ref(createEmptyFileLocationForm())
const editingFileLocationId = ref(null)
const fileLocationFileId = ref(null)
const locationTypeDialogOpen = ref(false)
const locationTypeSaving = ref(false)
const locationTypeError = ref('')
const locationTypeForm = ref(createEmptyLocationTypeForm())
const locationRootDialogOpen = ref(false)
const locationRootSaving = ref(false)
const locationRootError = ref('')
const locationRootForm = ref(createEmptyLocationRootForm())
const editingLocationRootId = ref(null)
const locationDialogOpen = ref(false)
const locationSaving = ref(false)
const locationError = ref('')
const locationItemId = ref(null)
const locationForm = ref(createEmptyLocationForm())
const editingLocationId = ref(null)
const confirmDialogOpen = ref(false)
const confirmDialog = ref(createEmptyConfirmDialog())

const itemTypes = [
  { label: 'Package', value: 'package' },
  { label: 'Book', value: 'book' },
  { label: 'Book series', value: 'book_series' },
  { label: 'Magazine', value: 'magazine' },
  { label: 'Magazine series', value: 'magazine_series' },
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

const ownershipStatusOptions = [
  { label: 'Owned', value: 'owned' },
  { label: 'Wishlist', value: 'wishlist' },
  { label: 'Borrowed', value: 'borrowed' },
  { label: 'Lent out', value: 'lent_out' },
  { label: 'Sold', value: 'sold' },
  { label: 'Archived', value: 'archived' },
]

const periodOptions = computed(() => taxonomyTerms.value.filter((term) => term.term_type === 'historical_period'))
const conflictOptions = computed(() => taxonomyTerms.value.filter((term) => term.term_type === 'conflict'))
const theatreOptions = computed(() => taxonomyTerms.value.filter((term) => term.term_type === 'theatre'))
const factionOptions = computed(() => taxonomyTerms.value.filter((term) => term.term_type === 'faction'))
const tagOptions = computed(() => [...tags.value].sort(sortTags))
const filteredTagOptions = computed(() => {
  const search = tagPickerSearch.value.trim().toLowerCase()
  if (!search) return tagOptions.value

  return tagOptions.value.filter((tag) =>
    [tag.name, tag.description, tag.tag_type].some((value) => formString(value).toLowerCase().includes(search))
  )
})
const creatorOptions = computed(() => [...creators.value].sort(sortCreators))
const publisherOptions = computed(() => uniqueNonEmpty(catalogRows.value.map((item) => item.publisher)))
const locationTypeOptions = computed(() =>
  locationTypes.value.map((type) => ({
    name: type.name,
    value: type.id,
  }))
)
const locationRootOptions = computed(() =>
  [...locationRoots.value].sort(sortLocationRoots).map((root) => ({
    label: root.base_path ? `${root.label} - ${root.base_path}` : root.label,
    value: root.id,
  }))
)
const taxonomyDialogLabel = computed(() =>
  taxonomyForm.value.term_type === 'conflict' ? 'Conflict' : 'Period'
)
const showPublicationFields = computed(() =>
  ['book', 'book_series', 'magazine', 'magazine_series'].includes(itemForm.value.item_type)
)
const showIsbnFields = computed(() => ['book', 'book_series'].includes(itemForm.value.item_type))
const showIssnField = computed(() => ['magazine', 'magazine_series'].includes(itemForm.value.item_type))
const showPublisherField = computed(() =>
  ['book', 'book_series', 'magazine', 'magazine_series'].includes(itemForm.value.item_type)
)
const showSeriesFields = computed(() =>
  ['book', 'book_series', 'magazine', 'magazine_series'].includes(itemForm.value.item_type)
)
const showIssueFields = computed(() => itemForm.value.item_type === 'magazine')
const creatorFieldLabel = computed(() => {
  const labelsByType = {
    book: 'Author',
    book_series: 'Series author',
    magazine: 'Publisher',
    magazine_series: 'Publisher',
    stl_model: 'Creator',
    package: 'Creator',
    document: 'Author or source',
    map: 'Cartographer or source',
    photo: 'Photographer or source',
  }

  return labelsByType[itemForm.value.item_type] || 'Creator'
})

const hasCatalogSearchOrFilters = computed(() =>
  Boolean(catalogSearch.value.trim()) ||
  catalogTypeFilter.value !== 'any' ||
  catalogCreatorFilter.value !== 'any' ||
  catalogPeriodFilter.value !== 'any' ||
  catalogConflictFilter.value !== 'any' ||
  catalogTheatreFilter.value !== 'any' ||
  catalogFactionFilter.value !== 'any' ||
  catalogTagFilter.value !== 'any'
)
const dashboardCatalogTitle = computed(() =>
  hasCatalogSearchOrFilters.value ? 'Matching Catalog Items' : 'Recent Catalog Items'
)
const catalogResultSummary = computed(() => {
  const count = catalogRows.value.length
  return `${count} ${count === 1 ? 'result' : 'results'}`
})
const dashboardCatalogItems = computed(() =>
  catalogRows.value.slice(0, hasCatalogSearchOrFilters.value ? 20 : 8).map((item) => ({
    id: item.id,
    title: item.title,
    displayTitle: item.displayTitle,
    type: item.type,
    topic: item.topic,
    location: itemLocationSummary(item.id),
  }))
)

const catalogTypeFilterOptions = computed(() => [
  { label: 'Any', value: 'any' },
  ...itemTypes,
])
const catalogCreatorFilterOptions = computed(() => [
  { label: 'Any', value: 'any' },
  ...creatorOptions.value.map((creator) => ({ label: creator.name, value: creator.id })),
])
const catalogPeriodFilterOptions = computed(() => [
  { label: 'Any', value: 'any' },
  ...periodOptions.value.map((period) => ({ label: period.name, value: period.id })),
])
const catalogConflictFilterOptions = computed(() => [
  { label: 'Any', value: 'any' },
  ...conflictOptions.value.map((conflict) => ({ label: conflict.name, value: conflict.id })),
])
const catalogTheatreFilterOptions = computed(() => [
  { label: 'Any', value: 'any' },
  ...theatreOptions.value.map((theatre) => ({ label: theatre.name, value: theatre.id })),
])
const catalogFactionFilterOptions = computed(() => [
  { label: 'Any', value: 'any' },
  ...factionOptions.value.map((faction) => ({ label: faction.name, value: faction.id })),
])
const catalogTagFilterOptions = computed(() => [
  { label: 'Any', value: 'any' },
  ...tagOptions.value.map((tag) => ({ label: tag.name, value: tag.id })),
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
    .filter((item) => catalogCreatorFilter.value === 'any' || item.creator_id === catalogCreatorFilter.value)
    .filter((item) => catalogPeriodFilter.value === 'any' || item.historical_period_id === catalogPeriodFilter.value)
    .filter((item) => catalogConflictFilter.value === 'any' || item.conflict_id === catalogConflictFilter.value)
    .filter((item) => catalogTheatreFilter.value === 'any' || item.theatre_id === catalogTheatreFilter.value)
    .filter((item) => catalogFactionFilter.value === 'any' || item.faction_id === catalogFactionFilter.value)
    .filter((item) => catalogTagFilter.value === 'any' || item.tagIds.includes(catalogTagFilter.value))
    .filter((item) => {
      if (!search) return true
      return [item.title, item.subtitle, item.displayTitle, item.creatorName, item.type, item.topic, item.description, ...item.tags.map((tag) => tag.name)].some((value) =>
        value.toLowerCase().includes(search)
      )
    })
    .sort(sortCatalogRows)
})

const selectedCatalogItem = computed(() =>
  catalogRows.value.find((item) => item.id === selectedCatalogItemId.value) || null
)

const selectedChildItems = computed(() =>
  catalogRows.value.filter((item) => item.parent_item_id === selectedCatalogItemId.value)
)
const selectedItemLocations = computed(() =>
  userItemLocations.value.filter((location) => location.item_id === selectedCatalogItemId.value)
)
const editingItemLocations = computed(() =>
  editingItemId.value ? userItemLocations.value.filter((location) => location.item_id === editingItemId.value) : []
)
const selectedItemNotes = computed(() =>
  notes.value.filter((note) => note.entity_type === 'catalog_item' && note.entity_id === selectedCatalogItemId.value)
)
const priorLocationLabels = computed(() => uniqueNonEmpty(userItemLocations.value.map((location) => location.location_label)))
const priorLocationPaths = computed(() => uniqueNonEmpty(userItemLocations.value.map((location) => location.path_or_detail)))
const parentItemOptions = computed(() =>
  catalogRows.value
    .filter((item) => item.id !== editingItemId.value && !isDescendantItem(item.id, editingItemId.value))
    .map((item) => ({
      id: item.id,
      label: `${item.displayTitle} (${item.type})`,
    }))
)

const metrics = computed(() => [
  { label: 'Catalog items', value: String(catalogItems.value.length), icon: 'mdi-archive-outline' },
  { label: 'Known locations', value: String(userItemLocations.value.length), icon: 'mdi-folder-marker-outline' },
  { label: 'Creators', value: String(creators.value.length), icon: 'mdi-account-group-outline' },
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
      userFileLocations.value = []
      notes.value = []
      tags.value = []
      creators.value = []
      locationTypes.value = []
      locationRoots.value = []
    }
  })
})

async function loadDashboardData() {
  await Promise.all([loadCatalogItems(), loadTags(), loadCreators(), loadLocationTypes(), loadLocationRoots(), loadTaxonomyTerms(), loadUserItemLocations(), loadUserFileLocations(), loadNotes()])
}

async function loadCatalogItems() {
  catalogLoading.value = true
  catalogError.value = ''

  const { data, error } = await supabase
    .schema('catalog')
    .from('items')
    .select(`
      id,
      parent_item_id,
      creator_id,
      title,
      subtitle,
      description,
      item_type,
      historical_period_id,
      conflict_id,
      theatre_id,
      faction_id,
      visibility,
      created_at,
      creator:creator_id(id, name, website_url),
      historical_period:historical_period_id(name),
      conflict:conflict_id(name),
      theatre:theatre_id(name),
      faction:faction_id(name),
      item_tags(
        tag_id,
        tag:tags(id, name, tag_type)
      ),
      files(
        id,
        filename,
        extension,
        file_kind,
        expected_size_bytes,
        checksum_sha256,
        notes,
        created_at
      ),
      book_details(
        isbn_10,
        isbn_13,
        issn,
        series_title,
        volume_number,
        issue_number,
        issue_date,
        publisher,
        page_count,
        format
      )
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
    .select('id, name, tag_type, description')
    .order('name', { ascending: true })

  tagsLoading.value = false

  if (error) {
    tagsError.value = error.message
    return
  }

  tags.value = data || []
}

async function loadCreators() {
  creatorsLoading.value = true
  creatorsError.value = ''

  const { data, error } = await supabase
    .schema('catalog')
    .from('creators')
    .select('id, name, website_url, notes, visibility, created_by')
    .order('name', { ascending: true })

  creatorsLoading.value = false

  if (error) {
    creatorsError.value = error.message
    return
  }

  creators.value = data || []
}

async function loadLocationTypes() {
  locationTypesLoading.value = true

  const { data, error } = await supabase
    .schema('library')
    .from('location_types')
    .select('id, name, description, created_by')
    .order('name', { ascending: true })

  locationTypesLoading.value = false

  if (error) {
    catalogError.value = error.message
    return
  }

  locationTypes.value = data || []
}

async function loadLocationRoots() {
  locationRootsLoading.value = true

  const { data, error } = await supabase
    .schema('library')
    .from('location_roots')
    .select('id, location_type_id, label, base_path, notes')
    .order('label', { ascending: true })

  locationRootsLoading.value = false

  if (error) {
    catalogError.value = error.message
    return
  }

  locationRoots.value = data || []
}

async function loadTaxonomyTerms() {
  taxonomyLoading.value = true

  const { data, error } = await supabase
    .schema('catalog')
    .from('taxonomy_terms')
    .select('id, term_type, name')
    .in('term_type', ['historical_period', 'conflict', 'theatre', 'faction'])
    .order('term_type', { ascending: true })
    .order('name', { ascending: true })

  taxonomyLoading.value = false

  if (error) {
    itemError.value = error.message
    return
  }

  taxonomyTerms.value = data || []
}

async function loadUserItemLocations() {
  const { data, error } = await supabase
    .schema('library')
    .from('user_item_locations')
    .select(`
      id,
      location_type,
      location_type_id,
      location_label,
      path_or_detail,
      notes,
      location_type_detail:location_type_id(id, name),
      user_item:user_item_id(item_id, ownership_status)
    `)
    .order('created_at', { ascending: false })

  if (error) {
    catalogError.value = error.message
    return
  }

  userItemLocations.value = (data || []).map((location) => ({
    ...location,
    item_id: location.user_item?.item_id,
    ownership_status: location.user_item?.ownership_status || 'owned',
    locationTypeName: location.location_type_detail?.name || formatItemType(location.location_type),
  }))
}

async function loadUserFileLocations() {
  const { data, error } = await supabase
    .schema('library')
    .from('user_file_locations')
    .select('id, file_id, location_type, location_type_id, root_label, path_text, notes, verified_at, missing_at, location_type_detail:location_type_id(id, name)')
    .order('created_at', { ascending: false })

  if (error) {
    catalogError.value = error.message
    return
  }

  userFileLocations.value = (data || []).map((location) => ({
    ...location,
    locationTypeName: location.location_type_detail?.name || formatItemType(location.location_type),
  }))
}

async function loadNotes() {
  const { data, error } = await supabase
    .schema('library')
    .from('notes')
    .select('id, entity_type, entity_id, body, visibility, created_at, updated_at')
    .order('updated_at', { ascending: false })

  if (error) {
    catalogError.value = error.message
    return
  }

  notes.value = data || []
}

function openAddItemDialog() {
  editingItemId.value = null
  itemForm.value = createEmptyItemForm()
  itemError.value = ''
  itemDialogOpen.value = true
}

function openAddChildItemDialog(parentItem) {
  const childItemType = childItemTypeForParent(parentItem)
  const isMagazineIssue = parentItem.item_type === 'magazine_series'
  const isPublicationSeries = ['book_series', 'magazine_series'].includes(parentItem.item_type)

  editingItemId.value = null
  itemForm.value = {
    ...createEmptyItemForm(),
    title: isMagazineIssue ? parentItem.title : '',
    parent_item_id: parentItem.id,
    creator_id: parentItem.creator_id,
    historical_period_id: parentItem.historical_period_id,
    conflict_id: parentItem.conflict_id,
    item_type: childItemType,
    series_title: isPublicationSeries ? parentItem.title : '',
  }
  itemError.value = ''
  itemDialogOpen.value = true
}

function openEditItemDialog(item) {
  editingItemId.value = item.id
  itemForm.value = {
    title: item.title,
    parent_item_id: item.parent_item_id,
    creator_id: item.creator_id,
    item_type: item.item_type,
    description: item.description,
    historical_period_id: item.historical_period_id,
    conflict_id: item.conflict_id,
    visibility: item.visibility_value,
    tag_ids: item.tagIds,
    publisher: item.publisher,
    isbn_10: item.isbn_10,
    isbn_13: item.isbn_13,
    issn: item.issn,
    series_title: item.series_title,
    volume_number: item.volume_number,
    issue_number: item.issue_number,
    issue_date: item.issue_date,
    page_count: item.page_count,
    format: item.format,
  }
  itemError.value = ''
  itemDialogOpen.value = true
}

function openLocationDialog(item, location = null) {
  locationItemId.value = item.id
  editingLocationId.value = location?.id || null
  locationForm.value = location
    ? {
        ownership_status: location.ownership_status || 'owned',
        location_type_id: location.location_type_id || fallbackLocationTypeId(location.location_type),
        location_label: location.location_label,
        path_or_detail: location.path_or_detail || '',
        notes: location.notes || '',
      }
    : createEmptyLocationForm()
  locationError.value = ''
  locationDialogOpen.value = true
}

function openTaxonomyDialog(termType) {
  taxonomyForm.value = {
    ...createEmptyTaxonomyForm(),
    term_type: termType,
  }
  taxonomyError.value = ''
  taxonomyDialogOpen.value = true
}

function openNoteDialog(note = null) {
  if (!selectedCatalogItem.value) return

  editingNoteId.value = note?.id || null
  noteForm.value = note
    ? {
        body: note.body,
      }
    : createEmptyNoteForm()
  noteError.value = ''
  noteDialogOpen.value = true
}

function openConfirmDialog({ title, message, confirmLabel = 'Delete', onConfirm }) {
  confirmDialog.value = {
    title,
    message,
    confirmLabel,
    loading: false,
    onConfirm,
  }
  confirmDialogOpen.value = true
}

function closeConfirmDialog() {
  if (confirmDialog.value.loading) return
  confirmDialogOpen.value = false
  confirmDialog.value = createEmptyConfirmDialog()
}

async function runConfirmAction() {
  if (!confirmDialog.value.onConfirm) return

  confirmDialog.value.loading = true
  const confirmed = await confirmDialog.value.onConfirm()
  confirmDialog.value.loading = false

  if (confirmed === false) return

  confirmDialogOpen.value = false
  confirmDialog.value = createEmptyConfirmDialog()
}

function applyLocationRootToItemLocation(rootId) {
  const root = locationRoots.value.find((candidate) => candidate.id === rootId)
  if (!root) return

  locationForm.value.location_type_id = root.location_type_id || fallbackLocationTypeId('other')
  locationForm.value.location_label = root.label
  if (root.base_path) {
    locationForm.value.path_or_detail = root.base_path
  }
}

function applyLocationRootToFileLocation(rootId) {
  const root = locationRoots.value.find((candidate) => candidate.id === rootId)
  if (!root) return

  fileLocationForm.value.location_type_id = root.location_type_id || fallbackLocationTypeId('other')
  fileLocationForm.value.root_label = root.label
  if (root.base_path) {
    fileLocationForm.value.path_text = root.base_path
  }
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

function showCatalogResults() {
  activeSection.value = 'catalog'
}

function clearSelectedCatalogItem() {
  selectedCatalogItemId.value = null
}

function clearCatalogFilters() {
  catalogSearch.value = ''
  catalogTypeFilter.value = 'any'
  catalogCreatorFilter.value = 'any'
  catalogPeriodFilter.value = 'any'
  catalogConflictFilter.value = 'any'
  catalogTheatreFilter.value = 'any'
  catalogFactionFilter.value = 'any'
  catalogTagFilter.value = 'any'
}

async function saveCatalogItem() {
  if (!itemForm.value.title.trim()) {
    itemError.value = 'Title is required.'
    return
  }

  if (editingItemId.value && isDescendantItem(itemForm.value.parent_item_id, editingItemId.value)) {
    itemError.value = 'An item cannot be nested inside itself.'
    return
  }

  itemSaving.value = true
  itemError.value = ''

  const payload = {
    title: itemForm.value.title.trim(),
    parent_item_id: itemForm.value.parent_item_id || null,
    creator_id: itemForm.value.creator_id || null,
    item_type: itemForm.value.item_type,
    description: itemForm.value.description.trim() || null,
    historical_period_id: itemForm.value.historical_period_id || null,
    conflict_id: itemForm.value.conflict_id || null,
    visibility: itemForm.value.visibility,
    created_by: session.value.user.id,
  }

  const query = supabase.schema('catalog').from('items')
  const savedItem = { id: editingItemId.value }
  const { data: insertedItem, error } = editingItemId.value
    ? await query.update(payload).eq('id', editingItemId.value)
    : await query.insert(payload).select('id').single()

  if (error) {
    itemSaving.value = false
    itemError.value = error.message
    return
  }

  if (insertedItem?.id) {
    savedItem.id = insertedItem.id
  }

  if (showPublicationFields.value) {
    const { error: detailsError } = await savePublicationDetails(savedItem.id)

    if (detailsError) {
      itemSaving.value = false
      itemError.value = detailsError.message
      return
    }
  }

  const { error: tagsSaveError } = await saveItemTags(savedItem.id)

  if (tagsSaveError) {
    itemSaving.value = false
    itemError.value = tagsSaveError.message
    return
  }

  itemSaving.value = false
  itemDialogOpen.value = false
  authMessageType.value = 'success'
  authMessage.value = editingItemId.value ? 'Catalog item updated.' : 'Catalog item added.'
  await loadCatalogItems()
}

async function savePublicationDetails(itemId) {
  formatIsbnField('isbn_10')
  formatIsbnField('isbn_13')

  return supabase.schema('catalog').from('book_details').upsert({
    item_id: itemId,
    isbn_10: itemForm.value.isbn_10.trim() || null,
    isbn_13: itemForm.value.isbn_13.trim() || null,
    issn: itemForm.value.issn.trim() || null,
    series_title: itemForm.value.series_title.trim() || null,
    volume_number: itemForm.value.volume_number.trim() || null,
    issue_number: itemForm.value.issue_number.trim() || null,
    issue_date: itemForm.value.issue_date || null,
    publisher: formString(itemForm.value.publisher).trim() || null,
    page_count: itemForm.value.page_count || null,
    format: itemForm.value.format.trim() || null,
  })
}

async function saveItemTags(itemId) {
  const { error: deleteError } = await supabase
    .schema('catalog')
    .from('item_tags')
    .delete()
    .eq('item_id', itemId)

  if (deleteError) return { error: deleteError }

  const tagIds = [...new Set(itemForm.value.tag_ids)].filter(Boolean)
  if (!tagIds.length) return { error: null }

  return supabase.schema('catalog').from('item_tags').insert(
    tagIds.map((tagId) => ({
      item_id: itemId,
      tag_id: tagId,
      created_by: session.value.user.id,
    }))
  )
}

async function saveNote() {
  const body = noteForm.value.body.trim()

  if (!selectedCatalogItem.value) {
    noteError.value = 'Select an item before adding a note.'
    return
  }

  if (!body) {
    noteError.value = 'Note is required.'
    return
  }

  noteSaving.value = true
  noteError.value = ''

  const payload = {
    user_id: session.value.user.id,
    entity_type: 'catalog_item',
    entity_id: selectedCatalogItem.value.id,
    body,
    visibility: 'private',
  }

  const query = supabase.schema('library').from('notes')
  const { error } = editingNoteId.value
    ? await query.update(payload).eq('id', editingNoteId.value)
    : await query.insert(payload)

  noteSaving.value = false

  if (error) {
    noteError.value = error.message
    return
  }

  noteDialogOpen.value = false
  await loadNotes()
}

async function deleteNote(note) {
  openConfirmDialog({
    title: 'Delete Note',
    message: 'Delete this personal note?',
    onConfirm: async () => {
      noteError.value = ''

      const { error } = await supabase.schema('library').from('notes').delete().eq('id', note.id)

      if (error) {
        catalogError.value = error.message
        return false
      }

      await loadNotes()
      return true
    },
  })
}

function openTagDialog() {
  tagForm.value = createEmptyTagForm()
  tagError.value = ''
  tagDialogOpen.value = true
}

function openCreatorDialog(creator = null) {
  editingCreatorId.value = creator?.id || null
  creatorForm.value = creator
    ? {
        name: creator.name,
        website_url: creator.website_url || '',
        notes: creator.notes || '',
        visibility: creator.visibility,
      }
    : createEmptyCreatorForm()
  creatorError.value = ''
  creatorDialogOpen.value = true
}

function openFileDialog(file = null) {
  if (!selectedCatalogItem.value) return

  editingFileId.value = file?.id || null
  fileForm.value = file
    ? {
        filename: file.filename,
        file_kind: file.file_kind || '',
        expected_size_bytes: file.expected_size_bytes || null,
        checksum_sha256: file.checksum_sha256 || '',
        notes: file.notes || '',
      }
    : createEmptyFileForm()
  fileError.value = ''
  fileDialogOpen.value = true
}

async function saveFile() {
  const filename = fileForm.value.filename.trim()

  if (!selectedCatalogItem.value) {
    fileError.value = 'Select an item before adding a file.'
    return
  }

  if (!filename) {
    fileError.value = 'Filename is required.'
    return
  }

  fileSaving.value = true
  fileError.value = ''

  const payload = {
    item_id: selectedCatalogItem.value.id,
    filename,
    extension: extensionFromFilename(filename),
    file_kind: fileForm.value.file_kind.trim() || null,
    expected_size_bytes: fileForm.value.expected_size_bytes || null,
    checksum_sha256: fileForm.value.checksum_sha256.trim() || null,
    notes: fileForm.value.notes.trim() || null,
    created_by: session.value.user.id,
  }

  const query = supabase.schema('catalog').from('files')
  const { error } = editingFileId.value
    ? await query.update(payload).eq('id', editingFileId.value)
    : await query.insert(payload)

  fileSaving.value = false

  if (error) {
    fileError.value = error.message
    return
  }

  fileDialogOpen.value = false
  await loadCatalogItems()
}

async function deleteFile(file) {
  openConfirmDialog({
    title: 'Delete File',
    message: `Delete file metadata for "${file.filename}"?`,
    onConfirm: async () => {
      fileError.value = ''

      const { error } = await supabase.schema('catalog').from('files').delete().eq('id', file.id)

      if (error) {
        fileError.value = error.message
        return false
      }

      await loadCatalogItems()
      return true
    },
  })
}

function openFileLocationDialog(file, location = null) {
  fileLocationFileId.value = file.id
  editingFileLocationId.value = location?.id || null
  fileLocationForm.value = location
    ? {
        location_type_id: location.location_type_id || fallbackLocationTypeId(location.location_type),
        root_label: location.root_label,
        path_text: location.path_text,
        notes: location.notes || '',
      }
    : createEmptyFileLocationForm()
  fileLocationError.value = ''
  fileLocationDialogOpen.value = true
}

async function saveFileLocation() {
  const rootLabel = formString(fileLocationForm.value.root_label).trim()
  const pathText = formString(fileLocationForm.value.path_text).trim()

  if (!rootLabel) {
    fileLocationError.value = 'Root label is required.'
    return
  }

  if (!pathText) {
    fileLocationError.value = 'Path is required.'
    return
  }

  if (isDuplicateFileLocation()) {
    fileLocationError.value = 'This file already has that location.'
    return
  }

  fileLocationSaving.value = true
  fileLocationError.value = ''

  const payload = {
    user_id: session.value.user.id,
    file_id: fileLocationFileId.value,
    location_type: 'other',
    location_type_id: fileLocationForm.value.location_type_id || fallbackLocationTypeId('other'),
    root_label: rootLabel,
    path_text: pathText,
    notes: formString(fileLocationForm.value.notes).trim() || null,
  }

  const query = supabase.schema('library').from('user_file_locations')
  const { error } = editingFileLocationId.value
    ? await query.update(payload).eq('id', editingFileLocationId.value)
    : await query.insert(payload)

  fileLocationSaving.value = false

  if (error) {
    fileLocationError.value = error.message
    return
  }

  fileLocationDialogOpen.value = false
  await loadUserFileLocations()
}

async function deleteFileLocation(location) {
  openConfirmDialog({
    title: 'Delete File Location',
    message: 'Delete this file location?',
    onConfirm: async () => {
      fileLocationError.value = ''

      const { error } = await supabase.schema('library').from('user_file_locations').delete().eq('id', location.id)

      if (error) {
        fileLocationError.value = error.message
        return false
      }

      await loadUserFileLocations()
      return true
    },
  })
}

function openLocationTypeDialog() {
  locationTypeForm.value = createEmptyLocationTypeForm()
  locationTypeError.value = ''
  locationTypeDialogOpen.value = true
}

function openLocationRootDialog(root = null) {
  editingLocationRootId.value = root?.id || null
  locationRootForm.value = root
    ? {
        location_type_id: root.location_type_id || fallbackLocationTypeId('other'),
        label: root.label,
        base_path: root.base_path || '',
        notes: root.notes || '',
      }
    : createEmptyLocationRootForm()
  locationRootError.value = ''
  locationRootDialogOpen.value = true
}

async function saveLocationType() {
  const name = locationTypeForm.value.name.trim()

  if (!name) {
    locationTypeError.value = 'Location type name is required.'
    return
  }

  locationTypeSaving.value = true
  locationTypeError.value = ''

  const { data, error } = await supabase
    .schema('library')
    .from('location_types')
    .insert({
      name,
      description: locationTypeForm.value.description.trim() || null,
      created_by: session.value.user.id,
    })
    .select('id, name, description, created_by')
    .single()

  locationTypeSaving.value = false

  if (error) {
    locationTypeError.value = error.message
    return
  }

  locationTypes.value = [...locationTypes.value, data].sort(sortLocationTypes)

  if (fileLocationDialogOpen.value) {
    fileLocationForm.value.location_type_id = data.id
  } else {
    locationForm.value.location_type_id = data.id
  }

  locationTypeDialogOpen.value = false
}

async function saveLocationRoot() {
  const label = formString(locationRootForm.value.label).trim()

  if (!label) {
    locationRootError.value = 'Location root label is required.'
    return
  }

  locationRootSaving.value = true
  locationRootError.value = ''

  const payload = {
    user_id: session.value.user.id,
    location_type_id: locationRootForm.value.location_type_id || fallbackLocationTypeId('other'),
    label,
    base_path: formString(locationRootForm.value.base_path).trim() || null,
    notes: formString(locationRootForm.value.notes).trim() || null,
  }

  const query = supabase.schema('library').from('location_roots')
  const { data, error } = editingLocationRootId.value
    ? await query.update(payload).eq('id', editingLocationRootId.value).select('id, location_type_id, label, base_path, notes').single()
    : await query.insert(payload).select('id, location_type_id, label, base_path, notes').single()

  locationRootSaving.value = false

  if (error) {
    locationRootError.value = error.message
    return
  }

  locationRoots.value = editingLocationRootId.value
    ? locationRoots.value.map((root) => (root.id === data.id ? data : root)).sort(sortLocationRoots)
    : [...locationRoots.value, data].sort(sortLocationRoots)

  locationForm.value.location_root_id = data.id
  fileLocationForm.value.location_root_id = data.id
  applyLocationRootToItemLocation(data.id)
  applyLocationRootToFileLocation(data.id)
  locationRootDialogOpen.value = false
}

async function deleteLocationRoot(root) {
  openConfirmDialog({
    title: 'Delete Location Root',
    message: `Delete location root "${root.label}"? Existing locations will keep their saved text.`,
    onConfirm: async () => {
      locationRootError.value = ''

      const { error } = await supabase.schema('library').from('location_roots').delete().eq('id', root.id)

      if (error) {
        locationRootError.value = error.message
        return false
      }

      locationRoots.value = locationRoots.value.filter((candidate) => candidate.id !== root.id)
      return true
    },
  })
}

async function saveCreator() {
  const name = creatorForm.value.name.trim()

  if (!name) {
    creatorError.value = 'Creator name is required.'
    return
  }

  creatorSaving.value = true
  creatorError.value = ''

  const payload = {
    name,
    website_url: creatorForm.value.website_url.trim() || null,
    notes: creatorForm.value.notes.trim() || null,
    visibility: creatorForm.value.visibility,
    created_by: session.value.user.id,
  }

  const query = supabase.schema('catalog').from('creators')
  const { data, error } = editingCreatorId.value
    ? await query.update(payload).eq('id', editingCreatorId.value).select('id, name, website_url, notes, visibility, created_by').single()
    : await query.insert(payload).select('id, name, website_url, notes, visibility, created_by').single()

  creatorSaving.value = false

  if (error) {
    creatorError.value = error.message
    return
  }

  creators.value = editingCreatorId.value
    ? creators.value.map((creator) => (creator.id === data.id ? data : creator)).sort(sortCreators)
    : [...creators.value, data].sort(sortCreators)

  itemForm.value.creator_id = data.id
  creatorDialogOpen.value = false
}

async function deleteCreator(creator) {
  openConfirmDialog({
    title: 'Delete Creator',
    message: `Delete creator "${creator.name}"?`,
    onConfirm: async () => {
      creatorsError.value = ''

      const { error } = await supabase.schema('catalog').from('creators').delete().eq('id', creator.id)

      if (error) {
        creatorsError.value = error.message
        return false
      }

      creators.value = creators.value.filter((candidate) => candidate.id !== creator.id)
      if (itemForm.value.creator_id === creator.id) {
        itemForm.value.creator_id = null
      }
      await loadCatalogItems()
      return true
    },
  })
}

async function saveTag() {
  const name = tagForm.value.name.trim()

  if (!name) {
    tagError.value = 'Tag name is required.'
    return
  }

  const existingTag = tags.value.find((tag) => tag.name.toLowerCase() === name.toLowerCase())
  if (existingTag) {
    itemForm.value.tag_ids = [...new Set([...itemForm.value.tag_ids, existingTag.id])]
    tagDialogOpen.value = false
    return
  }

  tagSaving.value = true
  tagError.value = ''

  const { error } = await supabase
    .schema('catalog')
    .from('tags')
    .insert({
      name,
      description: tagForm.value.description.trim() || null,
      created_by: session.value.user.id,
    })

  if (error) {
    tagSaving.value = false
    tagError.value = error.message
    return
  }

  const { data, error: lookupError } = await supabase
    .schema('catalog')
    .from('tags')
    .select('id, name, tag_type, description')
    .eq('name', name)
    .maybeSingle()

  tagSaving.value = false

  if (lookupError) {
    tagError.value = lookupError.message
    return
  }

  const savedTag = data || { id: null, name, tag_type: null, description: tagForm.value.description.trim() || null }
  await loadTags()

  const selectedTag = savedTag.id
    ? savedTag
    : tags.value.find((tag) => tag.name.toLowerCase() === name.toLowerCase())

  if (selectedTag?.id) {
    itemForm.value.tag_ids = [...new Set([...itemForm.value.tag_ids, selectedTag.id])]
  }

  tagDialogOpen.value = false
}

async function saveTaxonomyTerm() {
  const name = taxonomyForm.value.name.trim()

  if (!name) {
    taxonomyError.value = `${taxonomyDialogLabel.value} is required.`
    return
  }

  taxonomySaving.value = true
  taxonomyError.value = ''

  const { data, error } = await supabase
    .schema('catalog')
    .from('taxonomy_terms')
    .insert({
      term_type: taxonomyForm.value.term_type,
      name,
      description: taxonomyForm.value.description.trim() || null,
    })
    .select('id, term_type, name, description')
    .single()

  taxonomySaving.value = false

  if (error) {
    taxonomyError.value = error.message
    return
  }

  taxonomyTerms.value = [...taxonomyTerms.value, data].sort(sortTaxonomyTerms)

  if (data.term_type === 'historical_period') {
    itemForm.value.historical_period_id = data.id
  } else if (data.term_type === 'conflict') {
    itemForm.value.conflict_id = data.id
  }

  taxonomyDialogOpen.value = false
}

async function saveItemLocation() {
  const locationLabel = formString(locationForm.value.location_label).trim()
  const pathOrDetail = formString(locationForm.value.path_or_detail).trim()
  const notes = formString(locationForm.value.notes).trim()

  if (!locationLabel) {
    locationError.value = 'Location label is required.'
    return
  }

  if (isDuplicateLocation()) {
    locationError.value = 'This item already has that location.'
    return
  }

  locationSaving.value = true
  locationError.value = ''

  const { data: userItem, error: userItemError } = await supabase
    .schema('library')
    .from('user_items')
    .upsert(
      {
        user_id: session.value.user.id,
        item_id: locationItemId.value,
        ownership_status: locationForm.value.ownership_status,
      },
      { onConflict: 'user_id,item_id' }
    )
    .select('id')
    .single()

  if (userItemError) {
    locationSaving.value = false
    locationError.value = userItemError.message
    return
  }

  const locationPayload = {
    user_item_id: userItem.id,
    location_type: 'other',
    location_type_id: locationForm.value.location_type_id || fallbackLocationTypeId('other'),
    location_label: locationLabel,
    path_or_detail: pathOrDetail || null,
    notes: notes || null,
  }

  const locationQuery = supabase.schema('library').from('user_item_locations')
  const { error: locationSaveError } = editingLocationId.value
    ? await locationQuery.update(locationPayload).eq('id', editingLocationId.value)
    : await locationQuery.insert(locationPayload)

  locationSaving.value = false

  if (locationSaveError) {
    locationError.value = locationSaveError.message
    return
  }

  locationDialogOpen.value = false
  authMessageType.value = 'success'
  authMessage.value = editingLocationId.value ? 'Location updated.' : 'Location added.'
  await loadUserItemLocations()
}

async function deleteItemLocation(location) {
  openConfirmDialog({
    title: 'Delete Location',
    message: 'Delete this item location?',
    onConfirm: async () => {
      locationError.value = ''

      const { error } = await supabase.schema('library').from('user_item_locations').delete().eq('id', location.id)

      if (error) {
        catalogError.value = error.message
        return false
      }

      authMessageType.value = 'success'
      authMessage.value = 'Location deleted.'
      await loadUserItemLocations()
      return true
    },
  })
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
  const parentItem = catalogItems.value.find((candidate) => candidate.id === item.parent_item_id)
  const publication = item.book_details?.[0] || {}
  const itemTags = (item.item_tags || []).flatMap(tagFromItemTag).filter(Boolean).sort(sortTags)

  return {
    id: item.id,
    parent_item_id: item.parent_item_id,
    creator_id: item.creator_id,
    creatorName: item.creator?.name || '',
    creatorWebsiteUrl: item.creator?.website_url || '',
    parentTitle: parentItem?.title || '',
    childCount: catalogItems.value.filter((candidate) => candidate.parent_item_id === item.id).length,
    title: item.title,
    subtitle: item.subtitle || '',
    displayTitle: formatCatalogDisplayTitle(item, publication),
    description: item.description || '',
    item_type: item.item_type,
    type: formatItemType(item.item_type),
    historical_period_id: item.historical_period_id,
    conflict_id: item.conflict_id,
    theatre_id: item.theatre_id,
    faction_id: item.faction_id,
    topic: item.conflict?.name || item.historical_period?.name || 'Unassigned',
    visibility_value: item.visibility,
    visibility: formatItemType(item.visibility),
    created: new Intl.DateTimeFormat(undefined, { dateStyle: 'medium' }).format(new Date(item.created_at)),
    created_at: item.created_at,
    publisher: publication.publisher || '',
    isbn_10: publication.isbn_10 || '',
    isbn_13: publication.isbn_13 || '',
    issn: publication.issn || '',
    series_title: publication.series_title || '',
    volume_number: publication.volume_number || '',
    issue_number: publication.issue_number || '',
    issue_date: publication.issue_date || '',
    page_count: publication.page_count || null,
    format: publication.format || '',
    tags: itemTags,
    tagIds: itemTags.map((tag) => tag.id),
    files: (item.files || []).sort(sortFiles),
    publicationDetails: publicationDetailRows(publication),
  }
}

function tagFromItemTag(itemTag) {
  if (itemTag.tag) return itemTag.tag
  if (Array.isArray(itemTag.tags)) return itemTag.tags
  return itemTag.tags || []
}

function publicationDetailRows(publication) {
  return [
    { label: 'Publisher', value: publication.publisher },
    { label: 'ISBN-10', value: publication.isbn_10 },
    { label: 'ISBN-13', value: publication.isbn_13 },
    { label: 'ISSN', value: publication.issn },
    { label: 'Series', value: publication.series_title },
    { label: 'Volume', value: publication.volume_number },
    { label: 'Issue', value: publication.issue_number },
    { label: 'Issue date', value: publication.issue_date ? formatDate(publication.issue_date) : '' },
    { label: 'Pages', value: publication.page_count },
    { label: 'Format', value: publication.format },
  ].filter((detail) => detail.value)
}

function formatCatalogDisplayTitle(item, publication) {
  if (item.item_type !== 'magazine') return item.title

  const issueParts = [
    publication.volume_number ? `Vol. ${publication.volume_number}` : '',
    publication.issue_number ? `Issue ${publication.issue_number}` : '',
    publication.issue_date ? formatDate(publication.issue_date) : '',
  ].filter(Boolean)

  if (!issueParts.length) return item.title
  return `${item.title} - ${issueParts.join(', ')}`
}

function formatDate(value) {
  return new Intl.DateTimeFormat(undefined, { dateStyle: 'medium' }).format(new Date(value))
}

function formatDateTime(value) {
  return new Intl.DateTimeFormat(undefined, { dateStyle: 'medium', timeStyle: 'short' }).format(new Date(value))
}

function childCountLabel(item) {
  if (!item.childCount) return ''
  return `${item.childCount} child ${item.childCount === 1 ? 'item' : 'items'}`
}

function tagListLabel(itemTags) {
  return itemTags.map((tag) => tag.name).join(', ')
}

function tableCellValue(value) {
  return value || '-'
}

function itemLocationSummary(itemId) {
  const itemLocations = userItemLocations.value
    .filter((location) => location.item_id === itemId)
    .sort(sortItemLocations)

  if (!itemLocations.length) return 'No location yet'

  const primaryLocation = itemLocations[0]
  return [primaryLocation.location_label, primaryLocation.path_or_detail].filter(Boolean).join(' - ')
}

function isItemTagSelected(tagId) {
  return itemForm.value.tag_ids.includes(tagId)
}

function toggleItemTag(tagId) {
  if (isItemTagSelected(tagId)) {
    itemForm.value.tag_ids = itemForm.value.tag_ids.filter((selectedTagId) => selectedTagId !== tagId)
    return
  }

  itemForm.value.tag_ids = [...itemForm.value.tag_ids, tagId]
}

function fileMetaLabel(file) {
  return [
    file.file_kind || file.extension?.toUpperCase(),
    file.expected_size_bytes ? formatBytes(file.expected_size_bytes) : '',
    file.checksum_sha256 ? 'SHA-256 saved' : '',
  ].filter(Boolean).join(' - ') || 'Metadata only'
}

function formatIsbnField(fieldName) {
  const rawValue = formString(itemForm.value[fieldName])
  const normalized = rawValue.replace(/[^0-9Xx]/g, '').toUpperCase()

  if (fieldName === 'isbn_10') {
    itemForm.value.isbn_10 = formatIsbn10(normalized)
  } else if (fieldName === 'isbn_13') {
    itemForm.value.isbn_13 = formatIsbn13(normalized)
  }
}

function formatIsbn10(value) {
  if (value.length !== 10) return value
  return [value.slice(0, 1), value.slice(1, 4), value.slice(4, 9), value.slice(9)].join('-')
}

function formatIsbn13(value) {
  if (value.length !== 13) return value
  return [value.slice(0, 3), value.slice(3, 4), value.slice(4, 7), value.slice(7, 12), value.slice(12)].join('-')
}

function fileLocationsForFile(fileId) {
  return userFileLocations.value
    .filter((location) => location.file_id === fileId)
    .sort(sortFileLocations)
}

function fileLocationLabel(location) {
  return [
    location.locationTypeName,
    location.root_label,
    location.path_text,
  ].filter(Boolean).join(' - ')
}

function locationTypeName(locationTypeId) {
  return locationTypes.value.find((type) => type.id === locationTypeId)?.name || 'No location type'
}

function formatBytes(value) {
  const bytes = Number(value)
  if (!Number.isFinite(bytes) || bytes <= 0) return ''

  const units = ['B', 'KB', 'MB', 'GB', 'TB']
  let size = bytes
  let unitIndex = 0

  while (size >= 1024 && unitIndex < units.length - 1) {
    size /= 1024
    unitIndex += 1
  }

  return `${size.toFixed(size >= 10 || unitIndex === 0 ? 0 : 1)} ${units[unitIndex]}`
}

function extensionFromFilename(filename) {
  const lastDotIndex = filename.lastIndexOf('.')
  if (lastDotIndex <= 0 || lastDotIndex === filename.length - 1) return null
  return filename.slice(lastDotIndex + 1).toLowerCase()
}

function childItemTypeForParent(parentItem) {
  if (parentItem.item_type === 'magazine_series') return 'magazine'
  if (parentItem.item_type === 'book_series') return 'book'
  return 'document'
}

function isDescendantItem(itemId, ancestorId) {
  if (!itemId || !ancestorId) return false

  let currentItem = catalogItems.value.find((item) => item.id === itemId)
  while (currentItem) {
    if (currentItem.id === ancestorId) return true
    currentItem = catalogItems.value.find((item) => item.id === currentItem.parent_item_id)
  }

  return false
}

function sortCatalogRows(first, second) {
  if (catalogSortMode.value === 'oldest') {
    return new Date(first.created_at) - new Date(second.created_at)
  }

  if (catalogSortMode.value === 'title') {
    return first.displayTitle.localeCompare(second.displayTitle)
  }

  if (catalogSortMode.value === 'type') {
    return first.type.localeCompare(second.type) || first.displayTitle.localeCompare(second.displayTitle)
  }

  if (catalogSortMode.value === 'topic') {
    return first.topic.localeCompare(second.topic) || first.displayTitle.localeCompare(second.displayTitle)
  }

  return new Date(second.created_at) - new Date(first.created_at)
}

function isDuplicateLocation() {
  const nextTypeId = locationForm.value.location_type_id || fallbackLocationTypeId('other')
  const nextLabel = normalizeLocationValue(formString(locationForm.value.location_label))
  const nextPath = normalizeLocationValue(formString(locationForm.value.path_or_detail))

  return userItemLocations.value.some(
    (location) =>
      location.id !== editingLocationId.value &&
      location.item_id === locationItemId.value &&
      (location.location_type_id || fallbackLocationTypeId(location.location_type)) === nextTypeId &&
      normalizeLocationValue(location.location_label) === nextLabel &&
      normalizeLocationValue(location.path_or_detail) === nextPath
  )
}

function isDuplicateFileLocation() {
  const nextTypeId = fileLocationForm.value.location_type_id || fallbackLocationTypeId('other')
  const nextRoot = normalizeLocationValue(formString(fileLocationForm.value.root_label))
  const nextPath = normalizeLocationValue(formString(fileLocationForm.value.path_text))

  return userFileLocations.value.some(
    (location) =>
      location.id !== editingFileLocationId.value &&
      location.file_id === fileLocationFileId.value &&
      (location.location_type_id || fallbackLocationTypeId(location.location_type)) === nextTypeId &&
      normalizeLocationValue(location.root_label) === nextRoot &&
      normalizeLocationValue(location.path_text) === nextPath
  )
}

function normalizeLocationValue(value) {
  return (value || '').trim().replaceAll('\\', '/').replace(/\/+$/, '').toLowerCase()
}

function formString(value) {
  return typeof value === 'string' ? value : ''
}

function uniqueNonEmpty(values) {
  return [...new Set(values.filter((value) => value && value.trim()).map((value) => value.trim()))].sort((first, second) =>
    first.localeCompare(second)
  )
}

function sortTaxonomyTerms(first, second) {
  return first.term_type.localeCompare(second.term_type) || first.name.localeCompare(second.name)
}

function sortTags(first, second) {
  return first.name.localeCompare(second.name)
}

function sortCreators(first, second) {
  return first.name.localeCompare(second.name)
}

function sortFiles(first, second) {
  return first.filename.localeCompare(second.filename)
}

function sortLocationTypes(first, second) {
  return first.name.localeCompare(second.name)
}

function sortLocationRoots(first, second) {
  return first.label.localeCompare(second.label)
}

function sortFileLocations(first, second) {
  return first.root_label.localeCompare(second.root_label) || first.path_text.localeCompare(second.path_text)
}

function sortItemLocations(first, second) {
  return first.location_label.localeCompare(second.location_label) || normalizeLocationValue(first.path_or_detail).localeCompare(normalizeLocationValue(second.path_or_detail))
}

function fallbackLocationTypeId(value) {
  const nameByLegacyValue = {
    local_drive: 'Local drive',
    external_drive: 'External drive',
    nas: 'NAS',
    cloud: 'Cloud',
    archive_zip: 'Archive ZIP',
    bookshelf: 'Bookshelf',
    box: 'Box',
    office: 'Office',
    storage: 'Storage',
    other: 'Other',
  }
  const name = nameByLegacyValue[value] || 'Other'
  return locationTypes.value.find((type) => type.name === name)?.id || null
}

function createEmptyItemForm() {
  return {
    title: '',
    parent_item_id: null,
    creator_id: null,
    item_type: 'document',
    description: '',
    historical_period_id: null,
    conflict_id: null,
    visibility: 'private',
    tag_ids: [],
    publisher: '',
    isbn_10: '',
    isbn_13: '',
    issn: '',
    series_title: '',
    volume_number: '',
    issue_number: '',
    issue_date: '',
    page_count: null,
    format: '',
  }
}

function createEmptyNoteForm() {
  return {
    body: '',
  }
}

function createEmptyFileForm() {
  return {
    filename: '',
    file_kind: '',
    expected_size_bytes: null,
    checksum_sha256: '',
    notes: '',
  }
}

function createEmptyFileLocationForm() {
  return {
    location_root_id: null,
    location_type_id: fallbackLocationTypeId('local_drive'),
    root_label: '',
    path_text: '',
    notes: '',
  }
}

function createEmptyCreatorForm() {
  return {
    name: '',
    website_url: '',
    notes: '',
    visibility: 'private',
  }
}

function createEmptyLocationTypeForm() {
  return {
    name: '',
    description: '',
  }
}

function createEmptyLocationRootForm() {
  return {
    location_type_id: fallbackLocationTypeId('local_drive'),
    label: '',
    base_path: '',
    notes: '',
  }
}

function createEmptyTagForm() {
  return {
    name: '',
    description: '',
  }
}

function createEmptyLocationForm() {
  return {
    location_root_id: null,
    ownership_status: 'owned',
    location_type_id: fallbackLocationTypeId('local_drive'),
    location_label: '',
    path_or_detail: '',
    notes: '',
  }
}

function createEmptyTaxonomyForm() {
  return {
    term_type: 'historical_period',
    name: '',
    description: '',
  }
}

function createEmptyConfirmDialog() {
  return {
    title: '',
    message: '',
    confirmLabel: 'Delete',
    loading: false,
    onConfirm: null,
  }
}
</script>




