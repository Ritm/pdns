-- Минимальный конфиг только для подключения к консоли dnsdist (клиент).
-- Ключ в base64 (32 байта), тот же что в dnsdist.lua.
-- Использование: dnsdist -C /etc/dnsdist/console-client.lua -c 127.0.0.1:5199
setKey("MTIzNDU2Nzg5MDEyMzQ1Njc4OTAxMjM0NTY3ODkwMTI=")
