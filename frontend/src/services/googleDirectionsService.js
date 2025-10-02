import { Notify } from 'quasar';
import { api } from 'src/boot/axios';

//Como era a função antes quando usava a API Directions
/*export async function calcularRotaGoogle(
  origin,
  destination
) {
  return new Promise((resolve, reject) => {
    if (!origin || !destination) {
      Notify.create({ type: 'negative', message: 'Origem ou destino não informados.' });
      reject(new Error('Origem ou destino não informados.'));
      return;
    }

    if (!window.google || !window.google.maps) {
      Notify.create({ type: 'negative', message: 'API do Google Maps não está disponível.' });
      reject(new Error('API do Google Maps não está disponível.'));
      return;
    }

    const directionsService = new google.maps.DirectionsService();

    const request = {
      origin: origin,
      destination: destination,
      travelMode: google.maps.TravelMode.DRIVING,
    };

    directionsService.route(request, (result, status) => {
      if (status === 'OK' && result) {
        resolve(result);
      } else {
        const errorMessage = `Não foi possível encontrar a rota. Status: ${status}`;
        Notify.create({ type: 'negative', message: errorMessage });
        reject(new Error(errorMessage));
      }
    });
  });
}*/

export async function calcularRotaComPedagio(origem, destino, quantidade_eixos) {
  if (!origem || !destino) {
    const message = 'Origem e destino precisam ser informados.';
    Notify.create({ type: 'negative', message });
    return Promise.reject(new Error(message));
  }

  try {
    const response = await api.post('/routes/calcular', {
      origem: origem,
      destino: destino,
      quantidade_eixos:quantidade_eixos,
    });
    if (response.data && response.data.ok) {
      return response.data;
    } else {
      throw new Error(response.data.message || 'Resposta inválida do servidor.');
    }
  } catch (error) {
    const errorMessage = error.response?.data?.message || error.message || 'Falha ao calcular a rota.';
    Notify.create({ type: 'negative', message: errorMessage });
    return Promise.reject(new Error(errorMessage));
  }
}
