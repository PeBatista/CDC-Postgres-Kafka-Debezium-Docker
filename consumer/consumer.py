import json
import mysql.connector
from kafka import KafkaConsumer
import time

# =========================================
# CONFIGURAÇÕES
# =========================================

KAFKA_TOPICS = [
    "dw.public.dim_produto",
    "dw.public.dim_tempo",
    "dw.public.dim_materia_prima",
    "dw.public.fato_producao"
]

print("🔌 conectando ao Kafka...")

consumer = KafkaConsumer(
    *KAFKA_TOPICS,
    bootstrap_servers='kafka:9092',
    value_deserializer=lambda x: json.loads(x.decode('utf-8')) if x else None,
    auto_offset_reset='earliest',
    enable_auto_commit=True,
    group_id='cdc-group-v2',
    consumer_timeout_ms=1000,
    fetch_max_wait_ms=500
)

print("✅ conectado ao Kafka")

# =========================================
# CONEXÃO MYSQL
# =========================================

def connect_db():
    return mysql.connector.connect(
        host="host.docker.internal",
        port=, #xxx
        user="root", # xxx
        password="", # xxx
        database="", # xxx
        autocommit=True
    )

conn = connect_db()
cursor = conn.cursor()

print("🚀 Consumer iniciado... aguardando eventos CDC")

# =========================================
# UPSERTS DIMENSÕES
# =========================================

def upsert_dim_produto(data):
    sql = """
    INSERT INTO dim_produto
    (id_produto, cod_produto, desc_produto, cod_segmento, desc_segmento)
    VALUES (%s, %s, %s, %s, %s)
    ON DUPLICATE KEY UPDATE
        cod_produto = VALUES(cod_produto),
        desc_produto = VALUES(desc_produto),
        cod_segmento = VALUES(cod_segmento),
        desc_segmento = VALUES(desc_segmento)
    """
    cursor.execute(sql, (
        data["id_produto"],
        data["cod_produto"],
        data["desc_produto"],
        data.get("cod_segmento"),
        data.get("desc_segmento")
    ))


def upsert_dim_tempo(data):
    sql = """
    INSERT INTO dim_tempo
    (id_tempo, data_calendario, dia, mes, ano,
     nome_mes, trimestre, cod_mes_ano, desc_mes_ano)
    VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s)
    ON DUPLICATE KEY UPDATE
        dia = VALUES(dia),
        mes = VALUES(mes),
        ano = VALUES(ano),
        nome_mes = VALUES(nome_mes),
        trimestre = VALUES(trimestre),
        desc_mes_ano = VALUES(desc_mes_ano)
    """
    cursor.execute(sql, (
        data["id_tempo"],
        data["data_calendario"],
        data["dia"],
        data["mes"],
        data["ano"],
        data.get("nome_mes"),
        data.get("trimestre"),
        data["cod_mes_ano"],
        data.get("desc_mes_ano")
    ))


def upsert_dim_mp(data):
    sql = """
    INSERT INTO dim_materia_prima
    (id_materia_prima, cod_materia_prima, desc_materia_prima,
     tipo_materia_prima, unidade_medida)
    VALUES (%s,%s,%s,%s,%s)
    ON DUPLICATE KEY UPDATE
        desc_materia_prima = VALUES(desc_materia_prima),
        tipo_materia_prima = VALUES(tipo_materia_prima),
        unidade_medida = VALUES(unidade_medida)
    """
    cursor.execute(sql, (
        data["id_materia_prima"],
        data["cod_materia_prima"],
        data["desc_materia_prima"],
        data.get("tipo_materia_prima"),
        data.get("unidade_medida")
    ))


# =========================================
# FATO PRODUÇÃO
# =========================================

def insert_fato(data):
    sql = """
    INSERT INTO fato_producao
    (id_produto, id_tempo, id_mp_entrada, id_mp_saida,
     quantidade, custo_unitario, custo_total)
    VALUES (%s,%s,%s,%s,%s,%s,%s)
    ON DUPLICATE KEY UPDATE
        quantidade = VALUES(quantidade),
        custo_unitario = VALUES(custo_unitario),
        custo_total = VALUES(custo_total)
    """
    cursor.execute(sql, (
        data["id_produto"],
        data["id_tempo"],
        data["id_mp_entrada"],
        data["id_mp_saida"],
        data["quantidade"],
        data["custo_unitario"],
        data["custo_total"]
    ))

# =========================================
# LOOP PRINCIPAL
# =========================================

print("👀 aguardando mensagens...")

while True:
    try:
        for message in consumer:

            if message.value is None:
                continue

            payload = message.value.get("payload")

            if not payload:
                continue

            if payload.get("after") is None:
                continue

            data = payload["after"]

            topic = message.topic

            print(f"\n📥 Evento recebido → {topic}")
            print(data)

            if topic.endswith("dim_produto"):
                upsert_dim_produto(data)

            elif topic.endswith("dim_tempo"):
                upsert_dim_tempo(data)

            elif topic.endswith("dim_materia_prima"):
                upsert_dim_mp(data)

            elif topic.endswith("fato_producao"):
                insert_fato(data)

            print("✅ Inserido/Atualizado!")

    except mysql.connector.Error as db_err:
        print("❌ Erro banco:", db_err)
        conn = connect_db()
        cursor = conn.cursor()

    except Exception as e:
        print("⚠️ erro geral:", e)
        time.sleep(5)
