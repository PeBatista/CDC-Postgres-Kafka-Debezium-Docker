-- =========================================================
-- DATA WAREHOUSE PRODUÇÃO
-- EXECUÇÃO ÚNICA
-- =========================================================

BEGIN;

-- =========================================================
-- 1️⃣ CRIA SCHEMA
-- =========================================================
CREATE SCHEMA IF NOT EXISTS dw;
SET search_path TO dw;

-- =========================================================
-- 2️⃣ DROP SE EXISTIR (ORDEM CORRETA)
-- =========================================================
DROP TABLE IF EXISTS fato_producao CASCADE;
DROP TABLE IF EXISTS dim_materia_prima CASCADE;
DROP TABLE IF EXISTS dim_produto CASCADE;
DROP TABLE IF EXISTS dim_tempo CASCADE;

-- =========================================================
-- 3️⃣ DIMENSÃO TEMPO
-- =========================================================
CREATE TABLE dim_tempo (
    id_tempo        INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    data_calendario DATE NOT NULL,
    dia             SMALLINT NOT NULL,
    mes             SMALLINT NOT NULL,
    ano             SMALLINT NOT NULL,
    nome_mes        VARCHAR(20),
    trimestre       SMALLINT,
    cod_mes_ano     CHAR(6) NOT NULL,
    desc_mes_ano    VARCHAR(20)
);

CREATE UNIQUE INDEX idx_dim_tempo_data
ON dim_tempo(data_calendario);

-- =========================================================
-- 4️⃣ DIMENSÃO PRODUTO
-- =========================================================
CREATE TABLE dim_produto (
    id_produto    INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    cod_produto   VARCHAR(10) NOT NULL,
    desc_produto  VARCHAR(100) NOT NULL,
    cod_segmento  VARCHAR(10),
    desc_segmento VARCHAR(100)
);

CREATE UNIQUE INDEX idx_dim_produto_codigo
ON dim_produto(cod_produto);

-- =========================================================
-- 5️⃣ DIMENSÃO MATÉRIA-PRIMA
-- =========================================================
CREATE TABLE dim_materia_prima (
    id_materia_prima INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    cod_materia_prima VARCHAR(20) NOT NULL,
    desc_materia_prima VARCHAR(100) NOT NULL,
    tipo_materia_prima VARCHAR(30),   -- entrada / saída / ambos
    unidade_medida VARCHAR(10)
);

CREATE UNIQUE INDEX idx_dim_mp_codigo
ON dim_materia_prima(cod_materia_prima);

-- =========================================================
-- 6️⃣ TABELA FATO PRODUÇÃO
-- =========================================================
CREATE TABLE fato_producao (
    id_produto INT NOT NULL,
    id_tempo INT NOT NULL,
    id_mp_entrada INT NOT NULL,
    id_mp_saida INT NOT NULL,

    quantidade NUMERIC(18,4) NOT NULL CHECK (quantidade >= 0),
    custo_unitario NUMERIC(18,4) NOT NULL CHECK (custo_unitario >= 0),
    custo_total NUMERIC(18,4) NOT NULL CHECK (custo_total >= 0),

    CONSTRAINT fato_producao_pk PRIMARY KEY
    (id_produto, id_tempo, id_mp_entrada, id_mp_saida),

    CONSTRAINT fk_produto
        FOREIGN KEY (id_produto)
        REFERENCES dim_produto(id_produto),

    CONSTRAINT fk_tempo
        FOREIGN KEY (id_tempo)
        REFERENCES dim_tempo(id_tempo),

    CONSTRAINT fk_mp_entrada
        FOREIGN KEY (id_mp_entrada)
        REFERENCES dim_materia_prima(id_materia_prima),

    CONSTRAINT fk_mp_saida
        FOREIGN KEY (id_mp_saida)
        REFERENCES dim_materia_prima(id_materia_prima)
);

-- =========================================================
-- 7️⃣ ÍNDICES PARA PERFORMANCE ANALÍTICA
-- =========================================================
CREATE INDEX idx_fato_tempo
ON fato_producao(id_tempo);

CREATE INDEX idx_fato_produto
ON fato_producao(id_produto);

CREATE INDEX idx_fato_mp_entrada
ON fato_producao(id_mp_entrada);

CREATE INDEX idx_fato_mp_saida
ON fato_producao(id_mp_saida);

COMMIT;


/*--------------------------------------------*/
CREATE PUBLICATION pub_dw
FOR TABLE dim_produto, dim_tempo, dim_materia_prima;

SELECT * FROM pg_publication; /*verificando*/
/*--------------------------------------------*/


SELECT * FROM pg_create_logical_replication_slot('slot_dw', 'pgoutput');
/*Criando o Slot que o debezium usará também  ----------------- */



INSERT INTO dim_produto
(cod_produto, desc_produto, cod_segmento, desc_segmento)
VALUES ('P999','Produto CDC','TESTE','CDC');


select * from pg_replication_slots; /*Aqui podemos ver os logs do inserts e oque foi capturado pelo Debezium connector*/
