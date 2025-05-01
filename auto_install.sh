#!/bin/bash

# Автоматический скрипт установки ATOM-GAME
# Настраивает все автоматически на заданный IP и порт
# Май 2025

# Цвета для вывода
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # Сброс цвета

# Настройки установки (можно изменить)
SERVER_IP="193.109.78.85"
SERVER_PORT="5001"
INSTALL_PATH="/var/www/atomgame"
DB_USER="atomgame"
DB_PASSWORD="AtomGame2025"
DB_NAME="atomgame"
SESSION_SECRET="AtomGameSecretKey2025"
GIT_REPO_URL="https://github.com/yourusername/atomgame.git" # УКАЖИТЕ ПРАВИЛЬНЫЙ РЕПОЗИТОРИЙ

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
echo -e "${GREEN}   Автоматическая установка ATOM-GAME   ${NC}"
echo -e "${GREEN}==========================================${NC}"
echo ""
log "Начало установки..."
log "Сервер будет настроен на IP: $SERVER_IP и порт: $SERVER_PORT"
echo ""

# Остановка существующих сервисов (если есть)
log "Остановка существующих сервисов..."
if command -v pm2 &> /dev/null; then
  pm2 delete all || true
fi

# Проверка и остановка nginx
if systemctl is-active --quiet nginx; then
  systemctl stop nginx
fi

# Удаление существующих файлов в директории установки
if [ -d "$INSTALL_PATH" ]; then
  log "Удаление существующих файлов в $INSTALL_PATH..."
  rm -rf "$INSTALL_PATH"
fi

# Создание директории для установки
log "Создание директории для установки: $INSTALL_PATH"
mkdir -p "$INSTALL_PATH"

# Обновление системы и установка зависимостей
log "Обновление системы и установка зависимостей..."
apt update && apt upgrade -y
apt install -y curl git nginx postgresql postgresql-contrib build-essential unzip gpg

# Установка Node.js (с удалением существующих установок)
log "Установка Node.js..."
# Удаление существующих установок
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

# Удаление ключей репозитория NodeSource (если есть)
rm -f /etc/apt/keyrings/nodesource.gpg

# Установка необходимых зависимостей
log "Установка необходимых зависимостей..."
apt install -y curl gnupg ca-certificates apt-transport-https git

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

# Проверка установки Node.js
if command -v node &> /dev/null; then
  NODE_VERSION=$(node -v)
  NPM_VERSION=$(npm -v)
  log "Успешно установлен Node.js $NODE_VERSION с npm $NPM_VERSION"
else
  error "Не удалось установить Node.js. Проверьте журнал ошибок."
fi

# Установка PM2
log "Установка PM2..."
npm install -g pm2
if ! command -v pm2 &> /dev/null; then
  error "Не удалось установить PM2."
fi

# Настройка базы данных PostgreSQL
log "Настройка базы данных PostgreSQL..."

# Убедимся, что PostgreSQL запущен
systemctl start postgresql
systemctl enable postgresql

# Проверка существования пользователя
if sudo -u postgres psql -tAc "SELECT 1 FROM pg_roles WHERE rolname='$DB_USER'" | grep -q 1; then
  warning "Пользователь $DB_USER уже существует. Удаляем..."
  sudo -u postgres psql -c "DROP OWNED BY $DB_USER CASCADE;"
  sudo -u postgres psql -c "DROP USER IF EXISTS $DB_USER;"
fi

# Создание пользователя PostgreSQL
sudo -u postgres psql -c "CREATE USER $DB_USER WITH ENCRYPTED PASSWORD '$DB_PASSWORD';"
log "Создан пользователь PostgreSQL: $DB_USER"

# Проверка существования базы данных
if sudo -u postgres psql -lqt | cut -d \| -f 1 | grep -qw $DB_NAME; then
  warning "База данных $DB_NAME уже существует. Удаляем..."
  sudo -u postgres psql -c "DROP DATABASE IF EXISTS $DB_NAME;"
fi

# Создание базы данных
sudo -u postgres psql -c "CREATE DATABASE $DB_NAME OWNER $DB_USER;"
log "Создана база данных: $DB_NAME"

