import { api } from 'src/boot/axios'

export async function BuscarTiposCarga() {
  try {
    const response = await api.get('/tiposcarga');
    return {
      success: true,
      message: 'Tipos de carga obtidos com sucesso.',
      data: response.data.tiposCarga || [],
    };
  } catch (error) {
    if (error.response) {
      console.error('Erro do servidor:', error.response.status);
      console.error('Mensagem:', error.response.data.message);
      return {
        success: false,
        message: error.response.data.message || 'Não foi possível buscar os tipos de carga.',
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
        message: 'Ocorreu um erro inesperado ao buscar os tipos de carga.',
        data: [],
      };
    }
  }
}
