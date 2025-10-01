const CaminhaoModel = require("../models/caminhaoModel");

exports.criarCaminhao = async (req, res) => {
  try {
    const dadosRecebidos = req.body;
    const dadosFormatados = {
      ...dadosRecebidos,
      consumo_km_por_l_vazio: parseFloat(dadosRecebidos.consumo_km_por_l_vazio) || null,
      consumo_km_por_l_carregado: parseFloat(dadosRecebidos.consumo_km_por_l_carregado) || null,
      capacidade_ton: parseFloat(dadosRecebidos.capacidade_ton) || null,
      ano: parseInt(dadosRecebidos.ano, 10) || null,
      quantidade_eixos: parseInt(dadosRecebidos.quantidade_eixos, 10) || null
    };

    const novo = await CaminhaoModel.InserirCaminhao(dadosFormatados);
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

exports.buscarCaminhoes = async (req, res) => {
  try {
    const filtros = req.query;
    const data = await CaminhaoModel.BuscarCaminhoes(filtros);
    res.status(200).json({
      ok: true,
      message: "Busca de caminhões realizada com sucesso.",
      caminhoes: data,
    });
  } catch (error) {
    res.status(500).json({
      ok: false,
      message: "Não foi possível obter os caminhões",
      error: error.message,
    });
  }
};

exports.excluirCaminhao = async (req, res) => {
  try {
    const { id } = req.params;
    const caminhaoExcluido = await CaminhaoModel.ExcluirCaminhao(id);
    if (caminhaoExcluido) {
      res.status(200).json({
        ok: true,
        message: "Caminhão excluído com sucesso.",
        caminhao: caminhaoExcluido,
      });
    } else {
      res.status(404).json({
        ok: false,
        message: "Caminhão não encontrado.",
      });
    }
  } catch (error) {
    res.status(500).json({
      ok: false,
      message: "Erro ao excluir o caminhão.",
      error: error.message,
    });
  }
};

exports.atualizarCaminhao = async (req, res) => {
  try {
    console.log('req.params recebido na rota:', req.params);
    const { id } = req.params;

    console.log('Valor da variável "id" no controller:', id);
    const campos = req.body;

    if (Object.keys(campos).length === 0) {
      return res.status(400).json({
        ok: false,
        message: "Nenhum dado fornecido para atualização.",
      });
    }

    const caminhaoAtualizado = await CaminhaoModel.AtualizarCaminhao(
      id,
      campos
    );

    if (caminhaoAtualizado) {
      res.status(200).json({
        ok: true,
        message: "Caminhão atualizado com sucesso.",
        caminhao: caminhaoAtualizado,
      });
    } else {
      res.status(404).json({
        ok: false,
        message: "Caminhão não encontrado.",
      });
    }
  } catch (error) {
    res.status(500).json({
      ok: false,
      message: "Erro ao atualizar o caminhão.",
      error: error.message,
    });
  }
};