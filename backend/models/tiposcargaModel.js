const db = require("../db")

async function BuscarTiposCarga() {
    const query = 'SELECT id, nome FROM tipos_carga';
    const { rows } = await db.query(query);
    return rows;
};

module.exports = {
    BuscarTiposCarga
}