#!/bin/bash

# Скрипт автоматической установки ATOM-GAME
# Создано: ATOM-GAME Team, Май 2025

set -e  # Остановка скрипта при ошибках

# Цвета для вывода
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # Сброс цвета

# Функция для вывода с цветами
log() {
  echo -e "${GREEN}[УСТАНОВКА]${NC} $1"
}

error() {
  echo -e "${RED}[ОШИБКА]${NC} $1"
  exit 1
}

warning() {
  echo -e "${YELLOW}[ВНИМАНИЕ]${NC} $1"
}

# Функция для запроса переменных от пользователя
prompt() {
  local prompt_text="$1"
  local var_name="$2"
  local default_value="$3"
  
  if [ -n "$default_value" ]; then
    read -p "$prompt_text [$default_value]: " input
    if [ -z "$input" ]; then
      input="$default_value"
    fi
  else
    read -p "$prompt_text: " input
  fi
  
  eval "$var_name=\"$input\""
}

# Проверка прав суперпользователя
if [ "$(id -u)" != "0" ]; then
   error "Этот скрипт должен быть запущен с правами root. Используйте sudo."
fi

clear
echo -e "${GREEN}==========================================${NC}"
echo -e "${GREEN}   Установка ATOM-GAME рейтинговой системы   ${NC}"
echo -e "${GREEN}==========================================${NC}"
echo ""
log "Начало установки..."

# Запрос настроек от пользователя
prompt "Введите доменное имя (без www)" DOMAIN_NAME "atomgameblk.ru"
prompt "Введите путь установки" INSTALL_PATH "/var/www/atomgame"
prompt "Создать пользователя PostgreSQL" DB_USER "atomgame"
prompt "Пароль для PostgreSQL" DB_PASSWORD "AtomGame2025"
prompt "Имя базы данных" DB_NAME "atomgame"
prompt "Секретный ключ для сессий (любой сложный текст)" SESSION_SECRET "AtomGameSecretKey2025"

# Создание директории для установки
log "Создание директории для установки: $INSTALL_PATH"
mkdir -p $INSTALL_PATH
cd $INSTALL_PATH

# Обновление системы и установка зависимостей
log "Обновление системы и установка зависимостей..."
apt update && apt upgrade -y
apt install -y curl git nginx postgresql postgresql-contrib build-essential unzip

# Установка Node.js
log "Установка Node.js..."
if ! command -v node &> /dev/null; then
  curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
  apt install -y nodejs
  log "Node.js установлен: $(node -v)"
else
  log "Node.js уже установлен: $(node -v)"
fi

# Установка PM2
log "Установка менеджера процессов PM2..."
if ! command -v pm2 &> /dev/null; then
  npm install -g pm2
  log "PM2 установлен"
else
  log "PM2 уже установлен"
fi

# Настройка базы данных PostgreSQL
log "Настройка базы данных PostgreSQL..."
# Проверка существования пользователя
if sudo -u postgres psql -tAc "SELECT 1 FROM pg_roles WHERE rolname='$DB_USER'" | grep -q 1; then
  warning "Пользователь $DB_USER уже существует"
else
  sudo -u postgres psql -c "CREATE USER $DB_USER WITH ENCRYPTED PASSWORD '$DB_PASSWORD';"
  log "Создан пользователь PostgreSQL: $DB_USER"
fi

# Проверка существования базы данных
if sudo -u postgres psql -lqt | cut -d \| -f 1 | grep -qw $DB_NAME; then
  warning "База данных $DB_NAME уже существует"
else
  sudo -u postgres psql -c "CREATE DATABASE $DB_NAME OWNER $DB_USER;"
  log "Создана база данных: $DB_NAME"
fi

# Настройка переменных окружения
log "Создание файла конфигурации .env..."
cat > $INSTALL_PATH/.env << EOF
# Основные настройки
NODE_ENV=production
PORT=3000

# База данных PostgreSQL
PGUSER=$DB_USER
PGPASSWORD=$DB_PASSWORD
PGDATABASE=$DB_NAME
PGHOST=localhost
PGPORT=5432
DATABASE_URL=postgresql://$DB_USER:$DB_PASSWORD@localhost:5432/$DB_NAME

# Безопасность
SESSION_SECRET=$SESSION_SECRET
EOF

log "Файл .env создан"

