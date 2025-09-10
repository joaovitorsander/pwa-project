const db = require("../db");

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
    origem: origem_cidade,
    destino: destino_cidade,
    distancia: km_total,
    veiculo: caminhao_id,
    tipoCarga: tipo_carga_id,
    precoCombustivel: preco_combustivel_l,
    pedagio: pedagios_total,


    quantidade_eixos: eixos_carregados,
    consumo_km_por_l_carregado: consumo_km_por_l,


    freteBruto: valor_frete_negociado,
    custoTotalCombustivel: custo_combustivel,
    totalCustosOperacionais: custo_total,
    valorAnttSugerido: valor_minimo_antt,


    valorCCDAplicado: valor_ccd_aplicado,
    valorCCAplicado: valor_cc_aplicado,

  } = dadosParaSalvar;

  const lucro_estimado = valor_frete_negociado - custo_total;
  const viavel = lucro_estimado > 0;

  const query = `
    INSERT INTO calculos (
      caminhao_id,                  -- $1
      origem_cidade,                -- $2
      destino_cidade,               -- $3
      km_total,                     -- $4
      eixos_carregados,             -- $5
      tipo_carga_id,                -- $6
      tipo_transporte_id,           -- 1 
      consumo_km_por_l,             -- $8
      preco_combustivel_l,          -- $9
      pedagios_total,               -- $10
      antt_tabela_id,               -- $11 (Ver Dica 4)
      valor_ccd_aplicado,           -- $12
      valor_cc_aplicado,            -- $13
      valor_minimo_antt,            -- $14
      valor_frete_negociado,        -- $15
      custo_combustivel,            -- $16
      custo_total,                  -- $17
      lucro_estimado,               -- $18
      viavel                        -- $19
    ) VALUES (
      $1, $2, $3, $4, $5, $6, $7, $8, $9, $10,
      $11, $12, $13, $14, $15, $16, $17, $18, $19
    )
    RETURNING *;
  `;

  const values = [
    caminhao_id,                  // $1
    origem_cidade,                // $2
    destino_cidade,               // $3
    km_total,                     // $4
    eixos_carregados,             // $5
    tipo_carga_id,                // $6
    1,                            // $7: tipo_transporte_id (valor fixo por enquanto)
    consumo_km_por_l,             // $8
    preco_combustivel_l,          // $9
    pedagios_total,               // $10
    1,                            // $11: antt_tabela_id (valor fixo por enquanto)
    valor_ccd_aplicado,           // $12
    valor_cc_aplicado,            // $13
    valor_minimo_antt,            // $14
    valor_frete_negociado,        // $15
    custo_combustivel,            // $16
    custo_total,                  // $17
    lucro_estimado,               // $18
    viavel                        // $19
  ];

  const { rows } = await db.query(query, values);
  return rows[0];
}

module.exports = {
    buscarCoeficientesAntt,
    calcularCustoFrete,
    inserirCalculo
};
