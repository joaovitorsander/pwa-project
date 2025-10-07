-- Tipos ENUM
CREATE TYPE coef_tipo AS ENUM ('CCD','CC');      -- CCD = R$/km ; CC = R$
CREATE TYPE unidade_monet AS ENUM ('RS_KM','RS');

-- 1) Usuários
/*CREATE TABLE usuarios (
  id         SERIAL PRIMARY KEY,
  nome       TEXT NOT NULL,
  email      TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);*/

-- 2) Caminhões
CREATE TABLE caminhoes (
  id                         SERIAL PRIMARY KEY,
  --usuario_id               INT NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
  placa                      TEXT,
  modelo                     TEXT,
  ano                        INT,
  quantidade_eixos           INT,
  consumo_km_por_l_vazio     NUMERIC(10,2),
  consumo_km_por_l_carregado NUMERIC(10,2),
  capacidade_ton             INT,
  created_at                 TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 3) Catálogos
CREATE TABLE tipos_carga (
  id   SMALLSERIAL PRIMARY KEY,
  nome TEXT NOT NULL
);

CREATE TABLE tipos_transporte (
  id        SMALLSERIAL PRIMARY KEY,
  codigo    TEXT NOT NULL,   -- ex.: 'A', 'B'
  nome      TEXT NOT NULL   -- ex.: TABELA A - TRANSPORTE RODOVIÁRIO DE CARGA LOTAÇÃO 
);

-- 4) Versões/vigências da ANTT
CREATE TABLE antt_tabelas (
  id           SERIAL PRIMARY KEY,
  versao_label TEXT NOT NULL,
  vigente_de   DATE NOT NULL,
  vigente_ate  DATE,
  fonte_url    TEXT,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 5) Coeficientes ANTT (CCD/CC unificados)
CREATE TABLE antt_coeficientes (
  id                  BIGSERIAL PRIMARY KEY,
  antt_tabela_id      INT NOT NULL REFERENCES antt_tabelas(id) ON DELETE CASCADE,
  tipo_carga_id       SMALLINT NOT NULL REFERENCES tipos_carga(id),
  tipo_transporte_id  SMALLINT NOT NULL REFERENCES tipos_transporte(id),
  eixos_carregados    SMALLINT NOT NULL,
  tipo_coeficiente    coef_tipo NOT NULL,
  unidade             unidade_monet NOT NULL,
  valor               NUMERIC(12,4) NOT NULL
);

CREATE INDEX idx_coef_lookup
  ON antt_coeficientes (tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, antt_tabela_id);

-- 6) Cálculos (histórico)
CREATE TABLE calculos (
  id                      BIGSERIAL PRIMARY KEY,
  --usuario_id              INT NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
  caminhao_id             INT REFERENCES caminhoes(id) ON DELETE SET NULL,
  created_at              TIMESTAMPTZ NOT NULL DEFAULT now(),

  origem_uf                  CHAR(2),
  origem_cidade              TEXT,
  destino_uf                 CHAR(2),
  destino_cidade             TEXT,
  km_total                   NUMERIC(10,2) NOT NULL,
  quantidade_eixos           SMALLINT NOT NULL,
  tipo_carga_id              SMALLINT NOT NULL REFERENCES tipos_carga(id),
  tipo_transporte_id         SMALLINT NOT NULL REFERENCES tipos_transporte(id),

  consumo_km_por_l_vazio     NUMERIC(10,3),
  consumo_km_por_l_carregado NUMERIC(10,3),
  preco_combustivel_l        NUMERIC(10,3),
  pedagios_total             NUMERIC(12,2),
  outros_custos_total        NUMERIC(12,2),

  toneladas_carga          NUMERIC(10, 3),
  km_rodado_carregado      NUMERIC(10, 2),
  km_rodado_vazio          NUMERIC(10, 2),
  valor_por_tonelada       NUMERIC(12, 2),
  comissao_motorista       SMALLINT,

  antt_tabela_id             INT NOT NULL REFERENCES antt_tabelas(id),

  valor_ccd_aplicado         NUMERIC(12,4),
  valor_cc_aplicado          NUMERIC(12,2),
  valor_minimo_antt          NUMERIC(12,2),
  valor_frete_negociado      NUMERIC(12,2),

  custo_combustivel          NUMERIC(12,2),
  custo_total                NUMERIC(12,2),
  lucro_estimado             NUMERIC(12,2),
  viavel                     BOOLEAN
);


-- Seed para TABELA A - Transporte Rodoviário de Carga (Lotação)
BEGIN;

-- Tipo de transporte
INSERT INTO tipos_transporte (codigo, nome)
SELECT 'A', 'TABELA A - TRANSPORTE RODOVIÁRIO DE CARGA LOTAÇÃO'
WHERE NOT EXISTS (SELECT 1 FROM tipos_transporte WHERE codigo = 'A');

-- Tipos de carga
INSERT INTO tipos_carga (nome)
SELECT 'Granel sólido'
WHERE NOT EXISTS (SELECT 1 FROM tipos_carga WHERE nome = 'Granel sólido');
INSERT INTO tipos_carga (nome)
SELECT 'Granel líquido'
WHERE NOT EXISTS (SELECT 1 FROM tipos_carga WHERE nome = 'Granel líquido');
INSERT INTO tipos_carga (nome)
SELECT 'Frigorificada ou Aquecida'
WHERE NOT EXISTS (SELECT 1 FROM tipos_carga WHERE nome = 'Frigorificada ou Aquecida');
INSERT INTO tipos_carga (nome)
SELECT 'Conteinerizada'
WHERE NOT EXISTS (SELECT 1 FROM tipos_carga WHERE nome = 'Conteinerizada');
INSERT INTO tipos_carga (nome)
SELECT 'Carga Geral'
WHERE NOT EXISTS (SELECT 1 FROM tipos_carga WHERE nome = 'Carga Geral');
INSERT INTO tipos_carga (nome)
SELECT 'Neogranel'
WHERE NOT EXISTS (SELECT 1 FROM tipos_carga WHERE nome = 'Neogranel');
INSERT INTO tipos_carga (nome)
SELECT 'Perigosa (granel sólido)'
WHERE NOT EXISTS (SELECT 1 FROM tipos_carga WHERE nome = 'Perigosa (granel sólido)');
INSERT INTO tipos_carga (nome)
SELECT 'Perigosa (granel líquido)'
WHERE NOT EXISTS (SELECT 1 FROM tipos_carga WHERE nome = 'Perigosa (granel líquido)');
INSERT INTO tipos_carga (nome)
SELECT 'Perigosa (frigorificada ou aquecida)'
WHERE NOT EXISTS (SELECT 1 FROM tipos_carga WHERE nome = 'Perigosa (frigorificada ou aquecida)');
INSERT INTO tipos_carga (nome)
SELECT 'Perigosa (conteinerizada)'
WHERE NOT EXISTS (SELECT 1 FROM tipos_carga WHERE nome = 'Perigosa (conteinerizada)');
INSERT INTO tipos_carga (nome)
SELECT 'Perigosa (carga geral)'
WHERE NOT EXISTS (SELECT 1 FROM tipos_carga WHERE nome = 'Perigosa (carga geral)');
INSERT INTO tipos_carga (nome)
SELECT 'Carga Granel Pressurizada'
WHERE NOT EXISTS (SELECT 1 FROM tipos_carga WHERE nome = 'Carga Granel Pressurizada');

-- Vigência ANTT
INSERT INTO antt_tabelas (versao_label, vigente_de, fonte_url)
SELECT 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)', DATE '2025-07-17', 'https://anttlegis.antt.gov.br/action/UrlPublicasAction.php?acao=abrirAtoPublico&num_ato=00005867&sgl_tipo=RES&sgl_orgao=DG/ANTT/MI&vlr_ano=2020&seq_ato=000&cod_modulo=161&cod_menu=5408'
WHERE NOT EXISTS (SELECT 1 FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)');

INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Granel sólido'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'A'),
  2, 'CCD', 'RS_KM', 3.7050
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Granel sólido')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'A')
    AND eixos_carregados = 2
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Granel sólido'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'A'),
  3, 'CCD', 'RS_KM', 4.6875
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Granel sólido')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'A')
    AND eixos_carregados = 3
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Granel sólido'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'A'),
  4, 'CCD', 'RS_KM', 5.3526
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Granel sólido')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'A')
    AND eixos_carregados = 4
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Granel sólido'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'A'),
  5, 'CCD', 'RS_KM', 6.0301
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Granel sólido')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'A')
    AND eixos_carregados = 5
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Granel sólido'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'A'),
  6, 'CCD', 'RS_KM', 6.7408
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Granel sólido')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'A')
    AND eixos_carregados = 6
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Granel sólido'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'A'),
  7, 'CCD', 'RS_KM', 7.3130
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Granel sólido')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'A')
    AND eixos_carregados = 7
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Granel sólido'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'A'),
  9, 'CCD', 'RS_KM', 8.2420
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Granel sólido')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'A')
    AND eixos_carregados = 9
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Granel sólido'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'A'),
  2, 'CC', 'RS', 426.61
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Granel sólido')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'A')
    AND eixos_carregados = 2
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Granel sólido'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'A'),
  3, 'CC', 'RS', 519.67
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Granel sólido')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'A')
    AND eixos_carregados = 3
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Granel sólido'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'A'),
  4, 'CC', 'RS', 565.14
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Granel sólido')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'A')
    AND eixos_carregados = 4
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Granel sólido'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'A'),
  5, 'CC', 'RS', 615.26
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Granel sólido')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'A')
    AND eixos_carregados = 5
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Granel sólido'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'A'),
  6, 'CC', 'RS', 663.07
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Granel sólido')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'A')
    AND eixos_carregados = 6
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Granel sólido'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'A'),
  7, 'CC', 'RS', 753.88
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Granel sólido')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'A')
    AND eixos_carregados = 7
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Granel sólido'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'A'),
  9, 'CC', 'RS', 808.17
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Granel sólido')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'A')
    AND eixos_carregados = 9
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Granel líquido'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'A'),
  2, 'CCD', 'RS_KM', 3.7622
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Granel líquido')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'A')
    AND eixos_carregados = 2
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Granel líquido'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'A'),
  3, 'CCD', 'RS_KM', 4.7615
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Granel líquido')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'A')
    AND eixos_carregados = 3
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Granel líquido'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'A'),
  4, 'CCD', 'RS_KM', 5.5685
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Granel líquido')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'A')
    AND eixos_carregados = 4
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Granel líquido'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'A'),
  5, 'CCD', 'RS_KM', 6.1801
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Granel líquido')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'A')
    AND eixos_carregados = 5
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Granel líquido'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'A'),
  6, 'CCD', 'RS_KM', 6.8811
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Granel líquido')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'A')
    AND eixos_carregados = 6
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Granel líquido'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'A'),
  7, 'CCD', 'RS_KM', 7.4723
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Granel líquido')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'A')
    AND eixos_carregados = 7
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Granel líquido'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'A'),
  9, 'CCD', 'RS_KM', 8.4114
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Granel líquido')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'A')
    AND eixos_carregados = 9
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Granel líquido'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'A'),
  2, 'CC', 'RS', 433.79
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Granel líquido')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'A')
    AND eixos_carregados = 2
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Granel líquido'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'A'),
  3, 'CC', 'RS', 531.46
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Granel líquido')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'A')
    AND eixos_carregados = 3
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Granel líquido'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'A'),
  4, 'CC', 'RS', 607.41
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Granel líquido')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'A')
    AND eixos_carregados = 4
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Granel líquido'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'A'),
  5, 'CC', 'RS', 639.41
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Granel líquido')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'A')
    AND eixos_carregados = 5
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Granel líquido'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'A'),
  6, 'CC', 'RS', 684.54
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Granel líquido')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'A')
    AND eixos_carregados = 6
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Granel líquido'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'A'),
  7, 'CC', 'RS', 780.59
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Granel líquido')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'A')
    AND eixos_carregados = 7
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Granel líquido'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'A'),
  9, 'CC', 'RS', 837.65
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Granel líquido')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'A')
    AND eixos_carregados = 9
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Frigorificada ou Aquecida'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'A'),
  2, 'CCD', 'RS_KM', 4.3393
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Frigorificada ou Aquecida')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'A')
    AND eixos_carregados = 2
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Frigorificada ou Aquecida'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'A'),
  3, 'CCD', 'RS_KM', 5.4569
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Frigorificada ou Aquecida')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'A')
    AND eixos_carregados = 3
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Frigorificada ou Aquecida'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'A'),
  4, 'CCD', 'RS_KM', 6.3427
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Frigorificada ou Aquecida')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'A')
    AND eixos_carregados = 4
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Frigorificada ou Aquecida'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'A'),
  5, 'CCD', 'RS_KM', 7.1099
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Frigorificada ou Aquecida')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'A')
    AND eixos_carregados = 5
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Frigorificada ou Aquecida'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'A'),
  6, 'CCD', 'RS_KM', 7.8970
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Frigorificada ou Aquecida')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'A')
    AND eixos_carregados = 6
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Frigorificada ou Aquecida'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'A'),
  7, 'CCD', 'RS_KM', 8.7884
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Frigorificada ou Aquecida')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'A')
    AND eixos_carregados = 7
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Frigorificada ou Aquecida'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'A'),
  9, 'CCD', 'RS_KM', 9.8648
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Frigorificada ou Aquecida')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'A')
    AND eixos_carregados = 9
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Frigorificada ou Aquecida'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'A'),
  2, 'CC', 'RS', 486.21
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Frigorificada ou Aquecida')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'A')
    AND eixos_carregados = 2
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Frigorificada ou Aquecida'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'A'),
  3, 'CC', 'RS', 582.22
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Frigorificada ou Aquecida')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'A')
    AND eixos_carregados = 3
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Frigorificada ou Aquecida'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'A'),
  4, 'CC', 'RS', 662.76
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Frigorificada ou Aquecida')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'A')
    AND eixos_carregados = 4
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Frigorificada ou Aquecida'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'A'),
  5, 'CC', 'RS', 713.06
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Frigorificada ou Aquecida')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'A')
    AND eixos_carregados = 5
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Frigorificada ou Aquecida'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'A'),
  6, 'CC', 'RS', 754.06
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Frigorificada ou Aquecida')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'A')
    AND eixos_carregados = 6
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Frigorificada ou Aquecida'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'A'),
  7, 'CC', 'RS', 932.67
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Frigorificada ou Aquecida')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'A')
    AND eixos_carregados = 7
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Frigorificada ou Aquecida'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'A'),
  9, 'CC', 'RS', 993.46
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Frigorificada ou Aquecida')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'A')
    AND eixos_carregados = 9
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Conteinerizada'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'A'),
  2, 'CCD', 'RS_KM', 4.7626
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Conteinerizada')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'A')
    AND eixos_carregados = 2
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Conteinerizada'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'A'),
  3, 'CCD', 'RS_KM', 5.2867
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Conteinerizada')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'A')
    AND eixos_carregados = 3
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Conteinerizada'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'A'),
  4, 'CCD', 'RS_KM', 5.9579
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Conteinerizada')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'A')
    AND eixos_carregados = 4
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Conteinerizada'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'A'),
  5, 'CCD', 'RS_KM', 6.6621
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Conteinerizada')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'A')
    AND eixos_carregados = 5
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Conteinerizada'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'A'),
  6, 'CCD', 'RS_KM', 7.3528
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Conteinerizada')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'A')
    AND eixos_carregados = 6
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Conteinerizada'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'A'),
  7, 'CCD', 'RS_KM', 8.1922
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Conteinerizada')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'A')
    AND eixos_carregados = 7
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Conteinerizada'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'A'),
  2, 'CC', 'RS', 540.34
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Conteinerizada')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'A')
    AND eixos_carregados = 2
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Conteinerizada'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'A'),
  3, 'CC', 'RS', 547.03
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Conteinerizada')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'A')
    AND eixos_carregados = 3
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Conteinerizada'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'A'),
  4, 'CC', 'RS', 595.41
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Conteinerizada')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'A')
    AND eixos_carregados = 4
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Conteinerizada'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'A'),
  5, 'CC', 'RS', 641.42
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Conteinerizada')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'A')
    AND eixos_carregados = 5
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Conteinerizada'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'A'),
  6, 'CC', 'RS', 764.84
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Conteinerizada')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'A')
    AND eixos_carregados = 6
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Conteinerizada'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'A'),
  7, 'CC', 'RS', 794.47
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Conteinerizada')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'A')
    AND eixos_carregados = 7
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Carga Geral'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'A'),
  2, 'CCD', 'RS_KM', 3.6735
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Carga Geral')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'A')
    AND eixos_carregados = 2
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Carga Geral'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'A'),
  3, 'CCD', 'RS_KM', 4.6502
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Carga Geral')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'A')
    AND eixos_carregados = 3
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Carga Geral'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'A'),
  4, 'CCD', 'RS_KM', 5.3306
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Carga Geral')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'A')
    AND eixos_carregados = 4
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Carga Geral'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'A'),
  5, 'CCD', 'RS_KM', 6.0112
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Carga Geral')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'A')
    AND eixos_carregados = 5
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Carga Geral'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'A'),
  6, 'CCD', 'RS_KM', 6.7301
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Carga Geral')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'A')
    AND eixos_carregados = 6
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Carga Geral'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'A'),
  7, 'CCD', 'RS_KM', 7.3085
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Carga Geral')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'A')
    AND eixos_carregados = 7
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Carga Geral'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'A'),
  9, 'CCD', 'RS_KM', 8.2680
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Carga Geral')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'A')
    AND eixos_carregados = 9
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Carga Geral'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'A'),
  2, 'CC', 'RS', 417.95
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Carga Geral')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'A')
    AND eixos_carregados = 2
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Carga Geral'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'A'),
  3, 'CC', 'RS', 509.43
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Carga Geral')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'A')
    AND eixos_carregados = 3
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Carga Geral'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'A'),
  4, 'CC', 'RS', 559.08
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Carga Geral')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'A')
    AND eixos_carregados = 4
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Carga Geral'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'A'),
  5, 'CC', 'RS', 610.08
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Carga Geral')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'A')
    AND eixos_carregados = 5
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Carga Geral'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'A'),
  6, 'CC', 'RS', 660.12
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Carga Geral')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'A')
    AND eixos_carregados = 6
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Carga Geral'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'A'),
  7, 'CC', 'RS', 752.64
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Carga Geral')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'A')
    AND eixos_carregados = 7
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Carga Geral'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'A'),
  9, 'CC', 'RS', 815.30
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Carga Geral')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'A')
    AND eixos_carregados = 9
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Neogranel'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'A'),
  2, 'CCD', 'RS_KM', 3.3436
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Neogranel')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'A')
    AND eixos_carregados = 2
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Neogranel'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'A'),
  3, 'CCD', 'RS_KM', 4.6495
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Neogranel')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'A')
    AND eixos_carregados = 3
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Neogranel'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'A'),
  4, 'CCD', 'RS_KM', 5.3428
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Neogranel')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'A')
    AND eixos_carregados = 4
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Neogranel'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'A'),
  5, 'CCD', 'RS_KM', 6.0021
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Neogranel')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'A')
    AND eixos_carregados = 5
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Neogranel'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'A'),
  6, 'CCD', 'RS_KM', 6.7230
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Neogranel')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'A')
    AND eixos_carregados = 6
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Neogranel'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'A'),
  7, 'CCD', 'RS_KM', 7.3493
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Neogranel')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'A')
    AND eixos_carregados = 7
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Neogranel'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'A'),
  9, 'CCD', 'RS_KM', 8.2608
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Neogranel')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'A')
    AND eixos_carregados = 9
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Neogranel'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'A'),
  2, 'CC', 'RS', 417.95
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Neogranel')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'A')
    AND eixos_carregados = 2
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Neogranel'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'A'),
  3, 'CC', 'RS', 509.23
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Neogranel')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'A')
    AND eixos_carregados = 3
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Neogranel'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'A'),
  4, 'CC', 'RS', 562.44
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Neogranel')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'A')
    AND eixos_carregados = 4
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Neogranel'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'A'),
  5, 'CC', 'RS', 607.56
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Neogranel')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'A')
    AND eixos_carregados = 5
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Neogranel'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'A'),
  6, 'CC', 'RS', 658.16
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Neogranel')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'A')
    AND eixos_carregados = 6
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Neogranel'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'A'),
  7, 'CC', 'RS', 763.86
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Neogranel')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'A')
    AND eixos_carregados = 7
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Neogranel'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'A'),
  9, 'CC', 'RS', 813.33
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Neogranel')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'A')
    AND eixos_carregados = 9
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (granel sólido)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'A'),
  2, 'CCD', 'RS_KM', 4.4311
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (granel sólido)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'A')
    AND eixos_carregados = 2
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (granel sólido)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'A'),
  3, 'CCD', 'RS_KM', 5.4135
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (granel sólido)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'A')
    AND eixos_carregados = 3
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (granel sólido)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'A'),
  4, 'CCD', 'RS_KM', 6.1264
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (granel sólido)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'A')
    AND eixos_carregados = 4
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (granel sólido)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'A'),
  5, 'CCD', 'RS_KM', 6.8039
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (granel sólido)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'A')
    AND eixos_carregados = 5
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (granel sólido)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'A'),
  6, 'CCD', 'RS_KM', 7.5146
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (granel sólido)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'A')
    AND eixos_carregados = 6
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (granel sólido)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'A'),
  7, 'CCD', 'RS_KM', 8.1156
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (granel sólido)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'A')
    AND eixos_carregados = 7
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (granel sólido)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'A'),
  9, 'CCD', 'RS_KM', 9.0751
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (granel sólido)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'A')
    AND eixos_carregados = 9
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (granel sólido)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'A'),
  2, 'CC', 'RS', 565.59
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (granel sólido)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'A')
    AND eixos_carregados = 2
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (granel sólido)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'A'),
  3, 'CC', 'RS', 658.64
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (granel sólido)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'A')
    AND eixos_carregados = 3
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (granel sólido)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'A'),
  4, 'CC', 'RS', 712.46
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (granel sólido)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'A')
    AND eixos_carregados = 4
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (granel sólido)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'A'),
  5, 'CC', 'RS', 762.59
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (granel sólido)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'A')
    AND eixos_carregados = 5
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (granel sólido)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'A'),
  6, 'CC', 'RS', 810.39
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (granel sólido)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'A')
    AND eixos_carregados = 6
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (granel sólido)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'A'),
  7, 'CC', 'RS', 909.14
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (granel sólido)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'A')
    AND eixos_carregados = 7
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (granel sólido)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'A'),
  9, 'CC', 'RS', 971.80
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (granel sólido)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'A')
    AND eixos_carregados = 9
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (granel líquido)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'A'),
  2, 'CCD', 'RS_KM', 4.5003
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (granel líquido)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'A')
    AND eixos_carregados = 2
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (granel líquido)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'A'),
  3, 'CCD', 'RS_KM', 5.4995
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (granel líquido)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'A')
    AND eixos_carregados = 3
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (granel líquido)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'A'),
  4, 'CCD', 'RS_KM', 6.3232
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (granel líquido)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'A')
    AND eixos_carregados = 4
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (granel líquido)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'A'),
  5, 'CCD', 'RS_KM', 6.9348
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (granel líquido)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'A')
    AND eixos_carregados = 5
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (granel líquido)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'A'),
  6, 'CCD', 'RS_KM', 7.6358
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (granel líquido)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'A')
    AND eixos_carregados = 6
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (granel líquido)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'A'),
  7, 'CCD', 'RS_KM', 8.2559
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (granel líquido)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'A')
    AND eixos_carregados = 7
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (granel líquido)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'A'),
  9, 'CCD', 'RS_KM', 9.2254
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (granel líquido)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'A')
    AND eixos_carregados = 9
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (granel líquido)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'A'),
  2, 'CC', 'RS', 584.61
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (granel líquido)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'A')
    AND eixos_carregados = 2
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (granel líquido)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'A'),
  3, 'CC', 'RS', 682.28
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (granel líquido)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'A')
    AND eixos_carregados = 3
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (granel líquido)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'A'),
  4, 'CC', 'RS', 766.58
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (granel líquido)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'A')
    AND eixos_carregados = 4
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (granel líquido)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'A'),
  5, 'CC', 'RS', 798.58
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (granel líquido)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'A')
    AND eixos_carregados = 5
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (granel líquido)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'A'),
  6, 'CC', 'RS', 843.71
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (granel líquido)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'A')
    AND eixos_carregados = 6
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (granel líquido)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'A'),
  7, 'CC', 'RS', 947.70
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (granel líquido)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'A')
    AND eixos_carregados = 7
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (granel líquido)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'A'),
  9, 'CC', 'RS', 1013.12
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (granel líquido)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'A')
    AND eixos_carregados = 9
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (frigorificada ou aquecida)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'A'),
  2, 'CCD', 'RS_KM', 4.9079
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (frigorificada ou aquecida)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'A')
    AND eixos_carregados = 2
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (frigorificada ou aquecida)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'A'),
  3, 'CCD', 'RS_KM', 6.0255
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (frigorificada ou aquecida)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'A')
    AND eixos_carregados = 3
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (frigorificada ou aquecida)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'A'),
  4, 'CCD', 'RS_KM', 6.9433
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (frigorificada ou aquecida)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'A')
    AND eixos_carregados = 4
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (frigorificada ou aquecida)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'A'),
  5, 'CCD', 'RS_KM', 7.7105
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (frigorificada ou aquecida)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'A')
    AND eixos_carregados = 5
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (frigorificada ou aquecida)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'A'),
  6, 'CCD', 'RS_KM', 8.4977
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (frigorificada ou aquecida)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'A')
    AND eixos_carregados = 6
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (frigorificada ou aquecida)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'A'),
  7, 'CCD', 'RS_KM', 9.4266
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (frigorificada ou aquecida)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'A')
    AND eixos_carregados = 7
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (frigorificada ou aquecida)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'A'),
  9, 'CCD', 'RS_KM', 10.5426
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (frigorificada ou aquecida)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'A')
    AND eixos_carregados = 9
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (frigorificada ou aquecida)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'A'),
  2, 'CC', 'RS', 588.72
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (frigorificada ou aquecida)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'A')
    AND eixos_carregados = 2
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (frigorificada ou aquecida)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'A'),
  3, 'CC', 'RS', 684.73
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (frigorificada ou aquecida)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'A')
    AND eixos_carregados = 3
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (frigorificada ou aquecida)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'A'),
  4, 'CC', 'RS', 776.13
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (frigorificada ou aquecida)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'A')
    AND eixos_carregados = 4
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (frigorificada ou aquecida)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'A'),
  5, 'CC', 'RS', 826.43
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (frigorificada ou aquecida)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'A')
    AND eixos_carregados = 5
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (frigorificada ou aquecida)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'A'),
  6, 'CC', 'RS', 867.42
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (frigorificada ou aquecida)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'A')
    AND eixos_carregados = 6
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (frigorificada ou aquecida)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'A'),
  7, 'CC', 'RS', 1056.35
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (frigorificada ou aquecida)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'A')
    AND eixos_carregados = 7
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (frigorificada ou aquecida)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'A'),
  9, 'CC', 'RS', 1128.02
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (frigorificada ou aquecida)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'A')
    AND eixos_carregados = 9
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (conteinerizada)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'A'),
  2, 'CCD', 'RS_KM', 5.1110
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (conteinerizada)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'A')
    AND eixos_carregados = 2
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (conteinerizada)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'A'),
  3, 'CCD', 'RS_KM', 5.6828
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (conteinerizada)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'A')
    AND eixos_carregados = 3
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (conteinerizada)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'A'),
  4, 'CCD', 'RS_KM', 6.3540
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (conteinerizada)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'A')
    AND eixos_carregados = 4
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (conteinerizada)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'A'),
  5, 'CCD', 'RS_KM', 7.0582
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (conteinerizada)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'A')
    AND eixos_carregados = 5
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (conteinerizada)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'A'),
  6, 'CCD', 'RS_KM', 7.7778
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (conteinerizada)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'A')
    AND eixos_carregados = 6
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (conteinerizada)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'A'),
  7, 'CCD', 'RS_KM', 8.6476
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (conteinerizada)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'A')
    AND eixos_carregados = 7
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (conteinerizada)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'A'),
  2, 'CC', 'RS', 631.35
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (conteinerizada)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'A')
    AND eixos_carregados = 2
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (conteinerizada)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'A'),
  3, 'CC', 'RS', 646.39
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (conteinerizada)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'A')
    AND eixos_carregados = 3
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (conteinerizada)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'A'),
  4, 'CC', 'RS', 694.77
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (conteinerizada)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'A')
    AND eixos_carregados = 4
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (conteinerizada)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'A'),
  5, 'CC', 'RS', 740.78
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (conteinerizada)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'A')
    AND eixos_carregados = 5
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (conteinerizada)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'A'),
  6, 'CC', 'RS', 872.14
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (conteinerizada)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'A')
    AND eixos_carregados = 6
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (conteinerizada)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'A'),
  7, 'CC', 'RS', 910.14
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (conteinerizada)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'A')
    AND eixos_carregados = 7
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (carga geral)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'A'),
  2, 'CCD', 'RS_KM', 4.0218
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (carga geral)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'A')
    AND eixos_carregados = 2
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (carga geral)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'A'),
  3, 'CCD', 'RS_KM', 4.9986
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (carga geral)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'A')
    AND eixos_carregados = 3
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (carga geral)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'A'),
  4, 'CCD', 'RS_KM', 5.7267
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (carga geral)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'A')
    AND eixos_carregados = 4
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (carga geral)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'A'),
  5, 'CCD', 'RS_KM', 6.4073
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (carga geral)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'A')
    AND eixos_carregados = 5
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (carga geral)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'A'),
  6, 'CCD', 'RS_KM', 7.1262
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (carga geral)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'A')
    AND eixos_carregados = 6
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (carga geral)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'A'),
  7, 'CCD', 'RS_KM', 7.7334
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (carga geral)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'A')
    AND eixos_carregados = 7
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (carga geral)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'A'),
  9, 'CCD', 'RS_KM', 8.7233
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (carga geral)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'A')
    AND eixos_carregados = 9
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (carga geral)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'A'),
  2, 'CC', 'RS', 508.96
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (carga geral)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'A')
    AND eixos_carregados = 2
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (carga geral)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'A'),
  3, 'CC', 'RS', 600.44
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (carga geral)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'A')
    AND eixos_carregados = 3
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (carga geral)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'A'),
  4, 'CC', 'RS', 658.44
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (carga geral)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'A')
    AND eixos_carregados = 4
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (carga geral)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'A'),
  5, 'CC', 'RS', 709.44
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (carga geral)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'A')
    AND eixos_carregados = 5
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (carga geral)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'A'),
  6, 'CC', 'RS', 759.49
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (carga geral)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'A')
    AND eixos_carregados = 6
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (carga geral)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'A'),
  7, 'CC', 'RS', 859.94
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (carga geral)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'A')
    AND eixos_carregados = 7
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (carga geral)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'A'),
  9, 'CC', 'RS', 930.97
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (carga geral)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'A')
    AND eixos_carregados = 9
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Carga Granel Pressurizada'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'A'),
  2, 'CCD', 'RS_KM', 6.3124
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Carga Granel Pressurizada')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'A')
    AND eixos_carregados = 2
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Carga Granel Pressurizada'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'A'),
  3, 'CCD', 'RS_KM', 7.0865
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Carga Granel Pressurizada')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'A')
    AND eixos_carregados = 3
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Carga Granel Pressurizada'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'A'),
  4, 'CCD', 'RS_KM', 8.7009
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Carga Granel Pressurizada')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'A')
    AND eixos_carregados = 4
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Carga Granel Pressurizada'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'A'),
  2, 'CC', 'RS', 692.89
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Carga Granel Pressurizada')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'A')
    AND eixos_carregados = 2
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Carga Granel Pressurizada'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'A'),
  3, 'CC', 'RS', 758.14
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Carga Granel Pressurizada')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'A')
    AND eixos_carregados = 3
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Carga Granel Pressurizada'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'A'),
  4, 'CC', 'RS', 934.37
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela A (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Carga Granel Pressurizada')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'A')
    AND eixos_carregados = 4
    AND tipo_coeficiente = 'CC'
);

