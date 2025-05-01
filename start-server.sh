#!/bin/bash

# Скрипт для запуска сервера ATOM-GAME
echo "Запуск сервера ATOM-GAME..."

# Переменные окружения
DB_NAME="atomgame"
DB_USER="atomgame"
DB_PASSWORD="Atom&Game#2025!"
ESCAPED_PASSWORD=$(echo $DB_PASSWORD | sed 's/&/%26/g; s/#/%23/g')
DATABASE_URL="postgresql://$DB_USER:$ESCAPED_PASSWORD@localhost:5432/$DB_NAME"
SESSION_SECRET="AtomGameSecretSession2025!"
PROJECT_DIR="/var/www/atomgameblk"

# Установка переменных окружения
export PGUSER=$DB_USER
export PGPASSWORD=$DB_PASSWORD
export PGDATABASE=$DB_NAME
export PGHOST=localhost
export PGPORT=5432
export DATABASE_URL=$DATABASE_URL
export SESSION_SECRET=$SESSION_SECRET
export PORT=5000
export NODE_ENV=production
export UPLOADS_DIR="$PROJECT_DIR/uploads"

# Остановка существующих PM2 процессов
echo "Остановка существующих процессов..."
pm2 delete all 2>/dev/null || true

# Переход в директорию проекта
cd "$PROJECT_DIR"

# Создание нового файла ecosystem.config.js
echo "Создание нового файла конфигурации PM2..."
cat > ecosystem.config.js << 'EOL'
module.exports = {
  apps: [
    {
      name: "atom-game-server",
      script: "./server.js",
      env: {
        NODE_ENV: "production",
        PORT: 5000
      },
      watch: false,
      max_memory_restart: "512M",
      exec_mode: "fork",
      instances: 1,
      restart_delay: 3000
    }
  ]
};
EOL

# Запуск сервера через PM2
echo "Запуск сервера через PM2..."
pm2 start ecosystem.config.js
pm2 save

echo "Сервер запущен! Доступен по адресу http://localhost:5000"
echo "Логин админа: admin"
echo "Пароль админа: Atom&Game#2025!"

# Если сервер не запустился через PM2, запустим напрямую
if [ "$(pm2 list | grep atom-game-server | grep online | wc -l)" -eq 0 ]; then
  echo "PM2 не смог запустить сервер. Запуск напрямую через Node.js..."
  
  # Запуск сервера напрямую
  echo "node server.js &" > run-server.sh
  chmod +x run-server.sh
  ./run-server.sh
  
  echo "Сервер запущен напрямую через Node.js. Процесс запущен в фоне."
  echo "Для остановки используйте: kill \$(ps aux | grep 'node server.js' | grep -v grep | awk '{print \$2}')"
fi