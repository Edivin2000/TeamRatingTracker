#!/bin/bash

# ==========================================
# СКРИПТ ИСПРАВЛЕНИЯ УСТАНОВКИ ATOM-GAME
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
PROJECT_DIR="/var/www/atomgameblk"
DOMAIN="atomgameblk.ru"
DB_NAME="atomgame"
DB_USER="atomgame"
DB_PASSWORD="Atom&Game#2025!"
ADMIN_PASSWORD="Atom&Game#2025!"

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
   error "Пожалуйста, используйте: sudo ./fix-deployment.sh"
   exit 1
fi

# Исправление проблемы с базой данных
log "Исправление проблемы с базой данных PostgreSQL..."
if sudo -u postgres psql -lqt | cut -d \| -f 1 | grep -qw $DB_NAME; then
  warn "База данных $DB_NAME уже существует. Попытка обновления пользователя..."
  sudo -u postgres psql -c "ALTER USER $DB_USER WITH PASSWORD '$DB_PASSWORD';"
else
  sudo -u postgres psql -c "CREATE USER $DB_USER WITH PASSWORD '$DB_PASSWORD';"
  sudo -u postgres psql -c "CREATE DATABASE $DB_NAME;"
  sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;"
  sudo -u postgres psql -c "ALTER DATABASE $DB_NAME OWNER TO $DB_USER;"
fi
success "База данных настроена"

# Настройка прав доступа PostgreSQL
log "Настройка прав доступа PostgreSQL..."
cat > /etc/postgresql/$(ls /etc/postgresql/ | sort -V | tail -n1)/main/pg_hba.conf << EOF
# PostgreSQL Client Authentication Configuration File
# ===================================================
local   all             postgres                                peer
local   all             all                                     md5
host    all             all             127.0.0.1/32            md5
host    all             all             ::1/128                 md5
EOF

systemctl restart postgresql
success "Права доступа PostgreSQL настроены"

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
if PGPASSWORD="$DB_PASSWORD" psql -h localhost -U $DB_USER -d $DB_NAME -c "\conninfo"; then
  success "Соединение с базой данных установлено успешно"
else
  error "Не удалось подключиться к базе данных. Проверьте настройки и запустите скрипт еще раз."
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

# Проверка запуска приложения
log "Проверка запуска приложения..."
sleep 3
if pm2 list | grep -q "atom-game" && pm2 list | grep -q "online"; then
  success "Приложение запущено успешно"
else
  warn "Приложение может быть не запущено. Проверьте логи: pm2 logs atom-game"
fi

# Настройка Nginx
log "Настройка Nginx..."
cat > /etc/nginx/sites-available/$DOMAIN << EOF
server {
    listen 80;
    server_name $DOMAIN www.$DOMAIN;

    location / {
        proxy_pass http://localhost:5000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
    }
}
EOF

ln -sf /etc/nginx/sites-available/$DOMAIN /etc/nginx/sites-enabled/
nginx -t && systemctl restart nginx
success "Nginx настроен"

# Вывод информации об успешной установке
echo "=================================================================="
echo "        ИСПРАВЛЕНИЕ ATOM-GAME ЗАВЕРШЕНО УСПЕШНО!"
echo "=================================================================="
echo ""
echo "Ваше приложение доступно по адресу: http://$DOMAIN"
echo ""
echo "ИНФОРМАЦИЯ ДЛЯ ВХОДА В АДМИН-ПАНЕЛЬ:"
echo "Логин: admin"
echo "Пароль: $ADMIN_PASSWORD"
echo ""
echo "ВАЖНАЯ ИНФОРМАЦИЯ:"
echo "- База данных PostgreSQL:"
echo "  - Имя БД: $DB_NAME"
echo "  - Пользователь: $DB_USER"
echo "  - Пароль: $DB_PASSWORD"
echo ""
echo "- Путь к файлам приложения: $PROJECT_DIR"
echo ""
echo "КОМАНДЫ УПРАВЛЕНИЯ ПРИЛОЖЕНИЕМ:"
echo "- Перезапуск: pm2 restart atom-game"
echo "- Просмотр логов: pm2 logs atom-game"
echo "- Просмотр статуса: pm2 status"
echo ""
echo "=================================================================="