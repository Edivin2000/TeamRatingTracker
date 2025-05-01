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
DB_NAME="atomgame"
DB_USER="atomgame"
DB_PASSWORD="Atom&Game#2025!"
ESCAPED_PASSWORD=$(echo $DB_PASSWORD | sed 's/&/%26/g; s/#/%23/g')

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

# Проверка существования папки клиента
if [ ! -d "$PROJECT_DIR/client" ]; then
  error "Папка клиента не найдена: $PROJECT_DIR/client"
  exit 1
fi

# Проверка существования папки сервера
if [ ! -d "$PROJECT_DIR/server" ]; then
  error "Папка сервера не найдена: $PROJECT_DIR/server"
  exit 1
fi

# Искать и исправить WebSocket конфигурацию в клиентском коде
log "Поиск и исправление WebSocket конфигурации в клиентском коде..."

# Создаем резервную копию клиентских JS файлов
mkdir -p "$PROJECT_DIR/backups/$(date +%Y%m%d)"
find "$PROJECT_DIR/client/src" -name "*.ts" -o -name "*.tsx" -o -name "*.js" -o -name "*.jsx" | xargs -I{} cp {} "$PROJECT_DIR/backups/$(date +%Y%m%d)/"
success "Резервные копии созданы в папке $PROJECT_DIR/backups/$(date +%Y%m%d)"

# Исправляем файлы клиента
FILES_TO_CHECK=$(find "$PROJECT_DIR/client/src" -name "*.ts" -o -name "*.tsx" -o -name "*.js" -o -name "*.jsx" -type f -exec grep -l "wss://" {} \;)
if [ -n "$FILES_TO_CHECK" ]; then
  for file in $FILES_TO_CHECK; do
    log "Исправление WebSocket URL в файле: $file"
    sed -i 's|wss://localhost|ws://localhost|g' "$file"
    sed -i 's|const protocol = window.location.protocol === "https:" ? "wss:" : "ws:";|const protocol = "ws:";|g' "$file"
  done
  success "WebSocket URLs исправлены в клиентских файлах"
else
  warn "Не найдены файлы с WebSocket URL для исправления"
fi

# Проверяем наличие WebSocket сервера в routes.ts
if [ -f "$PROJECT_DIR/server/routes.ts" ]; then
  log "Проверка настроек WebSocket сервера в routes.ts..."
  if grep -q "WebSocketServer" "$PROJECT_DIR/server/routes.ts"; then
    log "WebSocketServer найден в routes.ts, проверяем конфигурацию..."
    
    # Если в routes.ts есть настройка пути для WebSocketServer, меняем её
    if grep -q "path: '/ws'" "$PROJECT_DIR/server/routes.ts"; then
      success "WebSocketServer уже настроен с правильным путем '/ws'"
    else
      log "Исправление пути WebSocketServer в routes.ts..."
      cp "$PROJECT_DIR/server/routes.ts" "$PROJECT_DIR/backups/$(date +%Y%m%d)/routes.ts.bak"
      sed -i 's|new WebSocketServer({ server: httpServer|new WebSocketServer({ server: httpServer, path: "/ws"|g' "$PROJECT_DIR/server/routes.ts"
      success "Путь WebSocketServer исправлен"
    fi
  else
    warn "WebSocketServer не найден в routes.ts"
  fi
else
  warn "Файл routes.ts не найден"
fi

# Перестройка приложения
log "Перестройка приложения..."
cd "$PROJECT_DIR"
npm run build
success "Приложение перестроено"

# Обновление конфигурации PM2
log "Обновление конфигурации PM2..."
cat > $PROJECT_DIR/ecosystem.config.cjs << EOF
module.exports = {
  apps: [{
    name: 'atom-game',
    script: 'dist/index.js',
    instances: 'max',
    exec_mode: 'cluster',
    env: {
      NODE_ENV: 'production',
      PORT: '5000',
      PGUSER: '$DB_USER',
      PGPASSWORD: '$DB_PASSWORD',
      PGDATABASE: '$DB_NAME',
      PGHOST: 'localhost',
      PGPORT: '5432',
      DATABASE_URL: 'postgresql://$DB_USER:$ESCAPED_PASSWORD@localhost:5432/$DB_NAME',
      SESSION_SECRET: '$(openssl rand -hex 32)',
      NODE_TLS_REJECT_UNAUTHORIZED: '0'
    },
    max_memory_restart: '500M'
  }]
};
EOF
success "Файл конфигурации PM2 обновлен"

# Перезапуск приложения с PM2
log "Перезапуск приложения с PM2..."
pm2 delete atom-game || true
pm2 start ecosystem.config.cjs
pm2 save
success "Приложение перезапущено"

echo "=================================================================="
echo "        ИСПРАВЛЕНИЕ WEBSOCKET СОЕДИНЕНИЯ ЗАВЕРШЕНО!"
echo "=================================================================="
echo ""
echo "Проверьте логи приложения для подтверждения исправления ошибки:"
echo "pm2 logs atom-game"
echo ""
echo "Теперь перезагрузите страницу в браузере и проверьте, работает ли сайт:"
echo "http://atomgameblk.ru"
echo "=================================================================="