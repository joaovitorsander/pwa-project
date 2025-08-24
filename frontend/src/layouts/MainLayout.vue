<template>
  <q-layout view="lHh Lpr lFf">
    <!-- Cabeçalho -->
    <q-header elevated>
      <q-toolbar class="bg-white text-black column items-center justify-center">
        <div class="text-h6 text-weight-bold text-green-7">FreteCalc</div>
        <div class="text-caption">Calculadora de Fretes para Caminhoneiros</div>
      </q-toolbar>

      <!-- Tabs de Navegação -->
      <q-tabs v-model="tab" align="justify" class="bg-grey-2" active-color="green-7" inactive-color="black"
        indicator-color="green-7">
        <q-route-tab name="calcular" label="Calcular" to="/" class="text-black"/>
        <q-route-tab name="caminhoes" label="Caminhões" to="/cadastrar-caminhao" class="text-black"/>
        <q-route-tab name="historico" label="Histórico" to="/historico" class="text-black"/>
      </q-tabs>
    </q-header>

    <!-- Área de páginas -->
    <q-page-container>
      <router-view />
    </q-page-container>
  </q-layout>
</template>

<script setup>
import { ref } from 'vue'

const tab = ref('calcular')
</script>
