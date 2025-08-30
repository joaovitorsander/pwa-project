const db = require("../db");

async function InserirCaminhao({ placa, modelo, ano, quantidade_eixos, consumo_km_por_l_vazio, consumo_km_por_l_carregado, capacidade_ton }) {
  const query =
    "INSERT INTO CAMINHOES (PLACA, MODELO, ANO, QUANTIDADE_EIXOS, CONSUMO_KM_POR_L_VAZIO, CONSUMO_KM_POR_L_CARREGADO, CAPACIDADE_TON) VALUES ($1, $2, $3, $4, $5, $6, $7) RETURNING *";
  const values = [placa, modelo, ano, quantidade_eixos, consumo_km_por_l_vazio, consumo_km_por_l_carregado, capacidade_ton];
  const { rows } = await db.query(query, values);
  return rows[0];
}

async function BuscarCaminhoes() {
  const query =
    "SELECT caminhoes.id, caminhoes.modelo, caminhoes.placa, caminhoes.ano, caminhoes.quantidade_eixos, caminhoes.consumo_km_por_l_vazio, caminhoes.consumo_km_por_l_carregado, capacidade_ton FROM caminhoes";
  const { rows } = await db.query(query);
  return rows;
}

async function ExcluirCaminhao(id) {
  const query = "DELETE FROM caminhoes WHERE caminhoes.id = $1 RETURNING *";
  const values = [id];
  const { rows } = await db.query(query, values);
  return rows[0];
}

async function AtualizarCaminhao(id, campos) {
  const chaves = Object.keys(campos);

  if (chaves.length === 0) {
    throw new Error("Nenhum campo fornecido para atualização.");
  }

  const setClause = chaves
    .map((chave, index) => `${chave.toUpperCase()} = $${index + 1}`)
    .join(", ");

  const values = Object.values(campos);

  const valueParamId = values.length + 1;

  const query = `UPDATE caminhoes
        SET ${setClause}
        WHERE id = $${valueParamId}
        RETURNING *`;

  const finalValues = [...values, id];

  const { rows } = await db.query(query, finalValues);
  return rows[0];
}

async function FiltrarCaminhoes(params) {
  let query = 'SELECT * FROM "CAMINHOES"';
  const values = [];
  const whereClauses = [];

  if (filtros.placa) {
    values.push(`%${filtros.placa}%`);
    whereClauses.push(`"PLACA" ILIKE $${values.length}`);
  }

  if (filtros.modelo) {
    values.push(`%${filtros.modelo}%`);
    whereClauses.push(`"MODELO" ILIKE $${values.length}`);
  }

  if (filtros.ano) {
    values.push(filtros.ano);
    whereClauses.push(`"ANO" = $${values.length}`);
  }

  if (whereClauses.length > 0) {
    query += ` WHERE ${whereClauses.join(" AND ")}`;
  }

  query += ' ORDER BY "ID" ASC';

  const { rows } = await db.query(query, values);
  return rows;
}

module.exports = {
  InserirCaminhao,
  BuscarCaminhoes,
  ExcluirCaminhao,
  AtualizarCaminhao,
  FiltrarCaminhoes,
};
