#!/bin/bash

# ==========================================
# СКРИПТ ИСПРАВЛЕНИЯ ЗАПУСКА ПРИЛОЖЕНИЯ
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
   error "Пожалуйста, используйте: sudo ./fix-app-start.sh"
   exit 1
fi

# Остановка всех экземпляров приложения
log "Остановка всех экземпляров приложения..."
pm2 delete all || true
success "Все приложения остановлены"

# Проверка наличия собранных файлов приложения
log "Проверка наличия собранных файлов приложения..."
if [ ! -f "$PROJECT_DIR/dist/index.js" ]; then
  warn "Файл index.js не найден. Выполняется сборка приложения..."
  cd "$PROJECT_DIR"
  npm run build
  
  if [ ! -f "$PROJECT_DIR/dist/index.js" ]; then
    error "Не удалось создать файл index.js. Проверьте процесс сборки."
    exit 1
  fi
  
  success "Приложение успешно собрано"
else
  success "Файлы приложения существуют"
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

neonConfig.webSocketConstructor = ws;

const connectionString = process.env.DATABASE_URL || 'postgresql://$DB_USER:$ESCAPED_PASSWORD@localhost:5432/$DB_NAME';
console.log('Connecting to database with connection string:', connectionString);

export const pool = new Pool({ connectionString });
export const db = drizzle({ client: pool, schema });
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
success "Файл .env создан с правильными настройками"

# Создание прямого запуска приложения (для тестирования)
log "Создание скрипта прямого запуска приложения..."
cat > $PROJECT_DIR/run-direct.sh << EOF
#!/bin/bash
cd $PROJECT_DIR
export NODE_ENV=production
export PORT=$APP_PORT
export PGUSER=$DB_USER
export PGPASSWORD=$DB_PASSWORD
export PGDATABASE=$DB_NAME
export PGHOST=localhost
export PGPORT=5432
export DATABASE_URL=postgresql://$DB_USER:$ESCAPED_PASSWORD@localhost:5432/$DB_NAME
export SESSION_SECRET=$(openssl rand -hex 32)

node dist/index.js
EOF
chmod +x $PROJECT_DIR/run-direct.sh
success "Скрипт прямого запуска создан"

# Обновление конфигурации PM2
log "Обновление конфигурации PM2..."
cat > $PROJECT_DIR/ecosystem.config.cjs << EOF
module.exports = {
  apps: [{
    name: 'atom-game',
    script: '$PROJECT_DIR/dist/index.js',
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
  }]
};
EOF
success "Файл конфигурации PM2 обновлен"

# Проверка соединения с базой данных
log "Проверка соединения с базой данных..."
if PGPASSWORD="$DB_PASSWORD" psql -h localhost -U $DB_USER -d $DB_NAME -c "\conninfo" 2>/dev/null; then
  success "Соединение с базой данных установлено успешно"
else
  warn "Не удалось подключиться к базе данных. Убедитесь, что PostgreSQL настроен правильно."
  warn "Возможно, нужно перезапустить PostgreSQL: sudo systemctl restart postgresql"
  exit 1
fi

# Перезапуск приложения с PM2 (1 экземпляр)
log "Запуск приложения с PM2..."
cd "$PROJECT_DIR"
pm2 delete atom-game || true

# Запуск в режиме fork (1 процесс) для облегчения отладки
pm2 start ecosystem.config.cjs
pm2 save
success "Приложение запущено"

# Проверка статуса приложения
log "Проверка статуса приложения..."
sleep 3
if pm2 list | grep -q "atom-game" && pm2 list | grep -q "online"; then
  success "Приложение запущено и находится в статусе online"
else
  warn "Приложение может быть не запущено. Проверьте логи: pm2 logs atom-game"
fi

# Проверка открытых портов
log "Проверка открытых портов..."
netstat -tulpn | grep $APP_PORT || warn "Порт $APP_PORT не прослушивается"

echo "=================================================================="
echo "        ИСПРАВЛЕНИЕ ЗАПУСКА ПРИЛОЖЕНИЯ ЗАВЕРШЕНО!"
echo "=================================================================="
echo ""
echo "Для просмотра логов приложения выполните:"
echo "pm2 logs atom-game"
echo ""
echo "Для прямого запуска приложения (без PM2, для отладки):"
echo "$PROJECT_DIR/run-direct.sh"
echo ""
echo "Ваш сайт должен быть доступен по адресу:"
echo "http://atomgameblk.ru или http://193.109.78.85"
echo "=================================================================="