COMMIT;

-- Seed para TABELA B - OPERAÇÕES EM QUE HAJA A CONTRATAÇÃO APENAS DO VEÍCULO AUTOMOTOR DE CARGAS
BEGIN;

-- Tipo de transporte
INSERT INTO tipos_transporte (codigo, nome)
SELECT 'B', 'TABELA B - OPERAÇÕES EM QUE HAJA A CONTRATAÇÃO APENAS DO VEÍCULO AUTOMOTOR DE CARGAS'
WHERE NOT EXISTS (SELECT 1 FROM tipos_transporte WHERE codigo = 'B');

-- Tipos de carga
INSERT INTO tipos_carga (nome)
SELECT 'Granel sólido'
WHERE NOT EXISTS (SELECT 1 FROM tipos_carga WHERE nome = 'Granel sólido');
INSERT INTO tipos_carga (nome)
SELECT 'Granel líquido'
WHERE NOT EXISTS (SELECT 1 FROM tipos_carga WHERE nome = 'Granel líquido');
INSERT INTO tipos_carga (nome)
SELECT 'Frigorificada ou Aquecida'
WHERE NOT EXISTS (SELECT 1 FROM tipos_carga WHERE nome = 'Frigorificada ou Aquecida');
INSERT INTO tipos_carga (nome)
SELECT 'Conteinerizada'
WHERE NOT EXISTS (SELECT 1 FROM tipos_carga WHERE nome = 'Conteinerizada');
INSERT INTO tipos_carga (nome)
SELECT 'Carga Geral'
WHERE NOT EXISTS (SELECT 1 FROM tipos_carga WHERE nome = 'Carga Geral');
INSERT INTO tipos_carga (nome)
SELECT 'Neogranel'
WHERE NOT EXISTS (SELECT 1 FROM tipos_carga WHERE nome = 'Neogranel');
INSERT INTO tipos_carga (nome)
SELECT 'Perigosa (granel sólido)'
WHERE NOT EXISTS (SELECT 1 FROM tipos_carga WHERE nome = 'Perigosa (granel sólido)');
INSERT INTO tipos_carga (nome)
SELECT 'Perigosa (granel líquido)'
WHERE NOT EXISTS (SELECT 1 FROM tipos_carga WHERE nome = 'Perigosa (granel líquido)');
INSERT INTO tipos_carga (nome)
SELECT 'Perigosa (frigorificada ou aquecida)'
WHERE NOT EXISTS (SELECT 1 FROM tipos_carga WHERE nome = 'Perigosa (frigorificada ou aquecida)');
INSERT INTO tipos_carga (nome)
SELECT 'Perigosa (conteinerizada)'
WHERE NOT EXISTS (SELECT 1 FROM tipos_carga WHERE nome = 'Perigosa (conteinerizada)');
INSERT INTO tipos_carga (nome)
SELECT 'Perigosa (carga geral)'
WHERE NOT EXISTS (SELECT 1 FROM tipos_carga WHERE nome = 'Perigosa (carga geral)');
INSERT INTO tipos_carga (nome)
SELECT 'Carga Granel Pressurizada'
WHERE NOT EXISTS (SELECT 1 FROM tipos_carga WHERE nome = 'Carga Granel Pressurizada');

-- Vigência ANTT
INSERT INTO antt_tabelas (versao_label, vigente_de, fonte_url)
SELECT 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)', DATE '2025-07-17', 'https://anttlegis.antt.gov.br/action/UrlPublicasAction.php?acao=abrirAtoPublico&num_ato=00005867&sgl_tipo=RES&sgl_orgao=DG/ANTT/MI&vlr_ano=2020&seq_ato=000&cod_modulo=161&cod_menu=5408'
WHERE NOT EXISTS (SELECT 1 FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)');

INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Granel sólido'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'B'),
  2, 'CCD', 'RS_KM', 4.7938
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Granel sólido')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'B')
    AND eixos_carregados = 2
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Granel sólido'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'B'),
  3, 'CCD', 'RS_KM', 5.3348
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Granel sólido')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'B')
    AND eixos_carregados = 3
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Granel sólido'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'B'),
  4, 'CCD', 'RS_KM', 6.0208
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Granel sólido')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'B')
    AND eixos_carregados = 4
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Granel sólido'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'B'),
  5, 'CCD', 'RS_KM', 6.3960
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Granel sólido')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'B')
    AND eixos_carregados = 5
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Granel sólido'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'B'),
  6, 'CCD', 'RS_KM', 6.9782
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Granel sólido')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'B')
    AND eixos_carregados = 6
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Granel sólido'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'B'),
  2, 'CC', 'RS', 511.74
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Granel sólido')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'B')
    AND eixos_carregados = 2
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Granel sólido'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'B'),
  3, 'CC', 'RS', 556.92
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Granel sólido')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'B')
    AND eixos_carregados = 3
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Granel sólido'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'B'),
  4, 'CC', 'RS', 597.91
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Granel sólido')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'B')
    AND eixos_carregados = 4
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Granel sólido'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'B'),
  5, 'CC', 'RS', 677.24
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Granel sólido')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'B')
    AND eixos_carregados = 5
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Granel sólido'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'B'),
  6, 'CC', 'RS', 701.32
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Granel sólido')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'B')
    AND eixos_carregados = 6
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Granel líquido'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'B'),
  2, 'CCD', 'RS_KM', 4.8560
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Granel líquido')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'B')
    AND eixos_carregados = 2
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Granel líquido'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'B'),
  3, 'CCD', 'RS_KM', 5.3970
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Granel líquido')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'B')
    AND eixos_carregados = 3
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Granel líquido'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'B'),
  4, 'CCD', 'RS_KM', 6.0829
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Granel líquido')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'B')
    AND eixos_carregados = 4
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Granel líquido'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'B'),
  5, 'CCD', 'RS_KM', 6.4582
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Granel líquido')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'B')
    AND eixos_carregados = 5
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Granel líquido'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'B'),
  6, 'CCD', 'RS_KM', 7.0404
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Granel líquido')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'B')
    AND eixos_carregados = 6
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Granel líquido'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'B'),
  2, 'CC', 'RS', 511.74
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Granel líquido')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'B')
    AND eixos_carregados = 2
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Granel líquido'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'B'),
  3, 'CC', 'RS', 556.92
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Granel líquido')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'B')
    AND eixos_carregados = 3
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Granel líquido'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'B'),
  4, 'CC', 'RS', 597.91
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Granel líquido')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'B')
    AND eixos_carregados = 4
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Granel líquido'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'B'),
  5, 'CC', 'RS', 677.24
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Granel líquido')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'B')
    AND eixos_carregados = 5
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Granel líquido'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'B'),
  6, 'CC', 'RS', 701.32
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Granel líquido')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'B')
    AND eixos_carregados = 6
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Frigorificada ou Aquecida'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'B'),
  2, 'CCD', 'RS_KM', 5.5986
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Frigorificada ou Aquecida')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'B')
    AND eixos_carregados = 2
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Frigorificada ou Aquecida'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'B'),
  3, 'CCD', 'RS_KM', 6.2287
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Frigorificada ou Aquecida')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'B')
    AND eixos_carregados = 3
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Frigorificada ou Aquecida'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'B'),
  4, 'CCD', 'RS_KM', 7.0158
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Frigorificada ou Aquecida')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'B')
    AND eixos_carregados = 4
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Frigorificada ou Aquecida'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'B'),
  5, 'CCD', 'RS_KM', 7.4200
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Frigorificada ou Aquecida')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'B')
    AND eixos_carregados = 5
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Frigorificada ou Aquecida'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'B'),
  6, 'CCD', 'RS_KM', 8.1563
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Frigorificada ou Aquecida')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'B')
    AND eixos_carregados = 6
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Frigorificada ou Aquecida'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'B'),
  2, 'CC', 'RS', 558.42
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Frigorificada ou Aquecida')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'B')
    AND eixos_carregados = 2
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Frigorificada ou Aquecida'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'B'),
  3, 'CC', 'RS', 603.60
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Frigorificada ou Aquecida')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'B')
    AND eixos_carregados = 3
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Frigorificada ou Aquecida'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'B'),
  4, 'CC', 'RS', 644.60
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Frigorificada ou Aquecida')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'B')
    AND eixos_carregados = 4
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Frigorificada ou Aquecida'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'B'),
  5, 'CC', 'RS', 731.86
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Frigorificada ou Aquecida')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'B')
    AND eixos_carregados = 5
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Frigorificada ou Aquecida'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'B'),
  6, 'CC', 'RS', 764.31
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Frigorificada ou Aquecida')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'B')
    AND eixos_carregados = 6
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Conteinerizada'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'B'),
  2, 'CCD', 'RS_KM', 4.7938
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Conteinerizada')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'B')
    AND eixos_carregados = 2
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Conteinerizada'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'B'),
  3, 'CCD', 'RS_KM', 5.3348
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Conteinerizada')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'B')
    AND eixos_carregados = 3
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Conteinerizada'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'B'),
  4, 'CCD', 'RS_KM', 6.0208
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Conteinerizada')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'B')
    AND eixos_carregados = 4
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Conteinerizada'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'B'),
  5, 'CCD', 'RS_KM', 6.3960
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Conteinerizada')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'B')
    AND eixos_carregados = 5
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Conteinerizada'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'B'),
  6, 'CCD', 'RS_KM', 6.9782
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Conteinerizada')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'B')
    AND eixos_carregados = 6
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Conteinerizada'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'B'),
  2, 'CC', 'RS', 511.74
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Conteinerizada')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'B')
    AND eixos_carregados = 2
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Conteinerizada'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'B'),
  3, 'CC', 'RS', 556.92
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Conteinerizada')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'B')
    AND eixos_carregados = 3
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Conteinerizada'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'B'),
  4, 'CC', 'RS', 597.91
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Conteinerizada')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'B')
    AND eixos_carregados = 4
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Conteinerizada'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'B'),
  5, 'CC', 'RS', 677.24
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Conteinerizada')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'B')
    AND eixos_carregados = 5
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Conteinerizada'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'B'),
  6, 'CC', 'RS', 701.32
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Conteinerizada')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'B')
    AND eixos_carregados = 6
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Carga Geral'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'B'),
  2, 'CCD', 'RS_KM', 4.7938
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Carga Geral')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'B')
    AND eixos_carregados = 2
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Carga Geral'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'B'),
  3, 'CCD', 'RS_KM', 5.3348
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Carga Geral')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'B')
    AND eixos_carregados = 3
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Carga Geral'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'B'),
  4, 'CCD', 'RS_KM', 6.0208
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Carga Geral')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'B')
    AND eixos_carregados = 4
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Carga Geral'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'B'),
  5, 'CCD', 'RS_KM', 6.3960
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Carga Geral')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'B')
    AND eixos_carregados = 5
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Carga Geral'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'B'),
  6, 'CCD', 'RS_KM', 6.9782
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Carga Geral')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'B')
    AND eixos_carregados = 6
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Carga Geral'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'B'),
  2, 'CC', 'RS', 511.74
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Carga Geral')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'B')
    AND eixos_carregados = 2
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Carga Geral'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'B'),
  3, 'CC', 'RS', 556.92
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Carga Geral')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'B')
    AND eixos_carregados = 3
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Carga Geral'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'B'),
  4, 'CC', 'RS', 597.91
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Carga Geral')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'B')
    AND eixos_carregados = 4
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Carga Geral'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'B'),
  5, 'CC', 'RS', 677.24
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Carga Geral')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'B')
    AND eixos_carregados = 5
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Carga Geral'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'B'),
  6, 'CC', 'RS', 701.32
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Carga Geral')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'B')
    AND eixos_carregados = 6
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Neogranel'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'B'),
  2, 'CCD', 'RS_KM', 4.7938
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Neogranel')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'B')
    AND eixos_carregados = 2
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Neogranel'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'B'),
  3, 'CCD', 'RS_KM', 5.3348
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Neogranel')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'B')
    AND eixos_carregados = 3
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Neogranel'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'B'),
  4, 'CCD', 'RS_KM', 6.0208
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Neogranel')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'B')
    AND eixos_carregados = 4
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Neogranel'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'B'),
  5, 'CCD', 'RS_KM', 6.3960
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Neogranel')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'B')
    AND eixos_carregados = 5
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Neogranel'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'B'),
  6, 'CCD', 'RS_KM', 6.9782
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Neogranel')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'B')
    AND eixos_carregados = 6
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Neogranel'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'B'),
  2, 'CC', 'RS', 511.74
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Neogranel')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'B')
    AND eixos_carregados = 2
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Neogranel'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'B'),
  3, 'CC', 'RS', 556.92
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Neogranel')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'B')
    AND eixos_carregados = 3
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Neogranel'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'B'),
  4, 'CC', 'RS', 597.91
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Neogranel')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'B')
    AND eixos_carregados = 4
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Neogranel'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'B'),
  5, 'CC', 'RS', 677.24
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Neogranel')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'B')
    AND eixos_carregados = 5
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Neogranel'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'B'),
  6, 'CC', 'RS', 701.32
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Neogranel')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'B')
    AND eixos_carregados = 6
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (granel sólido)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'B'),
  2, 'CCD', 'RS_KM', 5.5676
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (granel sólido)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'B')
    AND eixos_carregados = 2
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (granel sólido)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'B'),
  3, 'CCD', 'RS_KM', 6.1086
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (granel sólido)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'B')
    AND eixos_carregados = 3
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (granel sólido)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'B'),
  4, 'CCD', 'RS_KM', 6.7946
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (granel sólido)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'B')
    AND eixos_carregados = 4
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (granel sólido)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'B'),
  5, 'CCD', 'RS_KM', 7.1987
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (granel sólido)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'B')
    AND eixos_carregados = 5
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (granel sólido)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'B'),
  6, 'CCD', 'RS_KM', 7.8113
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (granel sólido)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'B')
    AND eixos_carregados = 6
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (granel sólido)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'B'),
  2, 'CC', 'RS', 659.06
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (granel sólido)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'B')
    AND eixos_carregados = 2
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (granel sólido)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'B'),
  3, 'CC', 'RS', 704.25
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (granel sólido)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'B')
    AND eixos_carregados = 3
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (granel sólido)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'B'),
  4, 'CC', 'RS', 745.24
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (granel sólido)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'B')
    AND eixos_carregados = 4
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (granel sólido)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'B'),
  5, 'CC', 'RS', 832.50
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (granel sólido)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'B')
    AND eixos_carregados = 5
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (granel sólido)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'B'),
  6, 'CC', 'RS', 864.95
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (granel sólido)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'B')
    AND eixos_carregados = 6
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (granel líquido)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'B'),
  2, 'CCD', 'RS_KM', 5.6107
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (granel líquido)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'B')
    AND eixos_carregados = 2
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (granel líquido)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'B'),
  3, 'CCD', 'RS_KM', 6.1517
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (granel líquido)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'B')
    AND eixos_carregados = 3
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (granel líquido)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'B'),
  4, 'CCD', 'RS_KM', 6.8376
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (granel líquido)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'B')
    AND eixos_carregados = 4
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (granel líquido)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'B'),
  5, 'CCD', 'RS_KM', 7.2418
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (granel líquido)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'B')
    AND eixos_carregados = 5
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (granel líquido)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'B'),
  6, 'CCD', 'RS_KM', 7.8544
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (granel líquido)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'B')
    AND eixos_carregados = 6
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (granel líquido)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'B'),
  2, 'CC', 'RS', 670.91
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (granel líquido)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'B')
    AND eixos_carregados = 2
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (granel líquido)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'B'),
  3, 'CC', 'RS', 716.09
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (granel líquido)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'B')
    AND eixos_carregados = 3
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (granel líquido)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'B'),
  4, 'CC', 'RS', 757.08
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (granel líquido)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'B')
    AND eixos_carregados = 4
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (granel líquido)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'B'),
  5, 'CC', 'RS', 844.35
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (granel líquido)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'B')
    AND eixos_carregados = 5
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (granel líquido)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'B'),
  6, 'CC', 'RS', 876.79
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (granel líquido)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'B')
    AND eixos_carregados = 6
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (frigorificada ou aquecida)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'B'),
  2, 'CCD', 'RS_KM', 6.1993
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (frigorificada ou aquecida)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'B')
    AND eixos_carregados = 2
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (frigorificada ou aquecida)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'B'),
  3, 'CCD', 'RS_KM', 6.8294
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (frigorificada ou aquecida)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'B')
    AND eixos_carregados = 3
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (frigorificada ou aquecida)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'B'),
  4, 'CCD', 'RS_KM', 7.6165
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (frigorificada ou aquecida)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'B')
    AND eixos_carregados = 4
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (frigorificada ou aquecida)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'B'),
  5, 'CCD', 'RS_KM', 8.0582
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (frigorificada ou aquecida)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'B')
    AND eixos_carregados = 5
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (frigorificada ou aquecida)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'B'),
  6, 'CCD', 'RS_KM', 8.8340
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (frigorificada ou aquecida)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'B')
    AND eixos_carregados = 6
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (frigorificada ou aquecida)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'B'),
  2, 'CC', 'RS', 671.79
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (frigorificada ou aquecida)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'B')
    AND eixos_carregados = 2
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (frigorificada ou aquecida)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'B'),
  3, 'CC', 'RS', 716.97
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (frigorificada ou aquecida)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'B')
    AND eixos_carregados = 3
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (frigorificada ou aquecida)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'B'),
  4, 'CC', 'RS', 757.96
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (frigorificada ou aquecida)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'B')
    AND eixos_carregados = 4
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (frigorificada ou aquecida)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'B'),
  5, 'CC', 'RS', 855.55
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (frigorificada ou aquecida)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'B')
    AND eixos_carregados = 5
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (frigorificada ou aquecida)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'B'),
  6, 'CC', 'RS', 898.87
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (frigorificada ou aquecida)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'B')
    AND eixos_carregados = 6
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (conteinerizada)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'B'),
  2, 'CCD', 'RS_KM', 5.1899
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (conteinerizada)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'B')
    AND eixos_carregados = 2
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (conteinerizada)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'B'),
  3, 'CCD', 'RS_KM', 5.7309
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (conteinerizada)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'B')
    AND eixos_carregados = 3
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (conteinerizada)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'B'),
  4, 'CCD', 'RS_KM', 6.4168
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (conteinerizada)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'B')
    AND eixos_carregados = 4
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (conteinerizada)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'B'),
  5, 'CCD', 'RS_KM', 6.8210
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (conteinerizada)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'B')
    AND eixos_carregados = 5
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (conteinerizada)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'B'),
  6, 'CCD', 'RS_KM', 7.4336
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (conteinerizada)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'B')
    AND eixos_carregados = 6
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (conteinerizada)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'B'),
  2, 'CC', 'RS', 611.10
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (conteinerizada)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'B')
    AND eixos_carregados = 2
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (conteinerizada)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'B'),
  3, 'CC', 'RS', 656.28
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (conteinerizada)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'B')
    AND eixos_carregados = 3
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (conteinerizada)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'B'),
  4, 'CC', 'RS', 697.28
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (conteinerizada)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'B')
    AND eixos_carregados = 4
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (conteinerizada)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'B'),
  5, 'CC', 'RS', 784.54
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (conteinerizada)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'B')
    AND eixos_carregados = 5
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (conteinerizada)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'B'),
  6, 'CC', 'RS', 816.98
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (conteinerizada)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'B')
    AND eixos_carregados = 6
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (carga geral)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'B'),
  2, 'CCD', 'RS_KM', 5.1899
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (carga geral)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'B')
    AND eixos_carregados = 2
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (carga geral)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'B'),
  3, 'CCD', 'RS_KM', 5.7309
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (carga geral)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'B')
    AND eixos_carregados = 3
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (carga geral)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'B'),
  4, 'CCD', 'RS_KM', 6.4168
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (carga geral)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'B')
    AND eixos_carregados = 4
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (carga geral)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'B'),
  5, 'CCD', 'RS_KM', 6.8210
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (carga geral)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'B')
    AND eixos_carregados = 5
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (carga geral)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'B'),
  6, 'CCD', 'RS_KM', 7.4336
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (carga geral)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'B')
    AND eixos_carregados = 6
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (carga geral)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'B'),
  2, 'CC', 'RS', 611.10
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (carga geral)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'B')
    AND eixos_carregados = 2
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (carga geral)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'B'),
  3, 'CC', 'RS', 656.28
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (carga geral)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'B')
    AND eixos_carregados = 3
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (carga geral)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'B'),
  4, 'CC', 'RS', 697.28
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (carga geral)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'B')
    AND eixos_carregados = 4
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (carga geral)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'B'),
  5, 'CC', 'RS', 784.54
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (carga geral)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'B')
    AND eixos_carregados = 5
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (carga geral)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'B'),
  6, 'CC', 'RS', 816.98
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (carga geral)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'B')
    AND eixos_carregados = 6
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Carga Granel Pressurizada'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'B'),
  2, 'CCD', 'RS_KM', 5.3348
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Carga Granel Pressurizada')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'B')
    AND eixos_carregados = 2
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Carga Granel Pressurizada'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'B'),
  3, 'CCD', 'RS_KM', 6.0208
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Carga Granel Pressurizada')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'B')
    AND eixos_carregados = 3
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Carga Granel Pressurizada'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'B'),
  4, 'CCD', 'RS_KM', 6.9782
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Carga Granel Pressurizada')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'B')
    AND eixos_carregados = 4
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Carga Granel Pressurizada'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'B'),
  2, 'CC', 'RS', 556.92
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Carga Granel Pressurizada')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'B')
    AND eixos_carregados = 2
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Carga Granel Pressurizada'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'B'),
  3, 'CC', 'RS', 597.91
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Carga Granel Pressurizada')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'B')
    AND eixos_carregados = 3
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Carga Granel Pressurizada'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'B'),
  4, 'CC', 'RS', 701.32
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela B (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Carga Granel Pressurizada')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'B')
    AND eixos_carregados = 4
    AND tipo_coeficiente = 'CC'
);

