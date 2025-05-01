#!/bin/bash

# ==========================================
# СКРИПТ АВТОМАТИЧЕСКОЙ УСТАНОВКИ ATOM-GAME
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

# Переменные настройки
PROJECT_NAME="ATOM-GAME"
PROJECT_DIR="/var/www/atomgameblk"
DOMAIN="atomgameblk.ru"
DB_NAME="atomgame"
DB_USER="atomgame"
DB_PASSWORD="Atom&Game#2025!"
ADMIN_PASSWORD="Atom&Game#2025!"
GIT_REPO="https://github.com/ваш-аккаунт/atom-game-rating.git"

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

# Функция для получения подтверждения пользователя
confirm() {
  read -p "$1 (д/н): " response
  case "$response" in
    [дД]* ) return 0 ;;
    * ) return 1 ;;
  esac
}

# Проверка запуска от root
if [ "$(id -u)" != "0" ]; then
   error "Этот скрипт должен быть запущен от имени root"
   error "Пожалуйста, используйте: sudo ./atomgame-install.sh"
   exit 1
fi

# Начальный вывод информации
clear
echo "=================================================================="
echo "        АВТОМАТИЧЕСКАЯ УСТАНОВКА $PROJECT_NAME"
echo "=================================================================="
echo "Этот скрипт установит и настроит рейтинговую систему ATOM-GAME"
echo "на вашем сервере. Процесс установки включает:"
echo ""
echo "  1. Установку всех необходимых зависимостей"
echo "  2. Настройку PostgreSQL базы данных"
echo "  3. Настройку Nginx и SSL-сертификатов"
echo "  4. Настройку и запуск приложения"
echo ""
echo "Рекомендуется запускать на чистой Ubuntu 22.04 или Debian 11"
echo "=================================================================="
echo ""

# Запрос подтверждения и переменных
if confirm "Продолжить установку?"; then
  log "Начинаем процесс установки..."
else
  log "Установка отменена пользователем."
  exit 0
fi

# Запрос данных для настройки
read -p "Укажите доменное имя [$DOMAIN]: " input_domain
DOMAIN=${input_domain:-$DOMAIN}

read -p "Укажите каталог установки [$PROJECT_DIR]: " input_dir
PROJECT_DIR=${input_dir:-$PROJECT_DIR}

read -p "Укажите имя базы данных [$DB_NAME]: " input_db_name
DB_NAME=${input_db_name:-$DB_NAME}

read -p "Укажите имя пользователя БД [$DB_USER]: " input_db_user
DB_USER=${input_db_user:-$DB_USER}

read -p "Укажите пароль пользователя БД [$DB_PASSWORD]: " input_db_password
DB_PASSWORD=${input_db_password:-$DB_PASSWORD}

read -p "Укажите пароль администратора [$ADMIN_PASSWORD]: " input_admin_password
ADMIN_PASSWORD=${input_admin_password:-$ADMIN_PASSWORD}

read -p "Укажите URL Git-репозитория [$GIT_REPO]: " input_git_repo
GIT_REPO=${input_git_repo:-$GIT_REPO}

# Проверка и установка зависимостей
log "Обновление списка пакетов..."
apt-get update

log "Установка основных зависимостей..."
apt-get install -y curl wget git gnupg2 apt-transport-https lsb-release ca-certificates

# Установка Node.js
log "Установка Node.js..."
if ! command -v node &> /dev/null; then
  curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
  apt-get install -y nodejs
  success "Node.js установлен: $(node -v)"
else
  success "Node.js уже установлен: $(node -v)"
fi

# Установка PostgreSQL
log "Установка PostgreSQL..."
if ! command -v psql &> /dev/null; then
  apt-get install -y postgresql postgresql-contrib
  success "PostgreSQL установлен"
else
  success "PostgreSQL уже установлен"
fi

# Установка Nginx
log "Установка Nginx..."
if ! command -v nginx &> /dev/null; then
  apt-get install -y nginx
  success "Nginx установлен"
else
  success "Nginx уже установлен"
fi

# Установка Certbot для SSL
log "Установка Certbot..."
if ! command -v certbot &> /dev/null; then
  apt-get install -y certbot python3-certbot-nginx
  success "Certbot установлен"
else
  success "Certbot уже установлен"
fi

# Установка PM2
log "Установка PM2..."
if ! command -v pm2 &> /dev/null; then
  npm install -g pm2
  success "PM2 установлен"
else
  success "PM2 уже установлен"
fi

# Создание директории проекта
log "Создание директории проекта..."
mkdir -p $PROJECT_DIR
cd $PROJECT_DIR

# Клонирование репозитория
log "Клонирование репозитория..."
if [ -d "$PROJECT_DIR/.git" ]; then
  log "Репозиторий уже клонирован, обновляем..."
  git pull
