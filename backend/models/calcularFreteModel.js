const db = require("../db");

const ufMap = {
  'Acre': 'AC', 'Alagoas': 'AL', 'Amapá': 'AP', 'Amazonas': 'AM',
  'Bahia': 'BA', 'Ceará': 'CE', 'Distrito Federal': 'DF', 'Espírito Santo': 'ES',
  'Goiás': 'GO', 'Maranhão': 'MA', 'Mato Grosso': 'MT', 'Mato Grosso do Sul': 'MS',
  'Minas Gerais': 'MG', 'Pará': 'PA', 'Paraíba': 'PB', 'Paraná': 'PR',
  'Pernambuco': 'PE', 'Piauí': 'PI', 'Rio de Janeiro': 'RJ', 'Rio Grande do Norte': 'RN',
  'Rio Grande do Sul': 'RS', 'Rondônia': 'RO', 'Roraima': 'RR', 'Santa Catarina': 'SC',
  'São Paulo': 'SP', 'Sergipe': 'SE', 'Tocantins': 'TO'
};

function parseLocalidade(localidadeStr) {
  if (!localidadeStr || typeof localidadeStr !== 'string') {
    return { cidade: null, uf: null };
  }

  const partes = localidadeStr.split(',').map(p => p.trim());

  if (partes[partes.length - 1].toLowerCase() === 'brasil') {
    partes.pop();
  }

  if (partes.length === 0) {
    return { cidade: null, uf: null };
  }

  const cidade = partes[0].split('-')[0].trim();

  const infoEstado = partes[partes.length - 1];
  let uf = infoEstado; 

  if (infoEstado.includes('-')) {
    const subPartes = infoEstado.split('-').map(sp => sp.trim());
    uf = subPartes[subPartes.length - 1];
  }

  const ufFinal = ufMap[uf] || uf;

  return { cidade, uf: ufFinal };
}

async function buscarCoeficientesAntt(tipoCargaId, quantidadeEixos) {
  const queryBuscaCoeficientes = `
    SELECT tipo_coeficiente, valor
    FROM antt_coeficientes
    WHERE antt_tabela_id = 1
      AND tipo_carga_id = $1
      AND eixos_carregados = $2
  `;
  
  const values = [tipoCargaId, quantidadeEixos];
  const { rows } = await db.query(queryBuscaCoeficientes, values);

  const getVal = (tipo) => {
    const r = rows.find(row => row.tipo_coeficiente === tipo);
    return r ? parseFloat(r.valor) : 0;
  };

  return {
    valorCCD: getVal('CCD'),
    valorCC: getVal('CC'),
  };
};

function calcularCustoFrete(dadosForm, dadosCaminhao, coeficientesAntt) {
  const {
    distancia,
    toneladaCarga,
    kmCarregado,
    kmVazio = 0,
    precoCombustivel,
    pedagio = 0,
    valor_tonelada,
    commissao_motorista,
  } = dadosForm;

  const {
    consumo_km_por_l_vazio,
    consumo_km_por_l_carregado,
  } = dadosCaminhao;

  if (!consumo_km_por_l_carregado || !consumo_km_por_l_vazio) {
    throw new Error('Dados de consumo do veículo inválidos (zero ou nulo).');
  }

  const freteBruto = valor_tonelada * toneladaCarga;
  const litrosCarregado = kmCarregado / consumo_km_por_l_carregado;
  const litrosVazio = kmVazio / consumo_km_por_l_vazio;
  const custoTotalCombustivel = (litrosCarregado + litrosVazio) * precoCombustivel;

  const valorComissaoMotorista = (freteBruto * commissao_motorista) / 100;
  const totalCustosOperacionais = custoTotalCombustivel + pedagio + valorComissaoMotorista;
  const lucroEstimado = freteBruto - totalCustosOperacionais;


  const { valorCCD, valorCC } = coeficientesAntt;
  const valorAnttSugerido = (distancia * valorCCD) + valorCC;

  return {
    freteBruto: freteBruto.toFixed(2),
    custoTotalCombustivel: custoTotalCombustivel.toFixed(2),
    valorComissaoMotorista: valorComissaoMotorista.toFixed(2),
    valorPedagio: pedagio.toFixed(2),
    totalCustosOperacionais: totalCustosOperacionais.toFixed(2),
    lucroEstimado: lucroEstimado.toFixed(2), 
    valorAnttSugerido: valorAnttSugerido.toFixed(2),
    valorCCDAplicado: valorCCD.toFixed(2), 
    valorCCAplicado: valorCC.toFixed(2)
  };
};