COMMIT;

-- Seed para TABELA C - TRANSPORTE RODOVIÁRIO DE CARGA LOTAÇÃO DE ALTO DESEMPENHO
BEGIN;

-- Tipo de transporte
INSERT INTO tipos_transporte (codigo, nome)
SELECT 'C', 'TABELA C - TRANSPORTE RODOVIÁRIO DE CARGA LOTAÇÃO DE ALTO DESEMPENHO'
WHERE NOT EXISTS (SELECT 1 FROM tipos_transporte WHERE codigo = 'C');

-- Tipos de carga
INSERT INTO tipos_carga (nome)
SELECT 'Granel sólido'
WHERE NOT EXISTS (SELECT 1 FROM tipos_carga WHERE nome = 'Granel sólido');
INSERT INTO tipos_carga (nome)
SELECT 'Granel líquido'
WHERE NOT EXISTS (SELECT 1 FROM tipos_carga WHERE nome = 'Granel líquido');
INSERT INTO tipos_carga (nome)
SELECT 'Frigorificada ou Aquecida'
WHERE NOT EXISTS (SELECT 1 FROM tipos_carga WHERE nome = 'Frigorificada ou Aquecida');
INSERT INTO tipos_carga (nome)
SELECT 'Conteinerizada'
WHERE NOT EXISTS (SELECT 1 FROM tipos_carga WHERE nome = 'Conteinerizada');
INSERT INTO tipos_carga (nome)
SELECT 'Carga Geral'
WHERE NOT EXISTS (SELECT 1 FROM tipos_carga WHERE nome = 'Carga Geral');
INSERT INTO tipos_carga (nome)
SELECT 'Neogranel'
WHERE NOT EXISTS (SELECT 1 FROM tipos_carga WHERE nome = 'Neogranel');
INSERT INTO tipos_carga (nome)
SELECT 'Perigosa (granel sólido)'
WHERE NOT EXISTS (SELECT 1 FROM tipos_carga WHERE nome = 'Perigosa (granel sólido)');
INSERT INTO tipos_carga (nome)
SELECT 'Perigosa (granel líquido)'
WHERE NOT EXISTS (SELECT 1 FROM tipos_carga WHERE nome = 'Perigosa (granel líquido)');
INSERT INTO tipos_carga (nome)
SELECT 'Perigosa (frigorificada ou aquecida)'
WHERE NOT EXISTS (SELECT 1 FROM tipos_carga WHERE nome = 'Perigosa (frigorificada ou aquecida)');
INSERT INTO tipos_carga (nome)
SELECT 'Perigosa (conteinerizada)'
WHERE NOT EXISTS (SELECT 1 FROM tipos_carga WHERE nome = 'Perigosa (conteinerizada)');
INSERT INTO tipos_carga (nome)
SELECT 'Perigosa (carga geral)'
WHERE NOT EXISTS (SELECT 1 FROM tipos_carga WHERE nome = 'Perigosa (carga geral)');
INSERT INTO tipos_carga (nome)
SELECT 'Carga Granel Pressurizada'
WHERE NOT EXISTS (SELECT 1 FROM tipos_carga WHERE nome = 'Carga Granel Pressurizada');

-- Vigência ANTT
INSERT INTO antt_tabelas (versao_label, vigente_de, fonte_url)
SELECT 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)', DATE '2025-07-17', 'https://anttlegis.antt.gov.br/action/UrlPublicasAction.php?acao=abrirAtoPublico&num_ato=00005867&sgl_tipo=RES&sgl_orgao=DG/ANTT/MI&vlr_ano=2020&seq_ato=000&cod_modulo=161&cod_menu=5408'
WHERE NOT EXISTS (SELECT 1 FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)');

INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Granel sólido'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'C'),
  2, 'CCD', 'RS_KM', 3.1236
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Granel sólido')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'C')
    AND eixos_carregados = 2
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Granel sólido'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'C'),
  3, 'CCD', 'RS_KM', 3.8892
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Granel sólido')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'C')
    AND eixos_carregados = 3
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Granel sólido'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'C'),
  4, 'CCD', 'RS_KM', 4.5210
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Granel sólido')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'C')
    AND eixos_carregados = 4
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Granel sólido'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'C'),
  5, 'CCD', 'RS_KM', 5.0817
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Granel sólido')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'C')
    AND eixos_carregados = 5
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Granel sólido'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'C'),
  6, 'CCD', 'RS_KM', 5.6810
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Granel sólido')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'C')
    AND eixos_carregados = 6
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Granel sólido'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'C'),
  7, 'CCD', 'RS_KM', 6.1106
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Granel sólido')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'C')
    AND eixos_carregados = 7
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Granel sólido'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'C'),
  9, 'CCD', 'RS_KM', 6.9860
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Granel sólido')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'C')
    AND eixos_carregados = 9
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Granel sólido'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'C'),
  2, 'CC', 'RS', 160.03
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Granel sólido')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'C')
    AND eixos_carregados = 2
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Granel sólido'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'C'),
  3, 'CC', 'RS', 180.08
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Granel sólido')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'C')
    AND eixos_carregados = 3
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Granel sólido'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'C'),
  4, 'CC', 'RS', 201.87
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Granel sólido')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'C')
    AND eixos_carregados = 4
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Granel sólido'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'C'),
  5, 'CC', 'RS', 212.67
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Granel sólido')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'C')
    AND eixos_carregados = 5
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Granel sólido'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'C'),
  6, 'CC', 'RS', 222.97
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Granel sólido')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'C')
    AND eixos_carregados = 6
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Granel sólido'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'C'),
  7, 'CC', 'RS', 253.94
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Granel sólido')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'C')
    AND eixos_carregados = 7
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Granel sólido'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'C'),
  9, 'CC', 'RS', 277.66
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Granel sólido')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'C')
    AND eixos_carregados = 9
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Granel líquido'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'C'),
  2, 'CCD', 'RS_KM', 3.1640
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Granel líquido')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'C')
    AND eixos_carregados = 2
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Granel líquido'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'C'),
  3, 'CCD', 'RS_KM', 3.9357
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Granel líquido')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'C')
    AND eixos_carregados = 3
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Granel líquido'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'C'),
  4, 'CCD', 'RS_KM', 4.6384
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Granel líquido')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'C')
    AND eixos_carregados = 4
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Granel líquido'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'C'),
  5, 'CCD', 'RS_KM', 5.1754
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Granel líquido')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'C')
    AND eixos_carregados = 5
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Granel líquido'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'C'),
  6, 'CCD', 'RS_KM', 5.7712
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Granel líquido')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'C')
    AND eixos_carregados = 6
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Granel líquido'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'C'),
  7, 'CCD', 'RS_KM', 6.2077
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Granel líquido')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'C')
    AND eixos_carregados = 7
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Granel líquido'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'C'),
  9, 'CCD', 'RS_KM', 7.0867
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Granel líquido')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'C')
    AND eixos_carregados = 9
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Granel líquido'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'C'),
  2, 'CC', 'RS', 161.57
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Granel líquido')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'C')
    AND eixos_carregados = 2
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Granel líquido'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'C'),
  3, 'CC', 'RS', 182.62
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Granel líquido')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'C')
    AND eixos_carregados = 3
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Granel líquido'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'C'),
  4, 'CC', 'RS', 210.98
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Granel líquido')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'C')
    AND eixos_carregados = 4
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Granel líquido'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'C'),
  5, 'CC', 'RS', 217.87
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Granel líquido')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'C')
    AND eixos_carregados = 5
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Granel líquido'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'C'),
  6, 'CC', 'RS', 227.59
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Granel líquido')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'C')
    AND eixos_carregados = 6
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Granel líquido'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'C'),
  7, 'CC', 'RS', 259.70
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Granel líquido')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'C')
    AND eixos_carregados = 7
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Granel líquido'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'C'),
  9, 'CC', 'RS', 284.01
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Granel líquido')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'C')
    AND eixos_carregados = 9
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Frigorificada ou Aquecida'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'C'),
  2, 'CCD', 'RS_KM', 3.7191
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Frigorificada ou Aquecida')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'C')
    AND eixos_carregados = 2
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Frigorificada ou Aquecida'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'C'),
  3, 'CCD', 'RS_KM', 4.6129
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Frigorificada ou Aquecida')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'C')
    AND eixos_carregados = 3
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Frigorificada ou Aquecida'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'C'),
  4, 'CCD', 'RS_KM', 5.4055
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Frigorificada ou Aquecida')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'C')
    AND eixos_carregados = 4
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Frigorificada ou Aquecida'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'C'),
  5, 'CCD', 'RS_KM', 6.0555
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Frigorificada ou Aquecida')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'C')
    AND eixos_carregados = 5
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Frigorificada ou Aquecida'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'C'),
  6, 'CCD', 'RS_KM', 6.7471
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Frigorificada ou Aquecida')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'C')
    AND eixos_carregados = 6
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Frigorificada ou Aquecida'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'C'),
  7, 'CCD', 'RS_KM', 7.3121
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Frigorificada ou Aquecida')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'C')
    AND eixos_carregados = 7
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Frigorificada ou Aquecida'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'C'),
  9, 'CCD', 'RS_KM', 8.3415
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Frigorificada ou Aquecida')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'C')
    AND eixos_carregados = 9
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Frigorificada ou Aquecida'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'C'),
  2, 'CC', 'RS', 189.39
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Frigorificada ou Aquecida')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'C')
    AND eixos_carregados = 2
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Frigorificada ou Aquecida'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'C'),
  3, 'CC', 'RS', 210.08
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Frigorificada ou Aquecida')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'C')
    AND eixos_carregados = 3
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Frigorificada ou Aquecida'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'C'),
  4, 'CC', 'RS', 243.02
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Frigorificada ou Aquecida')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'C')
    AND eixos_carregados = 4
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Frigorificada ou Aquecida'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'C'),
  5, 'CC', 'RS', 253.86
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Frigorificada ou Aquecida')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'C')
    AND eixos_carregados = 5
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Frigorificada ou Aquecida'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'C'),
  6, 'CC', 'RS', 262.69
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Frigorificada ou Aquecida')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'C')
    AND eixos_carregados = 6
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Frigorificada ou Aquecida'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'C'),
  7, 'CC', 'RS', 316.01
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Frigorificada ou Aquecida')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'C')
    AND eixos_carregados = 7
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Frigorificada ou Aquecida'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'C'),
  9, 'CC', 'RS', 344.73
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Frigorificada ou Aquecida')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'C')
    AND eixos_carregados = 9
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Conteinerizada'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'C'),
  2, 'CCD', 'RS_KM', 3.9162
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Conteinerizada')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'C')
    AND eixos_carregados = 2
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Conteinerizada'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'C'),
  3, 'CCD', 'RS_KM', 4.4973
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Conteinerizada')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'C')
    AND eixos_carregados = 3
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Conteinerizada'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'C'),
  4, 'CCD', 'RS_KM', 5.0557
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Conteinerizada')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'C')
    AND eixos_carregados = 4
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Conteinerizada'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'C'),
  5, 'CCD', 'RS_KM', 5.6527
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Conteinerizada')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'C')
    AND eixos_carregados = 5
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Conteinerizada'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'C'),
  6, 'CCD', 'RS_KM', 6.1249
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Conteinerizada')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'C')
    AND eixos_carregados = 6
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Conteinerizada'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'C'),
  7, 'CCD', 'RS_KM', 6.9681
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Conteinerizada')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'C')
    AND eixos_carregados = 7
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Conteinerizada'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'C'),
  2, 'CC', 'RS', 184.53
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Conteinerizada')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'C')
    AND eixos_carregados = 2
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Conteinerizada'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'C'),
  3, 'CC', 'RS', 197.96
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Conteinerizada')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'C')
    AND eixos_carregados = 3
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Conteinerizada'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'C'),
  4, 'CC', 'RS', 208.39
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Conteinerizada')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'C')
    AND eixos_carregados = 4
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Conteinerizada'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'C'),
  5, 'CC', 'RS', 218.30
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Conteinerizada')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'C')
    AND eixos_carregados = 5
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Conteinerizada'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'C'),
  6, 'CC', 'RS', 256.30
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Conteinerizada')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'C')
    AND eixos_carregados = 6
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Conteinerizada'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'C'),
  7, 'CC', 'RS', 274.71
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Conteinerizada')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'C')
    AND eixos_carregados = 7
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Carga Geral'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'C'),
  2, 'CCD', 'RS_KM', 3.1122
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Carga Geral')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'C')
    AND eixos_carregados = 2
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Carga Geral'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'C'),
  3, 'CCD', 'RS_KM', 3.8758
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Carga Geral')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'C')
    AND eixos_carregados = 3
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Carga Geral'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'C'),
  4, 'CCD', 'RS_KM', 4.5131
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Carga Geral')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'C')
    AND eixos_carregados = 4
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Carga Geral'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'C'),
  5, 'CCD', 'RS_KM', 5.0749
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Carga Geral')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'C')
    AND eixos_carregados = 5
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Carga Geral'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'C'),
  6, 'CCD', 'RS_KM', 5.6771
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Carga Geral')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'C')
    AND eixos_carregados = 6
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Carga Geral'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'C'),
  7, 'CCD', 'RS_KM', 6.1090
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Carga Geral')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'C')
    AND eixos_carregados = 7
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Carga Geral'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'C'),
  9, 'CCD', 'RS_KM', 6.9953
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Carga Geral')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'C')
    AND eixos_carregados = 9
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Carga Geral'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'C'),
  2, 'CC', 'RS', 158.16
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Carga Geral')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'C')
    AND eixos_carregados = 2
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Carga Geral'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'C'),
  3, 'CC', 'RS', 177.87
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Carga Geral')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'C')
    AND eixos_carregados = 3
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Carga Geral'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'C'),
  4, 'CC', 'RS', 200.56
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Carga Geral')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'C')
    AND eixos_carregados = 4
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Carga Geral'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'C'),
  5, 'CC', 'RS', 211.55
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Carga Geral')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'C')
    AND eixos_carregados = 5
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Carga Geral'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'C'),
  6, 'CC', 'RS', 222.33
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Carga Geral')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'C')
    AND eixos_carregados = 6
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Carga Geral'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'C'),
  7, 'CC', 'RS', 253.67
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Carga Geral')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'C')
    AND eixos_carregados = 7
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Carga Geral'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'C'),
  9, 'CC', 'RS', 279.20
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Carga Geral')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'C')
    AND eixos_carregados = 9
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Neogranel'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'C'),
  2, 'CCD', 'RS_KM', 2.7823
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Neogranel')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'C')
    AND eixos_carregados = 2
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Neogranel'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'C'),
  3, 'CCD', 'RS_KM', 3.8755
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Neogranel')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'C')
    AND eixos_carregados = 3
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Neogranel'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'C'),
  4, 'CCD', 'RS_KM', 4.5175
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Neogranel')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'C')
    AND eixos_carregados = 4
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Neogranel'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'C'),
  5, 'CCD', 'RS_KM', 5.0716
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Neogranel')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'C')
    AND eixos_carregados = 5
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Neogranel'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'C'),
  6, 'CCD', 'RS_KM', 5.6746
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Neogranel')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'C')
    AND eixos_carregados = 6
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Neogranel'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'C'),
  7, 'CCD', 'RS_KM', 6.1237
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Neogranel')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'C')
    AND eixos_carregados = 7
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Neogranel'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'C'),
  9, 'CCD', 'RS_KM', 6.9928
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Neogranel')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'C')
    AND eixos_carregados = 9
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Neogranel'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'C'),
  2, 'CC', 'RS', 158.16
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Neogranel')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'C')
    AND eixos_carregados = 2
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Neogranel'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'C'),
  3, 'CC', 'RS', 177.83
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Neogranel')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'C')
    AND eixos_carregados = 3
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Neogranel'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'C'),
  4, 'CC', 'RS', 201.29
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Neogranel')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'C')
    AND eixos_carregados = 4
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Neogranel'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'C'),
  5, 'CC', 'RS', 211.01
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Neogranel')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'C')
    AND eixos_carregados = 5
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Neogranel'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'C'),
  6, 'CC', 'RS', 221.91
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Neogranel')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'C')
    AND eixos_carregados = 6
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Neogranel'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'C'),
  7, 'CC', 'RS', 256.09
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Neogranel')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'C')
    AND eixos_carregados = 7
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Neogranel'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'C'),
  9, 'CC', 'RS', 278.77
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Neogranel')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'C')
    AND eixos_carregados = 9
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (granel sólido)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'C'),
  2, 'CCD', 'RS_KM', 3.6259
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (granel sólido)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'C')
    AND eixos_carregados = 2
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (granel sólido)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'C'),
  3, 'CCD', 'RS_KM', 4.3915
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (granel sólido)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'C')
    AND eixos_carregados = 3
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (granel sólido)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'C'),
  4, 'CCD', 'RS_KM', 5.0734
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (granel sólido)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'C')
    AND eixos_carregados = 4
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (granel sólido)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'C'),
  5, 'CCD', 'RS_KM', 5.6341
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (granel sólido)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'C')
    AND eixos_carregados = 5
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (granel sólido)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'C'),
  6, 'CCD', 'RS_KM', 6.2334
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (granel sólido)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'C')
    AND eixos_carregados = 6
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (granel sólido)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'C'),
  7, 'CCD', 'RS_KM', 6.6941
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (granel sólido)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'C')
    AND eixos_carregados = 7
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (granel sólido)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'C'),
  9, 'CCD', 'RS_KM', 7.6023
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (granel sólido)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'C')
    AND eixos_carregados = 9
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (granel sólido)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'C'),
  2, 'CC', 'RS', 206.49
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (granel sólido)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'C')
    AND eixos_carregados = 2
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (granel sólido)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'C'),
  3, 'CC', 'RS', 226.55
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (granel sólido)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'C')
    AND eixos_carregados = 3
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (granel sólido)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'C'),
  4, 'CC', 'RS', 253.73
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (granel sólido)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'C')
    AND eixos_carregados = 4
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (granel sólido)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'C'),
  5, 'CC', 'RS', 264.53
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (granel sólido)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'C')
    AND eixos_carregados = 5
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (granel sólido)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'C'),
  6, 'CC', 'RS', 274.83
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (granel sólido)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'C')
    AND eixos_carregados = 6
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (granel sólido)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'C'),
  7, 'CC', 'RS', 310.94
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (granel sólido)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'C')
    AND eixos_carregados = 7
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (granel sólido)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'C'),
  9, 'CC', 'RS', 340.06
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (granel sólido)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'C')
    AND eixos_carregados = 9
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (granel líquido)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'C'),
  2, 'CCD', 'RS_KM', 3.6507
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (granel líquido)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'C')
    AND eixos_carregados = 2
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (granel líquido)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'C'),
  3, 'CCD', 'RS_KM', 4.4224
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (granel líquido)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'C')
    AND eixos_carregados = 3
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (granel líquido)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'C'),
  4, 'CCD', 'RS_KM', 5.1441
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (granel líquido)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'C')
    AND eixos_carregados = 4
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (granel líquido)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'C'),
  5, 'CCD', 'RS_KM', 5.6811
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (granel líquido)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'C')
    AND eixos_carregados = 5
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (granel líquido)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'C'),
  6, 'CCD', 'RS_KM', 6.2769
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (granel líquido)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'C')
    AND eixos_carregados = 6
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (granel líquido)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'C'),
  7, 'CCD', 'RS_KM', 6.7445
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (granel líquido)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'C')
    AND eixos_carregados = 7
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (granel líquido)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'C'),
  9, 'CCD', 'RS_KM', 7.6563
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (granel líquido)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'C')
    AND eixos_carregados = 9
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (granel líquido)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'C'),
  2, 'CC', 'RS', 210.59
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (granel líquido)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'C')
    AND eixos_carregados = 2
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (granel líquido)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'C'),
  3, 'CC', 'RS', 231.64
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (granel líquido)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'C')
    AND eixos_carregados = 3
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (granel líquido)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'C'),
  4, 'CC', 'RS', 265.39
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (granel líquido)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'C')
    AND eixos_carregados = 4
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (granel líquido)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'C'),
  5, 'CC', 'RS', 272.29
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (granel líquido)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'C')
    AND eixos_carregados = 5
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (granel líquido)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'C'),
  6, 'CC', 'RS', 282.01
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (granel líquido)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'C')
    AND eixos_carregados = 6
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (granel líquido)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'C'),
  7, 'CC', 'RS', 319.25
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (granel líquido)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'C')
    AND eixos_carregados = 7
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (granel líquido)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'C'),
  9, 'CC', 'RS', 348.97
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (granel líquido)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'C')
    AND eixos_carregados = 9
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (frigorificada ou aquecida)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'C'),
  2, 'CCD', 'RS_KM', 4.1790
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (frigorificada ou aquecida)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'C')
    AND eixos_carregados = 2
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (frigorificada ou aquecida)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'C'),
  3, 'CCD', 'RS_KM', 5.0728
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (frigorificada ou aquecida)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'C')
    AND eixos_carregados = 3
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (frigorificada ou aquecida)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'C'),
  4, 'CCD', 'RS_KM', 5.9005
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (frigorificada ou aquecida)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'C')
    AND eixos_carregados = 4
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (frigorificada ou aquecida)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'C'),
  5, 'CCD', 'RS_KM', 6.5504
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (frigorificada ou aquecida)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'C')
    AND eixos_carregados = 5
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (frigorificada ou aquecida)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'C'),
  6, 'CCD', 'RS_KM', 7.2420
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (frigorificada ou aquecida)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'C')
    AND eixos_carregados = 6
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (frigorificada ou aquecida)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'C'),
  7, 'CCD', 'RS_KM', 7.8475
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (frigorificada ou aquecida)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'C')
    AND eixos_carregados = 7
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (frigorificada ou aquecida)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'C'),
  9, 'CCD', 'RS_KM', 8.9195
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (frigorificada ou aquecida)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'C')
    AND eixos_carregados = 9
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (frigorificada ou aquecida)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'C'),
  2, 'CC', 'RS', 232.96
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (frigorificada ou aquecida)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'C')
    AND eixos_carregados = 2
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (frigorificada ou aquecida)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'C'),
  3, 'CC', 'RS', 253.64
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (frigorificada ou aquecida)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'C')
    AND eixos_carregados = 3
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (frigorificada ou aquecida)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'C'),
  4, 'CC', 'RS', 293.60
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (frigorificada ou aquecida)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'C')
    AND eixos_carregados = 4
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (frigorificada ou aquecida)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'C'),
  5, 'CC', 'RS', 304.44
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (frigorificada ou aquecida)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'C')
    AND eixos_carregados = 5
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (frigorificada ou aquecida)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'C'),
  6, 'CC', 'RS', 313.27
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (frigorificada ou aquecida)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'C')
    AND eixos_carregados = 6
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (frigorificada ou aquecida)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'C'),
  7, 'CC', 'RS', 373.26
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (frigorificada ou aquecida)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'C')
    AND eixos_carregados = 7
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (frigorificada ou aquecida)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'C'),
  9, 'CC', 'RS', 409.02
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (frigorificada ou aquecida)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'C')
    AND eixos_carregados = 9
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (conteinerizada)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'C'),
  2, 'CCD', 'RS_KM', 4.1525
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (conteinerizada)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'C')
    AND eixos_carregados = 2
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (conteinerizada)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'C'),
  3, 'CCD', 'RS_KM', 4.7838
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (conteinerizada)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'C')
    AND eixos_carregados = 3
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (conteinerizada)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'C'),
  4, 'CCD', 'RS_KM', 5.3422
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (conteinerizada)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'C')
    AND eixos_carregados = 4
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (conteinerizada)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'C'),
  5, 'CCD', 'RS_KM', 5.9392
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (conteinerizada)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'C')
    AND eixos_carregados = 5
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (conteinerizada)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'C'),
  6, 'CCD', 'RS_KM', 6.4425
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (conteinerizada)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'C')
    AND eixos_carregados = 6
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (conteinerizada)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'C'),
  7, 'CCD', 'RS_KM', 7.3185
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (conteinerizada)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'C')
    AND eixos_carregados = 7
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (conteinerizada)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'C'),
  2, 'CC', 'RS', 220.66
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (conteinerizada)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'C')
    AND eixos_carregados = 2
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (conteinerizada)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'C'),
  3, 'CC', 'RS', 239.49
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (conteinerizada)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'C')
    AND eixos_carregados = 3
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (conteinerizada)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'C'),
  4, 'CC', 'RS', 249.92
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (conteinerizada)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'C')
    AND eixos_carregados = 4
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (conteinerizada)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'C'),
  5, 'CC', 'RS', 259.83
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (conteinerizada)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'C')
    AND eixos_carregados = 5
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (conteinerizada)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'C'),
  6, 'CC', 'RS', 302.96
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (conteinerizada)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'C')
    AND eixos_carregados = 6
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (conteinerizada)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'C'),
  7, 'CC', 'RS', 326.78
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (conteinerizada)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'C')
    AND eixos_carregados = 7
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (carga geral)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'C'),
  2, 'CCD', 'RS_KM', 3.3486
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (carga geral)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'C')
    AND eixos_carregados = 2
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (carga geral)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'C'),
  3, 'CCD', 'RS_KM', 4.1122
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (carga geral)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'C')
    AND eixos_carregados = 3
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (carga geral)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'C'),
  4, 'CCD', 'RS_KM', 4.7995
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (carga geral)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'C')
    AND eixos_carregados = 4
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (carga geral)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'C'),
  5, 'CCD', 'RS_KM', 5.3613
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (carga geral)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'C')
    AND eixos_carregados = 5
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (carga geral)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'C'),
  6, 'CCD', 'RS_KM', 5.9636
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (carga geral)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'C')
    AND eixos_carregados = 6
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (carga geral)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'C'),
  7, 'CCD', 'RS_KM', 6.4266
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (carga geral)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'C')
    AND eixos_carregados = 7
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (carga geral)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'C'),
  9, 'CCD', 'RS_KM', 7.3457
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (carga geral)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'C')
    AND eixos_carregados = 9
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (carga geral)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'C'),
  2, 'CC', 'RS', 194.29
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (carga geral)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'C')
    AND eixos_carregados = 2
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (carga geral)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'C'),
  3, 'CC', 'RS', 214.00
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (carga geral)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'C')
    AND eixos_carregados = 3
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (carga geral)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'C'),
  4, 'CC', 'RS', 242.09
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (carga geral)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'C')
    AND eixos_carregados = 4
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (carga geral)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'C'),
  5, 'CC', 'RS', 253.08
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (carga geral)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'C')
    AND eixos_carregados = 5
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (carga geral)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'C'),
  6, 'CC', 'RS', 263.86
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (carga geral)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'C')
    AND eixos_carregados = 6
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (carga geral)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'C'),
  7, 'CC', 'RS', 300.33
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (carga geral)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'C')
    AND eixos_carregados = 7
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (carga geral)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'C'),
  9, 'CC', 'RS', 331.27
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (carga geral)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'C')
    AND eixos_carregados = 9
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Carga Granel Pressurizada'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'C'),
  2, 'CCD', 'RS_KM', 5.1830
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Carga Granel Pressurizada')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'C')
    AND eixos_carregados = 2
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Carga Granel Pressurizada'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'C'),
  3, 'CCD', 'RS_KM', 5.8051
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Carga Granel Pressurizada')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'C')
    AND eixos_carregados = 3
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Carga Granel Pressurizada'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'C'),
  4, 'CCD', 'RS_KM', 7.1508
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Carga Granel Pressurizada')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'C')
    AND eixos_carregados = 4
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Carga Granel Pressurizada'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'C'),
  2, 'CC', 'RS', 229.39
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Carga Granel Pressurizada')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'C')
    AND eixos_carregados = 2
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Carga Granel Pressurizada'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'C'),
  3, 'CC', 'RS', 243.46
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Carga Granel Pressurizada')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'C')
    AND eixos_carregados = 3
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Carga Granel Pressurizada'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'C'),
  4, 'CC', 'RS', 304.85
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela C (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Carga Granel Pressurizada')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'C')
    AND eixos_carregados = 4
    AND tipo_coeficiente = 'CC'
);

