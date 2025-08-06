 ## Как запустить
Запускаем mongodb и приложение

```shell
docker compose up -d
```

 # Настройка шардирования
Подключитесь к серверу конфигурации и сделайте инициализацию
```shell
docker exec -it configSrv mongosh --port 27017
```
```
rs.initiate(
  {
    _id : "config_server",
       configsvr: true,
    members: [
      { _id : 0, host : "configSrv:27017" }
    ]
  }
)
```

Инициализируйте шарды
```
docker exec -it shard1 mongosh --port 27018

> rs.initiate(
    {
      _id : "shard1",
      members: [
        { _id : 0, host : "shard1:27018" },
       // { _id : 1, host : "shard2:27019" }
      ]
    }
);
> exit();

docker exec -it shard2 mongosh --port 27019

> rs.initiate(
    {
      _id : "shard2",
      members: [
       // { _id : 0, host : "shard1:27018" },
        { _id : 1, host : "shard2:27019" }
      ]
    }
  );
> exit();
```

Заполняем mongodb данными

```shell
./scripts/mongo-init.sh
```

## Как проверить

### Если вы запускаете проект на локальной машине

Откройте в браузере http://localhost:8080
 
 
 
 
 
 
 
 
 
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



## Как проверить

docker compose exec -T shard1 mongosh --port 27018 --quiet <<EOF
use somedb
db.helloDoc.countDocuments()
EOF 

docker compose exec -T shard2 mongosh --port 27018 --quiet <<EOF
use somedb
db.helloDoc.countDocuments()
EOF 