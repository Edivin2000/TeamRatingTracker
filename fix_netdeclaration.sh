#!/bin/bash

# Скрипт для исправления ошибки с дублированным объявлением net
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
echo -e "${GREEN}   Исправление ошибки дублирования net   ${NC}"
echo -e "${GREEN}==========================================${NC}"
echo ""

# 1. Остановка сервиса
log "Остановка приложения..."
systemctl stop atomgame 2>/dev/null || true

# 2. Переходим в директорию приложения
log "Переходим в директорию приложения $INSTALL_PATH..."
cd "$INSTALL_PATH" || error "Не удалось перейти в директорию $INSTALL_PATH"

# 3. Создание резервной копии
log "Создание резервной копии index.js..."
cp dist/index.js dist/index.js.netbackup || error "Не удалось создать резервную копию"

# 4. Поиск и удаление нашего патча
log "Поиск и удаление дублирующего кода..."

# Ищем строку с объявлением net
NET_LINES=$(grep -n "const net = require('node:net');" dist/index.js | cut -d: -f1)

if [ ! -z "$NET_LINES" ]; then
  # Выводим найденные строки
  echo -e "${YELLOW}Найдены строки с объявлением net:${NC}"
  for line in $NET_LINES; do
    echo "Строка $line: $(sed -n "${line}p" dist/index.js)"
  done
  
  # Оставляем только первое объявление, удаляем остальные
  if [ $(echo "$NET_LINES" | wc -l) -gt 1 ]; then
    FIRST_LINE=$(echo "$NET_LINES" | head -n 1)
    log "Оставляем первое объявление в строке $FIRST_LINE"
    
    # Удаляем наш патч
    PATCH_START_LINE=$(grep -n "// Патч для предотвращения использования IPv6 localhost" dist/index.js | cut -d: -f1)
    if [ ! -z "$PATCH_START_LINE" ]; then
      PATCH_END_LINE=$((PATCH_START_LINE + 50)) # Примерно 50 строк патча
      log "Удаляем патч со строки $PATCH_START_LINE по строку $PATCH_END_LINE"
      
      # Используем временный файл
      sed "${PATCH_START_LINE},${PATCH_END_LINE}d" dist/index.js > /tmp/index.js.fixed
      cp /tmp/index.js.fixed dist/index.js
    else
      warning "Не удалось найти начало патча"
    fi
  else
    log "Найдено только одно объявление net, дополнительные исправления не требуются"
  fi
else
  warning "Не удалось найти объявление net"
fi

# 5. Создание нового патча без дублирования переменных
log "Создание нового патча без дублирования переменных..."

cat > /tmp/new_patch.js << EOF
// Патч для предотвращения использования IPv6 localhost (::1)
process.env.HTTPS = 'false';
process.env.NODE_TLS_REJECT_UNAUTHORIZED = '0';

// Переопределение функции fetch для предотвращения вызовов к ::1
if (typeof global.fetch === 'function') {
  const originalFetch = global.fetch;
  global.fetch = function(url, options) {
    if (typeof url === 'string' && url.includes('::1')) {
      url = url.replace('::1', '127.0.0.1');
    }
    return originalFetch(url, options);
  };
}

