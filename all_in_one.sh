#!/bin/bash

# Полный скрипт решения всех проблем с развертыванием
# Май 2025

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
NODE_VERSION="18.x"

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
echo -e "${GREEN}   Полная настройка ATOM-GAME   ${NC}"
echo -e "${GREEN}==========================================${NC}"
echo ""

# 1. Установка Node.js версии 18.x
log "Установка Node.js $NODE_VERSION..."
if ! command -v node &> /dev/null || [[ $(node -v) != *"v18."* ]]; then
  warning "Node.js не установлен или установлена неправильная версия. Устанавливаем Node.js $NODE_VERSION..."
  
  apt-get update
  apt-get install -y ca-certificates curl gnupg
  mkdir -p /etc/apt/keyrings
  curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
  
  echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_18.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list
  
  apt-get update
  apt-get install -y nodejs
  
  if ! command -v node &> /dev/null; then
    error "Не удалось установить Node.js"
  fi
  
  log "Установлена версия Node.js: $(node -v)"
else
  log "Уже установлена версия Node.js: $(node -v)"
fi

# 2. Установка PostgreSQL, если не установлен
log "Проверка установки PostgreSQL..."
if ! command -v psql &> /dev/null; then
  warning "PostgreSQL не установлен. Устанавливаем..."
  apt-get update
  apt-get install -y postgresql postgresql-contrib
  
  # Запуск PostgreSQL
  systemctl enable postgresql
  systemctl start postgresql
  
  if ! command -v psql &> /dev/null; then
    error "Не удалось установить PostgreSQL"
  fi
else
  log "PostgreSQL уже установлен: $(psql --version)"
fi

# 3. Проверка, что PostgreSQL запущен
if ! systemctl is-active --quiet postgresql; then
  warning "PostgreSQL не запущен. Запускаем..."
  systemctl start postgresql
  sleep 5
  
  if ! systemctl is-active --quiet postgresql; then
    error "Не удалось запустить PostgreSQL"
  fi
fi

# 4. Установка Nginx, если не установлен
log "Проверка установки Nginx..."
if ! command -v nginx &> /dev/null; then
  warning "Nginx не установлен. Устанавливаем..."
  apt-get update
  apt-get install -y nginx
  
  # Запуск Nginx
  systemctl enable nginx
  systemctl start nginx
  
  if ! command -v nginx &> /dev/null; then
    error "Не удалось установить Nginx"
  fi
else
  log "Nginx уже установлен: $(nginx -v 2>&1)"
fi

# 5. Проверка пользователя и базы данных PostgreSQL
log "Настройка базы данных PostgreSQL..."
if ! sudo -u postgres psql -c "SELECT 1 FROM pg_roles WHERE rolname='$DB_USER';" | grep -q 1; then
  warning "Пользователь $DB_USER не существует в PostgreSQL. Создаем..."
  sudo -u postgres psql -c "CREATE USER $DB_USER WITH PASSWORD '$DB_PASSWORD';"
fi

sudo -u postgres psql -c "ALTER USER $DB_USER WITH SUPERUSER;"

if ! sudo -u postgres psql -c "SELECT 1 FROM pg_database WHERE datname='$DB_NAME';" | grep -q 1; then
  warning "База данных $DB_NAME не существует в PostgreSQL. Создаем..."
  sudo -u postgres psql -c "CREATE DATABASE $DB_NAME OWNER $DB_USER;"
fi

sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;"

# 6. Настройка pg_hba.conf для разрешения соединения по паролю
log "Настройка pg_hba.conf для разрешения соединения по паролю..."
PG_HBA_FILE=$(sudo -u postgres psql -t -c "SHOW hba_file;" | xargs)

# Проверка наличия записи MD5 для локального соединения
if ! grep -q "^host.*all.*all.*127.0.0.1/32.*md5" $PG_HBA_FILE; then
  warning "Добавляем запись для аутентификации MD5 в $PG_HBA_FILE..."
  
  # Безопасное удаление старых записей (если они существуют)
  sed -i '/^host.*all.*all.*127.0.0.1\/32.*ident/d' $PG_HBA_FILE
  sed -i '/^host.*all.*all.*::1\/128.*ident/d' $PG_HBA_FILE
  
  # Добавление новых записей
  echo "# Добавлено скриптом all_in_one.sh" >> $PG_HBA_FILE
  echo "host    all             all             127.0.0.1/32            md5" >> $PG_HBA_FILE
  echo "host    all             all             ::1/128                 md5" >> $PG_HBA_FILE
  
  # Перезапуск PostgreSQL
  log "Перезапуск PostgreSQL после изменения конфигурации..."
  systemctl restart postgresql
  sleep 5
fi

# 7. Создание .env файла с правильными переменными
log "Создание .env файла с правильными переменными..."
mkdir -p "$INSTALL_PATH"

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
SESSION_SECRET=AtomGameSecretKey2025
EOF

# 8. Клонирование репозитория, если он не существует
if [ ! -d "$INSTALL_PATH/.git" ]; then
  warning "Репозиторий не найден в $INSTALL_PATH. Клонируем..."
  
  # Сохранить .env если он существует
  if [ -f "$INSTALL_PATH/.env" ]; then
    cp "$INSTALL_PATH/.env" /tmp/.env.backup
  fi
  
  # Клонировать репозиторий
  rm -rf "$INSTALL_PATH"
  git clone https://github.com/Edivin2000/TeamRatingTracker.git "$INSTALL_PATH"
  
  # Восстановить .env
  if [ -f "/tmp/.env.backup" ]; then
    cp /tmp/.env.backup "$INSTALL_PATH/.env"
    rm /tmp/.env.backup
  fi
