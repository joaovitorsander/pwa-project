<template>
  <div ref="mapaContainer" style="width: 100%; height: 100%"></div>
</template>

<script setup>
import { onMounted, ref } from 'vue'

const mapaContainer = ref(null)
let map = null
let rotaPolyline = null

defineExpose({
  desenharRotaPorPolyline: (encodedPolyline) => {
    if (rotaPolyline) {
      rotaPolyline.setMap(null)
    }

    const path = google.maps.geometry.encoding.decodePath(encodedPolyline)

    rotaPolyline = new google.maps.Polyline({
      path: path,
      geodesic: true,
      strokeColor: '#006400',
      strokeOpacity: 0.9,
      strokeWeight: 5,
    })

    rotaPolyline.setMap(map)

    const bounds = new google.maps.LatLngBounds()
    path.forEach((point) => bounds.extend(point))
    map.fitBounds(bounds)
  },

  clearDirections: () => {
    if (rotaPolyline) {
      rotaPolyline.setMap(null)
      rotaPolyline = null
    }
    map.setCenter({ lat: -14.235, lng: -51.925 })
    map.setZoom(4)
  },
})

onMounted(() => {
  const inicializarMapa = () => {
    if (window.google && window.google.maps) {
      map = new google.maps.Map(mapaContainer.value, {
        zoom: 4,
        center: { lat: -14.235, lng: -51.925 },
        mapTypeControl: false,
        streetViewControl: false,
      })
    } else {
      setTimeout(inicializarMapa, 100)
    }
  }
  inicializarMapa()
})
</script>
