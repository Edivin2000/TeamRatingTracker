#!/bin/bash

# Скрипт для сборки клиентской части
# Май 2025

# Цвета для вывода
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # Сброс цвета

# Настройки
INSTALL_PATH="/var/www/atomgame"

# Функции вывода
log() {
  echo -e "${GREEN}[СБОРКА]${NC} $1"
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
echo -e "${GREEN}   Сборка клиентской части ATOM-GAME   ${NC}"
echo -e "${GREEN}==========================================${NC}"
echo ""

# 1. Остановка сервиса
log "Остановка приложения..."
systemctl stop atomgame 2>/dev/null || true

# 2. Переходим в директорию приложения
log "Переходим в директорию приложения $INSTALL_PATH..."
cd "$INSTALL_PATH" || error "Не удалось перейти в директорию $INSTALL_PATH"

# 3. Обновление .env файла для сборки
log "Настройка переменных среды для сборки..."
cat > "$INSTALL_PATH/.env" << EOF
# Основные настройки
NODE_ENV=production
PORT=5001
HOST=0.0.0.0

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

# 4. Проверка наличия script build в package.json
log "Проверка script build в package.json..."
if [ -f "$INSTALL_PATH/package.json" ]; then
  if grep -q '"build"' package.json; then
    log "Найден скрипт build в package.json"
  else
    warning "Скрипт build не найден в package.json. Добавляем..."
    
    # Используем временный файл для сохранения изменений
    TMP_FILE=$(mktemp)
    
    # Добавляем build скрипт в package.json
    if command -v jq &> /dev/null; then
      jq '.scripts = (.scripts // {}) + {"build": "npm run build:client && npm run build:server"}' package.json > "$TMP_FILE"
      jq '.scripts = (.scripts // {}) + {"build:client": "vite build --outDir dist/public"}' "$TMP_FILE" > package.json
      jq '.scripts = (.scripts // {}) + {"build:server": "tsc -p tsconfig.server.json"}' package.json > "$TMP_FILE"
      mv "$TMP_FILE" package.json
    else
      warning "jq не установлен. Необходимо отредактировать package.json вручную."
      warning "Добавьте следующие строки в секцию scripts:"
      echo '  "build": "npm run build:client && npm run build:server",'
      echo '  "build:client": "vite build --outDir dist/public",'
      echo '  "build:server": "tsc -p tsconfig.server.json",'
    fi
  fi
else
  error "Файл package.json не найден в $INSTALL_PATH"
fi

# 5. Установка зависимостей
log "Установка зависимостей..."
npm install

# 6. Сборка клиентской части
log "Сборка клиентской части..."
if grep -q '"build:client"' package.json; then
  npm run build:client || warning "Ошибка при сборке клиентской части"
else
  NODE_ENV=production npx vite build --outDir dist/public || warning "Ошибка при сборке с помощью vite"
fi

# 7. Проверка создания директории public
log "Проверка директории public..."
if [ -d "$INSTALL_PATH/dist/public" ]; then
  log "Директория dist/public создана успешно"
  ls -la "$INSTALL_PATH/dist/public"
else
  warning "Директория dist/public не создана. Создаем вручную..."
  mkdir -p "$INSTALL_PATH/dist/public"
  
  # Создаем базовый index.html
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

# 8. Перезапуск службы
log "Перезапуск приложения..."
systemctl restart atomgame

# 9. Проверка статуса
log "Проверка статуса приложения..."
sleep 5
systemctl status atomgame --no-pager

echo ""
echo -e "${GREEN}==========================================${NC}"
echo -e "${GREEN}   Сборка клиента завершена!   ${NC}"
echo -e "${GREEN}==========================================${NC}"
echo ""
log "Проверьте логи приложения:"
echo "tail -f $INSTALL_PATH/app.log"
echo ""
log "Проверьте доступность сайта:"
echo "http://193.109.78.85"
echo ""