#!/bin/bash

# ==========================================
# ФИНАЛЬНЫЙ СКРИПТ ИСПРАВЛЕНИЯ ПРИЛОЖЕНИЯ ATOM-GAME
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
DB_NAME="atomgame"
DB_USER="atomgame"
DB_PASSWORD="Atom&Game#2025!"
ESCAPED_PASSWORD=$(echo $DB_PASSWORD | sed 's/&/%26/g; s/#/%23/g')
APP_PORT=8080  # Изменяем порт на 8080, который, судя по netstat, свободен

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
   error "Пожалуйста, используйте: sudo ./fix-final.sh"
   exit 1
fi

# Остановка всех экземпляров приложения
log "Остановка всех экземпляров приложения..."
pm2 delete all || true
success "Все приложения остановлены"

# Исправление WebSocket в исходных файлах
log "Исправление WebSocket в исходных файлах..."
FILES_TO_CHECK=$(find "$PROJECT_DIR/client/src" -name "*.ts" -o -name "*.tsx" -o -name "*.js" -o -name "*.jsx" | xargs grep -l "WebSocket" 2>/dev/null || echo "")

if [ -n "$FILES_TO_CHECK" ]; then
  for file in $FILES_TO_CHECK; do
    log "Проверка файла: $file"
    # Создаем резервную копию
    cp "$file" "$file.bak"
    # Исправляем WebSocket URL
    sed -i 's|wss://localhost|ws://localhost|g' "$file"
    sed -i 's|"wss:"|"ws:"|g' "$file"
    sed -i 's|window.location.protocol === "https:" ? "wss:" : "ws:"|"ws:"|g' "$file"
    success "Файл $file обработан"
  done
else
  warn "Не найдены файлы с WebSocket для исправления в исходном коде"
fi

# Исправление WebSocket в скомпилированных файлах
log "Исправление WebSocket в скомпилированных файлах..."
if [ -d "$PROJECT_DIR/dist" ]; then
  DIST_FILES=$(find "$PROJECT_DIR/dist" -name "*.js" | xargs grep -l "WebSocket" 2>/dev/null || echo "")
  if [ -n "$DIST_FILES" ]; then
    for file in $DIST_FILES; do
      log "Проверка скомпилированного файла: $file"
      # Создаем резервную копию
      cp "$file" "$file.bak"
      # Исправляем WebSocket URL
      sed -i 's|wss://localhost|ws://localhost|g' "$file"
      sed -i 's|"wss:"|"ws:"|g' "$file"
      sed -i 's|"https:"===.location.protocol?"wss:":"ws:"|"ws:"|g' "$file"
      success "Скомпилированный файл $file обработан"
    done
  else
    warn "Не найдены файлы с WebSocket для исправления в скомпилированном коде"
  fi
else
  warn "Директория dist не найдена"
fi

# Исправляем скомпилированные клиентские файлы
log "Исправление всех скомпилированных client-*.js файлов..."
if [ -d "$PROJECT_DIR/dist/client" ]; then
  CLIENT_FILES=$(find "$PROJECT_DIR/dist/client" -name "*.js" 2>/dev/null || echo "")
  if [ -n "$CLIENT_FILES" ]; then
    for file in $CLIENT_FILES; do
      log "Проверка клиентского файла: $file"
      # Создаем резервную копию
      cp "$file" "$file.bak"
      # Исправляем WebSocket URL
      sed -i 's|wss://|ws://|g' "$file"
      sed -i 's|"wss:"|"ws:"|g' "$file"
      sed -i 's|"https:"===.location.protocol?"wss:":"ws:"|"ws:"|g' "$file"
      success "Клиентский файл $file обработан"
    done
  else
    warn "Не найдены клиентские файлы для исправления"
  fi
else
  warn "Директория dist/client не найдена"
fi

# Установка новых прав для директории проекта
log "Установка прав для директории проекта..."
chown -R root:root $PROJECT_DIR
chmod -R 755 $PROJECT_DIR
success "Права установлены"

# Исправление файла подключения к базе данных
log "Исправление файла подключения к базе данных..."
if [ -f "$PROJECT_DIR/server/db.ts" ]; then
  cp "$PROJECT_DIR/server/db.ts" "$PROJECT_DIR/server/db.ts.bak"
  cat > "$PROJECT_DIR/server/db.ts" << EOF
import { Pool, neonConfig } from '@neondatabase/serverless';
import { drizzle } from 'drizzle-orm/neon-serverless';
import ws from "ws";
import * as schema from "@shared/schema";

// Отключаем WebSocket для Neon DB и используем прямое соединение
// neonConfig.webSocketConstructor = ws;

// Явное определение строки подключения
const DATABASE_URL = process.env.DATABASE_URL || 'postgresql://$DB_USER:$ESCAPED_PASSWORD@localhost:5432/$DB_NAME';
console.log('Connecting to database with connection string:', DATABASE_URL);

