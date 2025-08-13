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