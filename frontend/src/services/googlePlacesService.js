import { Notify } from 'quasar'

function debounce(func, delay = 400) {
  let timeoutId
  return (...args) => {
    clearTimeout(timeoutId)
    timeoutId = setTimeout(() => {
      func.apply(this, args)
    }, delay)
  }
}

const _buscarCidades = (termoDeBusca, callback) => {
  if (!window.google || !window.google.maps || !window.google.maps.places) {
    Notify.create({ type: 'negative', message: 'API de locais do Google Maps não está disponível.' })
    callback([])
    return
  }

  if (!termoDeBusca || termoDeBusca.length < 3) {
    callback([])
    return
  }

  const autocompleteService = new window.google.maps.places.AutocompleteService()

  const requestOptions = {
    input: termoDeBusca,
    types: ['(cities)'],
    componentRestrictions: { country: 'BR' },
  }

  autocompleteService.getPlacePredictions(requestOptions, (predictions, status) => {
    if (status === window.google.maps.places.PlacesServiceStatus.OK && predictions) {
      const resultados = predictions.map((p) => p.description)
      callback(resultados)
    } else if (status !== 'ZERO_RESULTS') {
      console.error('Erro ao buscar previsões de local:', status)
      callback([])
    } else {
      callback([])
    }
  })
}

export const buscarCidadesDebounced = debounce(_buscarCidades);
