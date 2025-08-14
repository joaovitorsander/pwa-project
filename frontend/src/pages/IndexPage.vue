<template>
  <q-page class="flex flex-center">
    <img
      alt="Quasar logo"
      src="~assets/quasar-logo-vertical.svg"
      style="width: 200px; height: 200px"
    />
    <div>
      <q-btn label = "Testar API" color="primary" @click="buscarMensagem"/>
      <div v-if="mensagem" style="margin-top: 20px">
        {{ mensagem }}
      </div>
    </div>
  </q-page>
</template>

<script>
import api from 'src/services/api';

export default {
  name: 'IndexPage',
  data() {
    return {
      mensagem: ''
    }
  },
  methods: {
    async buscarMensagem() {
      try {
        const response = await api.get('/');
        this.mensagem = response.data;
      } catch (error) {
        console.log('Erro ao buscar a API:', error)
      }
    }
  }
}
</script>
