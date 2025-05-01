#!/bin/bash

# Скрипт для развертывания ATOM-GAME платформы
# Май 2025

# Цвета для вывода
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # Сброс цвета

# Функции вывода
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

# Проверка прав суперпользователя
if [ "$(id -u)" != "0" ]; then
   error "Этот скрипт должен быть запущен с правами root. Используйте sudo."
fi

# Вывод заголовка
clear
echo -e "${GREEN}==========================================${NC}"
echo -e "${GREEN}   Установка ATOM-GAME рейтинговой системы   ${NC}"
echo -e "${GREEN}==========================================${NC}"
echo ""
log "Начало установки..."

# Запрос настроек от пользователя
read -p "Введите доменное имя (без www) [atomgameblk.ru]: " DOMAIN_NAME
DOMAIN_NAME=${DOMAIN_NAME:-atomgameblk.ru}

read -p "Введите путь установки [/var/www/atomgame]: " INSTALL_PATH
INSTALL_PATH=${INSTALL_PATH:-/var/www/atomgame}

read -p "Создать пользователя PostgreSQL [atomgame]: " DB_USER
DB_USER=${DB_USER:-atomgame}

read -p "Пароль для PostgreSQL [AtomGame2025]: " DB_PASSWORD
DB_PASSWORD=${DB_PASSWORD:-AtomGame2025}

read -p "Имя базы данных [atomgame]: " DB_NAME
DB_NAME=${DB_NAME:-atomgame}

read -p "Секретный ключ для сессий (любой сложный текст) [AtomGameSecretKey2025]: " SESSION_SECRET
SESSION_SECRET=${SESSION_SECRET:-AtomGameSecretKey2025}

# Создание директории для установки
log "Создание директории для установки: $INSTALL_PATH"
mkdir -p $INSTALL_PATH
cd $INSTALL_PATH

# Обновление системы и установка зависимостей
log "Обновление системы и установка зависимостей..."
apt update && apt upgrade -y
apt install -y curl git nginx postgresql postgresql-contrib build-essential unzip

# Установка Node.js через отдельный скрипт
log "Установка Node.js..."
# Создаем временный файл с скриптом установки Node.js
cat > /tmp/setup_nodejs.sh << 'EOF'
#!/bin/bash

# Скрипт для правильной настройки Node.js и npm
# Разработано для ATOM-GAME
# Май 2025

# Цвета для вывода
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # Сброс цвета

# Функции вывода
log() {
  echo -e "${GREEN}[ИНФО]${NC} $1"
}

error() {
  echo -e "${RED}[ОШИБКА]${NC} $1"
  exit 1
}

warning() {
  echo -e "${YELLOW}[ВНИМАНИЕ]${NC} $1"
}

# Проверка и удаление существующих установок Node.js
log "Проверка и удаление существующих установок Node.js..."

# Проверка наличия Node.js
if command -v node &> /dev/null; then
  NODE_VERSION=$(node -v)
  warning "Найдена установка Node.js $NODE_VERSION. Удаляем..."
  
  # Принудительное удаление всех пакетов Node.js
  apt purge -y nodejs npm
  apt autoremove -y
  
  # Удаление возможных глобальных директорий npm
  rm -rf /usr/local/lib/node_modules
  rm -rf /usr/local/bin/node
  rm -rf /usr/local/bin/npm
  
  # Проверка и удаление репозиториев NodeSource
  for file in /etc/apt/sources.list.d/nodesource*.list; do
    if [ -f "$file" ]; then
      warning "Удаление репозитория: $file"
      rm -f "$file"
    fi
  done
fi

# Очистка и обновление источников apt
log "Обновление списка пакетов..."
apt update -y

# Установка необходимых зависимостей
log "Установка необходимых зависимостей..."
apt install -y curl gnupg ca-certificates apt-transport-https

# Добавление репозитория NodeSource 18.x
log "Добавление репозитория NodeSource для Node.js 18.x..."
mkdir -p /etc/apt/keyrings
curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_18.x nodistro main" > /etc/apt/sources.list.d/nodesource.list

# Обновление после добавления репозитория
apt update -y

# Установка Node.js (включает npm)
log "Установка Node.js 18.x..."
apt install -y nodejs

# Проверка установки
if command -v node &> /dev/null; then
  NODE_VERSION=$(node -v)
  NPM_VERSION=$(npm -v)
  log "Успешно установлен Node.js $NODE_VERSION с npm $NPM_VERSION"
else
  error "Не удалось установить Node.js. Проверьте журнал ошибок."
fi

# Установка глобальных пакетов npm (если нужны)
log "Установка глобальных пакетов npm..."
npm install -g pm2

# Очистка кэша npm
log "Очистка кэша npm..."
npm cache clean --force

log "Node.js и npm успешно настроены!"
EOF

# Запускаем скрипт установки Node.js
chmod +x /tmp/setup_nodejs.sh
/tmp/setup_nodejs.sh
rm /tmp/setup_nodejs.sh

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
HOST=0.0.0.0

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
    read -p "Введите путь к ZIP-архиву с проектом: " ZIP_PATH
    log "Распаковка архива..."
    unzip -q $ZIP_PATH -d $INSTALL_PATH
    ;;
  2)
    read -p "Введите URL Git-репозитория: " GIT_URL
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
nginx -t && systemctl reload nginx

# Настройка SSL с помощью Certbot
log "Настройка SSL с помощью Certbot..."
apt install -y certbot python3-certbot-nginx
certbot --nginx -d $DOMAIN_NAME -d www.$DOMAIN_NAME

# Создание скрипта резервного копирования
log "Создание скрипта резервного копирования..."
cat > $INSTALL_PATH/backup.sh << 'EOF'
#!/bin/bash

# Скрипт резервного копирования базы данных ATOM-GAME
# Создает резервную копию и сохраняет 7 последних резервных копий

# Загрузка переменных окружения
source $(dirname "$0")/.env

# Создание директории для резервных копий
BACKUP_DIR=$(dirname "$0")/backups
mkdir -p $BACKUP_DIR

# Имя файла резервной копии с датой
BACKUP_FILE="$BACKUP_DIR/backup_$(date +"%Y%m%d_%H%M%S").sql"

# Создание резервной копии
echo "Создание резервной копии базы данных в $BACKUP_FILE..."
PGPASSWORD=$PGPASSWORD pg_dump -U $PGUSER -h $PGHOST -p $PGPORT $PGDATABASE > $BACKUP_FILE

# Проверка успешности создания резервной копии
if [ $? -eq 0 ]; then
  echo "Резервная копия успешно создана: $BACKUP_FILE"
  
  # Удаление старых резервных копий (оставляем только 7 последних)
  echo "Очистка старых резервных копий..."
  ls -t $BACKUP_DIR/backup_*.sql | tail -n +8 | xargs -r rm
  echo "Готово!"
else
  echo "Ошибка создания резервной копии!"
fi
EOF

chmod +x $INSTALL_PATH/backup.sh

# Настройка автоматического резервного копирования через cron
log "Настройка автоматического резервного копирования..."
(crontab -l 2>/dev/null; echo "0 3 * * * $INSTALL_PATH/backup.sh > /dev/null 2>&1") | crontab -

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
echo "- Резервное копирование: $INSTALL_PATH/backup.sh"
echo ""
echo -e "${RED}ВАЖНО: Не забудьте сменить пароль администратора после первого входа!${NC}"
echo ""