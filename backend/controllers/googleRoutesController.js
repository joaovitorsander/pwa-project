const axios = require('axios');

exports.calcularRotaComPedagio = async (req, res) => {
  const { origem, destino, quantidade_eixos } = req.body;
  const apiKey = process.env.GOOGLE_MAPS_API_KEY;

  if (!origem || !destino) {
    return res.status(400).json({ message: 'Origem e destino são obrigatórios.' });
  }

  const eixosParaCalculo = Number(quantidade_eixos) || 1;

  const url = 'https://routes.googleapis.com/directions/v2:computeRoutes';

  const requestBody = {
    origin: { address: origem },
    destination: { address: destino },
    travelMode: 'DRIVE',
    extraComputations: ['TOLLS'],
    routeModifiers: {
      vehicleInfo: {
        emissionType: 'DIESEL',
      },
    },
    languageCode: 'pt-BR',
  };

  try {
    const response = await axios.post(url, requestBody, {
      headers: {
        'Content-Type': 'application/json',
        'X-Goog-Api-Key': apiKey,
        'X-Goog-FieldMask': 'routes.duration,routes.distanceMeters,routes.polyline,routes.travelAdvisory.tollInfo',
      },
    });

    const rotaPrincipal = response.data.routes?.[0];

    if (!rotaPrincipal) {
      return res.status(404).json({ message: 'Nenhuma rota encontrada.' });
    }

    const tollInfo = rotaPrincipal.travelAdvisory?.tollInfo;
    const custoBasePedagio  = tollInfo?.estimatedPrice.reduce((acc, price) => {
        return acc + (parseFloat(price.units) || 0) + (price.nanos / 1_000_000_000 || 0);
    }, 0);

    const custoTotalEstimado = custoBasePedagio * eixosParaCalculo;

    res.status(200).json({
      ok: true,
      route: {
        distanceMeters: rotaPrincipal.distanceMeters,
        duration: rotaPrincipal.duration,
        polyline: rotaPrincipal.polyline,
        tollInfo: {
          cost: custoTotalEstimado,
          baseCost: custoBasePedagio,
          eixos: eixosParaCalculo,
          currency: tollInfo?.estimatedPrice[0]?.currencyCode || 'BRL'
        }
      },
      googleResponse: rotaPrincipal
    });

  } catch (error) {
    console.error('Erro ao chamar a Routes API do Google:', error.response?.data || error.message);
    res.status(500).json({
      ok: false,
      message: 'Não foi possível calcular a rota.',
      error: error.message,
    });
  }
};