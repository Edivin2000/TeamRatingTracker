#!/bin/bash

# Скрипт для исправления проблем с ES модулями
# Май 2025

# Цвета для вывода
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # Сброс цвета

# Настройки
INSTALL_PATH="/var/www/atomgame"
NODE_VERSION="18.x"

# Функции вывода
log() {
  echo -e "${GREEN}[УСТАНОВКА]${NC} $1"
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
echo -e "${GREEN}   Исправление проблем с ES модулями   ${NC}"
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

# 2. Проверка версии Node.js
log "Проверка версии Node.js..."
if ! command -v node &> /dev/null || [[ $(node -v) != *"v18."* ]]; then
  warning "Обнаружена неправильная версия Node.js: $(node -v 2>/dev/null || echo 'не установлена')"
  warning "Для ES модулей рекомендуется Node.js 18.x. Устанавливаем..."
  
  apt-get update
  apt-get install -y ca-certificates curl gnupg
  mkdir -p /etc/apt/keyrings
  curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
  
  echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_18.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list
  
  apt-get update
  apt-get install -y nodejs
  
  log "Установлена версия Node.js: $(node -v)"
else
  log "Используется Node.js $(node -v)"
fi

# 3. Переходим в директорию приложения
log "Переходим в директорию приложения $INSTALL_PATH..."
cd "$INSTALL_PATH" || error "Не удалось перейти в директорию $INSTALL_PATH"

# 4. Добавление type: module в package.json
log "Проверка и обновление package.json..."
if [ -f "$INSTALL_PATH/package.json" ]; then
  # Проверяем, есть ли уже type: module
  if ! grep -q '"type":\s*"module"' package.json; then
    warning "Добавляем type: module в package.json..."
    # Использование временного файла для сохранения изменений
    TMP_FILE=$(mktemp)
    jq '. + {"type": "module"}' package.json > "$TMP_FILE" && mv "$TMP_FILE" package.json
  else
    log "type: module уже присутствует в package.json"
  fi
else
  error "Файл package.json не найден в $INSTALL_PATH"
fi

# 5. Проверка и обновление index.js, если он содержит require
log "Проверка использования ESM в основных файлах..."
if [ -f "$INSTALL_PATH/dist/index.js" ]; then
  # Если файл содержит require или module.exports
  if grep -q "require(" "$INSTALL_PATH/dist/index.js" || grep -q "module.exports" "$INSTALL_PATH/dist/index.js"; then
    warning "Файл index.js использует CommonJS синтаксис. Конвертируем в ESM..."
    
    # Создание резервной копии
    cp "$INSTALL_PATH/dist/index.js" "$INSTALL_PATH/dist/index.js.backup"
    
    # Замена require на import
    sed -i 's/const \(.*\) = require(\(.*\));/import \1 from \2;/g' "$INSTALL_PATH/dist/index.js"
    
    # Замена module.exports на export default
    sed -i 's/module.exports = \(.*\);/export default \1;/g' "$INSTALL_PATH/dist/index.js"
    
    log "Конвертация завершена. Резервная копия сохранена в dist/index.js.backup"
  else
    log "Файл index.js уже использует ESM синтаксис"
  fi
else
  error "Файл dist/index.js не найден в $INSTALL_PATH"
fi

# 6. Обновление файла .env с правильными переменными
log "Обновление .env файла..."
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

# 7. Настройка переменных NODE_OPTIONS для поддержки ESM
log "Настройка переменных NODE_OPTIONS для поддержки ESM..."
export NODE_OPTIONS="--experimental-specifier-resolution=node --no-warnings"

# 8. Создание нового systemd сервиса с правильными опциями для ESM
log "Создание systemd службы с поддержкой ESM..."
cat > /etc/systemd/system/atomgame.service << EOF
[Unit]
Description=ATOM-GAME Application
After=network.target postgresql.service

[Service]
User=root
WorkingDirectory=$INSTALL_PATH
Environment=NODE_ENV=production
Environment=PORT=5001
Environment=HOST=0.0.0.0
Environment=PGUSER=atomgame
Environment=PGPASSWORD=AtomGame2025
Environment=PGDATABASE=atomgame
Environment=PGHOST=localhost
Environment=PGPORT=5432
Environment=DATABASE_URL=postgresql://atomgame:AtomGame2025@localhost:5432/atomgame
Environment=SESSION_SECRET=AtomGameSecretKey2025
Environment=NODE_OPTIONS=--experimental-specifier-resolution=node --no-warnings
ExecStart=/usr/bin/node $INSTALL_PATH/dist/index.js
StandardOutput=append:$INSTALL_PATH/app.log
StandardError=append:$INSTALL_PATH/app.log
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Перезагрузка конфигурации systemd
log "Перезагрузка конфигурации systemd..."
systemctl daemon-reload
systemctl enable atomgame
systemctl restart atomgame

# 9. Создание скрипта для прямого запуска с правильными опциями
log "Создание скрипта для прямого запуска с поддержкой ESM..."
cat > "$INSTALL_PATH/start_esm.sh" << EOF
#!/bin/bash
export NODE_ENV=production
export PORT=5001
export HOST=0.0.0.0
export PGUSER=atomgame
export PGPASSWORD=AtomGame2025
export PGDATABASE=atomgame
export PGHOST=localhost
export PGPORT=5432
export DATABASE_URL=postgresql://atomgame:AtomGame2025@localhost:5432/atomgame
export SESSION_SECRET=AtomGameSecretKey2025
export NODE_OPTIONS="--experimental-specifier-resolution=node --no-warnings"

node dist/index.js
EOF

chmod +x "$INSTALL_PATH/start_esm.sh"

# 10. Проверка статуса приложения
log "Проверка статуса приложения..."
sleep 5
systemctl status atomgame --no-pager

echo ""
echo -e "${GREEN}==========================================${NC}"
echo -e "${GREEN}   Исправление завершено!   ${NC}"
echo -e "${GREEN}==========================================${NC}"
echo ""
echo -e "${YELLOW}Если проблема сохраняется, выполните:${NC}"
echo "cd $INSTALL_PATH && ./start_esm.sh"
echo ""
echo -e "${YELLOW}Для просмотра логов:${NC}"
echo "journalctl -u atomgame -f"
echo "или"
echo "tail -f $INSTALL_PATH/app.log"
echo ""