#!/bin/bash

# Функция для инициализации репликасета
init_replicaset() {
  local container=$1
  local port=$2
  local rs_name=$3
  local members=$4
  echo "Инициализация репликасета $rs_name на $container:$port"
  docker exec -i $container mongosh --port $port --quiet <<EOF
rs.initiate({
  _id: "$rs_name",
  members: $members
});
EOF
}

# Функция для выполнения MongoDB команд
run_mongo_commands() {
  docker compose exec -T mongos_router mongosh --quiet <<EOF
$@
EOF
}

# 1. Инициализация config сервера
init_replicaset "configSrv" 27019 "config_server" '[
  { _id: 0, host: "configSrv:27019" }
]'

# 2. Инициализация репликасетов для шардов
# Shard 1 (primary + 2 secondary)
init_replicaset "shard1a" 27018 "shard1rs" '[
  { _id: 0, host: "shard1a:27018", priority: 2 },
  { _id: 1, host: "shard1b:27018", priority: 1 },
  { _id: 2, host: "shard1c:27018", priority: 1 }
]'

# Shard 2 (primary + 2 secondary)
init_replicaset "shard2a" 27028 "shard2rs" '[
  { _id: 0, host: "shard2a:27028", priority: 2 },
  { _id: 1, host: "shard2b:27028", priority: 1 },
  { _id: 2, host: "shard2c:27028", priority: 1 }
]'

# Ждем инициализации
echo "Ожидание инициализации репликасетов (30 секунд)..."
sleep 30

# 3. Добавление шардов и настройка шардинга
echo "Настройка шардинга..."
run_mongo_commands '
// Добавляем шарды со всеми репликами
sh.addShard("shard1rs/shard1a:27018,shard1b:27018,shard1c:27018");
sh.addShard("shard2rs/shard2a:27028,shard2b:27028,shard2c:27028");

// Включаем шардинг для базы данных
sh.enableSharding("somedb");

// Шардируем коллекцию
sh.shardCollection("somedb.helloDoc", { "_id": "hashed" });
'

# 4. Вставка тестовых данных
echo "Вставка тестовых данных (1000 документов)..."
run_mongo_commands '
use somedb;
for (var i = 0; i < 1000; i++) {
  db.helloDoc.insertOne({ 
    _id: "doc_" + i,
    age: i, 
    name: "user" + i,
    timestamp: new Date(),
    data: "sample_data_" + Math.random().toString(36).substring(7)
  });
}
'

# 5. Проверка
echo "Проверка распределения данных:"
run_mongo_commands '
use somedb;
print("Общее количество документов:");
db.helloDoc.countDocuments();

print("\nРаспределение по шардам:");
db.helloDoc.getShardDistribution();

print("\nСтатус шардинга:");
sh.status();
'

# 6. Проверка репликации
echo "\nПроверка репликации shard1:"
docker exec -i shard1a mongosh --port 27018 --quiet --eval '
rs.status().members.forEach(member => {
  print(`Нода: ${member.name}, состояние: ${member.stateStr}, здоровье: ${member.health}`)
});
'

echo "\nПроверка репликации shard2:"
docker exec -i shard2a mongosh --port 27028 --quiet --eval '
rs.status().members.forEach(member => {
  print(`Нода: ${member.name}, состояние: ${member.stateStr}, здоровье: ${member.health}`)
});
'