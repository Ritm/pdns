-- dnsdist: только свой список DoH вышестоящих, кэш, при необходимости — локальные зоны в PowerDNS Authoritative

setLocal("0.0.0.0:53")
setLocal("[::]:53")

-- Кэш ответов (только для пула по умолчанию — DoH)
pc = newPacketCache(100000, {
  maxTTL = 86400,
  minTTL = 0,
  temporaryFailureTTL = 60,
  staleTTL = 60,
  dontAge = false,
  shuffle = false
})
getPool(""):setCache(pc)

-- Зоны, которые обслуживает PowerDNS Authoritative (запросы к ним идут на pdns:53)
-- Укажите суффиксы ваших зон или оставьте пустым, если используете только DoH
LocalZoneSuffixes = {"example.org", "example.com"}

-- PowerDNS Authoritative — только для запросов к LocalZoneSuffixes
if #LocalZoneSuffixes > 0 then
  newServer({address = "pdns:53", pool = "pdns"})
  addAction(SuffixMatchNodeRule(LocalZoneSuffixes), PoolAction("pdns"))
end

-- Вышестоящие DoH-серверы (только из списка в upstreams.lua)
dofile("/etc/dnsdist/upstreams.lua")

-- Все остальные запросы обрабатываются пулом по умолчанию (DoH + кэш)
-- Дополнительных вышестоящих серверов нет — только перечисленные в upstreams.lua

setConsoleACL({"0.0.0.0/0", "::/0"})
