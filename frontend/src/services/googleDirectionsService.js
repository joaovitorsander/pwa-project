import { Notify } from 'quasar';

export async function calcularRotaGoogle(
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
}
