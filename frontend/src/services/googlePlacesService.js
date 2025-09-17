import { api } from 'src/boot/axios'

function debounce(func, delay = 400) {
  let timeoutId
  return (...args) => {
    clearTimeout(timeoutId)
    timeoutId = setTimeout(() => {
      func.apply(this, args)
    }, delay)
  }
}

const _buscarCidades = async (termoDeBusca, callback) => {
  if (!termoDeBusca || termoDeBusca.length < 3) {
    callback([]);
    return;
  }

  try {

    const response = await api.get('/places/autocomplete', {
      params: {
        input: termoDeBusca,
      },
    });

    const predictions = response.data.predictions || [];
    const resultados = predictions.map((p) => p.description);
    callback(resultados);

  } catch (error) {
    console.error('ERRO! A chamada para o backend falhou:', error);
    callback([]);
  }
};

export const buscarCidadesDebounced = debounce(_buscarCidades)
