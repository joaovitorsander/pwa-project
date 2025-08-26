<template>
  <div ref="mapaComponent" style="width: 100%; height: 100%"></div>
</template>

<script setup>
import { onMounted, ref } from 'vue'

let directionsRenderer

const mapaComponent = ref(null)

// Agora o 'defineExpose' funcionará corretamente
defineExpose({
  setDirections: (directions) => {
    if (directionsRenderer) {
      directionsRenderer.setDirections(directions)
    }
  },
  clearDirections: () => {
    if (directionsRenderer) {
      directionsRenderer.set('directions', null)
    }
  },
})

onMounted(() => {
  const inicializarMapa = () => {
    if (window.google && window.google.maps) {
      const map = new google.maps.Map(mapaComponent.value, {
        zoom: 4,
        center: { lat: -14.235, lng: -51.925 },
      })
      directionsRenderer = new google.maps.DirectionsRenderer()
      directionsRenderer.setMap(map)
    } else {
      setTimeout(inicializarMapa, 500)
    }
  }
  inicializarMapa()
})
</script>
