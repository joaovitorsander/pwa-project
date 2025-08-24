<template>
  <GMapMap :center="center" :zoom="12" map-type-id="roadmap" style="width: 100%; height: 400px">
    <GMapMarker :position="center" />
  </GMapMap>
</template>

<script>
export default {
  name: 'MapaComponent',
  data() {
    return {
      center: {
        lat: -23.55052,
        lng: -46.633308
      }
    };
  }
};
</script>
