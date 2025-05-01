#!/bin/bash

# ==========================================
# ФИНАЛЬНЫЙ СКРИПТ ИСПРАВЛЕНИЯ
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
   error "Пожалуйста, используйте: sudo ./fix-final.sh"
   exit 1
fi

# Остановка всех PM2 процессов
log "Остановка всех PM2 процессов..."
pm2 delete all || true
success "Все PM2 процессы остановлены"

# Проверка доступности порта
log "Проверка доступности порта $APP_PORT..."
if netstat -tuln | grep -q ":$APP_PORT "; then
  warn "Порт $APP_PORT уже используется. Процесс будет завершен."
  PID=$(netstat -tuln | grep ":$APP_PORT " | awk '{print $7}' | cut -d'/' -f1)
  if [ -n "$PID" ]; then
    log "Завершение процесса PID: $PID"
    kill -9 $PID || true
  fi
fi
success "Порт $APP_PORT свободен"

# Установка express если его нет
log "Проверка установки Express..."
if ! npm list express | grep -q "express@"; then
  log "Установка Express..."
  npm install express --save
  success "Express установлен"
else
  success "Express уже установлен"
fi

# Копирование файла простого сервера
log "Копирование файла сервера..."
if [ -f "./server.js" ]; then
  cp ./server.js $PROJECT_DIR/
  success "Файл сервера скопирован"
else
  error "Файл server.js не найден"
  exit 1
fi

# Обновление конфигурации PM2
log "Обновление конфигурации PM2..."
cat > $PROJECT_DIR/ecosystem.config.cjs << EOF
module.exports = {
  apps : [{
    name: "atom-game",
    script: "server.js",
    instances: 1,
    autorestart: true,
    watch: false,
    max_memory_restart: "1G",
    env: {
      NODE_ENV: "production",
      PORT: $APP_PORT
    }
  }]
};
EOF
success "Файл конфигурации PM2 обновлен"

# Перестройка приложения
log "Перестройка приложения..."
cd $PROJECT_DIR
npm run build
success "Приложение перестроено"

# Запуск через PM2
log "Запуск приложения через PM2..."
cd $PROJECT_DIR
pm2 start ecosystem.config.cjs
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
echo "        ФИНАЛЬНОЕ ИСПРАВЛЕНИЕ ЗАВЕРШЕНО!"
echo "=================================================================="
echo ""
echo "Проверьте доступность сайта по адресам:"
echo "  http://atomgameblk.ru"
echo "  http://193.109.78.85"
echo ""
echo "Для просмотра логов сервера:"
echo "  pm2 logs atom-game"
echo ""
echo "ВАЖНО: Этот скрипт настроил простой сервер с временными данными,"
echo "который не использует базу данных. Это позволяет сайту работать,"
echo "но изменения не будут сохраняться между перезапусками."
echo "=================================================================="