const db = require("../db");

async function buscarHistorico(filtros = {}) {
  let baseQuery = `
    SELECT
      caminhoes.modelo AS veiculo_modelo,
      caminhoes.placa,
      tipos_carga.nome AS tipo_carga,
      calculos.id,                         
      calculos.caminhao_id,             
      calculos.created_at,              
      calculos.origem_uf,                 
      calculos.origem_cidade,              
      calculos.destino_uf,                 
      calculos.destino_cidade,             
      calculos.km_total,                   
      calculos.quantidade_eixos,           
      calculos.tipo_carga_id,              
      calculos.tipo_transporte_id,         
      calculos.consumo_km_por_l_vazio,     
      calculos.consumo_km_por_l_carregado, 
      calculos.preco_combustivel_l,        
      calculos.pedagios_total,             
      calculos.outros_custos_total,        
      calculos.antt_tabela_id,             
      calculos.valor_ccd_aplicado,         
      calculos.valor_cc_aplicado,          
      calculos.valor_minimo_antt,          
      calculos.valor_frete_negociado,     
      calculos.custo_combustivel,          
      calculos.custo_total,                
      calculos.lucro_estimado,             
      calculos.viavel
    FROM
      calculos
      LEFT JOIN caminhoes ON calculos.caminhao_id = caminhoes.id
      LEFT JOIN tipos_carga ON calculos.tipo_carga_id = tipos_carga.id
  `;

  const whereClauses = [];
  const params = [];

  
  if (filtros.uf_origem) {
    params.push(`%${filtros.uf_origem}%`);
    whereClauses.push(`calculos.origem_uf ILIKE $${params.length}`);
  }

  if (filtros.uf_destino) {
    params.push(`%${filtros.uf_destino}%`);
    whereClauses.push(`calculos.destino_uf ILIKE $${params.length}`);
  }

  if (filtros.cidade_origem) {
    params.push(`%${filtros.cidade_origem}%`);
    whereClauses.push(`calculos.origem_cidade ILIKE $${params.length}`);
  }

  if (filtros.cidade_destino) {
    params.push(`%${filtros.cidade_destino}%`);
    whereClauses.push(`calculos.destino_cidade ILIKE $${params.length}`);
  }
  
  if (filtros.placa) {
    params.push(`%${filtros.placa}%`);
    whereClauses.push(`caminhoes.placa ILIKE $${params.length}`);
  }

  if (filtros.caminhao) {
    params.push(`%${filtros.caminhao}%`);
    whereClauses.push(`caminhoes.modelo ILIKE $${params.length}`);
  }

  if (filtros.data_de) {
    params.push(formatarDataParaSQL(filtros.data_de));
    whereClauses.push(`calculos.created_at::date >= $${params.length}`);
  }

  if (filtros.data_ate) {
    params.push(formatarDataParaSQL(filtros.data_ate));
    whereClauses.push(`calculos.created_at::date <= $${params.length}`);
  }

  if (whereClauses.length > 0) {
    baseQuery += ` WHERE ${whereClauses.join(" AND ")}`;
  }

  baseQuery += ` ORDER BY calculos.created_at DESC`;

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