# Предоставление привилегий
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;"
log "Права на базу данных выданы пользователю $DB_USER"

# Клонирование приложения из GitHub
log "Клонирование приложения из GitHub..."
git clone "$GIT_REPO_URL" "$INSTALL_PATH" || error "Не удалось клонировать репозиторий. Проверьте URL и доступ."

# Переход в директорию установки
cd "$INSTALL_PATH" || error "Не удалось перейти в директорию установки."

# Создание файла .env
log "Создание файла конфигурации .env..."
cat > "$INSTALL_PATH/.env" << EOF
# Основные настройки
NODE_ENV=production
PORT=$SERVER_PORT
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

# Установка зависимостей проекта
log "Установка зависимостей проекта..."
npm install

# Создание директории для логов
mkdir -p "$INSTALL_PATH/logs"

# Применение схемы базы данных
log "Применение схемы базы данных..."
npm run db:push

# Сборка проекта
log "Сборка проекта..."
npm run build

# Настройка PM2
log "Настройка PM2..."
cat > "$INSTALL_PATH/ecosystem.config.js" << EOF
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
        PORT: $SERVER_PORT,
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
pm2 start ecosystem.config.js
pm2 startup
pm2 save

# Настройка Nginx для проксирования на порт 5001
log "Настройка Nginx..."
cat > /etc/nginx/sites-available/atomgame << EOF
server {
    listen 80;
    server_name $SERVER_IP;
    
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
        proxy_pass http://localhost:$SERVER_PORT;
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

# Включение сайта в Nginx
ln -sf /etc/nginx/sites-available/atomgame /etc/nginx/sites-enabled/
# Удаление дефолтной конфигурации
rm -f /etc/nginx/sites-enabled/default

# Проверка конфигурации Nginx
nginx -t && systemctl restart nginx

# Создание скрипта резервного копирования
log "Создание скрипта резервного копирования..."
cat > "$INSTALL_PATH/backup.sh" << 'EOF'
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

chmod +x "$INSTALL_PATH/backup.sh"

# Настройка автоматического резервного копирования через cron
log "Настройка автоматического резервного копирования..."
(crontab -l 2>/dev/null; echo "0 3 * * * $INSTALL_PATH/backup.sh > /dev/null 2>&1") | crontab -

# Настройка файервола (если есть ufw)
if command -v ufw &> /dev/null; then
  log "Настройка файервола..."
  ufw allow 80/tcp
  ufw allow $SERVER_PORT/tcp
  ufw status
fi

# Проверка запущенного приложения
log "Проверка работы приложения..."
sleep 3
if curl -s "http://localhost:$SERVER_PORT/api/health" | grep -q "ok"; then
  log "Приложение успешно запущено и отвечает на запросы!"
else
  warning "Приложение может не работать. Проверьте логи: pm2 logs"
fi

# Вывод информации о завершении установки
echo ""
echo -e "${GREEN}==========================================${NC}"
echo -e "${GREEN}   Установка успешно завершена!   ${NC}"
echo -e "${GREEN}==========================================${NC}"
echo ""
echo -e "Ваш сайт доступен по адресу: ${YELLOW}http://$SERVER_IP${NC}"
echo -e "API доступен по адресу: ${YELLOW}http://$SERVER_IP/api${NC}"
echo -e "Порт приложения: ${YELLOW}$SERVER_PORT${NC}"
echo ""
echo -e "Настройки базы данных:"
echo -e "- Пользователь: ${YELLOW}$DB_USER${NC}"
echo -e "- Пароль: ${YELLOW}$DB_PASSWORD${NC}"
echo -e "- База данных: ${YELLOW}$DB_NAME${NC}"
echo ""
echo -e "${YELLOW}Полезные команды:${NC}"
echo "- Просмотр логов: pm2 logs atomgame"
echo "- Перезапуск: pm2 restart atomgame"
echo "- Резервное копирование: $INSTALL_PATH/backup.sh"
echo ""
echo -e "${RED}ВАЖНО: Не забудьте сменить пароль администратора после первого входа!${NC}"
echo -e "Логин: admin"
echo -e "Пароль: admin123"
echo ""