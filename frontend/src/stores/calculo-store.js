import { defineStore } from 'pinia';
import { ref } from 'vue';

export const useCalculoStore = defineStore('calculo', () => {
  const calculoParaCarregar = ref(null);

  function setCalculoParaCarregar(calculo) {
    calculoParaCarregar.value = calculo;
  }

  function limparCalculoParaCarregar() {
    calculoParaCarregar.value = null;
  }

  return {
    calculoParaCarregar,
    setCalculoParaCarregar,
    limparCalculoParaCarregar
  };
});
