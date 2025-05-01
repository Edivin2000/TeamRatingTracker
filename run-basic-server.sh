#!/bin/bash

# Скрипт для запуска базового сервера в случае, если основной сервер не запускается

# Цвета для вывода
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Переменные
SERVER_DIR="/var/www/atomgameblk"
PORT=5000

# Экспорт переменных окружения для PostgreSQL
export PGUSER=atomgame
export PGPASSWORD='Atom&Game#2025!'
export PGDATABASE=atomgame
export PGHOST=localhost
export PGPORT=5432
export DATABASE_URL="postgresql://atomgame:Atom%26Game%232025!@localhost:5432/atomgame"
export PORT=$PORT

echo -e "${YELLOW}Останавливаем PM2...${NC}"
pm2 delete all || true

echo -e "${YELLOW}Переходим в директорию проекта...${NC}"
cd $SERVER_DIR

echo -e "${YELLOW}Устанавливаем необходимые пакеты для базового сервера...${NC}"
npm install express pg

echo -e "${GREEN}Запускаем базовый сервер...${NC}"
echo -e "${YELLOW}Лог будет доступен в текущем терминале.${NC}"
echo -e "${YELLOW}Для остановки сервера нажмите Ctrl+C${NC}"
echo "-----------------------------------------------------"

# Запускаем базовый сервер
node basic-server.mjs