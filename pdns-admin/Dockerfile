# Образ с pymysql для подключения к MySQL (mysql+pymysql://)
FROM ngoduykhanh/powerdns-admin:latest
USER root
RUN pip install --no-cache-dir pymysql
# Базовый образ задаёт своего пользователя в ENTRYPOINT — не переключаем обратно
