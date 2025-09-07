const calcularFreteModel = require("../models/calcularFreteModel");
const caminhaoModel = require("../models/caminhaoModel");

exports.calcularFrete = async (req, res) => {
  try {
    const dadosDoFormulario = req.body;

    const dadosTratados = {
      ...dadosDoFormulario,
      distancia: parseFloat(dadosDoFormulario.distancia),
      toneladaCarga: parseFloat(dadosDoFormulario.toneladaCarga),
      kmCarregado: parseFloat(dadosDoFormulario.kmCarregado),
      kmVazio: parseFloat(dadosDoFormulario.kmVazio || 0),
      precoCombustivel: parseFloat(dadosDoFormulario.precoCombustivel),
      pedagio: parseFloat(dadosDoFormulario.pedagio || 0),
      valor_tonelada: parseFloat(dadosDoFormulario.valor_tonelada),
      commissao_motorista: parseFloat(dadosDoFormulario.commissao_motorista),
    };

    if (!dadosTratados.veiculo || !dadosTratados.distancia) {
      return res
        .status(400)
        .json({ ok: false, message: "Dados insuficientes para o cálculo." });
    }

    const caminhaoSelecionado = await caminhaoModel.BuscarCaminhaoPeloId(
      dadosTratados.veiculo
    );
    if (!caminhaoSelecionado) {
      return res
        .status(404)
        .json({ ok: false, message: "Veículo selecionado não encontrado." });
    }

    const coeficientesAntt = await calcularFreteModel.buscarCoeficientesAntt(
      dadosTratados.tipoCarga,
      caminhaoSelecionado.quantidade_eixos
    );

    const resultados = calcularFreteModel.calcularCustoFrete(
      dadosTratados,
      caminhaoSelecionado,
      coeficientesAntt
    );

    res.status(200).json({
      ok: true,
      message: "Cálculo de frete simulado com sucesso!",
      resultados: resultados,
    });
  } catch (error) {
    console.error("Erro ao simular frete:", error);
    res.status(500).json({
      ok: false,
      message: "Ocorreu um erro no servidor ao simular o frete.",
      error: error.message,
    });
  }
};

exports.salvarFreteCalculado = async (req, res) => {
  try {
    const calculoCompleto = req.body;

    const novoCalculoSalvo = await calcularFreteModel.inserirCalculo(
      calculoCompleto
    );

    res.status(201).json({
      ok: true,
      message: "Frete salvo com sucesso!",
      calculo: novoCalculoSalvo,
    });
  } catch (error) {
    console.error("Erro ao salvar cálculo de frete:", error);
    res.status(500).json({
      ok: false,
      message: "Ocorreu um erro no servidor ao salvar o cálculo.",
      error: error.message,
    });
  }
};
