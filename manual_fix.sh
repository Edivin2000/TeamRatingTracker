#!/bin/bash

# Скрипт для ручного исправления дублирования переменной net
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
echo -e "${GREEN}   Ручное исправление дублирования net   ${NC}"
echo -e "${GREEN}==========================================${NC}"
echo ""

# 1. Остановка сервиса
log "Остановка всех процессов приложения..."
systemctl stop atomgame 2>/dev/null || true

# Убиваем все процессы node, связанные с приложением
pkill -f "/var/www/atomgame/dist/index.js" 2>/dev/null || true

# 2. Переходим в директорию приложения
log "Переходим в директорию приложения $INSTALL_PATH..."
cd "$INSTALL_PATH" || error "Не удалось перейти в директорию $INSTALL_PATH"

# 3. Создание резервной копии
log "Создание резервной копии index.js..."
cp dist/index.js dist/index.js.bak || error "Не удалось создать резервную копию"

# 4. Отображение информации о файле
log "Анализ файла dist/index.js..."
LINE_COUNT=$(wc -l dist/index.js | awk '{print $1}')
log "Файл содержит $LINE_COUNT строк"

# Находим все объявления net
NET_LINES=$(grep -n "const net = require" dist/index.js | cut -d: -f1)
log "Найдены объявления net в строках: $NET_LINES"

# 5. Создание временного файла без дублирующего объявления
log "Создание временного файла без дублирующего объявления..."

# Находим вторую строку с объявлением
SECOND_NET_LINE=$(echo "$NET_LINES" | sed -n '2p')

if [ ! -z "$SECOND_NET_LINE" ]; then
  log "Удаляем второе объявление в строке $SECOND_NET_LINE"
  
  # Создаем временный файл и удаляем строку
  sed "${SECOND_NET_LINE}d" dist/index.js > /tmp/index.fixed.js
  cp /tmp/index.fixed.js dist/index.js
  
  log "Второе объявление удалено"
else
  warning "Не найдено второе объявление net"
  
  # Альтернативный подход - закомментировать все объявления net
  log "Комментируем все объявления net..."
  sed -i 's/const net = require/\/\/ const net = require/' dist/index.js
  
  # Добавляем одно чистое объявление в начало файла
  sed -i '1i const net = require("node:net");' dist/index.js
  
  log "Все объявления net закомментированы и добавлено одно в начало файла"
fi

# 6. Настройка правильных переменных окружения
log "Создание .env файла..."
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

# 7. Создание простого скрипта запуска
log "Создание простого скрипта запуска..."
cat > "$INSTALL_PATH/start_simple.sh" << EOF
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

chmod +x "$INSTALL_PATH/start_simple.sh"

# 8. Запуск приложения в фоновом режиме
log "Запуск приложения..."
nohup "$INSTALL_PATH/start_simple.sh" > "$INSTALL_PATH/app.log" 2>&1 &

APP_PID=$!
echo $APP_PID > "$INSTALL_PATH/app.pid"

log "Приложение запущено с PID: $APP_PID"
log "Логи перенаправлены в $INSTALL_PATH/app.log"

# 9. Обновление конфигурации Nginx
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
        proxy_pass http://127.0.0.1:5001;
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

# Перезапуск Nginx
nginx -t && systemctl restart nginx

# 10. Проверка, что приложение запустилось
log "Ожидание запуска приложения (5 секунд)..."
sleep 5

if kill -0 $APP_PID 2>/dev/null; then
  log "Процесс запущен и работает!"
  
  # Выводим последние строки логов
  log "Последние строки логов:"
  tail -n 10 "$INSTALL_PATH/app.log"
else
  warning "Процесс не запущен или уже завершился"
  
  # Выводим последние строки логов
  log "Содержимое логов:"
  cat "$INSTALL_PATH/app.log"
fi

echo ""
echo -e "${GREEN}==========================================${NC}"
echo -e "${GREEN}   Исправление завершено!   ${NC}"
echo -e "${GREEN}==========================================${NC}"
echo ""
echo -e "${YELLOW}Для просмотра логов:${NC}"
echo "tail -f $INSTALL_PATH/app.log"
echo ""
echo -e "${YELLOW}Для остановки приложения:${NC}"
echo "kill \$(cat $INSTALL_PATH/app.pid)"
echo ""
echo -e "${YELLOW}Для проверки доступности сайта:${NC}"
echo "http://193.109.78.85"
echo ""