COMMIT;

-- Seed para TABELA D - OPERAÇÕES EM QUE HAJA A CONTRATAÇÃO APENAS DO VEÍCULO AUTOMOTOR DE CARGAS DE ALTO DESEMPENHO
BEGIN;

-- Tipo de transporte
INSERT INTO tipos_transporte (codigo, nome)
SELECT 'D', 'TABELA D - OPERAÇÕES EM QUE HAJA A CONTRATAÇÃO APENAS DO VEÍCULO AUTOMOTOR DE CARGAS DE ALTO DESEMPENHO'
WHERE NOT EXISTS (SELECT 1 FROM tipos_transporte WHERE codigo = 'D');

-- Tipos de carga
INSERT INTO tipos_carga (nome)
SELECT 'Granel sólido'
WHERE NOT EXISTS (SELECT 1 FROM tipos_carga WHERE nome = 'Granel sólido');
INSERT INTO tipos_carga (nome)
SELECT 'Granel líquido'
WHERE NOT EXISTS (SELECT 1 FROM tipos_carga WHERE nome = 'Granel líquido');
INSERT INTO tipos_carga (nome)
SELECT 'Frigorificada ou Aquecida'
WHERE NOT EXISTS (SELECT 1 FROM tipos_carga WHERE nome = 'Frigorificada ou Aquecida');
INSERT INTO tipos_carga (nome)
SELECT 'Conteinerizada'
WHERE NOT EXISTS (SELECT 1 FROM tipos_carga WHERE nome = 'Conteinerizada');
INSERT INTO tipos_carga (nome)
SELECT 'Carga Geral'
WHERE NOT EXISTS (SELECT 1 FROM tipos_carga WHERE nome = 'Carga Geral');
INSERT INTO tipos_carga (nome)
SELECT 'Neogranel'
WHERE NOT EXISTS (SELECT 1 FROM tipos_carga WHERE nome = 'Neogranel');
INSERT INTO tipos_carga (nome)
SELECT 'Perigosa (granel sólido)'
WHERE NOT EXISTS (SELECT 1 FROM tipos_carga WHERE nome = 'Perigosa (granel sólido)');
INSERT INTO tipos_carga (nome)
SELECT 'Perigosa (granel líquido)'
WHERE NOT EXISTS (SELECT 1 FROM tipos_carga WHERE nome = 'Perigosa (granel líquido)');
INSERT INTO tipos_carga (nome)
SELECT 'Perigosa (frigorificada ou aquecida)'
WHERE NOT EXISTS (SELECT 1 FROM tipos_carga WHERE nome = 'Perigosa (frigorificada ou aquecida)');
INSERT INTO tipos_carga (nome)
SELECT 'Perigosa (conteinerizada)'
WHERE NOT EXISTS (SELECT 1 FROM tipos_carga WHERE nome = 'Perigosa (conteinerizada)');
INSERT INTO tipos_carga (nome)
SELECT 'Perigosa (carga geral)'
WHERE NOT EXISTS (SELECT 1 FROM tipos_carga WHERE nome = 'Perigosa (carga geral)');
INSERT INTO tipos_carga (nome)
SELECT 'Carga Granel Pressurizada'
WHERE NOT EXISTS (SELECT 1 FROM tipos_carga WHERE nome = 'Carga Granel Pressurizada');

-- Vigência ANTT
INSERT INTO antt_tabelas (versao_label, vigente_de, fonte_url)
SELECT 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)', DATE '2025-07-17', 'https://anttlegis.antt.gov.br/action/UrlPublicasAction.php?acao=abrirAtoPublico&num_ato=00005867&sgl_tipo=RES&sgl_orgao=DG/ANTT/MI&vlr_ano=2020&seq_ato=000&cod_modulo=161&cod_menu=5408'
WHERE NOT EXISTS (SELECT 1 FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)');

INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Granel sólido'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'D'),
  2, 'CCD', 'RS_KM', 4.0866
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Granel sólido')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'D')
    AND eixos_carregados = 2
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Granel sólido'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'D'),
  3, 'CCD', 'RS_KM', 4.5223
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Granel sólido')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'D')
    AND eixos_carregados = 3
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Granel sólido'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'D'),
  4, 'CCD', 'RS_KM', 5.1128
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Granel sólido')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'D')
    AND eixos_carregados = 4
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Granel sólido'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'D'),
  5, 'CCD', 'RS_KM', 5.3723
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Granel sólido')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'D')
    AND eixos_carregados = 5
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Granel sólido'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'D'),
  6, 'CCD', 'RS_KM', 5.9712
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Granel sólido')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'D')
    AND eixos_carregados = 6
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Granel sólido'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'D'),
  2, 'CC', 'RS', 190.36
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Granel sólido')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'D')
    AND eixos_carregados = 2
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Granel sólido'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'D'),
  3, 'CC', 'RS', 200.10
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Granel sólido')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'D')
    AND eixos_carregados = 3
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Granel sólido'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'D'),
  4, 'CC', 'RS', 208.93
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Granel sólido')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'D')
    AND eixos_carregados = 4
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Granel sólido'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'D'),
  5, 'CC', 'RS', 237.43
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Granel sólido')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'D')
    AND eixos_carregados = 5
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Granel sólido'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'D'),
  6, 'CC', 'RS', 254.64
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Granel sólido')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'D')
    AND eixos_carregados = 6
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Granel líquido'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'D'),
  2, 'CCD', 'RS_KM', 4.1488
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Granel líquido')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'D')
    AND eixos_carregados = 2
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Granel líquido'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'D'),
  3, 'CCD', 'RS_KM', 4.5845
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Granel líquido')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'D')
    AND eixos_carregados = 3
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Granel líquido'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'D'),
  4, 'CCD', 'RS_KM', 5.1750
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Granel líquido')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'D')
    AND eixos_carregados = 4
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Granel líquido'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'D'),
  5, 'CCD', 'RS_KM', 5.4345
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Granel líquido')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'D')
    AND eixos_carregados = 5
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Granel líquido'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'D'),
  6, 'CCD', 'RS_KM', 6.0334
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Granel líquido')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'D')
    AND eixos_carregados = 6
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Granel líquido'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'D'),
  2, 'CC', 'RS', 190.36
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Granel líquido')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'D')
    AND eixos_carregados = 2
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Granel líquido'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'D'),
  3, 'CC', 'RS', 200.10
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Granel líquido')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'D')
    AND eixos_carregados = 3
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Granel líquido'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'D'),
  4, 'CC', 'RS', 208.93
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Granel líquido')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'D')
    AND eixos_carregados = 4
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Granel líquido'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'D'),
  5, 'CC', 'RS', 237.43
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Granel líquido')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'D')
    AND eixos_carregados = 5
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Granel líquido'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'D'),
  6, 'CC', 'RS', 254.64
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Granel líquido')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'D')
    AND eixos_carregados = 6
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Frigorificada ou Aquecida'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'D'),
  2, 'CCD', 'RS_KM', 4.9046
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Frigorificada ou Aquecida')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'D')
    AND eixos_carregados = 2
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Frigorificada ou Aquecida'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'D'),
  3, 'CCD', 'RS_KM', 5.4294
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Frigorificada ou Aquecida')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'D')
    AND eixos_carregados = 3
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Frigorificada ou Aquecida'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'D'),
  4, 'CCD', 'RS_KM', 6.1210
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Frigorificada ou Aquecida')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'D')
    AND eixos_carregados = 4
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Frigorificada ou Aquecida'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'D'),
  5, 'CCD', 'RS_KM', 6.4116
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Frigorificada ou Aquecida')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'D')
    AND eixos_carregados = 5
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Frigorificada ou Aquecida'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'D'),
  6, 'CCD', 'RS_KM', 7.1670
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Frigorificada ou Aquecida')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'D')
    AND eixos_carregados = 6
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Frigorificada ou Aquecida'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'D'),
  2, 'CC', 'RS', 220.54
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Frigorificada ou Aquecida')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'D')
    AND eixos_carregados = 2
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Frigorificada ou Aquecida'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'D'),
  3, 'CC', 'RS', 230.27
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Frigorificada ou Aquecida')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'D')
    AND eixos_carregados = 3
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Frigorificada ou Aquecida'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'D'),
  4, 'CC', 'RS', 239.11
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Frigorificada ou Aquecida')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'D')
    AND eixos_carregados = 4
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Frigorificada ou Aquecida'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'D'),
  5, 'CC', 'RS', 272.74
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Frigorificada ou Aquecida')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'D')
    AND eixos_carregados = 5
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Frigorificada ou Aquecida'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'D'),
  6, 'CC', 'RS', 295.35
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Frigorificada ou Aquecida')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'D')
    AND eixos_carregados = 6
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Conteinerizada'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'D'),
  2, 'CCD', 'RS_KM', 4.0866
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Conteinerizada')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'D')
    AND eixos_carregados = 2
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Conteinerizada'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'D'),
  3, 'CCD', 'RS_KM', 4.5223
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Conteinerizada')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'D')
    AND eixos_carregados = 3
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Conteinerizada'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'D'),
  4, 'CCD', 'RS_KM', 5.1128
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Conteinerizada')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'D')
    AND eixos_carregados = 4
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Conteinerizada'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'D'),
  5, 'CCD', 'RS_KM', 5.3723
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Conteinerizada')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'D')
    AND eixos_carregados = 5
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Conteinerizada'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'D'),
  6, 'CCD', 'RS_KM', 5.9712
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Conteinerizada')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'D')
    AND eixos_carregados = 6
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Conteinerizada'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'D'),
  2, 'CC', 'RS', 190.36
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Conteinerizada')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'D')
    AND eixos_carregados = 2
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Conteinerizada'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'D'),
  3, 'CC', 'RS', 200.10
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Conteinerizada')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'D')
    AND eixos_carregados = 3
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Conteinerizada'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'D'),
  4, 'CC', 'RS', 208.93
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Conteinerizada')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'D')
    AND eixos_carregados = 4
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Conteinerizada'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'D'),
  5, 'CC', 'RS', 237.43
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Conteinerizada')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'D')
    AND eixos_carregados = 5
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Conteinerizada'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'D'),
  6, 'CC', 'RS', 254.64
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Conteinerizada')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'D')
    AND eixos_carregados = 6
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Carga Geral'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'D'),
  2, 'CCD', 'RS_KM', 4.0866
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Carga Geral')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'D')
    AND eixos_carregados = 2
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Carga Geral'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'D'),
  3, 'CCD', 'RS_KM', 4.5223
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Carga Geral')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'D')
    AND eixos_carregados = 3
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Carga Geral'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'D'),
  4, 'CCD', 'RS_KM', 5.1128
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Carga Geral')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'D')
    AND eixos_carregados = 4
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Carga Geral'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'D'),
  5, 'CCD', 'RS_KM', 5.3723
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Carga Geral')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'D')
    AND eixos_carregados = 5
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Carga Geral'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'D'),
  6, 'CCD', 'RS_KM', 5.9712
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Carga Geral')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'D')
    AND eixos_carregados = 6
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Carga Geral'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'D'),
  2, 'CC', 'RS', 190.36
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Carga Geral')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'D')
    AND eixos_carregados = 2
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Carga Geral'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'D'),
  3, 'CC', 'RS', 200.10
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Carga Geral')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'D')
    AND eixos_carregados = 3
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Carga Geral'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'D'),
  4, 'CC', 'RS', 208.93
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Carga Geral')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'D')
    AND eixos_carregados = 4
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Carga Geral'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'D'),
  5, 'CC', 'RS', 237.43
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Carga Geral')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'D')
    AND eixos_carregados = 5
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Carga Geral'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'D'),
  6, 'CC', 'RS', 254.64
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Carga Geral')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'D')
    AND eixos_carregados = 6
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Neogranel'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'D'),
  2, 'CCD', 'RS_KM', 4.0866
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Neogranel')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'D')
    AND eixos_carregados = 2
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Neogranel'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'D'),
  3, 'CCD', 'RS_KM', 4.5223
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Neogranel')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'D')
    AND eixos_carregados = 3
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Neogranel'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'D'),
  4, 'CCD', 'RS_KM', 5.1128
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Neogranel')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'D')
    AND eixos_carregados = 4
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Neogranel'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'D'),
  5, 'CCD', 'RS_KM', 5.3723
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Neogranel')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'D')
    AND eixos_carregados = 5
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Neogranel'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'D'),
  6, 'CCD', 'RS_KM', 5.9712
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Neogranel')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'D')
    AND eixos_carregados = 6
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Neogranel'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'D'),
  2, 'CC', 'RS', 190.36
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Neogranel')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'D')
    AND eixos_carregados = 2
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Neogranel'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'D'),
  3, 'CC', 'RS', 200.10
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Neogranel')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'D')
    AND eixos_carregados = 3
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Neogranel'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'D'),
  4, 'CC', 'RS', 208.93
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Neogranel')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'D')
    AND eixos_carregados = 4
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Neogranel'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'D'),
  5, 'CC', 'RS', 237.43
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Neogranel')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'D')
    AND eixos_carregados = 5
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Neogranel'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'D'),
  6, 'CC', 'RS', 254.64
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Neogranel')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'D')
    AND eixos_carregados = 6
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (granel sólido)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'D'),
  2, 'CCD', 'RS_KM', 4.6390
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (granel sólido)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'D')
    AND eixos_carregados = 2
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (granel sólido)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'D'),
  3, 'CCD', 'RS_KM', 5.0747
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (granel sólido)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'D')
    AND eixos_carregados = 3
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (granel sólido)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'D'),
  4, 'CCD', 'RS_KM', 5.6652
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (granel sólido)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'D')
    AND eixos_carregados = 4
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (granel sólido)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'D'),
  5, 'CCD', 'RS_KM', 5.9558
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (granel sólido)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'D')
    AND eixos_carregados = 5
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (granel sólido)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'D'),
  6, 'CCD', 'RS_KM', 6.5875
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (granel sólido)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'D')
    AND eixos_carregados = 6
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (granel sólido)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'D'),
  2, 'CC', 'RS', 242.22
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (granel sólido)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'D')
    AND eixos_carregados = 2
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (granel sólido)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'D'),
  3, 'CC', 'RS', 251.96
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (granel sólido)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'D')
    AND eixos_carregados = 3
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (granel sólido)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'D'),
  4, 'CC', 'RS', 260.79
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (granel sólido)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'D')
    AND eixos_carregados = 4
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (granel sólido)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'D'),
  5, 'CC', 'RS', 294.42
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (granel sólido)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'D')
    AND eixos_carregados = 5
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (granel sólido)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'D'),
  6, 'CC', 'RS', 317.04
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (granel sólido)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'D')
    AND eixos_carregados = 6
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (granel líquido)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'D'),
  2, 'CCD', 'RS_KM', 4.6545
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (granel líquido)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'D')
    AND eixos_carregados = 2
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (granel líquido)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'D'),
  3, 'CCD', 'RS_KM', 5.0902
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (granel líquido)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'D')
    AND eixos_carregados = 3
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (granel líquido)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'D'),
  4, 'CCD', 'RS_KM', 5.6806
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (granel líquido)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'D')
    AND eixos_carregados = 4
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (granel líquido)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'D'),
  5, 'CCD', 'RS_KM', 5.9713
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (granel líquido)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'D')
    AND eixos_carregados = 5
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (granel líquido)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'D'),
  6, 'CCD', 'RS_KM', 6.6030
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (granel líquido)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'D')
    AND eixos_carregados = 6
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (granel líquido)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'D'),
  2, 'CC', 'RS', 244.78
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (granel líquido)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'D')
    AND eixos_carregados = 2
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (granel líquido)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'D'),
  3, 'CC', 'RS', 254.51
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (granel líquido)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'D')
    AND eixos_carregados = 3
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (granel líquido)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'D'),
  4, 'CC', 'RS', 263.35
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (granel líquido)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'D')
    AND eixos_carregados = 4
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (granel líquido)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'D'),
  5, 'CC', 'RS', 296.97
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (granel líquido)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'D')
    AND eixos_carregados = 5
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (granel líquido)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'D'),
  6, 'CC', 'RS', 319.59
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (granel líquido)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'D')
    AND eixos_carregados = 6
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (frigorificada ou aquecida)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'D'),
  2, 'CCD', 'RS_KM', 5.3996
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (frigorificada ou aquecida)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'D')
    AND eixos_carregados = 2
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (frigorificada ou aquecida)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'D'),
  3, 'CCD', 'RS_KM', 5.9244
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (frigorificada ou aquecida)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'D')
    AND eixos_carregados = 3
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (frigorificada ou aquecida)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'D'),
  4, 'CCD', 'RS_KM', 6.6160
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (frigorificada ou aquecida)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'D')
    AND eixos_carregados = 4
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (frigorificada ou aquecida)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'D'),
  5, 'CCD', 'RS_KM', 6.9470
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (frigorificada ou aquecida)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'D')
    AND eixos_carregados = 5
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (frigorificada ou aquecida)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'D'),
  6, 'CCD', 'RS_KM', 7.7450
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (frigorificada ou aquecida)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'D')
    AND eixos_carregados = 6
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (frigorificada ou aquecida)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'D'),
  2, 'CC', 'RS', 271.12
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (frigorificada ou aquecida)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'D')
    AND eixos_carregados = 2
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (frigorificada ou aquecida)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'D'),
  3, 'CC', 'RS', 280.86
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (frigorificada ou aquecida)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'D')
    AND eixos_carregados = 3
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (frigorificada ou aquecida)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'D'),
  4, 'CC', 'RS', 289.69
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (frigorificada ou aquecida)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'D')
    AND eixos_carregados = 4
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (frigorificada ou aquecida)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'D'),
  5, 'CC', 'RS', 329.99
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (frigorificada ou aquecida)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'D')
    AND eixos_carregados = 5
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (frigorificada ou aquecida)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'D'),
  6, 'CC', 'RS', 359.64
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (frigorificada ou aquecida)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'D')
    AND eixos_carregados = 6
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (conteinerizada)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'D'),
  2, 'CCD', 'RS_KM', 4.3731
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (conteinerizada)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'D')
    AND eixos_carregados = 2
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (conteinerizada)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'D'),
  3, 'CCD', 'RS_KM', 4.8088
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (conteinerizada)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'D')
    AND eixos_carregados = 3
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (conteinerizada)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'D'),
  4, 'CCD', 'RS_KM', 5.3992
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (conteinerizada)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'D')
    AND eixos_carregados = 4
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (conteinerizada)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'D'),
  5, 'CCD', 'RS_KM', 5.6898
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (conteinerizada)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'D')
    AND eixos_carregados = 5
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (conteinerizada)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'D'),
  6, 'CCD', 'RS_KM', 6.3216
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (conteinerizada)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'D')
    AND eixos_carregados = 6
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (conteinerizada)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'D'),
  2, 'CC', 'RS', 231.89
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (conteinerizada)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'D')
    AND eixos_carregados = 2
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (conteinerizada)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'D'),
  3, 'CC', 'RS', 241.62
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (conteinerizada)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'D')
    AND eixos_carregados = 3
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (conteinerizada)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'D'),
  4, 'CC', 'RS', 250.46
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (conteinerizada)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'D')
    AND eixos_carregados = 4
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (conteinerizada)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'D'),
  5, 'CC', 'RS', 284.09
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (conteinerizada)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'D')
    AND eixos_carregados = 5
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (conteinerizada)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'D'),
  6, 'CC', 'RS', 306.70
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (conteinerizada)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'D')
    AND eixos_carregados = 6
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (carga geral)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'D'),
  2, 'CCD', 'RS_KM', 4.3731
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (carga geral)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'D')
    AND eixos_carregados = 2
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (carga geral)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'D'),
  3, 'CCD', 'RS_KM', 4.8088
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (carga geral)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'D')
    AND eixos_carregados = 3
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (carga geral)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'D'),
  4, 'CCD', 'RS_KM', 5.3992
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (carga geral)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'D')
    AND eixos_carregados = 4
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (carga geral)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'D'),
  5, 'CCD', 'RS_KM', 5.6898
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (carga geral)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'D')
    AND eixos_carregados = 5
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (carga geral)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'D'),
  6, 'CCD', 'RS_KM', 6.3216
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (carga geral)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'D')
    AND eixos_carregados = 6
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (carga geral)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'D'),
  2, 'CC', 'RS', 231.89
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (carga geral)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'D')
    AND eixos_carregados = 2
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (carga geral)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'D'),
  3, 'CC', 'RS', 241.62
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (carga geral)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'D')
    AND eixos_carregados = 3
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (carga geral)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'D'),
  4, 'CC', 'RS', 250.46
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (carga geral)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'D')
    AND eixos_carregados = 4
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (carga geral)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'D'),
  5, 'CC', 'RS', 284.09
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (carga geral)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'D')
    AND eixos_carregados = 5
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (carga geral)'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'D'),
  6, 'CC', 'RS', 306.70
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Perigosa (carga geral)')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'D')
    AND eixos_carregados = 6
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Carga Granel Pressurizada'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'D'),
  2, 'CCD', 'RS_KM', 4.5223
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Carga Granel Pressurizada')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'D')
    AND eixos_carregados = 2
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Carga Granel Pressurizada'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'D'),
  3, 'CCD', 'RS_KM', 5.1128
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Carga Granel Pressurizada')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'D')
    AND eixos_carregados = 3
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Carga Granel Pressurizada'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'D'),
  4, 'CCD', 'RS_KM', 5.9712
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Carga Granel Pressurizada')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'D')
    AND eixos_carregados = 4
    AND tipo_coeficiente = 'CCD'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Carga Granel Pressurizada'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'D'),
  2, 'CC', 'RS', 200.10
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Carga Granel Pressurizada')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'D')
    AND eixos_carregados = 2
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Carga Granel Pressurizada'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'D'),
  3, 'CC', 'RS', 208.93
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Carga Granel Pressurizada')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'D')
    AND eixos_carregados = 3
    AND tipo_coeficiente = 'CC'
);
INSERT INTO antt_coeficientes (antt_tabela_id, tipo_carga_id, tipo_transporte_id, eixos_carregados, tipo_coeficiente, unidade, valor)
SELECT
  (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)'),
  (SELECT id FROM tipos_carga WHERE nome = 'Carga Granel Pressurizada'),
  (SELECT id FROM tipos_transporte WHERE codigo = 'D'),
  4, 'CC', 'RS', 254.64
WHERE NOT EXISTS (
  SELECT 1 FROM antt_coeficientes
  WHERE antt_tabela_id = (SELECT id FROM antt_tabelas WHERE versao_label = 'ANTT - Tabela D (RESOLUÇÃO Nº 6.067, DE 17 DE JULHO DE 2025)')
    AND tipo_carga_id = (SELECT id FROM tipos_carga WHERE nome = 'Carga Granel Pressurizada')
    AND tipo_transporte_id = (SELECT id FROM tipos_transporte WHERE codigo = 'D')
    AND eixos_carregados = 4
    AND tipo_coeficiente = 'CC'
);

COMMIT;