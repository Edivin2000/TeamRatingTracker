#!/bin/bash

# ==========================================
# СКРИПТ ВОССТАНОВЛЕНИЯ ATOM-GAME СЕРВЕРА
# ==========================================
# Версия: 1.0.0
# Дата: 01.05.2025
# ==========================================

set -e

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Переменные настройки
DB_NAME="atomgame"
DB_USER="atomgame"
DB_PASSWORD="Atom&Game#2025!"
PROJECT_DIR="/var/www/atomgameblk"
ESCAPED_PASSWORD=$(echo $DB_PASSWORD | sed 's/&/%26/g; s/#/%23/g')
DATABASE_URL="postgresql://$DB_USER:$ESCAPED_PASSWORD@localhost:5432/$DB_NAME"

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
   error "Пожалуйста, используйте: sudo ./fix-server.sh"
   exit 1
fi

# Шаг 1: Остановка PM2 процессов
log "Остановка всех PM2 процессов..."
pm2 delete all 2>/dev/null || true
success "PM2 процессы остановлены."

# Шаг 2: Проверка базы данных PostgreSQL
log "Проверка статуса базы данных PostgreSQL..."
if systemctl is-active --quiet postgresql; then
  success "PostgreSQL уже запущен."
else
  warn "PostgreSQL не запущен. Запускаем..."
  systemctl start postgresql
  success "PostgreSQL запущен."
fi

# Шаг 3: Восстановление базы данных
log "Проверка базы данных и пользователя..."
if sudo -u postgres psql -lqt | cut -d \| -f 1 | grep -qw $DB_NAME; then
  success "База данных $DB_NAME уже существует."
else
  warn "База данных $DB_NAME не существует. Создаем..."
  
  # Создание пользователя, если не существует
  if ! sudo -u postgres psql -c "\du" | grep -qw $DB_USER; then
    log "Создание пользователя $DB_USER..."
    sudo -u postgres psql -c "CREATE USER $DB_USER WITH ENCRYPTED PASSWORD '$DB_PASSWORD';"
  fi
  
  # Создание базы данных
  sudo -u postgres psql -c "CREATE DATABASE $DB_NAME OWNER $DB_USER;"
  success "База данных $DB_NAME успешно создана."
fi

# Шаг 4: Переход в директорию проекта
log "Переход в директорию проекта $PROJECT_DIR..."
if [ -d "$PROJECT_DIR" ]; then
  cd $PROJECT_DIR
  success "Перешли в директорию проекта."
else
  error "Директория проекта $PROJECT_DIR не существует!"
  exit 1
fi

# Шаг 5: Обновление зависимостей
log "Обновление зависимостей NodeJS..."
npm install ws @neondatabase/serverless
success "Зависимости успешно обновлены."

# Шаг 6: Обновление файла подключения к базе данных
log "Обновление файла подключения к базе данных..."
cat > server/db.ts << 'EOF'
import { Pool, neonConfig } from '@neondatabase/serverless';
import { drizzle } from 'drizzle-orm/neon-serverless';
import * as schema from "@shared/schema";
import ws from 'ws';

// Configure WebSocket for Neon Database
neonConfig.webSocketConstructor = ws;

// Получение строки подключения из переменных окружения
const DATABASE_URL = process.env.DATABASE_URL || 'postgresql://atomgame:Atom%26Game%232025!@localhost:5432/atomgame';
console.log('Connecting to database using URL:', DATABASE_URL);

// Создание пула соединений
const pool = new Pool({ 
  connectionString: DATABASE_URL,
});

// Создание экземпляра Drizzle ORM
const db = drizzle({ client: pool, schema });
console.log('Database connection pool created successfully');

export { pool, db };
EOF
success "Файл подключения к базе данных обновлен."

# Шаг 7: Применение миграций к базе данных
log "Применение миграций к базе данных..."
export DATABASE_URL=$DATABASE_URL
npx drizzle-kit push:pg --schema=./shared/schema.ts
success "Миграции применены успешно."

# Шаг 8: Установка правильных разрешений
log "Установка правильных разрешений для файлов проекта..."
chown -R www-data:www-data $PROJECT_DIR
chmod -R 755 $PROJECT_DIR
success "Разрешения установлены."

# Шаг 9: Запуск сервера с помощью PM2
log "Запуск сервера через PM2..."
cd $PROJECT_DIR
export DATABASE_URL=$DATABASE_URL
pm2 start ecosystem.config.js
success "Сервер успешно запущен через PM2."

# Шаг 10: Сохранение конфигурации PM2
log "Сохранение конфигурации PM2..."
pm2 save
success "Конфигурация PM2 сохранена."

# Шаг 11: Настройка автозапуска PM2
log "Настройка автозапуска PM2..."
pm2 startup | tail -n 1 > /tmp/pm2-startup.sh
chmod +x /tmp/pm2-startup.sh
/tmp/pm2-startup.sh
rm /tmp/pm2-startup.sh
success "Автозапуск PM2 настроен."

# Проверка доступности сайта
log "Проверка доступности сайта..."
sleep 5
if curl -s http://localhost:5000 > /dev/null; then
  success "Сайт успешно запущен и доступен!"
else
  warn "Сайт не отвечает. Проверьте логи PM2 с помощью команды 'pm2 logs'."
fi

success "Восстановление сервера завершено!"
log "Для просмотра логов используйте: pm2 logs"
log "Для просмотра статуса процессов: pm2 status"
log "Если сайт все еще не работает, проверьте логи ошибок с помощью: pm2 logs --err"