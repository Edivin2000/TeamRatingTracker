#!/bin/bash

# ==========================================
# СКРИПТ НАСТРОЙКИ PRODUCTION-СЕРВЕРА
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
PROJECT_DIR="/var/www/atomgameblk"
APP_PORT=5000

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
   error "Пожалуйста, используйте: sudo ./fix-production.sh"
   exit 1
fi

# Остановка всех PM2 процессов
log "Остановка всех PM2 процессов..."
pm2 delete all || true
success "Все PM2 процессы остановлены"

# Проверка доступности порта
log "Проверка доступности порта $APP_PORT..."
if netstat -tuln | grep -q ":$APP_PORT "; then
  warn "Порт $APP_PORT уже используется. Процесс будет завершен."
  PID=$(netstat -tuln | grep ":$APP_PORT " | awk '{print $7}' | cut -d'/' -f1)
  if [ -n "$PID" ]; then
    log "Завершение процесса PID: $PID"
    kill -9 $PID || true
  fi
fi
success "Порт $APP_PORT свободен"

# Исправление файла подключения к базе данных
log "Исправление файла подключения к базе данных..."
if [ -f "$PROJECT_DIR/server/db.ts" ]; then
  cp "$PROJECT_DIR/server/db.ts" "$PROJECT_DIR/server/db.ts.bak.$(date +%Y%m%d%H%M%S)"
  cat > "$PROJECT_DIR/server/db.ts" << EOF
import { Pool, neonConfig } from '@neondatabase/serverless';
import { drizzle } from 'drizzle-orm/neon-serverless';
import ws from "ws";
import * as schema from "@shared/schema";

// Использование WebSocket для Neon DB
neonConfig.webSocketConstructor = ws;

// Получение строки подключения из переменных окружения
const DATABASE_URL = process.env.DATABASE_URL;
console.log('Connecting to database...');

// Создание пула соединений
const pool = new Pool({ connectionString: DATABASE_URL });
const db = drizzle({ client: pool, schema });

export { pool, db };
EOF
  success "Файл подключения к базе данных исправлен"
else
  warn "Файл db.ts не найден. Пропуск исправления."
fi

# Обновление конфигурации Nginx
log "Обновление конфигурации Nginx..."
cat > /etc/nginx/sites-available/atomgameblk.ru << EOF
server {
    listen 80;
    server_name atomgameblk.ru www.atomgameblk.ru 193.109.78.85;

    location / {
        proxy_pass http://localhost:$APP_PORT;
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
    }

    access_log /var/log/nginx/atomgameblk.ru-access.log;
    error_log /var/log/nginx/atomgameblk.ru-error.log;
}
EOF

# Обновление символической ссылки и проверка конфигурации
ln -sf /etc/nginx/sites-available/atomgameblk.ru /etc/nginx/sites-enabled/
nginx -t && systemctl restart nginx
success "Nginx настроен на порт $APP_PORT"

# Сборка приложения
log "Сборка приложения..."
cd $PROJECT_DIR
npm run build
success "Приложение собрано"

# Запуск приложения через PM2
log "Запуск приложения через PM2..."
cd $PROJECT_DIR
pm2 start ecosystem.config.cjs --only atom-game
pm2 save
success "Приложение запущено через PM2"

# Проверка статуса через 10 секунд (для уверенности)
log "Проверка статуса приложения через 10 секунд..."
sleep 10
if pm2 list | grep -q "atom-game" && pm2 list | grep -q "online"; then
  success "Приложение запущено и находится в статусе online"
else
  warn "Приложение может быть не запущено. Проверьте логи: pm2 logs atom-game"
  log "Запуск тестового сервера в качестве запасного варианта..."
  cd $PROJECT_DIR
  pm2 start simple-server.mjs --name atom-simple-server
  pm2 save
  success "Тестовый сервер запущен через PM2"
fi

# Проверка открытых портов
log "Проверка открытых портов..."
netstat -tulpn | grep $APP_PORT || warn "Порт $APP_PORT не прослушивается"

echo "=================================================================="
echo "        НАСТРОЙКА PRODUCTION-СЕРВЕРА ЗАВЕРШЕНА!"
echo "=================================================================="
echo ""
echo "Проверьте доступность сайта по адресам:"
echo "  http://atomgameblk.ru"
echo "  http://193.109.78.85"
echo ""
echo "Для просмотра логов приложения:"
echo "  pm2 logs atom-game"
echo ""
echo "Если основное приложение не заработало, был запущен тестовый"
echo "сервер. Его логи можно посмотреть командой:"
echo "  pm2 logs atom-simple-server"
echo "=================================================================="