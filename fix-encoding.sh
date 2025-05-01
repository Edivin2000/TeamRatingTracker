#!/bin/bash

# ==========================================
# СКРИПТ ИСПРАВЛЕНИЯ КОДИРОВКИ БАЗЫ ДАННЫХ ATOM-GAME
# ==========================================
# Версия: 1.0.0
# Дата: 01.05.2025
# Автор: ATOM-GAME Team
# ==========================================

set -e

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Переменные настройки с реальными данными
DB_NAME="atomgame"
DB_USER="atomgame"
DB_PASSWORD="Atom&Game#2025!"
PROJECT_DIR="/var/www/atomgameblk"
ESCAPED_PASSWORD=$(echo $DB_PASSWORD | sed 's/&/%26/g; s/#/%23/g')
DATABASE_URL="postgresql://$DB_USER:$ESCAPED_PASSWORD@localhost:5432/$DB_NAME"

# Функции для вывода
log() {
  echo -e "${BLUE}[ИНФО]${NC} $1"
}

success() {
  echo -e "${GREEN}[УСПЕХ]${NC} $1"
}

warn() {
  echo -e "${YELLOW}[ВНИМАНИЕ]${NC} $1"
}

error() {
  echo -e "${RED}[ОШИБКА]${NC} $1"
}

# Проверка запуска от root
if [ "$(id -u)" != "0" ]; then
   error "Этот скрипт должен быть запущен от имени root"
   error "Пожалуйста, используйте: sudo ./fix-encoding.sh"
   exit 1
fi

# Исправление проблемы с кодировкой базы данных
log "Исправление проблемы с кодировкой базы данных PostgreSQL..."

# Проверка существования базы данных
if ! sudo -u postgres psql -lqt | cut -d \| -f 1 | grep -qw $DB_NAME; then
  error "База данных $DB_NAME не существует. Сначала создайте базу данных."
  exit 1
fi

# Исправление кодировки базы данных
log "Обновление кодировки базы данных..."
sudo -u postgres psql -c "UPDATE pg_database SET datistemplate = FALSE WHERE datname = '$DB_NAME';"
sudo -u postgres psql -c "DROP DATABASE $DB_NAME;"
sudo -u postgres psql -c "CREATE DATABASE $DB_NAME WITH OWNER = $DB_USER ENCODING = 'UTF8' LC_COLLATE = 'en_US.UTF-8' LC_CTYPE = 'en_US.UTF-8' TEMPLATE = template0;"
success "Кодировка базы данных обновлена на UTF8"

# Создание .env файла с правильными настройками
log "Создание конфигурационного файла .env..."
cat > $PROJECT_DIR/.env << EOF
# Основные настройки
NODE_ENV=production
PORT=5000

# База данных PostgreSQL
PGUSER=$DB_USER
PGPASSWORD=$DB_PASSWORD
PGDATABASE=$DB_NAME
PGHOST=localhost
PGPORT=5432
DATABASE_URL=$DATABASE_URL

# Безопасность
SESSION_SECRET=$(openssl rand -hex 32)
EOF
success "Файл .env создан с правильными настройками"

# Проверка соединения с БД
log "Проверка соединения с базой данных..."
if PGPASSWORD="$DB_PASSWORD" psql -h localhost -U $DB_USER -d $DB_NAME -c "\conninfo" 2>/dev/null; then
  success "Соединение с базой данных установлено успешно"
else
  warn "Не удалось подключиться к базе данных. Убедитесь, что PostgreSQL настроен правильно."
  warn "Возможно, нужно перезапустить PostgreSQL: sudo systemctl restart postgresql"
  exit 1
fi

# Создание схемы базы данных
log "Создание схемы базы данных..."
cd $PROJECT_DIR
npm run db:push || true
success "Схема базы данных создана"

# Обновление конфигурации PM2 с переменными окружения
log "Обновление конфигурации PM2..."
cat > $PROJECT_DIR/ecosystem.config.cjs << EOF
module.exports = {
  apps: [{
    name: 'atom-game',
    script: 'dist/index.js',
    instances: 'max',
    exec_mode: 'cluster',
    env: {
      NODE_ENV: 'production',
      PORT: '5000',
      PGUSER: '$DB_USER',
      PGPASSWORD: '$DB_PASSWORD',
      PGDATABASE: '$DB_NAME',
      PGHOST: 'localhost',
      PGPORT: '5432',
      DATABASE_URL: '$DATABASE_URL',
      SESSION_SECRET: '$(openssl rand -hex 32)'
    },
    max_memory_restart: '500M'
  }]
};
EOF
success "Файл конфигурации PM2 обновлен"

# Перестройка приложения
log "Перестройка приложения..."
cd $PROJECT_DIR
npm run build
success "Приложение перестроено"

# Перезапуск приложения с PM2
log "Перезапуск приложения с PM2..."
pm2 delete atom-game || true
pm2 start ecosystem.config.cjs
pm2 save
success "Приложение перезапущено"

echo "=================================================================="
echo "        ИСПРАВЛЕНИЕ КОДИРОВКИ БАЗЫ ДАННЫХ ЗАВЕРШЕНО УСПЕШНО!"
echo "=================================================================="
echo ""
echo "ПРОВЕРКА СТАТУСА ПРИЛОЖЕНИЯ:"
echo ""
pm2 status atom-game
echo ""
echo "Дождитесь несколько секунд, затем проверьте логи приложения:" 
echo "pm2 logs atom-game"
echo ""
echo "Вы можете проверить работу приложения, открыв его в браузере:"
echo "http://atomgameblk.ru или http://193.109.78.85"
echo "=================================================================="