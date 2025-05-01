#!/bin/bash

# ==========================================
# СКРИПТ ИСПРАВЛЕНИЯ ФАЙЛА DB.TS
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
APP_PORT=8080

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
   error "Пожалуйста, используйте: sudo ./fix-db-export.sh"
   exit 1
fi

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

let pool;
let db;

try {
  console.log('Creating database pool...');
  pool = new Pool({ connectionString: DATABASE_URL });
  console.log('Database pool created successfully');
  db = drizzle({ client: pool, schema });
  console.log('Drizzle ORM initialized successfully');
} catch (error) {
  console.error('Error initializing database connection:', error);
  throw error;
}

export { pool, db };
EOF

  success "Файл подключения к базе данных исправлен"
else
  warn "Файл db.ts не найден. Пропуск исправления."
fi

# Перестройка приложения
log "Перестройка приложения..."
cd "$PROJECT_DIR"
npm run build
success "Приложение перестроено"

# Запуск тестового сервера для проверки
log "Запуск тестового сервера для проверки сайта..."
cd "$PROJECT_DIR/test-server"
node server.js &
SERVER_PID=$!
success "Тестовый сервер запущен с PID: $SERVER_PID"

# Настраиваем автоматическое убийство процесса через 10 секунд
log "Тестовый сервер будет автоматически остановлен через 10 секунд..."
(sleep 10 && kill $SERVER_PID) &

echo "=================================================================="
echo "        ИСПРАВЛЕНИЕ ФАЙЛА DB.TS ЗАВЕРШЕНО!"
echo "=================================================================="
echo ""
echo "Тестовый сервер запущен для проверки доступности сайта."
echo "Проверьте доступность:"
echo "  http://atomgameblk.ru или http://193.109.78.85"
echo ""
echo "Теперь запустите PM2 для постоянной работы сервера:"
echo "  pm2 delete all"
echo "  pm2 start $PROJECT_DIR/test-server/server.js --name atom-test-server"
echo "  pm2 save"
echo "=================================================================="