const CaminhaoModel = require("../models/caminhaoModel");

exports.criarCaminhao = async (req, res) => {
  try {
    const novo = await CaminhaoModel.InserirCaminhao(req.body);
    res.status(201).json({
      ok: true,
      message: "Caminhão cadastrado com sucesso.",
      caminhao: novo,
    });
  } catch (error) {
    res.status(500).json({
      ok: false,
      message: "Erro ao cadastrar caminhão.",
      error: error.message,
    });
  }
};
