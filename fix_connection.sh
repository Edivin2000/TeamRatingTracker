#!/bin/bash

# Скрипт для исправления ошибки подключения ECONNREFUSED ::1:443
# Май 2025

# Цвета для вывода
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # Сброс цвета

# Настройки
INSTALL_PATH="/var/www/atomgame"

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
echo -e "${GREEN}   Исправление ошибки подключения   ${NC}"
echo -e "${GREEN}==========================================${NC}"
echo ""

# 1. Остановка сервиса
log "Остановка приложения..."
systemctl stop atomgame 2>/dev/null || true

# 2. Переходим в директорию приложения
log "Переходим в директорию приложения $INSTALL_PATH..."
cd "$INSTALL_PATH" || error "Не удалось перейти в директорию $INSTALL_PATH"

# 3. Создание новой конфигурации .env без HTTPS
log "Создание новой конфигурации .env без HTTPS..."
cat > "$INSTALL_PATH/.env" << EOF
# Основные настройки
NODE_ENV=production
PORT=5001
HOST=0.0.0.0

# Отключение HTTPS
HTTPS=false
NODE_TLS_REJECT_UNAUTHORIZED=0

# База данных PostgreSQL
PGUSER=atomgame
PGPASSWORD=AtomGame2025
PGDATABASE=atomgame
PGHOST=localhost
PGPORT=5432
DATABASE_URL=postgresql://atomgame:AtomGame2025@localhost:5432/atomgame

# Безопасность
SESSION_SECRET=AtomGameSecretKey2025
EOF

# 4. Добавление правильной конфигурации в systemd
log "Обновление конфигурации systemd..."
cat > /etc/systemd/system/atomgame.service << EOF
[Unit]
Description=ATOM-GAME Application
After=network.target postgresql.service

[Service]
User=root
WorkingDirectory=$INSTALL_PATH
Environment=NODE_ENV=production
Environment=PORT=5001
Environment=HOST=0.0.0.0
Environment=HTTPS=false
Environment=NODE_TLS_REJECT_UNAUTHORIZED=0
Environment=PGUSER=atomgame
Environment=PGPASSWORD=AtomGame2025
Environment=PGDATABASE=atomgame
Environment=PGHOST=localhost
Environment=PGPORT=5432
Environment=DATABASE_URL=postgresql://atomgame:AtomGame2025@localhost:5432/atomgame
Environment=SESSION_SECRET=AtomGameSecretKey2025
Environment=NODE_OPTIONS=--experimental-specifier-resolution=node --no-warnings
ExecStart=/usr/bin/node $INSTALL_PATH/dist/index.js
StandardOutput=append:$INSTALL_PATH/app.log
StandardError=append:$INSTALL_PATH/app.log
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# 5. Поиск в коде мест, где используется HTTPS
log "Поиск в коде мест, где используется HTTPS..."
grep -r "https://" dist/ > /tmp/https_mentions.log 2>/dev/null
grep -r "::1" dist/ > /tmp/ipv6_localhost.log 2>/dev/null
grep -r "443" dist/ > /tmp/port443_mentions.log 2>/dev/null

# Вывод найденных упоминаний
if [ -s /tmp/https_mentions.log ]; then
  echo -e "${YELLOW}Упоминания HTTPS в коде:${NC}"
  cat /tmp/https_mentions.log
fi

if [ -s /tmp/ipv6_localhost.log ]; then
  echo -e "${YELLOW}Упоминания IPv6 localhost (::1) в коде:${NC}"
  cat /tmp/ipv6_localhost.log
fi

if [ -s /tmp/port443_mentions.log ]; then
  echo -e "${YELLOW}Упоминания порта 443 в коде:${NC}"
  cat /tmp/port443_mentions.log
fi

# 6. Создание патча для исправления проблемы с ::1
log "Создание патча для исправления проблемы с ::1..."
cat > /tmp/ipv6_patch.js << EOF
// Патч для предотвращения использования IPv6 localhost (::1)
process.env.HTTPS = 'false';
process.env.NODE_TLS_REJECT_UNAUTHORIZED = '0';

