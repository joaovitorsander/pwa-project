const db = require("../db");

async function InserirCaminhao({
  placa,
  modelo,
  ano,
  quantidade_eixos,
  consumo_km_por_l_vazio,
  consumo_km_por_l_carregado,
  capacidade_ton,
}) {
  const query =
    "INSERT INTO CAMINHOES (PLACA, MODELO, ANO, QUANTIDADE_EIXOS, CONSUMO_KM_POR_L_VAZIO, CONSUMO_KM_POR_L_CARREGADO, CAPACIDADE_TON) VALUES ($1, $2, $3, $4, $5, $6, $7) RETURNING *";
  const values = [
    placa,
    modelo,
    ano,
    quantidade_eixos,
    consumo_km_por_l_vazio,
    consumo_km_por_l_carregado,
    capacidade_ton,
  ];
  const { rows } = await db.query(query, values);
  return rows[0];
}

async function BuscarCaminhoes(filtros = {}) {
  let query =
    "SELECT id, modelo, placa, ano, quantidade_eixos, consumo_km_por_l_vazio, consumo_km_por_l_carregado, capacidade_ton FROM caminhoes";

  const values = [];
  const whereClauses = [];

  if (filtros.placa) {
    values.push(`%${filtros.placa}%`);
    whereClauses.push(`placa ILIKE $${values.length}`);
  }

  if (filtros.modelo) {
    values.push(`%${filtros.modelo}%`);
    whereClauses.push(`modelo ILIKE $${values.length}`);
  }

  if (filtros.ano) {
    values.push(filtros.ano);
    whereClauses.push(`ano = $${values.length}`);
  }

  if (whereClauses.length > 0) {
    query += ` WHERE ${whereClauses.join(" AND ")}`;
  }

  query += " ORDER BY id ASC";

  const { rows } = await db.query(query, values);
  return rows;
}

async function BuscarCaminhaoPeloId(id) {
  const query = "SELECT * FROM caminhoes WHERE caminhoes.id = $1";
  const values = [id];
  const { rows } = await db.query(query, values);
  return rows[0];  
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

module.exports = {
  InserirCaminhao,
  BuscarCaminhoes,
  BuscarCaminhaoPeloId,
  ExcluirCaminhao,
  AtualizarCaminhao,
};