else
  git clone $GIT_REPO .
fi
success "Репозиторий получен"

# Настройка базы данных PostgreSQL
log "Настройка базы данных PostgreSQL..."
if sudo -u postgres psql -lqt | cut -d \| -f 1 | grep -qw $DB_NAME; then
  log "База данных $DB_NAME уже существует"
else
  sudo -u postgres psql -c "CREATE USER $DB_USER WITH ENCRYPTED PASSWORD '$DB_PASSWORD';"
  sudo -u postgres psql -c "CREATE DATABASE $DB_NAME OWNER $DB_USER;"
  success "База данных создана"
fi

# Создание .env файла
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
success "Файл .env создан"

# Установка зависимостей NPM
log "Установка зависимостей NPM..."
npm install
success "Зависимости установлены"

# Применение миграций базы данных
log "Применение миграций базы данных..."
npm run db:push
success "Структура базы данных создана"

# Сборка приложения
log "Сборка приложения..."
npm run build
success "Приложение собрано"

# Настройка PM2
log "Настройка PM2..."
cat > $PROJECT_DIR/ecosystem.config.js << EOF
module.exports = {
  apps: [{
    name: 'atom-game',
    script: 'dist/index.js',
    instances: 'max',
    exec_mode: 'cluster',
    env: {
      NODE_ENV: 'production',
      PORT: 5000
    },
    max_memory_restart: '500M'
  }]
};
EOF
success "Файл конфигурации PM2 создан"

# Запуск через PM2
log "Запуск приложения через PM2..."
pm2 start ecosystem.config.js
pm2 save
pm2 startup
success "Приложение запущено через PM2"

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

# Настройка SSL с Let's Encrypt
log "Настройка SSL-сертификата..."
if confirm "Настроить SSL-сертификат для домена $DOMAIN?"; then
  certbot --nginx -d $DOMAIN -d www.$DOMAIN --non-interactive --agree-tos -m admin@$DOMAIN
  success "SSL-сертификат установлен"
else
  warn "Настройка SSL-сертификата пропущена"
fi

# Настройка автоматического обновления
log "Настройка автоматического обновления..."
cat > /etc/cron.daily/update-atomgame << EOF
#!/bin/bash
cd $PROJECT_DIR
git pull
npm install
npm run build
pm2 reload atom-game
EOF
chmod +x /etc/cron.daily/update-atomgame
success "Автоматическое обновление настроено"

# Настройка резервного копирования
log "Настройка автоматического резервного копирования..."
BACKUP_DIR="/var/backups/atomgame"
mkdir -p $BACKUP_DIR

cat > $PROJECT_DIR/backup.sh << EOF
#!/bin/bash
BACKUP_DIR="$BACKUP_DIR"
PROJECT_DIR="$PROJECT_DIR"
PGUSER="$DB_USER"
PGPASSWORD="$DB_PASSWORD"
PGDATABASE="$DB_NAME"
TIMESTAMP=\$(date +"%Y%m%d_%H%M%S")

mkdir -p \$BACKUP_DIR
export PGPASSWORD=\$PGPASSWORD
pg_dump -U \$PGUSER \$PGDATABASE -F c -f "\$BACKUP_DIR/db_\$TIMESTAMP.dump"
tar -czf "\$BACKUP_DIR/files_\$TIMESTAMP.tar.gz" -C \$(dirname \$PROJECT_DIR) \$(basename \$PROJECT_DIR)
find \$BACKUP_DIR -name "db_*.dump" -type f -mtime +7 -delete
find \$BACKUP_DIR -name "files_*.tar.gz" -type f -mtime +7 -delete
EOF
chmod +x $PROJECT_DIR/backup.sh

# Добавление в cron
crontab -l 2>/dev/null | { cat; echo "0 2 * * * $PROJECT_DIR/backup.sh"; } | crontab -
success "Автоматическое резервное копирование настроено"

# Вывод информации об успешной установке
clear
echo "=================================================================="
echo "        УСТАНОВКА $PROJECT_NAME ЗАВЕРШЕНА УСПЕШНО!"
echo "=================================================================="
echo ""
echo "Ваше приложение доступно по адресу: https://$DOMAIN"
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
echo "- Резервные копии хранятся в: $BACKUP_DIR"
echo "- Автоматическое резервное копирование: каждый день в 2:00"
echo ""
echo "КОМАНДЫ УПРАВЛЕНИЯ ПРИЛОЖЕНИЕМ:"
echo "- Перезапуск: pm2 restart atom-game"
echo "- Просмотр логов: pm2 logs atom-game"
echo "- Просмотр статуса: pm2 status"
echo ""
echo "=================================================================="