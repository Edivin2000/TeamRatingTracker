#!/bin/bash

# Скрипт для исправления проблемы с Nginx (502 Bad Gateway)
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
echo -e "${GREEN}   Исправление ошибки 502 Bad Gateway   ${NC}"
echo -e "${GREEN}==========================================${NC}"
echo ""
log "Начало исправления..."

# 1. Остановка и удаление всех процессов
log "Остановка всех процессов..."
if command -v pm2 &> /dev/null; then
  pm2 delete all 2>/dev/null || true
fi

if systemctl is-active --quiet atomgame; then
  systemctl stop atomgame
fi

# 2. Проверка, запущено ли что-то на нужном порту
log "Проверка, что порт $SERVER_PORT свободен..."
if lsof -i:$SERVER_PORT >/dev/null 2>&1; then
  warning "Порт $SERVER_PORT занят. Освобождаем..."
  fuser -k $SERVER_PORT/tcp
fi

# 3. Проверка, что Nginx работает
log "Проверка статуса Nginx..."
if ! systemctl is-active --quiet nginx; then
  log "Nginx не запущен. Запускаем..."
  systemctl start nginx
fi

# 4. Настройка Nginx правильно для прямого проксирования
log "Обновление конфигурации Nginx..."
cat > /etc/nginx/sites-available/atomgame << EOF
server {
    listen 80;
    server_name 193.109.78.85;
    
    # Корневая директория с файлами
    root $INSTALL_PATH/dist/public;
    
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

# Проверка конфигурации и перезапуск Nginx
log "Проверка конфигурации Nginx..."
nginx -t

if [ $? -eq 0 ]; then
  log "Конфигурация Nginx правильная. Перезапуск..."
  systemctl restart nginx
else
  error "Ошибка в конфигурации Nginx. Исправьте ошибки вручную."
fi

# 5. Запуск приложения напрямую вместо PM2 или systemd
log "Создание скрипта для запуска приложения..."
cat > "$INSTALL_PATH/start_app.sh" << EOF
#!/bin/bash

# Настройка переменных окружения
export NODE_ENV=production
export PORT=$SERVER_PORT
export HOST=0.0.0.0
export PGUSER=atomgame
export PGPASSWORD=AtomGame2025
export PGDATABASE=atomgame
export PGHOST=localhost
export PGPORT=5432
export DATABASE_URL=postgresql://atomgame:AtomGame2025@localhost:5432/atomgame
export SESSION_SECRET=AtomGameSecretKey2025

# Запуск приложения
cd $INSTALL_PATH
node dist/index.js > app.log 2>&1 &
echo \$! > app.pid
echo "Приложение запущено с PID: \$(cat app.pid)"
EOF

chmod +x "$INSTALL_PATH/start_app.sh"

# 6. Создание скрипта остановки
cat > "$INSTALL_PATH/stop_app.sh" << EOF
#!/bin/bash
if [ -f $INSTALL_PATH/app.pid ]; then
  kill \$(cat $INSTALL_PATH/app.pid)
  rm $INSTALL_PATH/app.pid
  echo "Приложение остановлено"
else
  echo "Файл PID не найден. Приложение не запущено?"
fi
EOF

chmod +x "$INSTALL_PATH/stop_app.sh"

# 7. Создание скрипта для просмотра логов
cat > "$INSTALL_PATH/view_logs.sh" << EOF
#!/bin/bash
tail -f $INSTALL_PATH/app.log
EOF

chmod +x "$INSTALL_PATH/view_logs.sh"

# 8. Создание службы systemd (более надежный способ)
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
Environment=PGUSER=atomgame
Environment=PGPASSWORD=AtomGame2025
Environment=PGDATABASE=atomgame
Environment=PGHOST=localhost
Environment=PGPORT=5432
Environment=DATABASE_URL=postgresql://atomgame:AtomGame2025@localhost:5432/atomgame
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

# 9. Проверка, что приложение запущено через systemd
log "Проверка статуса приложения..."
systemctl status atomgame --no-pager

# 10. Проверка доступности через Nginx
log "Проверка доступности через Nginx..."
sleep 5
curl -I http://localhost || warning "Не удалось получить ответ от локального сервера"

echo ""
echo -e "${GREEN}==========================================${NC}"
echo -e "${GREEN}   Исправление завершено!   ${NC}"
echo -e "${GREEN}==========================================${NC}"
echo ""
echo -e "Ваш сайт доступен по адресу: ${YELLOW}http://193.109.78.85${NC}"
echo -e ""
echo -e "${YELLOW}Полезные команды:${NC}"
echo "- Просмотр логов systemd: journalctl -u atomgame -f"
echo "- Просмотр логов приложения: cat $INSTALL_PATH/app.log"
echo "- Перезапуск приложения: systemctl restart atomgame"
echo "- Проверка статуса: systemctl status atomgame"
echo ""
echo -e "${RED}Если проблема сохраняется, выполните следующие команды:${NC}"
echo "1. systemctl stop atomgame"
echo "2. cd $INSTALL_PATH"
echo "3. ./start_app.sh  # запустит приложение напрямую"
echo "4. ./view_logs.sh  # покажет логи в реальном времени"
echo ""