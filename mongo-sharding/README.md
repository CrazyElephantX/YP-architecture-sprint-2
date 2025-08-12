## Как запустить

Запускаем MongoDB и приложение:

```shell
docker compose up -d
```

Заполняем MongoDB данными:

```shell
./scripts/mongo-init.sh
```

## Как проверить
Откройте в браузере http://localhost:8080

## Как остановить

```shell
docker compose down
```
# Проверка через CLI
Проверьте количество документов в коллекции helloDoc на разных шардах:

# Для shard1 (порт 27018)
docker compose exec -T shard1 mongosh --port 27018 --eval "db.helloDoc.countDocuments()" somedb --quiet

# Для shard2 (порт 27028)
docker compose exec -T shard2 mongosh --port 27028 --eval "db.helloDoc.countDocuments()" somedb --quiet