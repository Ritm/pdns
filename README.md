# PowerDNS + PowerDNS-Admin + MySQL + dnsdist

## Что разворачивается

- **dnsdist** — принимает запросы на порту 53, кэширует ответы, отправляет рекурсию **только** на ваш список DoH-серверов
- `PowerDNS Authoritative` (MySQL backend) — только для ваших зон (по списку в конфиге dnsdist)
- `PowerDNS-Admin` (веб-панель)
- `MariaDB` (хранилище DNS и данных панели)

Все данные сохраняются на хосте в каталоге `./data`.

### DoH и кэш

- Вышестоящие серверы задаются **только** в `dnsdist/upstreams.lua` в формате DoH (DNS over HTTPS). Других запросов «наружу» нет.
- По умолчанию dnsdist принимает запросы только из частных сетей. Чтобы резолвинг работал с вашего ПК по интернету, в конфиге задано `setACL({"0.0.0.0/0", "::/0"})`. Для ограничения доступа замените на свои подсети или IP (см. комментарий в `dnsdist.lua`).
- Ответы от DoH кэшируются в dnsdist (до 100 000 записей, TTL до 24 ч).
- Зоны, которые обслуживает PowerDNS Authoritative, перечислены в `dnsdist/dnsdist.lua` в переменной `LocalZoneSuffixes`; запросы к ним идут на pdns, остальное — на DoH.

## Структура

- `docker-compose.yml` - сервисы
- `.env.example` - пример переменных окружения
- `dnsdist/dnsdist.lua` - конфиг dnsdist (кэш, пулы, локальные зоны)
- `dnsdist/console-client.lua` - только ключ консоли (для подключения клиента без загрузки полного конфига)
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

### Доступ снаружи (файрвол и security group)

Если с другого компьютера к серверу недоступны порты 53 или 9191 (telnet/IP «connection refused»), при этом контейнеры запущены и в `docker ps` порты проброшены (`0.0.0.0:53->53`, `0.0.0.0:9191->...`) — скорее всего блокирует **файрвол на сервере** или **правила у хостинга** (security group / firewall в панели).

**На сервере (ufw):**
```bash
sudo ufw allow 53/tcp
sudo ufw allow 53/udp
sudo ufw allow 9191/tcp
sudo ufw status
sudo ufw enable   # если ещё не включён
```

**У хостинга (Hetzner, AWS, и т.п.):** в панели управления открыть входящие порты 53 (tcp/udp) и 9191 (tcp) для этого сервера.

## Проверка

- Откройте панель: `http://<host>:9191`
- **Первый вход:** логина/пароля по умолчанию нет. На странице входа нажмите **Sign up** (Регистрация) и создайте первого пользователя — он будет администратором.
- API PowerDNS: `http://<host>:8081/api/v1/servers/localhost` (в браузере по корню `/` может быть «сброс» — API отдаёт JSON по путям `/api/...`)
  - используйте ключ `PDNS_API_KEY` из `.env`

## Проверка DoH и кэша

**1. Работа с вышестоящими DoH**

Если запросы к вашему резолверу (порт 53) возвращают ответы — они уже идут через ваш список DoH из `dnsdist/upstreams.lua`; других вышестоящих в конфиге нет. Проверка с хоста (или с машины, чей DNS указывает на этот сервер):

```bash
dig @127.0.0.1 ya.ru +short
# или с другого ПК: dig @<IP_сервера> ya.ru +short
```

Ответ с адресами означает, что DoH-резолверы из списка отвечают.

**2. Кэширование**

- Первый запрос по домену уходит в DoH и попадает в кэш dnsdist.
- Повторный запрос по тому же домену (пока не истёк TTL) обслуживается из кэша — без повторного запроса на DoH.

Проверка «на глаз»: выполнить один и тот же запрос дважды подряд; второй ответ часто приходит быстрее (особенно заметно при задержке до интернета).

**3. Статистика кэша dnsdist**

Консоль dnsdist слушает порт 5199 внутри контейнера. Подключение (ключ задан в `console-client.lua` и в `dnsdist.lua`, в формате base64):

```bash
docker exec -it pdns-dnsdist dnsdist -C /etc/dnsdist/console-client.lua -c 127.0.0.1:5199
```

Если в каталоге есть `dnsdist.conf` с полным конфигом, клиент по умолчанию его подхватит и упадёт на `newServer("pdns:53")`. В каталоге должны быть только `dnsdist.lua`, `console-client.lua` и `upstreams.lua`.

В приглашении консоли ввести (и нажать Enter):

```lua
getPool(""):getCache():printStats()
```

Будут выведены счётчики записей, попаданий и промахов кэша. Выход из консоли: `quit` или Ctrl+D.

### Как проверить, что ПК использует ваш DNS

1. **На рабочем ПК — какой DNS прописан**
   - **Windows:** `ipconfig /all` — смотрите «DNS-серверы» для нужного подключения. Или Параметры → Сеть и Интернет → свой адаптер → Назначение DNS (или «Дополнительно»).
   - **Linux:** `resolvectl status` или `cat /etc/resolv.conf` — смотрите `nameserver`.