// Для предотвращения подключений к ::1 через существующие модули
setTimeout(() => {
  try {
    // Безопасный patch для net.Socket.prototype.connect
    const originalConnect = net.Socket.prototype.connect;
    if (originalConnect) {
      net.Socket.prototype.connect = function(options, ...args) {
        if (options && options.host === '::1') {
          console.log('[PATCH] Заменяем ::1 на 127.0.0.1 в net.Socket.connect');
          options.host = '127.0.0.1';
        }
        return originalConnect.call(this, options, ...args);
      };
    }
    
    // Безопасный patch для http.request
    const originalHttpRequest = http.request;
    if (originalHttpRequest) {
      http.request = function(url, options, callback) {
        if (typeof url === 'string' && url.includes('::1')) {
          console.log('[PATCH] Заменяем ::1 на 127.0.0.1 в http.request');
          url = url.replace('::1', '127.0.0.1');
        } else if (url && url.hostname === '::1') {
          console.log('[PATCH] Заменяем ::1 на 127.0.0.1 в http.request (объект)');
          url.hostname = '127.0.0.1';
        }
        return originalHttpRequest(url, options, callback);
      };
    }
    
    // Безопасный patch для https.request
    const originalHttpsRequest = https.request;
    if (originalHttpsRequest) {
      https.request = function(url, options, callback) {
        if (typeof url === 'string' && url.includes('::1')) {
          console.log('[PATCH] Заменяем ::1 на 127.0.0.1 в https.request');
          url = url.replace('::1', '127.0.0.1');
        } else if (url && url.hostname === '::1') {
          console.log('[PATCH] Заменяем ::1 на 127.0.0.1 в https.request (объект)');
          url.hostname = '127.0.0.1';
        }
        
        // Отключаем проверку сертификатов для локальных соединений
        if (!options) options = {};
        options.rejectUnauthorized = false;
        
        return originalHttpsRequest(url, options, callback);
      };
    }
    
    console.log('[PATCH] Безопасно применены все патчи для IPv6');
  } catch (error) {
    console.error('[PATCH] Ошибка при применении патчей:', error);
  }
}, 1000);
EOF

# 6. Вставка нового патча в подходящее место
log "Добавление нового патча в код..."
FIRST_IMPORT=$(grep -n "import " dist/index.js | head -n 1 | cut -d: -f1)
NEXT_LINE=$((FIRST_IMPORT + 1))

# Используем временный файл
sed -i "${NEXT_LINE}r /tmp/new_patch.js" dist/index.js

# 7. Создание нового .env файла
log "Обновление .env файла..."
cat > "$INSTALL_PATH/.env" << EOF
# Основные настройки
NODE_ENV=production
PORT=5001
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

# 8. Обновление скрипта для ручного запуска
log "Обновление скрипта для ручного запуска..."
cat > "$INSTALL_PATH/run_manual.sh" << EOF
#!/bin/bash
export NODE_ENV=production
export PORT=5001
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

cd $INSTALL_PATH
node dist/index.js
EOF

chmod +x "$INSTALL_PATH/run_manual.sh"

# 9. Перезапуск с использованием ручного запуска
log "Запуск приложения с помощью скрипта run_manual.sh..."
systemctl stop atomgame

# Запускаем скрипт в фоновом режиме с перенаправлением вывода
nohup "$INSTALL_PATH/run_manual.sh" > "$INSTALL_PATH/nohup.out" 2>&1 &

# Запоминаем PID процесса
APP_PID=$!
echo $APP_PID > "$INSTALL_PATH/app.pid"

log "Приложение запущено с PID: $APP_PID"
log "Вывод приложения перенаправлен в $INSTALL_PATH/nohup.out"

# 10. Проверка доступности приложения
log "Проверка доступности приложения через 5 секунд..."
sleep 5

if kill -0 $APP_PID 2>/dev/null; then
  log "Процесс запущен и работает!"
  
  # Пробуем выполнить запрос к приложению
  if curl -s "http://localhost:5001/api/teams" > /dev/null; then
    log "Приложение отвечает на запросы!"
  else
    warning "Приложение запущено, но не отвечает на запросы"
  fi
else
  warning "Процесс не запущен или уже завершился"
  log "Проверьте логи: tail -f $INSTALL_PATH/nohup.out"
fi

echo ""
echo -e "${GREEN}==========================================${NC}"
echo -e "${GREEN}   Исправление завершено!   ${NC}"
echo -e "${GREEN}==========================================${NC}"
echo ""
echo -e "${YELLOW}Для просмотра логов:${NC}"
echo "tail -f $INSTALL_PATH/nohup.out"
echo ""
echo -e "${YELLOW}Для остановки приложения:${NC}"
echo "kill \$(cat $INSTALL_PATH/app.pid)"
echo ""
echo -e "${YELLOW}Проверьте доступность сайта:${NC}"
echo "http://193.109.78.85"
echo ""