import api from 'src/boot/axios'

export async function BuscarTiposCarga() {
  try {
    const response = await api.get('/tiposcarga')
    return response.data.tiposCarga
  } catch (error) {
    console.error('Erro ao buscar tipos de carga:', error)
    return []
  }
}
