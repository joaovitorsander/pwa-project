<template>
  <q-page class="q-pa-md">
    <q-form @submit="handleSubmit" class="q-gutter-md" greedy>
      <q-input v-model="form.placa" label="Placa" required />
      <q-input v-model="form.modelo" label="Modelo" required />
      <q-input v-model="form.ano" type="number" label="Ano" required />
      <q-input v-model="form.quantidade_eixos" type="number" label="Quantidade de eixos" required/>
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
        quantidade_eixos: 0
      },
      mensagem: ''
    };
  },
  methods: {
    async handleSubmit() {
      try {
        const response = await api.post('/caminhoes', this.form);
        this.mensagem = 'Caminhão cadastrado com sucesso.';
        this.form = { placa: '', modelo: '', ano: '', quantidade_eixos: 0 }
      } catch (error) {
        this.mensagem = 'Erro ao cadastrar caminhão.';
        console.log(error);
      }
    }
  }
};
</script>
