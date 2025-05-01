#!/bin/bash

# Скрипт для ручного запуска приложения ATOM-GAME без PM2
# Май 2025

# Переход в корневую директорию для предотвращения ошибок c getcwd()
cd /

# Цвета для вывода
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # Сброс цвета

# Настройки
INSTALL_PATH="/var/www/atomgame"
SERVER_PORT="5001"
DB_USER="atomgame"
DB_PASSWORD="AtomGame2025"
DB_NAME="atomgame"

# Функции вывода
log() {
  echo -e "${GREEN}[ЗАПУСК]${NC} $1"
}

error() {
  echo -e "${RED}[ОШИБКА]${NC} $1"
  exit 1
}

# Проверка существования директории
if [ ! -d "$INSTALL_PATH" ]; then
   error "Директория $INSTALL_PATH не существует!"
fi

# Переход в директорию проекта
cd "$INSTALL_PATH" || error "Не удалось перейти в $INSTALL_PATH"

# Экспорт переменных окружения
export NODE_ENV=production
export PORT=$SERVER_PORT
export HOST=0.0.0.0
export PGUSER=$DB_USER
export PGPASSWORD=$DB_PASSWORD
export PGDATABASE=$DB_NAME
export PGHOST=localhost
export PGPORT=5432
export DATABASE_URL=postgresql://$DB_USER:$DB_PASSWORD@localhost:5432/$DB_NAME
export SESSION_SECRET=AtomGameSecretKey2025

log "Запуск приложения на порту $SERVER_PORT..."
log "Для остановки нажмите Ctrl+C"
echo ""

# Запуск приложения напрямую
node dist/index.js