try {
  console.log('Creating database pool...');
  export const pool = new Pool({ connectionString: DATABASE_URL });
  console.log('Database pool created successfully');
  export const db = drizzle({ client: pool, schema });
  console.log('Drizzle ORM initialized successfully');
} catch (error) {
  console.error('Error initializing database connection:', error);
  throw error;
}
EOF

  success "Файл подключения к базе данных исправлен"
else
  warn "Файл db.ts не найден. Пропуск исправления."
fi

# Создание .env файла с правильными настройками
log "Создание конфигурационного файла .env..."
cat > $PROJECT_DIR/.env << EOF
# Основные настройки
NODE_ENV=production
PORT=$APP_PORT

# База данных PostgreSQL
PGUSER=$DB_USER
PGPASSWORD=$DB_PASSWORD
PGDATABASE=$DB_NAME
PGHOST=localhost
PGPORT=5432
DATABASE_URL=postgresql://$DB_USER:$ESCAPED_PASSWORD@localhost:5432/$DB_NAME

# Безопасность
SESSION_SECRET=$(openssl rand -hex 32)
EOF
success "Файл .env создан с правильными настройками на порт $APP_PORT"

# Создание простого прямого сервера Express
log "Создание простого Express сервера для проверки..."
mkdir -p $PROJECT_DIR/test-server
cat > $PROJECT_DIR/test-server/server.js << EOF
const express = require('express');
const path = require('path');
const app = express();
const PORT = $APP_PORT;

app.use(express.static(path.join('$PROJECT_DIR', 'dist', 'client')));

app.get('/api/health', (req, res) => {
  res.json({ status: 'ok', message: 'Server is running' });
});

app.get('*', (req, res) => {
  res.sendFile(path.join('$PROJECT_DIR', 'dist', 'client', 'index.html'));
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(\`Test server running at http://0.0.0.0:\${PORT}\`);
});
EOF
success "Тестовый сервер создан"

# Установка Express для тестового сервера
log "Установка Express для тестового сервера..."
cd $PROJECT_DIR/test-server
npm init -y
npm install express
success "Express установлен"

# Обновление конфигурации PM2
log "Обновление конфигурации PM2..."
cat > $PROJECT_DIR/ecosystem.config.cjs << EOF
module.exports = {
  apps: [
    {
      name: 'atom-game',
      script: '$PROJECT_DIR/dist/index.js',
      cwd: '$PROJECT_DIR',
      instances: 1,
      exec_mode: 'fork',
      env: {
        NODE_ENV: 'production',
        PORT: '$APP_PORT',
        PGUSER: '$DB_USER',
        PGPASSWORD: '$DB_PASSWORD',
        PGDATABASE: '$DB_NAME',
        PGHOST: 'localhost',
        PGPORT: '5432',
        DATABASE_URL: 'postgresql://$DB_USER:$ESCAPED_PASSWORD@localhost:5432/$DB_NAME',
        SESSION_SECRET: '$(openssl rand -hex 32)'
      },
      watch: false,
      max_memory_restart: '500M'
    },
    {
      name: 'atom-test-server',
      script: '$PROJECT_DIR/test-server/server.js',
      instances: 1,
      exec_mode: 'fork',
      env: {
        NODE_ENV: 'production'
      },
      watch: false
    }
  ]
};
EOF
success "Файл конфигурации PM2 обновлен"

# Перестройка приложения
log "Перестройка приложения..."
cd "$PROJECT_DIR"
npm run build
success "Приложение перестроено"

# Обновление Nginx
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

# Удаление дефолтного конфига
rm -f /etc/nginx/sites-enabled/default

# Создание символической ссылки и проверка конфигурации
ln -sf /etc/nginx/sites-available/atomgameblk.ru /etc/nginx/sites-enabled/
nginx -t && systemctl restart nginx
success "Nginx настроен на порт $APP_PORT"

# Запуск тестового сервера с PM2
log "Запуск тестового сервера с PM2..."
pm2 delete all || true
pm2 start $PROJECT_DIR/test-server/server.js --name atom-test-server
pm2 save
success "Тестовый сервер запущен"

# Проверка статуса
log "Проверка статуса сервера..."
sleep 3
if pm2 list | grep -q "atom-test-server" && pm2 list | grep -q "online"; then
  success "Тестовый сервер запущен и находится в статусе online"
else
  warn "Тестовый сервер может быть не запущен. Проверьте логи: pm2 logs atom-test-server"
fi

# Проверка открытых портов
log "Проверка открытых портов..."
netstat -tulpn | grep $APP_PORT || warn "Порт $APP_PORT не прослушивается"

echo "=================================================================="
echo "        ФИНАЛЬНОЕ ИСПРАВЛЕНИЕ ПРИЛОЖЕНИЯ ЗАВЕРШЕНО!"
echo "=================================================================="
echo ""
echo "Запущен тестовый сервер для проверки доступности сайта."
echo "Проверьте доступность:"
echo "  http://atomgameblk.ru или http://193.109.78.85"
echo ""
echo "Для просмотра логов выполните:"
echo "  pm2 logs atom-test-server"
echo ""
echo "После успешной проверки можно запустить основное приложение:"
echo "  pm2 start ecosystem.config.cjs --only atom-game"
echo "=================================================================="