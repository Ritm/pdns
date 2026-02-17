# PowerDNS + PowerDNS-Admin + MySQL

## Что разворачивается

- `PowerDNS Authoritative` (MySQL backend)
- `PowerDNS-Admin` (веб-панель)
- `MariaDB` (хранилище DNS и данных панели)

Все данные сохраняются на хосте в каталоге `./data`.

## Структура

- `docker-compose.yml` - сервисы
- `.env.example` - пример переменных окружения
- `mysql/init/01-pdns.sql` - инициализация схемы PowerDNS и БД панели
- `data/mysql` - данные MariaDB (на хосте)
- `data/pdns-admin` - данные PowerDNS-Admin (на хосте)

## Быстрый старт

1. Перейдите в каталог:
   - `cd /home/user/ownCloud/pdns`
2. Создайте `.env`:
   - `cp .env.example .env`
3. Отредактируйте секреты в `.env`.
4. Запустите:
   - `docker compose up -d`

## Порты

- DNS: `53/tcp` и `53/udp`
- API PowerDNS: `8081`
- PowerDNS-Admin: `9191`

## Проверка

- Откройте панель: `http://<host>:9191`
- API PowerDNS: `http://<host>:8081/api/v1/servers/localhost`
  - используйте ключ `PDNS_API_KEY` из `.env`

## Примечания

- Для порта `53` обычно нужны права root или CAP_NET_BIND_SERVICE.
- Если первый запуск PowerDNS-Admin длится долго, подождите 1-2 минуты: выполняются миграции.
# pdns
