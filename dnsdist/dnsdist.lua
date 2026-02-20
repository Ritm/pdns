-- dnsdist: только свой список DoH вышестоящих, кэш, при необходимости — локальные зоны в PowerDNS Authoritative

setLocal("0.0.0.0:53")
-- Слушать ещё и [::]:53 ломало ответы (dig таймаут). Оставлен только IPv4.
-- setLocal("[::]:53")

-- Разрешить запросы с любых адресов (по умолчанию только частные сети — с внешнего ПК не резолвит).
-- Для ограничения доступа: setACL({'10.0.0.0/8', '192.168.0.0/16', 'ВАШ_IP/32'})
setACL({"0.0.0.0/0", "::/0"})

-- Кэш ответов (только для пула по умолчанию — DoH)
pc = newPacketCache(100000, {
  maxTTL = 86400,
  minTTL = 0,
  temporaryFailureTTL = 60,
  staleTTL = 60,
  dontAge = false
})
getPool(""):setCache(pc)

-- Зоны, которые обслуживает PowerDNS Authoritative (запросы к ним идут на pdns:53)
-- Пустой список = только DoH, без ошибки "Unable to convert presentation address 'pdns:53'" при старте.
-- Когда понадобятся локальные зоны — укажите суффиксы и убедитесь, что имя pdns резолвится (Docker DNS).
LocalZoneSuffixes = {}

-- PowerDNS Authoritative — только для запросов к LocalZoneSuffixes
if #LocalZoneSuffixes > 0 then
  newServer({address = "pdns:53", pool = "pdns"})
  addAction(SuffixMatchNodeRule(LocalZoneSuffixes), PoolAction("pdns"))
end

-- Вышестоящие DoH-серверы (только из списка в upstreams.lua)
dofile("/etc/dnsdist/upstreams.lua")
-- Явно задаём воркеры для исходящего DoH (по умолчанию 0, поднимается до 1 при наличии DoH-бэкендов; ставим 2 для надёжности)
setOutgoingDoHWorkerThreads(2)

-- Все остальные запросы обрабатываются пулом по умолчанию (DoH + кэш)
-- Дополнительных вышестоящих серверов нет — только перечисленные в upstreams.lua

-- Консоль: явно слушать 5199 и ключ в base64 (подключение: dnsdist -C /etc/dnsdist/console-client.lua -c 127.0.0.1:5199)
controlSocket("0.0.0.0:5199")
setKey("MTIzNDU2Nzg5MDEyMzQ1Njc4OTAxMjM0NTY3ODkwMTI=")
setConsoleACL({"0.0.0.0/0", "::/0"})