else
  log "Репозиторий уже клонирован в $INSTALL_PATH"
  
  # Обновить репозиторий до последней версии
  cd "$INSTALL_PATH" && git pull
fi

# 9. Установка зависимостей
log "Установка зависимостей npm..."
cd "$INSTALL_PATH"
npm install

# 10. Сборка проекта
log "Сборка проекта..."
cd "$INSTALL_PATH"
NODE_ENV=production npm run build

# 11. Создание конфигурации Nginx
log "Создание конфигурации Nginx..."
cat > /etc/nginx/sites-available/atomgame << EOF
server {
    listen 80;
    server_name 193.109.78.85;
    
    # Файлы логов
    access_log /var/log/nginx/atomgame.access.log;
    error_log /var/log/nginx/atomgame.error.log debug;
    
    # Включение сжатия
    gzip on;
    gzip_types text/plain application/javascript application/x-javascript text/javascript text/xml text/css;
    
    # Проксирование всех запросов на приложение Node.js
    location / {
        proxy_pass http://localhost:$SERVER_PORT;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
        proxy_read_timeout 300;
        proxy_connect_timeout 300;
        proxy_send_timeout 300;
    }
}
EOF

# Включение конфигурации и проверка
ln -sf /etc/nginx/sites-available/atomgame /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# Проверка конфигурации Nginx
log "Проверка конфигурации Nginx..."
nginx -t

if [ $? -eq 0 ]; then
  log "Конфигурация Nginx правильная. Перезапуск..."
  systemctl restart nginx
else
  error "Ошибка в конфигурации Nginx. Исправьте ошибки вручную."
fi

# 12. Создание службы systemd
log "Создание службы systemd..."
cat > /etc/systemd/system/atomgame.service << EOF
[Unit]
Description=ATOM-GAME Application
After=network.target postgresql.service

[Service]
User=root
WorkingDirectory=$INSTALL_PATH
Environment=NODE_ENV=production
Environment=PORT=$SERVER_PORT
Environment=HOST=0.0.0.0
Environment=PGUSER=$DB_USER
Environment=PGPASSWORD=$DB_PASSWORD
Environment=PGDATABASE=$DB_NAME
Environment=PGHOST=localhost
Environment=PGPORT=5432
Environment=DATABASE_URL=postgresql://$DB_USER:$DB_PASSWORD@localhost:5432/$DB_NAME
Environment=SESSION_SECRET=AtomGameSecretKey2025
ExecStart=/usr/bin/node $INSTALL_PATH/dist/index.js
StandardOutput=append:$INSTALL_PATH/app.log
StandardError=append:$INSTALL_PATH/app.log
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Перезагрузка конфигурации systemd
log "Перезагрузка конфигурации systemd..."
systemctl daemon-reload
systemctl enable atomgame
systemctl restart atomgame

# 13. Создание дополнительных скриптов для управления
log "Создание дополнительных скриптов для управления..."

# Скрипт для просмотра логов
cat > "$INSTALL_PATH/view_logs.sh" << EOF
#!/bin/bash
echo "Просмотр логов приложения..."
tail -f $INSTALL_PATH/app.log
EOF

chmod +x "$INSTALL_PATH/view_logs.sh"

# Скрипт для перезапуска
cat > "$INSTALL_PATH/restart.sh" << EOF
#!/bin/bash
echo "Перезапуск приложения..."
systemctl restart atomgame
sleep 3
systemctl status atomgame --no-pager
EOF

chmod +x "$INSTALL_PATH/restart.sh"

# Скрипт для обновления
cat > "$INSTALL_PATH/update.sh" << EOF
#!/bin/bash
echo "Обновление приложения..."
cd $INSTALL_PATH
git pull
npm install
NODE_ENV=production npm run build
systemctl restart atomgame
echo "Приложение обновлено!"
EOF

chmod +x "$INSTALL_PATH/update.sh"

# 14. Проверка, что приложение запущено
log "Проверка статуса приложения..."
sleep 5
systemctl status atomgame --no-pager

# 15. Проверка доступности через Nginx
log "Проверка доступности через Nginx..."
curl -s -I http://localhost | head -n 1 || warning "Не удалось получить ответ от локального сервера"

echo ""
echo -e "${GREEN}==========================================${NC}"
echo -e "${GREEN}   Установка завершена!   ${NC}"
echo -e "${GREEN}==========================================${NC}"
echo ""
echo -e "Ваш сайт доступен по адресу: ${YELLOW}http://193.109.78.85${NC}"
echo -e ""
echo -e "${YELLOW}Полезные команды:${NC}"
echo "- Просмотр логов: $INSTALL_PATH/view_logs.sh"
echo "- Перезапуск: $INSTALL_PATH/restart.sh"
echo "- Обновление: $INSTALL_PATH/update.sh"
echo "- Просмотр статуса: systemctl status atomgame"
echo "- Просмотр логов systemd: journalctl -u atomgame -f"
echo ""
echo -e "${YELLOW}Если возникли проблемы:${NC}"
echo "1. Проверьте логи: tail -f $INSTALL_PATH/app.log"
echo "2. Проверьте настройки .env: cat $INSTALL_PATH/.env"
echo "3. Перезапустите PostgreSQL: systemctl restart postgresql"
echo "4. Перезапустите Nginx: systemctl restart nginx"
echo ""