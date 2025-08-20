<template>
  <q-page class="q-pa-md">
    <q-form @submit="handleSubmit" class="q-gutter-md" greedy>
      <q-input v-model="form.placa" label="Placa" required />
      <q-input v-model="form.modelo" label="Modelo" required />
      <q-input v-model="form.ano" type="number" label="Ano" required />
      <q-input v-model="form.quantidade_eixos" type="number" label="Quantidade de eixos" required />
      <q-btn label="Cadastrar Caminhão" type="submit" color="primary" />
    </q-form>

    <div v-if="mensagem" class="q-mt-md">{{ mensagem }}</div>
  </q-page>
</template>

<script>
import api from 'src/services/api';

export default {
  data() {
    return {
      form: {
        placa: '',
        modelo: '',
        ano: '',
        quantidade_eixos: ''
      },
      mensagem: ''
    };
  },
  methods: {
    async handleSubmit() {
      try {
        const response = await api.post('/caminhoes', this.form);
        if (response.status === 201) {
          this.mensagem = 'Caminhão cadastrado com sucesso.';
          this.form = { placa: '', modelo: '', ano: '', quantidade_eixos: '' }
        }
      } catch (error) {
        if (error.response) {
          console.error('Erro do servidor:', error.response.status);
          console.error('Mensagem:', error.response.data.message);

          this.mensagem = error.response.data.message || 'Erro ao cadastrar caminhão.';
        } else if (error.request) {
          console.error('Sem resposta do servidor');
          this.mensagem = 'Servidor não respondeu.';
        } else {
          console.error('Erro desconhecido:', error.message);
          this.mensagem = 'Erro inesperado.';
        }
      }
    }
  }
};
</script>
