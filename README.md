# 🚀 CDC Pipeline com PostgreSQL, Debezium e Apache Kafka (Docker Lab)

Este laboratório demonstra uma arquitetura moderna de Change Data Capture (CDC)
utilizando PostgreSQL, Debezium e Apache Kafka, executando localmente via Docker.

A solução captura alterações no banco transacional e as publica em tempo real no Kafka,
permitindo integração com Data Lakes, Analytics e arquiteturas orientadas a eventos.

---

## 🧱 Arquitetura

A arquitetura é composta pelos seguintes serviços:

### 🔹 Zookeeper (Confluent)
Responsável por coordenar os brokers do Kafka.

- Gerencia metadados do cluster
- Controla líderes e sincronização
- Necessário para o Kafka funcionar

---

### 🔹 Apache Kafka
Plataforma distribuída de streaming de eventos.

- Recebe eventos do Debezium
- Armazena eventos em topics
- Permite consumo por múltiplos serviços

Porta: 9092

Configuração importante:
- replication factor = 1 (lab local)

---

### 🔹 PostgreSQL 15 (Debezium Image)
Banco de dados transacional com suporte a CDC.

Responsável por:

- armazenar os dados do DW
- gerar WAL (Write-Ahead Log) com alterações
- permitir captura lógica via replication slot

Configurações aplicadas:

wal_level=logical
max_wal_senders=5
max_replication_slots=5

Porta: 5432

---

### 🔹 Debezium Connect
Serviço Kafka Connect com o conector PostgreSQL.

Responsável por:

- ler mudanças do WAL
- converter mudanças em eventos
- enviar eventos para o Kafka

Porta REST API: 8083

---

### 🔹 Kafka UI
Interface web para visualização do Kafka.

Permite:

- visualizar topics
- visualizar eventos
- monitorar producers/consumers

Porta: 8080

---

## ⚙️ Subindo o ambiente

Dentro da pasta do projeto:

docker compose up -d

Verificar containers:

docker ps

---

## 🗄️ Conectando ao PostgreSQL

Conectar via PGAdmin ou DBeaver:

Host: localhost
Port: 5432
Database: dw
User: postgres
Password: postgres

---

## 🧱 Criação das tabelas

Após conectar, foram criadas as tabelas dimensionais e fato do Data Warehouse.

Exemplos:

- dim_produto
- dim_tempo
- dim_materia_prima
- fato_producao

---

## 📢 Criação da Publication (CDC)

A publication permite que o Debezium capture alterações.

CREATE PUBLICATION dw_publication
FOR TABLE public.dim_produto,
           public.dim_tempo,
           public.dim_materia_prima;

---

## 🔌 Criação do Connector Debezium

Criamos o conector via REST API:

curl -X POST http://localhost:8083/connectors \
-H "Content-Type: application/json" \
-d '{
  "name": "dw-connector",
  "config": {
    "connector.class": "io.debezium.connector.postgresql.PostgresConnector",
    "database.hostname": "postgres",
    "database.port": "5432",
    "database.user": "postgres",
    "database.password": "postgres",
    "database.dbname": "dw",
    "database.server.name": "dwserver",
    "plugin.name": "pgoutput",
    "publication.name": "dw_publication",
    "slot.name": "slot_dw",
    "table.include.list": "public.dim_produto,public.dim_tempo,public.dim_materia_prima",
    "topic.prefix": "dw"
  }
}'

---

## 🔄 Como funciona o fluxo CDC

1️⃣ Inserção ocorre no PostgreSQL  
2️⃣ Alteração é gravada no WAL  
3️⃣ Debezium lê o WAL via replication slot  
4️⃣ Debezium envia evento para Kafka  
5️⃣ Kafka armazena evento em um topic  
6️⃣ Kafka UI permite visualizar os eventos  

---

## 🧪 Testando CDC

Execute um insert:

INSERT INTO dim_produto
(cod_produto, desc_produto, cod_segmento, desc_segmento)
VALUES
('P001','Produto Teste','SEG1','Segmento Teste');

---

## 👀 Visualizando eventos

Acesse:

http://localhost:8080

Vá em:

Topics
dw.public.dim_produto
Messages

Você verá o evento capturado em tempo real.

---

## 📦 Topics criados automaticamente

Após o primeiro insert:

- dw.public.dim_produto
- dw.public.dim_tempo
- dw.public.dim_materia_prima

---

## 🧠 O que este lab demonstra

✔ Change Data Capture em tempo real  
✔ Integração PostgreSQL → Kafka  
✔ Arquitetura orientada a eventos  
✔ Base para Data Lake / Streaming Analytics  
✔ Padrão utilizado por empresas modernas
