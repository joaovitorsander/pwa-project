const db = require('../db');

async function InserirCaminhao({placa, modelo, ano, quantidade_eixos}) {
    const query = 'INSERT INTO CAMINHOES (PLACA, MODELO, ANO, QUANTIDADE_EIXOS) VALUES ($1, $2, $3, $4) RETURNING *';
    const values = [placa, modelo, ano, quantidade_eixos];
    const { rows } = await db.query(query, values);
    return rows[0];
};

module.exports = {
    InserirCaminhao
};