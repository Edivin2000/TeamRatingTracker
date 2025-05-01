#!/bin/bash

# Скрипт для непосредственного запуска приложения без PM2 и systemd
# Май 2025

# Переход в корневую директорию
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

# Проверка директории
if [ ! -d "$INSTALL_PATH" ]; then
   error "Директория $INSTALL_PATH не существует!"
fi

# Перейти в директорию проекта
cd "$INSTALL_PATH" || error "Не удалось перейти в директорию $INSTALL_PATH"

# Отображение информации о среде
echo -e "${GREEN}==========================================${NC}"
echo -e "${GREEN}   Прямой запуск ATOM-GAME приложения   ${NC}"
echo -e "${GREEN}==========================================${NC}"
echo ""
log "Настройка переменных окружения..."

# Настройка переменных окружения
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

# Отображение настроек переменных
echo "NODE_ENV=$NODE_ENV"
echo "PORT=$PORT"
echo "HOST=$HOST"
echo "DATABASE_URL=$DATABASE_URL"
echo ""
log "Запуск приложения..."
echo -e "${YELLOW}Для остановки нажмите Ctrl+C${NC}"
echo ""

# Прямой запуск Node.js приложения
node dist/index.js