# Запрос метода загрузки проекта
echo "Выберите способ загрузки файлов проекта:"
echo "1. У меня есть ZIP-архив с проектом"
echo "2. Клонировать из Git-репозитория"
echo "3. Я уже загрузил файлы в директорию $INSTALL_PATH"
read -p "Выберите вариант (1-3): " DEPLOY_METHOD

case $DEPLOY_METHOD in
  1)
    prompt "Введите путь к ZIP-архиву с проектом" ZIP_PATH
    log "Распаковка архива..."
    unzip -q $ZIP_PATH -d $INSTALL_PATH
    ;;
  2)
    prompt "Введите URL Git-репозитория" GIT_URL
    log "Клонирование репозитория..."
    git clone $GIT_URL $INSTALL_PATH
    ;;
  3)
    log "Используются существующие файлы в $INSTALL_PATH"
    ;;
  *)
    error "Неверный выбор. Прекращение установки."
    ;;
esac

# Установка зависимостей проекта
log "Установка зависимостей проекта..."
cd $INSTALL_PATH
npm install

# Создание директории для логов
mkdir -p $INSTALL_PATH/logs

# Миграция базы данных
log "Применение схемы базы данных..."
npm run db:push

# Сборка проекта
log "Сборка проекта..."
npm run build

# Настройка PM2
log "Настройка PM2..."
cat > $INSTALL_PATH/ecosystem.config.js << EOF
module.exports = {
  apps: [
    {
      name: "atomgame",
      script: "dist/index.js",
      instances: 1,
      autorestart: true,
      watch: false,
      env: {
        NODE_ENV: "production",
        PORT: 3000,
        HOST: "0.0.0.0",
      },
      max_memory_restart: "500M",
      error_file: "logs/error.log",
      out_file: "logs/output.log",
      log_date_format: "YYYY-MM-DD HH:mm Z",
    },
  ],
};
EOF

# Запуск приложения с PM2
log "Запуск приложения..."
cd $INSTALL_PATH
pm2 start ecosystem.config.js
pm2 startup
pm2 save

# Настройка Nginx
log "Настройка Nginx..."
cat > /etc/nginx/sites-available/atomgame << EOF
server {
    listen 80;
    server_name $DOMAIN_NAME www.$DOMAIN_NAME;
    
    # Корневая директория с файлами
    root $INSTALL_PATH/dist;
    
    # Файлы логов
    access_log /var/log/nginx/atomgame.access.log;
    error_log /var/log/nginx/atomgame.error.log;
    
    # Включение сжатия
    gzip on;
    gzip_types text/plain application/javascript application/x-javascript text/javascript text/xml text/css;
    
    # Проксирование API запросов
    location /api {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
    }
    
    # Для остальных запросов (фронтенд SPA)
    location / {
        try_files \$uri \$uri/ /index.html;
        add_header Cache-Control "public, max-age=3600";
    }
    
    # Кэширование статических файлов
    location ~* \.(jpg|jpeg|png|gif|ico|css|js|svg)\$ {
        expires 7d;
        add_header Cache-Control "public, max-age=604800";
    }
}
EOF

ln -sf /etc/nginx/sites-available/atomgame /etc/nginx/sites-enabled/
nginx -t
systemctl reload nginx

# Настройка SSL с помощью Certbot
log "Настройка SSL с помощью Certbot..."
apt install -y certbot python3-certbot-nginx
certbot --nginx -d $DOMAIN_NAME -d www.$DOMAIN_NAME

# Завершение установки
echo ""
echo -e "${GREEN}==========================================${NC}"
echo -e "${GREEN}   Установка успешно завершена!   ${NC}"
echo -e "${GREEN}==========================================${NC}"
echo ""
echo -e "Ваш сайт доступен по адресу: ${YELLOW}https://$DOMAIN_NAME${NC}"
echo ""
echo -e "Панель администрирования: ${YELLOW}https://$DOMAIN_NAME/admin${NC}"
echo "Логин: admin"
echo "Пароль: admin123 (рекомендуется сменить)"
echo ""
echo -e "${YELLOW}Полезные команды:${NC}"
echo "- Просмотр логов: pm2 logs atomgame"
echo "- Перезапуск: pm2 restart atomgame"
echo "- Обновление: cd $INSTALL_PATH && ./update.sh"
echo ""
echo -e "${RED}ВАЖНО: Не забудьте сменить пароль администратора после первого входа!${NC}"
echo ""