# PowerDNS + PowerDNS-Admin + MySQL + dnsdist

## Что разворачивается

- **dnsdist** — принимает запросы на порту 53, кэширует ответы, отправляет рекурсию **только** на ваш список DoH-серверов
- `PowerDNS Authoritative` (MySQL backend) — только для ваших зон (по списку в конфиге dnsdist)
- `PowerDNS-Admin` (веб-панель)
- `MariaDB` (хранилище DNS и данных панели)

Все данные сохраняются на хосте в каталоге `./data`.

### DoH и кэш

- Вышестоящие серверы задаются **только** в `dnsdist/upstreams.lua` в формате DoH (DNS over HTTPS). Других запросов «наружу» нет.
- Ответы от DoH кэшируются в dnsdist (до 100 000 записей, TTL до 24 ч).
- Зоны, которые обслуживает PowerDNS Authoritative, перечислены в `dnsdist/dnsdist.lua` в переменной `LocalZoneSuffixes`; запросы к ним идут на pdns, остальное — на DoH.

## Структура

- `docker-compose.yml` - сервисы
- `.env.example` - пример переменных окружения
- `dnsdist/dnsdist.lua` - конфиг dnsdist (кэш, пулы, локальные зоны)
- `dnsdist/upstreams.lua` - **список вышестоящих DoH-серверов** (редактируйте под себя)
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
- Чтобы изменить список вышестоящих серверов: правьте `dnsdist/upstreams.lua` и перезапустите контейнер `pdns-dnsdist`.
- Чтобы изменить зоны, уходящие на PowerDNS Authoritative: правьте `LocalZoneSuffixes` в `dnsdist/dnsdist.lua`.