// Переопределение функции fetch для предотвращения вызовов к ::1
if (typeof global.fetch === 'function') {
  const originalFetch = global.fetch;
  global.fetch = function(url, options) {
    if (typeof url === 'string' && url.includes('::1')) {
      url = url.replace('::1', '127.0.0.1');
    }
    return originalFetch(url, options);
  };
}

// Патч для предотвращения подключений к ::1
const net = require('node:net');
const originalConnect = net.Socket.prototype.connect;
net.Socket.prototype.connect = function(options, ...args) {
  if (options && options.host === '::1') {
    options.host = '127.0.0.1';
  }
  return originalConnect.call(this, options, ...args);
};

// Для HTTP запросов
const http = require('node:http');
const https = require('node:https');
const originalHttpRequest = http.request;
const originalHttpsRequest = https.request;

http.request = function(url, options, callback) {
  if (typeof url === 'string' && url.includes('::1')) {
    url = url.replace('::1', '127.0.0.1');
  } else if (url && url.hostname === '::1') {
    url.hostname = '127.0.0.1';
  }
  return originalHttpRequest(url, options, callback);
};

https.request = function(url, options, callback) {
  if (typeof url === 'string' && url.includes('::1')) {
    url = url.replace('::1', '127.0.0.1');
  } else if (url && url.hostname === '::1') {
    url.hostname = '127.0.0.1';
  }
  
  // Отключаем проверку сертификатов для локальных соединений
  if (!options) options = {};
  options.rejectUnauthorized = false;
  
  return originalHttpsRequest(url, options, callback);
};
EOF

# Найдем начало файла index.js
log "Применение патча в начало файла index.js..."
cat /tmp/ipv6_patch.js > /tmp/new_index.js
cat dist/index.js >> /tmp/new_index.js
cp /tmp/new_index.js dist/index.js

# 7. Отключение HTTPS в настройках Nginx
log "Обновление конфигурации Nginx..."
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
        proxy_pass http://localhost:5001;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto http;
        proxy_cache_bypass \$http_upgrade;
        proxy_read_timeout 300;
        proxy_connect_timeout 300;
        proxy_send_timeout 300;
    }
}
EOF

# Проверяем конфигурацию и перезапускаем Nginx
nginx -t && systemctl restart nginx

# 8. Создание скрипта для ручного запуска
log "Создание скрипта для ручного запуска..."
cat > "$INSTALL_PATH/run_without_https.sh" << EOF
#!/bin/bash
export NODE_ENV=production
export PORT=5001
export HOST=0.0.0.0
export HTTPS=false
export NODE_TLS_REJECT_UNAUTHORIZED=0
export PGUSER=atomgame
export PGPASSWORD=AtomGame2025
export PGDATABASE=atomgame
export PGHOST=localhost
export PGPORT=5432
export DATABASE_URL=postgresql://atomgame:AtomGame2025@localhost:5432/atomgame
export SESSION_SECRET=AtomGameSecretKey2025
export NODE_OPTIONS="--experimental-specifier-resolution=node --no-warnings"

node dist/index.js
EOF

chmod +x "$INSTALL_PATH/run_without_https.sh"

# 9. Перезапуск службы
log "Перезапуск приложения..."
systemctl daemon-reload
systemctl restart atomgame

# 10. Проверка статуса
log "Проверка статуса приложения..."
sleep 5
systemctl status atomgame --no-pager

echo ""
echo -e "${GREEN}==========================================${NC}"
echo -e "${GREEN}   Исправление завершено!   ${NC}"
echo -e "${GREEN}==========================================${NC}"
echo ""
log "Если проблема с подключением сохраняется:"
echo "1. Остановите службу: systemctl stop atomgame"
echo "2. Запустите приложение вручную: $INSTALL_PATH/run_without_https.sh"
echo "3. Проверьте логи напрямую в консоли"
echo ""
log "Проверьте доступность сайта:"
echo "http://193.109.78.85"
echo ""