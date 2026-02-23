-- =====================================================
-- DATA WAREHOUSE ANALÍTICO (MYSQL / MARIADB)
-- Compatível com CDC Kafka → Consumer Python
-- =====================================================

-- 🔹 Criar banco
CREATE DATABASE IF NOT EXISTS dw;

USE dw;

-- =====================================================
-- DIMENSÃO: PRODUTO
-- =====================================================
CREATE TABLE IF NOT EXISTS dim_produto (
    id_produto INT NOT NULL,
    cod_produto VARCHAR(10),
    desc_produto VARCHAR(100),
    cod_segmento VARCHAR(10),
    desc_segmento VARCHAR(100),
    PRIMARY KEY (id_produto)
);

-- =====================================================
-- DIMENSÃO: MATÉRIA PRIMA
-- =====================================================
CREATE TABLE IF NOT EXISTS dim_materia_prima (
    id_materia_prima INT NOT NULL,
    cod_materia_prima VARCHAR(20),
    desc_materia_prima VARCHAR(100),
    tipo_materia_prima VARCHAR(30),
    unidade_medida VARCHAR(10),
    PRIMARY KEY (id_materia_prima)
);

-- =====================================================
-- DIMENSÃO: TEMPO
-- =====================================================
CREATE TABLE IF NOT EXISTS dim_tempo (
    id_tempo INT NOT NULL,
    data_calendario DATE,
    dia SMALLINT,
    mes SMALLINT,
    ano SMALLINT,
    nome_mes VARCHAR(20),
    trimestre SMALLINT,
    cod_mes_ano VARCHAR(6),
    desc_mes_ano VARCHAR(20),
    PRIMARY KEY (id_tempo)
);

-- =====================================================
-- TABELA FATO: PRODUÇÃO
-- =====================================================
CREATE TABLE IF NOT EXISTS fato_producao (
    id_produto INT NOT NULL,
    id_tempo INT NOT NULL,
    id_mp_entrada INT NOT NULL,
    id_mp_saida INT NOT NULL,
    quantidade DECIMAL(18,4),
    custo_unitario DECIMAL(18,4),
    custo_total DECIMAL(18,4),
    PRIMARY KEY (id_produto, id_tempo, id_mp_entrada, id_mp_saida)
);

-- =====================================================
-- ÍNDICES PARA PERFORMANCE ANALÍTICA
-- =====================================================
CREATE INDEX idx_fato_produto ON fato_producao(id_produto);
CREATE INDEX idx_fato_tempo ON fato_producao(id_tempo);
CREATE INDEX idx_fato_mp_entrada ON fato_producao(id_mp_entrada);
CREATE INDEX idx_fato_mp_saida ON fato_producao(id_mp_saida);

-- =====================================================
-- FIM mysql -u root -p -P 3307 < dw.sql
-- =====================================================