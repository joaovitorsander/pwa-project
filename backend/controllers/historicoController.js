const HistoricoModel = require('../models/historicoModel');

exports.buscarHistorico = async (req, res) => {
  try {
    const filtros = req.query;
    const historico = await HistoricoModel.buscarHistorico(filtros);

    res.status(200).json({
      ok: true,
      message: "Busca no histórico realizada com sucesso.",
      historico: historico,
    });
  } catch (error) {
    res.status(500).json({
      ok: false,
      message: "Não foi possível obter o histórico.",
      error: error.message,
    });
  }
};

exports.excluirCalculo = async (req, res) => {
  try {
    const { id } = req.params;
    if (!id) {
        return res.status(400).json({ ok: false, message: 'O ID do cálculo é obrigatório.' });
    }

    const itemExcluido = await HistoricoModel.excluirCalculo(id);

    if (itemExcluido) {
      res.status(200).json({
        ok: true,
        message: "Cálculo excluído com sucesso.",
      });
    } else {
      res.status(404).json({
        ok: false,
        message: "Cálculo não encontrado.",
      });
    }
  } catch (error) {
    res.status(500).json({
      ok: false,
      message: "Erro ao excluir o cálculo.",
      error: error.message,
    });
  }
};

exports.limparHistorico = async (req, res) => {
    try {
        await HistoricoModel.limparHistorico();

        res.status(200).json({
            ok: true,
            message: 'Histórico de cálculos foi limpo com sucesso.'
        });
    } catch (error) {
        res.status(500).json({
            ok: false,
            message: 'Erro ao limpar o histórico.',
            error: error.message
        });
    }
}