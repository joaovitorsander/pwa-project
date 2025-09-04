import { api } from 'src/boot/axios'

export async function cadastrarCaminhao(dadosCaminhao) {
  try {
    const response = await api.post('/caminhoes', dadosCaminhao)
    if (response.status === 201) {
      return {
        success: true,
        message: 'Caminhão cadastrado com sucesso.',
        data: response.data,
      }
    }
  } catch (error) {
    if (error.response) {
      console.error('Erro do servidor:', error.response.status)
      console.error('Mensagem:', error.response.data.message)
      return {
        success: false,
        message: error.response.data.message || 'Erro ao cadastrar caminhão. Verifique os dados.',
      }
    } else if (error.request) {
      console.error('Sem resposta do servidor:', error.request)
      return {
        success: false,
        message: 'O servidor não respondeu. Tente novamente mais tarde.',
      }
    } else {
      console.error('Erro desconhecido:', error.message)
      return {
        success: false,
        message: 'Ocorreu um erro inesperado.',
      }
    }
  }
  return {
    success: false,
    message: 'Ocorreu um erro desconhecido ao processar a requisição.',
  }
}

export async function excluirCaminhao(id) {
  try {
    const response = await api.delete(`/caminhoes/${id}`)
    if (response.status === 200) {
      return {
        success: true,
        message: 'Caminhões obtidos com sucesso.',
        data: response.data.caminhoes || [],
      }
    }
  } catch (error) {
    if (error.response) {
      console.error('Erro do servidor:', error.response.status)
      console.error('Mensagem:', error.response.data.message)
      return {
        success: false,
        message: error.response.data.message || 'Não foi possível excluir o caminhão.',
      }
    } else if (error.request) {
      console.error('Sem resposta do servidor:', error.request)
      return {
        success: false,
        message: 'O servidor não respondeu. Tente novamente mais tarde.',
      }
    } else {
      console.error('Erro desconhecido:', error.message)
      return {
        success: false,
        message: 'Ocorreu um erro inesperado ao tentar excluir.',
      }
    }
  }
}

export async function atualizarCaminhao(id, dadosAtualizados) {
  try {
    const response = await api.patch(`/caminhoes/${id}`, dadosAtualizados);

    return {
      success: true,
      message: 'Caminhão atualizado com sucesso.',
      data: response.data,
    };
  } catch (error) {
    if (error.response) {
      console.error('Erro do servidor:', error.response.status);
      console.error('Mensagem:', error.response.data.message);
      return {
        success: false,
        message: error.response.data.message || 'Não foi possível atualizar o caminhão.',
      };
    } else if (error.request) {
      console.error('Sem resposta do servidor:', error.request);
      return {
        success: false,
        message: 'O servidor não respondeu. Tente novamente mais tarde.',
      };
    } else {
      console.error('Erro desconhecido:', error.message);
      return {
        success: false,
        message: 'Ocorreu um erro inesperado ao tentar atualizar.',
      };
    }
  }
}

export async function buscarCaminhoes(filtros = {}) {
  try {
    const response = await api.get('/caminhoes', { params: filtros });

    return {
      success: true,
      message: 'Caminhões encontrados com sucesso.',
      data: response.data.caminhoes || [],
    };
  } catch (error) {
    if (error.response) {
      console.error('Erro do servidor:', error.response.status);
      console.error('Mensagem:', error.response.data.message);
      return {
        success: false,
        message: error.response.data.message || 'Não foi possível buscar os caminhões.',
        data: [],
      };
    } else if (error.request) {
      console.error('Sem resposta do servidor:', error.request);
      return {
        success: false,
        message: 'O servidor não respondeu. Tente novamente mais tarde.',
        data: [],
      };
    } else {
      console.error('Erro desconhecido:', error.message);
      return {
        success: false,
        message: 'Ocorreu um erro inesperado ao buscar os caminhões.',
        data: [],
      };
    }
  }
}
