#!/bin/bash

# Функция для инициализации репликасета
init_replicaset() {
  local container=$1
  local port=$2
  local rs_name=$3
  echo "Инициализация репликасета $rs_name на $container:$port"
  docker exec -i $container mongosh --port $port --quiet <<EOF
rs.initiate({
  _id: "$rs_name",
  members: [
    { _id: 0, host: "$container:$port" }
  ]
});
EOF
}

# Функция для выполнения MongoDB команд
run_mongo_commands() {
  docker compose exec -T mongos_router mongosh --quiet <<EOF
$@
EOF
}

# 1. Инициализация репликасетов
init_replicaset "configSrv" 27019 "config_server"
init_replicaset "shard1" 27018 "shard1rs"
init_replicaset "shard2" 27028 "shard2rs"

# Ждем инициализации
sleep 10

# 2. Добавление шардов и настройка шардинга
echo "Настройка шардинга..."
run_mongo_commands '
sh.addShard("shard1rs/shard1:27018");
sh.addShard("shard2rs/shard2:27028");
sh.enableSharding("somedb");
sh.shardCollection("somedb.helloDoc", { "_id": "hashed" });
'

# 3. Вставка тестовых данных
echo "Вставка тестовых данных..."
run_mongo_commands '
use somedb;
for (var i = 0; i < 1000; i++) {
  db.helloDoc.insertOne({ age: i, name: "user" + i });
}
db.helloDoc.countDocuments();
'

# 4. Проверка
echo "Проверка распределения данных:"
run_mongo_commands '
use somedb;
db.helloDoc.getShardDistribution();
'