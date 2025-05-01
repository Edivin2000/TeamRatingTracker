#!/bin/bash

# ==========================================
# СКРИПТ ИСПРАВЛЕНИЯ WEBSOCKET СОЕДИНЕНИЯ
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
   error "Пожалуйста, используйте: sudo ./fix-websocket.sh"
   exit 1
fi

# Остановка всех PM2 процессов
log "Остановка всех PM2 процессов..."
pm2 delete all || true
success "Все PM2 процессы остановлены"

# Исправление файла подключения к базе данных - отключение WebSocket
log "Исправление файла подключения к базе данных (отключение WebSocket)..."
if [ -f "$PROJECT_DIR/server/db.ts" ]; then
  cp "$PROJECT_DIR/server/db.ts" "$PROJECT_DIR/server/db.ts.bak.$(date +%Y%m%d%H%M%S)"
  cat > "$PROJECT_DIR/server/db.ts" << EOF
import { Pool, neonConfig } from '@neondatabase/serverless';
import { drizzle } from 'drizzle-orm/neon-serverless';
// Убираем импорт ws
// import ws from "ws";
import * as schema from "@shared/schema";

// ВНИМАНИЕ: Отключаем WebSocket для Neon DB и используем прямое соединение
// neonConfig.webSocketConstructor = ws;

// Уточняем режим подключения
console.log('Connecting to database using direct connection (WebSocket disabled)');

// Получение строки подключения из переменных окружения
const DATABASE_URL = process.env.DATABASE_URL;
console.log('Database URL is set:', !!DATABASE_URL);

// Опции без WebSocket
const poolOptions = { 
  connectionString: DATABASE_URL,
  ssl: true  // Добавляем SSL для безопасного соединения
};

// Создание пула соединений
const pool = new Pool(poolOptions);
const db = drizzle({ client: pool, schema });

console.log('Database connection pool created successfully');

export { pool, db };
EOF
  success "Файл подключения к базе данных исправлен (WebSocket отключен)"
else
  error "Файл db.ts не найден. Исправление не выполнено."
  exit 1
fi

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

# Проверка статуса через 5 секунд
log "Проверка статуса приложения через 5 секунд..."
sleep 5
if pm2 list | grep -q "atom-game" && pm2 list | grep -q "online"; then
  success "Приложение запущено и находится в статусе online"
else
  warn "Приложение может быть не запущено. Проверьте логи: pm2 logs atom-game"
fi

echo "=================================================================="
echo "    ИСПРАВЛЕНИЕ WEBSOCKET СОЕДИНЕНИЯ ЗАВЕРШЕНО!"
echo "=================================================================="
echo ""
echo "Проверьте доступность сайта по адресам:"
echo "  http://atomgameblk.ru"
echo "  http://193.109.78.85"
echo ""
echo "Для проверки работы приложения, запустите:"
echo "  pm2 logs atom-game"
echo "=================================================================="