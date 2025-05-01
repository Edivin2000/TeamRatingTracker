#!/bin/bash

# Скрипт для отладки приложения ATOM-GAME с подробным логированием
# Май 2025

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
  echo -e "${GREEN}[ОТЛАДКА]${NC} $1"
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
echo -e "${GREEN}   Отладка приложения ATOM-GAME   ${NC}"
echo -e "${GREEN}==========================================${NC}"
echo ""

# 1. Остановка всех процессов
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

# 3. Проверка базы данных
log "Проверка подключения к базе данных..."
if ! sudo -u postgres psql -c "SELECT 1;" > /dev/null 2>&1; then
  warning "PostgreSQL не запущен или не отвечает. Пробуем перезапустить..."
  systemctl restart postgresql
  sleep 5
fi

# 4. Проверка пользователя и базы данных PostgreSQL
log "Проверка пользователя и базы данных PostgreSQL..."
if ! sudo -u postgres psql -c "SELECT 1 FROM pg_roles WHERE rolname='$DB_USER';" | grep -q 1; then
  warning "Пользователь $DB_USER не существует в PostgreSQL. Создаем..."
  sudo -u postgres psql -c "CREATE USER $DB_USER WITH PASSWORD '$DB_PASSWORD';"
  sudo -u postgres psql -c "ALTER USER $DB_USER WITH SUPERUSER;"
fi

if ! sudo -u postgres psql -c "SELECT 1 FROM pg_database WHERE datname='$DB_NAME';" | grep -q 1; then
  warning "База данных $DB_NAME не существует в PostgreSQL. Создаем..."
  sudo -u postgres psql -c "CREATE DATABASE $DB_NAME OWNER $DB_USER;"
fi

sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;"

# 5. Проверка соединения с базой данных от имени пользователя atomgame
log "Проверка соединения с базой данных от имени пользователя $DB_USER..."
export PGPASSWORD=$DB_PASSWORD
if ! psql -U $DB_USER -d $DB_NAME -c "SELECT 1;" > /dev/null 2>&1; then
  warning "Не удалось подключиться к базе данных $DB_NAME с пользователем $DB_USER"
  
  # Проверка метода аутентификации в pg_hba.conf
  log "Проверка метода аутентификации в pg_hba.conf..."
  PG_HBA_FILE=$(sudo -u postgres psql -t -c "SHOW hba_file;" | xargs)
  
  # Добавление записей для локального соединения с паролем
  log "Обновление pg_hba.conf для разрешения соединения по паролю..."
  sed -i '/^host.*all.*all.*127.0.0.1\/32.*ident/d' $PG_HBA_FILE
  sed -i '/^host.*all.*all.*::1\/128.*ident/d' $PG_HBA_FILE
  
  echo "# Добавлено скриптом отладки" >> $PG_HBA_FILE
  echo "host    all             all             127.0.0.1/32            md5" >> $PG_HBA_FILE
  echo "host    all             all             ::1/128                 md5" >> $PG_HBA_FILE
  
  # Перезапуск PostgreSQL
  log "Перезапуск PostgreSQL..."
  systemctl restart postgresql
  sleep 5
  
  # Повторная проверка
  if ! psql -U $DB_USER -d $DB_NAME -c "SELECT 1;" > /dev/null 2>&1; then
    error "Не удалось подключиться к базе данных даже после исправления pg_hba.conf"
  fi
fi

# 6. Создание .env файла с правильными переменными
log "Создание .env файла с правильными переменными..."
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

# 7. Проверка директории dist и файла index.js
log "Проверка директории dist и файла index.js..."
if [ ! -d "$INSTALL_PATH/dist" ]; then
  error "Директория $INSTALL_PATH/dist не существует! Проверьте, правильно ли установлено приложение."
fi

if [ ! -f "$INSTALL_PATH/dist/index.js" ]; then
  error "Файл $INSTALL_PATH/dist/index.js не существует! Проверьте, правильно ли установлено приложение."
fi

# 8. Переходим в директорию приложения
log "Переходим в директорию приложения $INSTALL_PATH..."
cd "$INSTALL_PATH" || error "Не удалось перейти в директорию $INSTALL_PATH"

# 9. Проверка и установка node_modules
log "Проверка и установка node_modules..."
if [ ! -d "$INSTALL_PATH/node_modules" ] || [ ! -f "$INSTALL_PATH/node_modules/.package-lock.json" ]; then
  warning "Директория node_modules не найдена или установлена неправильно. Переустанавливаем зависимости..."
  if [ -f "$INSTALL_PATH/package.json" ]; then
    npm install --production
  else
    error "Файл package.json не найден! Проверьте, правильно ли установлено приложение."
  fi
fi

# 10. Запуск приложения в режиме отладки
log "Запуск приложения в режиме отладки..."
echo -e "${YELLOW}Для остановки нажмите Ctrl+C${NC}"
echo ""

# Установка всех переменных среды и запуск с подробными логами
NODE_ENV=production \
PORT=$SERVER_PORT \
HOST=0.0.0.0 \
PGUSER=$DB_USER \
PGPASSWORD=$DB_PASSWORD \
PGDATABASE=$DB_NAME \
PGHOST=localhost \
PGPORT=5432 \
DATABASE_URL=postgresql://$DB_USER:$DB_PASSWORD@localhost:5432/$DB_NAME \
SESSION_SECRET=AtomGameSecretKey2025 \
DEBUG=* \
NODE_DEBUG=* \
node --inspect dist/index.js