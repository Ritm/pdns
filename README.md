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
- `pdns/pdns.conf` - конфиг PowerDNS Authoritative (gmysql, без gsqlite3)
- `pdns-admin/Dockerfile` - образ панели с драйвером pymysql для MySQL
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

## Порт 53 занят systemd-resolved

Если dnsdist не стартует из‑за «port is already allocated», на хосте обычно слушает **systemd-resolved**. Освободить порт 53:

1. **Отключить DNS-заглушку resolved:**
   ```bash
   sudo mkdir -p /etc/systemd/resolved.conf.d
   echo -e '[Resolve]\nDNSStubListener=no' | sudo tee /etc/systemd/resolved.conf.d/disable-stub.conf
   sudo systemctl restart systemd-resolved
   ```

2. **Сделать резолвером системы dnsdist** (чтобы сам хост ходил в DNS через ваш стек):
   - В `resolved` можно указать DNS=127.0.0.1 (тогда резолвер — кто слушает на 127.0.0.1:53, т.е. dnsdist после проброса порта).
   - Или статически прописать в `/etc/resolv.conf` строку `nameserver 127.0.0.1` (если не используете resolved для DNS).

3. Запустить стек: `docker compose up -d`.

**Если порт 53 трогать не хотите:** в `docker-compose.yml` у сервиса `dnsdist` замените проброс портов на, например, `"5353:53"` и используйте для DNS адрес `<хост>:5353`.

## Ошибка «ERROR: for pdns 'ContainerConfig'»

Известный баг Docker Compose при пересоздании контейнеров. Решение: удалить контейнеры и поднять заново:

```bash
docker compose down
docker compose up -d
```

Если не помогло — пересоздать только pdns и перезапустить стек:

```bash
docker compose stop pdns-auth
docker rm -f pdns-auth 2>/dev/null
docker compose up -d
```

## Примечания

- Для порта `53` обычно нужны права root или CAP_NET_BIND_SERVICE.
- Если первый запуск PowerDNS-Admin длится долго, подождите 1-2 минуты: выполняются миграции.
- Чтобы изменить список вышестоящих серверов: правьте `dnsdist/upstreams.lua` и перезапустите контейнер `pdns-dnsdist`.
- Чтобы изменить зоны, уходящие на PowerDNS Authoritative: правьте `LocalZoneSuffixes` в `dnsdist/dnsdist.lua`.
