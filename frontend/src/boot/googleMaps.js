import { boot } from 'quasar/wrappers'

let googleApiPromise = null

export default boot(() => {
  if (googleApiPromise) {
    return googleApiPromise
  }

  googleApiPromise = new Promise((resolve, reject) => {
    const apiKey = import.meta.env.VITE_GOOGLE_MAPS_API_KEY
    if (!apiKey) {
      console.error('Variável de ambiente VITE_GOOGLE_MAPS_API_KEY não definida!')
      reject(new Error('Chave da API do Google Maps não definida.'))
      return
    }

    const script = document.createElement('script')

    script.src = `https://maps.googleapis.com/maps/api/js?key=${apiKey}&loading=async&libraries=places`
    script.async = true
    script.defer = true

    script.onload = () => {
      console.log('Google Maps API (com Places) carregada com sucesso.')
      resolve()
    }

    script.onerror = (error) => {
      console.error('Erro ao carregar o script do Google Maps:', error)
      reject(error)
    }

    if (!document.querySelector(`script[src*="maps.googleapis.com"]`)) {
      document.head.appendChild(script)
    } else {
      resolve()
    }
  })

  return googleApiPromise
})
