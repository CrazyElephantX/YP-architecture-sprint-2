 # Настройка шардирования
 1. Инициализировать сервер конфигураций
 docker exec -it configSrv mongosh --port 27017

> rs.initiate(
  {
    _id : "config_server",
       configsvr: true,
    members: [
      { _id : 0, host : "configSrv:27017" }
    ]
  }
);
> exit();

2. Инициализировать шарды
docker exec -it shard1 mongosh --port 27017

> rs.initiate(
  {
    _id : "shard1",
    members: [
      { _id : 0, host : "shard1:27017" }
    ]
  }
);
> exit();

3. Инициализировать шарды
docker exec -it shard2 mongosh --port 27017

> rs.initiate(
  {
    _id : "shard2",
    members: [
      { _id : 0, host : "shard2:27017" }
    ]
  }
);
> exit();
3. Создайте тестовые документы
docker exec -it mongos_router mongosh --port 27020

> sh.addShard( "shard1/shard1:27018");
> sh.addShard( "shard2/shard2:27019");

> sh.enableSharding("somedb");
> sh.shardCollection("somedb.helloDoc", { "name" : "hashed" } )

> use somedb

> for(var i = 0; i < 1000; i++) db.helloDoc.insert({age:i, name:"ly"+i})

> db.helloDoc.countDocuments() 
> exit();


# pymongo-api

## Как запустить

Запускаем mongodb и приложение

```shell
docker compose up -d
```
Заполняем mongodb данными

```shell
./scripts/mongo-init.sh
```

## Как проверить
### Если вы запускаете проект на локальной машине
Откройте в браузере http://localhost:8080

### Если вы запускаете проект на предоставленной виртуальной машине
Узнать белый ip виртуальной машины

```shell
curl --silent http://ifconfig.me
```
Откройте в браузере http://<ip виртуальной машины>:8080
## Доступные эндпоинты

Список доступных эндпоинтов, swagger http://<ip виртуальной машины>:8080/docs