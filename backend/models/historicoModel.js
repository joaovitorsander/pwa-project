const db = require("../db");

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

  
  if (filtros.uf_origem) {
    params.push(`%${filtros.uf_origem}%`);
    whereClauses.push(`c.origem_uf ILIKE $${params.length}`);
  }

  if (filtros.uf_destino) {
    params.push(`%${filtros.uf_destino}%`);
    whereClauses.push(`c.destino_uf ILIKE $${params.length}`);
  }

  if (filtros.cidade_origem) {
    params.push(`%${filtros.cidade_origem}%`);
    whereClauses.push(`c.origem_cidade ILIKE $${params.length}`);
  }

  if (filtros.cidade_destino) {
    params.push(`%${filtros.cidade_destino}%`);
    whereClauses.push(`c.destino_cidade ILIKE $${params.length}`);
  }
  
  if (filtros.placa) {
    params.push(`%${filtros.placa}%`);
    whereClauses.push(`cam.placa ILIKE $${params.length}`);
  }

  if (filtros.caminhao) {
    params.push(`%${filtros.caminhao}%`);
    whereClauses.push(`cam.modelo ILIKE $${params.length}`);
  }

  if (filtros.data_de) {
    params.push(formatarDataParaSQL(filtros.data_de));
    whereClauses.push(`c.created_at::date >= $${params.length}`);
  }

  if (filtros.data_ate) {
    params.push(formatarDataParaSQL(filtros.data_ate));
    whereClauses.push(`c.created_at::date <= $${params.length}`);
  }

  if (whereClauses.length > 0) {
    baseQuery += ` WHERE ${whereClauses.join(" AND ")}`;
  }

  baseQuery += ` ORDER BY c.created_at DESC`;

  const { rows } = await db.query(baseQuery, params);
  return rows;
}

async function excluirCalculo(id) {
  const query = "DELETE FROM calculos WHERE id = $1 RETURNING *";
  const values = [id];
  const { rows } = await db.query(query, values);
  return rows[0];
}

async function limparHistorico() {
  const query = "DELETE FROM calculos";
  await db.query(query);
}

function formatarDataParaSQL(data) {
  if (!data || typeof data !== 'string' || data.length !== 10) return null;
  const [dia, mes, ano] = data.split('/');
  return `${ano}-${mes}-${dia}`;
}

module.exports = {
  buscarHistorico,
  excluirCalculo,
  limparHistorico,
};
