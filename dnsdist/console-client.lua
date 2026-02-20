-- Минимальный конфиг только для подключения к консоли dnsdist (клиент).
-- Не содержит newServer и т.п., поэтому не падает при загрузке клиентом.
-- Использование: dnsdist -C /etc/dnsdist/console-client.lua -c 127.0.0.1:5199
setKey("dnsdist-console")
