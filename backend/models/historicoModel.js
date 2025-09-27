const db = require('../db');

async function buscarHistorico(filtros = {}) {
  let baseQuery = `
    SELECT
      c.id,
      c.origem_cidade AS origem,
      c.destino_cidade AS destino,
      c.km_total AS distancia_km,
      cam.modelo AS veiculo_modelo,
      cam.placa,
      c.consumo_km_por_l_carregado AS consumo_km_l,
      tc.nome AS tipo_carga,
      c.created_at AS data_calculo,
      c.valor_frete_negociado AS valor_total
    FROM
      calculos c
      LEFT JOIN caminhoes cam ON c.caminhao_id = cam.id
      LEFT JOIN tipos_carga tc ON c.tipo_carga_id = tc.id
  `;

  const whereClauses = [];
  const params = [];

  if (filtros.termo) {
    params.push(`%${filtros.termo}%`);
    const paramIndex = params.length;
    whereClauses.push(
      `(c.origem_cidade ILIKE $${paramIndex} OR c.destino_cidade ILIKE $${paramIndex} OR cam.placa ILIKE $${paramIndex})`
    );
  }

  if (filtros.data_de) {
    params.push(filtros.data_de);
    whereClauses.push(`c.created_at::date >= $${params.length}`);
  }

  if (filtros.data_ate) {
    params.push(filtros.data_ate);
    whereClauses.push(`c.created_at::date <= $${params.length}`);
  }

  if (whereClauses.length > 0) {
    baseQuery += ` WHERE ${whereClauses.join(' AND ')}`;
  }

  baseQuery += ` ORDER BY c.created_at DESC`;

  const { rows } = await db.query(baseQuery, params);
  return rows;
}

async function excluirCalculo(id) {
  const query = 'DELETE FROM calculos WHERE id = $1 RETURNING *';
  const values = [id];
  const { rows } = await db.query(query, values);
  return rows[0];
}

async function limparHistorico() {
  const query = 'DELETE FROM calculos';
  await db.query(query);
}


module.exports = {
  buscarHistorico,
  excluirCalculo,
  limparHistorico,
};