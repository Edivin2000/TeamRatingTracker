#!/bin/bash

# ==========================================
# СКРИПТ ИСПРАВЛЕНИЯ БАЗЫ ДАННЫХ ATOM-GAME
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
   error "Пожалуйста, используйте: sudo ./fix-db.sh"
   exit 1
fi

# Исправление проблемы с базой данных PostgreSQL
log "Исправление проблемы с базой данных PostgreSQL..."

# Проверка и создание пользователя базы данных
if ! sudo -u postgres psql -tAc "SELECT 1 FROM pg_roles WHERE rolname='$DB_USER'" | grep -q 1; then
  log "Создание пользователя $DB_USER..."
  sudo -u postgres psql -c "CREATE USER $DB_USER WITH PASSWORD '$DB_PASSWORD';"
  success "Пользователь $DB_USER создан"
else
  log "Пользователь $DB_USER уже существует. Обновление пароля..."
  sudo -u postgres psql -c "ALTER USER $DB_USER WITH PASSWORD '$DB_PASSWORD';"
  success "Пароль пользователя $DB_USER обновлен"
fi

# Проверка и создание базы данных
if ! sudo -u postgres psql -lqt | cut -d \| -f 1 | grep -qw $DB_NAME; then
  log "Создание базы данных $DB_NAME..."
  sudo -u postgres psql -c "CREATE DATABASE $DB_NAME;"
  success "База данных $DB_NAME создана"
else
  log "База данных $DB_NAME уже существует"
fi

# Настройка прав доступа
log "Настройка прав доступа к базе данных..."
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;"
sudo -u postgres psql -c "ALTER DATABASE $DB_NAME OWNER TO $DB_USER;"
success "Права доступа к базе данных настроены"

# Настройка прав доступа PostgreSQL
log "Настройка конфигурации PostgreSQL..."
cat > /etc/postgresql/$(ls /etc/postgresql/ | sort -V | tail -n1)/main/pg_hba.conf << EOF
# PostgreSQL Client Authentication Configuration File
# ===================================================
local   all             postgres                                peer
local   all             all                                     md5
host    all             all             127.0.0.1/32            md5
host    all             all             ::1/128                 md5
EOF

systemctl restart postgresql
success "Конфигурация PostgreSQL обновлена"

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
DATABASE_URL=postgresql://$DB_USER:$(echo $DB_PASSWORD | sed 's/&/%26/g; s/#/%23/g')@localhost:5432/$DB_NAME

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

# Применение миграций базы данных
log "Применение миграций базы данных..."
cd $PROJECT_DIR
npm run db:push
success "Структура базы данных создана"

# Перезапуск приложения с PM2
log "Перезапуск приложения с PM2..."
pm2 delete atom-game || true
pm2 start ecosystem.config.cjs
pm2 save
success "Приложение перезапущено"

echo "=================================================================="
echo "        ИСПРАВЛЕНИЕ БАЗЫ ДАННЫХ ЗАВЕРШЕНО УСПЕШНО!"
echo "=================================================================="
echo ""
echo "Вы можете проверить работу приложения, открыв его в браузере."
echo ""
echo "Для просмотра логов приложения используйте: pm2 logs atom-game"
echo "=================================================================="