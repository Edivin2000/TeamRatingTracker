#!/bin/bash

# Скрипт для исправления проблемы с переменной среды DATABASE_URL
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
  echo -e "${GREEN}[ИСПРАВЛЕНИЕ]${NC} $1"
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
echo -e "${GREEN}   Исправление переменной DATABASE_URL   ${NC}"
echo -e "${GREEN}==========================================${NC}"
echo ""
log "Начало исправления..."

# Проверка существования директории
if [ ! -d "$INSTALL_PATH" ]; then
   error "Директория $INSTALL_PATH не существует!"
fi

# Остановка всех процессов PM2
log "Остановка всех процессов PM2..."
pm2 delete all 2>/dev/null || true

# 1. Обновление файла .env с правильным DATABASE_URL
log "Обновление файла .env..."
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

# 2. Исправление прав пользователя PostgreSQL
log "Настройка привилегий пользователя PostgreSQL..."
sudo -u postgres psql -c "ALTER USER $DB_USER WITH PASSWORD '$DB_PASSWORD';"
sudo -u postgres psql -c "ALTER USER $DB_USER WITH SUPERUSER;"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;"

# 3. Создание systemd службы для приложения
log "Создание systemd службы для приложения..."
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
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# 4. Включение и запуск службы
log "Перезагрузка и запуск службы..."
systemctl daemon-reload
systemctl enable atomgame
systemctl restart atomgame

# 5. Проверка статуса службы
log "Проверка статуса службы..."
systemctl status atomgame --no-pager

# 6. Перезапуск Nginx с правильной конфигурацией
log "Перенастройка Nginx для проксирования на порт $SERVER_PORT..."
cat > /etc/nginx/sites-available/atomgame << EOF
server {
    listen 80;
    server_name 193.109.78.85;
    
    # Корневая директория с файлами
    root $INSTALL_PATH/dist/public;
    
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

# Перезапуск Nginx
log "Перезапуск Nginx..."
nginx -t && systemctl restart nginx

# Выполнение проверки доступности приложения
log "Проверка доступности приложения..."
sleep 5
if curl -s "http://localhost:$SERVER_PORT" >/dev/null; then
  log "Приложение успешно запущено и отвечает!"
else
  warning "Приложение может еще не запуститься. Проверьте логи через 10-15 секунд:"
  warning "journalctl -u atomgame -f"
fi

echo ""
echo -e "${GREEN}==========================================${NC}"
echo -e "${GREEN}   Исправление завершено!   ${NC}"
echo -e "${GREEN}==========================================${NC}"
echo ""
echo -e "Ваш сайт доступен по адресу: ${YELLOW}http://193.109.78.85${NC}"
echo -e "API доступен по адресу: ${YELLOW}http://193.109.78.85/api${NC}"
echo ""
echo -e "${YELLOW}Полезные команды:${NC}"
echo "- Просмотр логов systemd: journalctl -u atomgame -f"
echo "- Перезапуск приложения: systemctl restart atomgame"
echo "- Проверка статуса: systemctl status atomgame"
echo ""