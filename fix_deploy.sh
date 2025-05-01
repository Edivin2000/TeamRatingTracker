#!/bin/bash

# Скрипт для исправления проблем с установкой ATOM-GAME
# Май 2025

# Переход в корневую директорию для предотвращения ошибок c getcwd()
cd /

# Цвета для вывода
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # Сброс цвета

# Настройки установки
INSTALL_PATH="/var/www/atomgame"
SERVER_PORT="5001"
DB_USER="atomgame"
DB_PASSWORD="AtomGame2025"
DB_NAME="atomgame"

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
echo -e "${GREEN}   Исправление установки ATOM-GAME   ${NC}"
echo -e "${GREEN}==========================================${NC}"
echo ""
log "Начало восстановления..."

# Проверка существования директории
if [ ! -d "$INSTALL_PATH" ]; then
   error "Директория $INSTALL_PATH не существует. Запустите сначала скрипт полной установки."
fi

# Остановка PM2 и других сервисов
log "Остановка сервисов..."
if command -v pm2 &> /dev/null; then
  pm2 delete all 2>/dev/null || true
fi

# Переключаемся в корневую директорию
cd /

# 1. Исправление проблемы с PostgreSQL
log "Исправление проблемы с базой данных PostgreSQL..."

# Проверка работы PostgreSQL
systemctl restart postgresql
systemctl status postgresql --no-pager

# Пересоздание пользователя базы данных с правильным паролем
log "Пересоздание пользователя БД с правильным паролем..."
sudo -u postgres psql -c "DROP OWNED BY $DB_USER CASCADE;" || true
sudo -u postgres psql -c "DROP USER IF EXISTS $DB_USER;" || true
sudo -u postgres psql -c "CREATE USER $DB_USER WITH PASSWORD '$DB_PASSWORD';"
sudo -u postgres psql -c "ALTER USER $DB_USER WITH SUPERUSER;"

# Пересоздание базы данных
log "Пересоздание базы данных..."
sudo -u postgres psql -c "DROP DATABASE IF EXISTS $DB_NAME;" || true
sudo -u postgres psql -c "CREATE DATABASE $DB_NAME OWNER $DB_USER;"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;"

# 2. Исправление конфигурации PM2 для ESM-модулей
log "Исправление конфигурации PM2 для ES модулей..."

# Переход в директорию проекта
cd "$INSTALL_PATH" || error "Не удалось перейти в $INSTALL_PATH"

# Обновление ecosystem.config.js для поддержки ESM
log "Создание правильного файла конфигурации PM2..."
cat > "$INSTALL_PATH/ecosystem.config.cjs" << EOF
module.exports = {
  apps: [
    {
      name: "atomgame",
      script: "dist/index.js",
      instances: 1,
      autorestart: true,
      watch: false,
      env: {
        NODE_ENV: "production",
        PORT: $SERVER_PORT,
        HOST: "0.0.0.0",
      },
      max_memory_restart: "500M",
      error_file: "logs/error.log",
      out_file: "logs/output.log",
      log_date_format: "YYYY-MM-DD HH:mm Z",
    },
  ],
};
EOF

# Удаление старого файла конфигурации, если он существует
if [ -f "$INSTALL_PATH/ecosystem.config.js" ]; then
  rm "$INSTALL_PATH/ecosystem.config.js"
fi

# 3. Исправление файла .env
log "Обновление файла .env с правильными параметрами..."
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

# 4. Повторное применение схемы базы данных
log "Повторное применение схемы базы данных..."
cd "$INSTALL_PATH"
npm run db:push

# 5. Запуск приложения с использованием .cjs расширения
log "Запуск приложения через PM2..."
cd "$INSTALL_PATH"
pm2 start ecosystem.config.cjs
pm2 save

# 6. Перезапуск Nginx
log "Перезапуск Nginx..."
nginx -t && systemctl restart nginx

# Вывод статуса
log "Проверка статуса приложения..."
curl -s "http://localhost:$SERVER_PORT" >/dev/null
if [ $? -eq 0 ]; then
  log "Приложение работает!"
else
  warning "Приложение может не работать. Проверьте логи: pm2 logs"
fi

echo ""
echo -e "${GREEN}==========================================${NC}"
echo -e "${GREEN}   Исправление завершено!   ${NC}"
echo -e "${GREEN}==========================================${NC}"
echo ""
echo -e "Ваш сайт доступен по адресу: ${YELLOW}http://193.109.78.85${NC}"
echo -e "API доступен по адресу: ${YELLOW}http://193.109.78.85/api${NC}"
echo ""
echo -e "${YELLOW}Проверьте работу приложения и логи:${NC}"
echo "- pm2 logs"
echo "- cat $INSTALL_PATH/logs/error.log"
echo "- cat $INSTALL_PATH/logs/output.log"
echo ""
echo -e "${YELLOW}Если приложение по-прежнему не работает, попробуйте:${NC}"
echo "cd $INSTALL_PATH && node dist/index.js"
echo ""