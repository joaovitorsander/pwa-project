const TiposCargaModel = require("../models/tiposcargaModel");

exports.BuscarTiposCargas = async (req, res) => {
  try {
    const data = await TiposCargaModel.BuscarTiposCarga();
    res.status(200).json({
      ok: true,
      message: "Tipos de cargas foram obtidos com sucesso",
      tiposCarga: data,
    });
  } catch (error) {
    res.status(500).json({
      ok: false,
      message: "Não foi possível obter os tipos de carga",
      error: error.message,
    });
  }
};
