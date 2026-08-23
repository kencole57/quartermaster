<template>
  <v-app>
    <v-layout>
      <v-navigation-drawer permanent width="280">
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
      </v-navigation-drawer>

      <v-main>
        <v-container fluid class="app-shell">
          <section class="topbar">
            <div>
              <h1>Quartermaster</h1>
              <p>Track what you have, what it describes, and where your copy lives.</p>
            </div>
            <v-btn color="primary" prepend-icon="mdi-plus">Add Item</v-btn>
          </section>

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
            <v-card variant="flat" class="panel-card">
              <div class="panel-heading">
                <h2>Recent Catalog Items</h2>
                <v-btn icon="mdi-arrow-right" variant="text" aria-label="Open catalog" />
              </div>
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
            </v-card>

            <v-card variant="flat" class="panel-card">
              <div class="panel-heading">
                <h2>Tags To Prove Out</h2>
                <v-btn icon="mdi-tune" variant="text" aria-label="Manage tags" />
              </div>
              <div class="tag-cloud">
                <v-chip v-for="tag in tags" :key="tag" variant="tonal" color="primary">{{ tag }}</v-chip>
              </div>
            </v-card>
          </section>
        </v-container>
      </v-main>
    </v-layout>
  </v-app>
</template>

<script setup>
const metrics = [
  { label: 'Catalog items', value: '0', icon: 'mdi-archive-outline' },
  { label: 'Known locations', value: '0', icon: 'mdi-folder-marker-outline' },
  { label: 'Creators', value: '0', icon: 'mdi-account-group-outline' },
  { label: 'Tags', value: '0', icon: 'mdi-tag-outline' },
]

const recentItems = [
  { title: 'Battle of Nui Le report', type: 'Document', topic: 'Vietnam War', location: 'To add' },
  { title: 'Cold War Germans', type: 'Package', topic: 'Cold War', location: 'To add' },
  { title: 'Panzer IV Ausf. H', type: 'STL model', topic: 'Second World War', location: 'To add' },
]

const tags = ['Vietnam War', 'Battle reports', 'Cold War', 'STL', 'Books', 'Maps', 'Kickstarter', 'Australian Army']
</script>
