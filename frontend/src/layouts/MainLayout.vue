<template>
  <q-layout view="lHh Lpr lFf">
    <q-header elevated>
      <q-toolbar :class="$q.dark.isActive ? 'bg-grey-10' : 'bg-white text-black'">

        <q-space />

        <div class="column items-center">
          <div class="text-h6 text-weight-bold text-green-7">FreteCalc</div>
          <div class="text-caption">Calculadora de Fretes para Caminhoneiros</div>
        </div>

        <q-space />

        <q-toggle v-model="isDarkMode" checked-icon="dark_mode" unchecked-icon="light_mode" size="lg" color="grey-9">
          <q-tooltip>{{ isDarkMode ? 'Mudar para tema claro' : 'Mudar para tema escuro' }}</q-tooltip>
        </q-toggle>

      </q-toolbar>

      <q-tabs v-model="tab" align="justify" :class="$q.dark.isActive ? 'bg-grey-9' : 'bg-grey-2'" active-color="green-7" inactive-color="black"
        indicator-color="green-7">
        <q-route-tab name="calcular" label="Calcular" to="/" :class="$q.dark.isActive ? 'text-white' : 'text-black'"/>
        <q-route-tab name="caminhoes" label="Caminhões" to="/cadastrar-caminhao" :class="$q.dark.isActive ? 'text-white' : 'text-black'"/>
        <q-route-tab name="historico" label="Histórico" to="/historico" :class="$q.dark.isActive ? 'text-white' : 'text-black'"/>
      </q-tabs>
    </q-header>

    <q-page-container>
      <router-view />
    </q-page-container>
  </q-layout>
</template>

<script setup>
import { ref, onMounted, computed } from 'vue'
import { useQuasar } from 'quasar'

const tab = ref('calcular')
const $q = useQuasar()

const isDarkMode = computed({
  get: () => $q.dark.isActive,

  set: (val) => {
    $q.dark.set(val)
    localStorage.setItem('darkMode', val)
  }
})

onMounted(() => {
  const darkModeIsActive = JSON.parse(localStorage.getItem('darkMode'))
  $q.dark.set(darkModeIsActive)
})

</script>