async function inserirCalculo(dadosParaSalvar) {
  const {
    origem: origem,
    destino: destino,
    distancia: km_total,
    veiculo: caminhao_id,
    tipoCarga: tipo_carga_id,
    precoCombustivel: preco_combustivel_l,
    pedagio: pedagios_total,


    quantidade_eixos: quantidade_eixos,
    consumo_km_por_l_vazio: consumo_km_por_l_vazio,
    consumo_km_por_l_carregado: consumo_km_por_l_carregado,


    freteBruto: valor_frete_negociado,
    custoTotalCombustivel: custo_combustivel,
    totalCustosOperacionais: custo_total,
    valorAnttSugerido: valor_minimo_antt,


    valorCCDAplicado: valor_ccd_aplicado,
    valorCCAplicado: valor_cc_aplicado,

  } = dadosParaSalvar;

  const origemParseada = parseLocalidade(origem);
  const destinoParseada = parseLocalidade(destino);

  const lucro_estimado = valor_frete_negociado - custo_total;
  const viavel = lucro_estimado > 0;

  const query = `
    INSERT INTO calculos (
      caminhao_id,                  -- $1
      origem_uf,                    -- $2 
      origem_cidade,                -- $3
      destino_uf,                   -- $4
      destino_cidade,               -- $5
      km_total,                     -- $6
      quantidade_eixos,             -- $7
      tipo_carga_id,                -- $8
      tipo_transporte_id,           -- $9 
      consumo_km_por_l_vazio,       -- $10
      consumo_km_por_l_carregado,   -- $11
      preco_combustivel_l,          -- $12
      pedagios_total,               -- $13
      antt_tabela_id,               -- $14
      valor_ccd_aplicado,           -- $15
      valor_cc_aplicado,            -- $16
      valor_minimo_antt,            -- $17
      valor_frete_negociado,        -- $18
      custo_combustivel,            -- $19
      custo_total,                  -- $20
      lucro_estimado,               -- $21
      viavel                        -- $22
    ) VALUES (
      $1, $2, $3, $4, $5, $6, $7, $8, $9, $10,
      $11, $12, $13, $14, $15, $16, $17, $18, $19, $20, $21, $22
    )
    RETURNING *;
  `;

  const values = [
    caminhao_id,                  // $1
    origemParseada.uf,            // $2 
    origemParseada.cidade,        // $3
    destinoParseada.uf,           // $4
    destinoParseada.cidade,       // $5
    km_total,                     // $6
    quantidade_eixos,             // $7
    tipo_carga_id,                // $8
    1,                            // $9
    consumo_km_por_l_vazio,       // $10
    consumo_km_por_l_carregado,   // $11
    preco_combustivel_l,          // $12
    pedagios_total,               // $13
    1,                            // $14
    valor_ccd_aplicado,           // $15
    valor_cc_aplicado,            // $16
    valor_minimo_antt,            // $17
    valor_frete_negociado,        // $18
    custo_combustivel,            // $19
    custo_total,                  // $20
    lucro_estimado,               // $21
    viavel                        // $22
  ];

  const { rows } = await db.query(query, values);
  return rows[0];
}

module.exports = {
    buscarCoeficientesAntt,
    calcularCustoFrete,
    inserirCalculo
};
