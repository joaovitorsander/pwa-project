import { api } from 'src/boot/axios';

export async function buscarHistorico(filtros = {}) {
  try {
    const response = await api.get('/historico', { params: filtros });

    return {
      success: true,
      message: response.data.message,
      data: response.data.historico || [],
    };
  } catch (error) {
    console.error("Falha ao carregar histórico:", error);
    const errorMessage = error.response?.data?.message || 'Não foi possível carregar o histórico.';
    return { success: false, message: errorMessage, data: [] };
  }
}

export async function excluirCalculo(id) {
  try {
    const response = await api.delete(`/historico/${id}`);
    return {
      success: true,
      message: response.data.message,
    };
  } catch (error) {
    console.error(`Falha ao excluir cálculo ${id}:`, error);
    const errorMessage = error.response?.data?.message || 'Não foi possível excluir o cálculo.';
    return { success: false, message: errorMessage };
  }
}

export async function limparHistorico() {
  try {
    const response = await api.delete('/historico');
    return {
      success: true,
      message: response.data.message,
    };
  } catch (error) {
    console.error("Falha ao limpar histórico:", error);
    const errorMessage = error.response?.data?.message || 'Não foi possível limpar o histórico.';
    return { success: false, message: errorMessage };
  }
}
