#!/bin/bash

# Скрипт для прямого запуска приложения без systemd или PM2
# Май 2025

# Цвета для вывода
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # Сброс цвета

# Настройки
INSTALL_PATH="/var/www/atomgame"
SERVER_PORT="5001"

# Функции вывода
log() {
  echo -e "${GREEN}[ЗАПУСК]${NC} $1"
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
echo -e "${GREEN}   Прямой запуск ATOM-GAME приложения   ${NC}"
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

# 3. Перенастройка nginx для соответствия новому порту
log "Обновление конфигурации Nginx..."
cat > /etc/nginx/sites-available/atomgame << EOF
server {
    listen 80;
    server_name 193.109.78.85;
    
    # Включение отладочных логов
    access_log /var/log/nginx/atomgame.access.log;
    error_log /var/log/nginx/atomgame.error.log debug;
    
    # Включение сжатия
    gzip on;
    gzip_types text/plain application/javascript application/x-javascript text/javascript text/xml text/css;
    
    # Проксирование всех запросов на приложение Node.js
    location / {
        proxy_pass http://127.0.0.1:$SERVER_PORT;
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
        
        # Для отладки
        error_log /var/log/nginx/atomgame-proxy-error.log debug;
        access_log /var/log/nginx/atomgame-proxy-access.log;
    }
}
EOF

# Проверяем конфигурацию и перезапускаем Nginx
nginx -t && systemctl restart nginx

# 4. Переходим в директорию приложения
log "Переходим в директорию приложения $INSTALL_PATH..."
cd "$INSTALL_PATH" || error "Не удалось перейти в директорию $INSTALL_PATH"

# 5. Создание .env файла с правильными переменными
log "Настройка необходимых переменных среды..."
cat > "$INSTALL_PATH/.env" << EOF
# Основные настройки
NODE_ENV=production
PORT=$SERVER_PORT
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

# 6. Проверка директории dist/public
log "Проверка директории dist/public..."
if [ ! -d "$INSTALL_PATH/dist/public" ]; then
  warning "Директория dist/public не существует. Создаем..."
  mkdir -p "$INSTALL_PATH/dist/public"
  
  # Создаем простой index.html
  cat > "$INSTALL_PATH/dist/public/index.html" << EOF
<!DOCTYPE html>
<html lang="ru">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>ATOM GAME</title>
  <style>
    body {
      font-family: Arial, sans-serif;
      margin: 0;
      padding: 0;
      display: flex;
      justify-content: center;
      align-items: center;
      min-height: 100vh;
      background-color: #1a1a1a;
      color: white;
    }
    .container {
      text-align: center;
      padding: 2rem;
    }
    h1 {
      font-size: 2.5rem;
      margin-bottom: 1rem;
      color: #3498db;
    }
    p {
      font-size: 1.2rem;
      margin-bottom: 2rem;
    }
    .logo {
      max-width: 200px;
      margin-bottom: 2rem;
    }
    .btn {
      display: inline-block;
      background-color: #3498db;
      color: white;
      padding: 0.8rem 1.5rem;
      border-radius: 4px;
      text-decoration: none;
      font-weight: bold;
      transition: background-color 0.3s;
    }
    .btn:hover {
      background-color: #2980b9;
    }
  </style>
</head>
<body>
  <div class="container">
    <h1>ATOM﮳GAME</h1>
    <p>Управление рейтингами команд</p>
    <a href="/auth" class="btn">Вход в систему</a>
  </div>
</body>
</html>
EOF
fi

# 7. Очистка логов для лучшей отладки
log "Очистка логов для лучшей отладки..."
> "$INSTALL_PATH/app.log"
> /var/log/nginx/atomgame.error.log
> /var/log/nginx/atomgame.access.log

# 8. Запуск приложения напрямую
log "Запуск приложения напрямую с выводом в консоль..."
log "Для остановки нажмите Ctrl+C"
echo ""

# Экспорт переменных среды
export NODE_ENV=production
export PORT=$SERVER_PORT
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

# Запуск приложения с перенаправлением вывода в терминал
node dist/index.js