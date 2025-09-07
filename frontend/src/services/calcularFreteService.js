import { api } from 'src/boot/axios'

export async function BuscarTiposCarga() {
  try {
    const response = await api.get('/tiposcarga')
    return {
      success: true,
      message: 'Tipos de carga obtidos com sucesso.',
      data: response.data.tiposCarga || [],
    }
  } catch (error) {
    if (error.response) {
      console.error('Erro do servidor:', error.response.status)
      console.error('Mensagem:', error.response.data.message)
      return {
        success: false,
        message: error.response.data.message || 'Não foi possível buscar os tipos de carga.',
        data: [],
      }
    } else if (error.request) {
      console.error('Sem resposta do servidor:', error.request)
      return {
        success: false,
        message: 'O servidor não respondeu. Tente novamente mais tarde.',
        data: [],
      }
    } else {
      console.error('Erro desconhecido:', error.message)
      return {
        success: false,
        message: 'Ocorreu um erro inesperado ao buscar os tipos de carga.',
        data: [],
      }
    }
  }
}

export async function simularCalculoFrete(dadosDoFormulario) {
  try {
    const response = await api.post('/fretes/calcular', dadosDoFormulario)
    return {
      success: true,
      message: response.data.message || 'Cálculo simulado com sucesso.',
      data: response.data.resultados,
    }
  } catch (error) {
    if (error.response) {
      console.error('Erro do servidor:', error.response.status, error.response.data)
      return {
        success: false,
        message: error.response.data.message || 'Não foi possível simular o cálculo.',
        data: null,
      }
    } else if (error.request) {
      console.error('Sem resposta do servidor:', error.request)
      return {
        success: false,
        message: 'O servidor não respondeu. Tente novamente mais tarde.',
        data: null,
      }
    } else {
      console.error('Erro desconhecido:', error.message)
      return {
        success: false,
        message: 'Ocorreu um erro inesperado ao simular o cálculo.',
        data: null,
      }
    }
  }
}

export async function salvarFreteCalculado(calculoCompleto) {
  try {
    const response = await api.post('/fretes', calculoCompleto)
    return {
      success: true,
      message: response.data.message || 'Cálculo de frete salvo com sucesso.',
      data: response.data.calculo,
    }
  } catch (error) {
    if (error.response) {
      console.error('Erro do servidor:', error.response.status, error.response.data)
      return {
        success: false,
        message: error.response.data.message || 'Não foi possível salvar o cálculo.',
        data: null,
      }
    } else if (error.request) {
      console.error('Sem resposta do servidor:', error.request)
      return {
        success: false,
        message: 'O servidor não respondeu. Tente novamente mais tarde.',
        data: null,
      }
    } else {
      console.error('Erro desconhecido:', error.message)
      return {
        success: false,
        message: 'Ocorreu um erro inesperado ao salvar o cálculo.',
        data: null,
      }
    }
  }
}
