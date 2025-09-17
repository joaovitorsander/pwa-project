const axios = require('axios');

exports.buscarCidades = async (req, res) => {
  const termoDeBusca = req.query.input;
  const apiKey = process.env.GOOGLE_MAPS_API_KEY;

  if (!termoDeBusca || termoDeBusca.length < 3) {
    return res.json({ suggestions: [] });
  }


  const url = 'https://places.googleapis.com/v1/places:autocomplete';

  const requestBody = {
    input: termoDeBusca,
    includedRegionCodes: ['br'],
    languageCode: 'pt-BR',
    includedPrimaryTypes: ['locality']
  };

  try {
    const response = await axios.post(url, requestBody, {
      headers: {
        'Content-Type': 'application/json',
        'X-Goog-Api-Key': apiKey,
      },
    });

    const predictionsFormatadas = (response.data.suggestions || []).map(s => ({
      description: s.placePrediction.text.text
    }));

    res.status(200).json({ predictions: predictionsFormatadas });

  } catch (error) {
    console.error('Erro ao chamar a nova Places API do Google:', error.response?.data || error.message);
    res.status(500).json({
      ok: false,
      message: 'Não foi possível buscar as cidades.',
      error: error.message,
    });
  }
};