2. **Кто реально отвечает на запросы**
   - На ПК выполните `nslookup ya.ru` (без указания сервера). В выводе будет строка **Server: …** — это и есть DNS, который использует система. Должен быть IP вашего сервера (например 194.87.35.238).
   - Либо: `dig ya.ru +short` и на сервере в консоли dnsdist сразу выполните `getPool(""):getCache():printStats()` и `showServers()` — если счётчики (Hits/Misses, Queries) выросли после запроса с ПК, запросы идут на ваш сервер.

3. **Проверка через сайт**
   - Откройте на рабочем ПК https://dnsleaktest.com (или https://ipleak.net ), запустите тест DNS. В списке «DNS Servers» должен отображаться IP вашего сервера (если система действительно использует его как DNS).

### dig даёт timeout, кэш 0/0

Запросы приходят в dnsdist, но ответа нет — обычно **контейнер dnsdist не может достучаться до DoH** (1.1.1.1:443, 9.9.9.9:443) или хост «зациклился» на dnsdist для DNS.

**Важно:** если хост использует для DNS только dnsdist (127.0.0.1), а dnsdist не отвечает (нет выхода в интернет из контейнера), хост перестаёт резолвить имена — в том числе `registry-1.docker.io` при `docker pull`. Лучше, чтобы **хост** для своего DNS использовал отдельный резолвер (systemd-resolved, провайдерский DNS и т.п.), а на dnsdist указывали только те клиенты/сети, которым нужен ваш DoH-резолвер.

Что проверить:

1. **Статус бэкендов в консоли dnsdist:**
   ```bash
   docker exec -it pdns-dnsdist dnsdist -C /etc/dnsdist/console-client.lua -c 127.0.0.1:5199
   ```
   В приглашении ввести: `showServers()` — смотреть колонку State (UP/DOWN) и счётчики.

2. **Доступ из контейнера dnsdist до 1.1.1.1:443** (без скачивания образов; образ dnsdist обычно содержит openssl):
   ```bash
   docker exec pdns-dnsdist timeout 5 openssl s_client -connect 1.1.1.1:443 -brief </dev/null 2>&1 | head -5
   ```
   Успех: в выводе есть что‑то вроде `Connection established` или `Protocol version: TLSv1.3`. Таймаут или «Connection refused» — из контейнера нет выхода на 1.1.1.1:443 (файрвол, NAT, ограничения хостинга).

3. **Проверка по TCP:** если до 1.1.1.1:443 из контейнера есть (openssl s_client успешен), но `dig @127.0.0.1 ya.ru +short` таймаутит — попробуйте `dig @127.0.0.1 ya.ru +short +tcp`. Если по TCP отвечает, а по UDP нет, возможна особенность обработки UDP в связке Docker/DoH.
4. **Слушать только IPv4:** в части окружений при `setLocal("[::]:53")` (IPv6) ответы перестают доходить (dig таймаут). В `dnsdist.lua` закомментирован вызов для IPv6; остаётся только `setLocal("0.0.0.0:53")`.
5. В `dnsdist/upstreams.lua` для проверки уже стоит `validateCertificates = false`. После проверки связи лучше вернуть `true` и при необходимости смонтировать CA (см. ниже).

### DoH-бэкенды «down», запросы не идут

Если в логах dnsdist видно «Marking downstream … as 'down'», запросы к DoH не доходят или падают. Частые причины:

1. **Проверка сертификатов** — в образе может не быть актуальных CA или неверное время. Во временном режиме в `dnsdist/upstreams.lua` для всех `newServer(...)` можно выставить `validateCertificates = false` (менее безопасно). После проверки связи лучше вернуть `true` и при необходимости смонтировать в контейнер хостовые сертификаты, например: в `docker-compose.yml` у сервиса `dnsdist` добавить в `volumes`: `- /etc/ssl/certs/ca-certificates.crt:/etc/ssl/certs/ca-certificates.crt:ro` (путь может отличаться: на Debian/Ubuntu это часто `/etc/ssl/certs/ca-certificates.crt`).

2. **Нет выхода в интернет из контейнера** — проверить с хоста:  
   `docker exec pdns-dnsdist sh -c 'wget -q -O- https://1.1.1.1 --no-check-certificate | head -1'`  
   или что из контейнера разрешается DNS и открывается HTTPS до 1.1.1.1 / 9.9.9.9.

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

## Ошибка «Table 'pdns.domains' doesn't exist»

Появляется, если каталог `data/mysql` уже существовал до добавления скрипта инициализации — скрипты в `mysql/init/` выполняются только при **первом** запуске с пустой БД. Применить схему вручную (подставьте пароль root из `.env`):

```bash
docker exec -i pdns-db mysql -uroot -p'ВАШ_MYSQL_ROOT_PASSWORD' < mysql/init/01-pdns.sql
```

Или из каталога проекта с подстановкой из `.env`:

```bash
source .env 2>/dev/null; docker exec -i pdns-db mysql -uroot -p"${MYSQL_ROOT_PASSWORD}" < mysql/init/01-pdns.sql
```

После этого перезапустите pdns: `docker compose restart pdns-auth`.

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
