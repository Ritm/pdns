-- Список вышестоящих DoH-серверов. Используются только они, других запросов нет.
-- Формат: newServer({address="host:443", dohPath="/dns-query", subjectName="host", validateCertificates=true})
-- Добавьте или удалите серверы по необходимости.
--
-- Если бэкенды помечаются "down" и dig даёт timeout: часто виновата проверка сертификатов
-- (в образе нет доверенных CA или дата контейнера неверна). Временно можно поставить
-- validateCertificates = false (менее безопасно, только для проверки связи).

-- Cloudflare
newServer({
  address = "1.1.1.1:443",
  tls = "openssl",
  subjectName = "cloudflare-dns.com",
  dohPath = "/dns-query",
  validateCertificates = false
})

-- Quad9
newServer({
  address = "9.9.9.9:443",
  tls = "openssl",
  subjectName = "dns.quad9.net",
  dohPath = "/dns-query",
  validateCertificates = false
})

-- Google (пример, раскомментируйте при необходимости)
-- newServer({
--   address = "8.8.8.8:443",
--   tls = "openssl",
--   subjectName = "dns.google",
--   dohPath = "/dns-query",
--   validateCertificates = true
-- })
