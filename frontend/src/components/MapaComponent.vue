<template>
  <div ref="mapaContainer" style="width: 100%; height: 100%"></div>
</template>

<script setup>
import { onMounted, ref } from 'vue'

const mapaContainer = ref(null)
let map = null
let rotaPolyline = null
let originMarker = null
let destinationMarker = null

defineExpose({
  desenharRotaPorPolyline: async (encodedPolyline) => {
    const { AdvancedMarkerElement } = await google.maps.importLibrary('marker')

    clearAll()

    const path = google.maps.geometry.encoding.decodePath(encodedPolyline)
    if (path.length === 0) return

    rotaPolyline = new google.maps.Polyline({
      path: path,
      geodesic: true,
      strokeColor: '#4285F4',
      strokeOpacity: 0.8,
      strokeWeight: 6,
    })
    rotaPolyline.setMap(map)

    const originPoint = path[0]
    const destinationPoint = path[path.length - 1]

    const originIconDiv = document.createElement('div')
    originIconDiv.style.width = '18px'
    originIconDiv.style.height = '18px'
    originIconDiv.style.backgroundColor = '#4285F4'
    originIconDiv.style.borderRadius = '50%'
    originIconDiv.style.border = '2px solid white'
    originIconDiv.style.boxShadow = '0 2px 4px rgba(0,0,0,0.4)'

    originMarker = new AdvancedMarkerElement({
      position: originPoint,
      map: map,
      content: originIconDiv,
      title: 'Origem',
    })

    destinationMarker = new AdvancedMarkerElement({
      position: destinationPoint,
      map: map,
      title: 'Destino',
    })

    const bounds = new google.maps.LatLngBounds()
    path.forEach((point) => bounds.extend(point))
    map.fitBounds(bounds)
  },

  clearDirections: () => {
    clearAll()
    if (map) {
      map.setCenter({ lat: -14.235, lng: -51.925 })
      map.setZoom(4)
    }
  },
})

function clearAll() {
  if (rotaPolyline) {
    rotaPolyline.setMap(null)
    rotaPolyline = null
  }
  if (originMarker) {
    originMarker.map = null
    originMarker = null
  }
  if (destinationMarker) {
    destinationMarker.map = null
    destinationMarker = null
  }
}

onMounted(() => {
  const inicializarMapa = () => {
    if (window.google && window.google.maps) {
      if (mapaContainer.value) {
        map = new google.maps.Map(mapaContainer.value, {
          zoom: 4,
          center: { lat: -14.235, lng: -51.925 },
          mapTypeControl: false,
          streetViewControl: false,
          mapId: '595d1e0028ca685151e79bec',
        })
      }
    } else {
      setTimeout(inicializarMapa, 100)
    }
  }
  inicializarMapa()
})
</script>
