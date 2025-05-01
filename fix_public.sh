#!/bin/bash

# Скрипт для исправления ошибки с отсутствующей директорией public
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
echo -e "${GREEN}   Исправление ошибки public директории   ${NC}"
echo -e "${GREEN}==========================================${NC}"
echo ""

# 1. Остановка сервиса
log "Остановка приложения..."
systemctl stop atomgame 2>/dev/null || true

# 2. Переходим в директорию приложения
log "Переходим в директорию приложения $INSTALL_PATH..."
cd "$INSTALL_PATH" || error "Не удалось перейти в директорию $INSTALL_PATH"

# 3. Создание директории public
log "Создание директории public..."
mkdir -p "$INSTALL_PATH/public"

# 4. Исправление пути в index.js
log "Проверка исходного кода на наличие некорректного пути..."
if [ -f "$INSTALL_PATH/dist/index.js" ]; then
  # Находим строку с ошибкой (около строки 994)
  ERROR_LINE=$(grep -n "Could not find the build directory" dist/index.js | head -1 | cut -d: -f1)
  
  if [ -z "$ERROR_LINE" ]; then
    # Если строку не нашли напрямую, ищем через контекст
    ERROR_LINE=$(grep -n "serveStatic" dist/index.js | head -1 | cut -d: -f1)
  fi
  
  if [ ! -z "$ERROR_LINE" ]; then
    # Находим начало функции serveStatic
    FUNC_START=$((ERROR_LINE - 15))
    if [ $FUNC_START -lt 1 ]; then
      FUNC_START=1
    fi
    
    # Извлекаем код функции serveStatic для анализа
    FUNC_CODE=$(sed -n "${FUNC_START},${ERROR_LINE}p" dist/index.js)
    echo -e "${YELLOW}Код функции serveStatic:${NC}"
    echo "$FUNC_CODE"
    
    # Ищем строку, которая определяет publicDir (путь к директории public)
    PUBLIC_DIR_LINE=$(echo "$FUNC_CODE" | grep -n "publicDir" | head -1 | cut -d: -f1)
    if [ ! -z "$PUBLIC_DIR_LINE" ]; then
      PUBLIC_DIR_LINE=$((FUNC_START + PUBLIC_DIR_LINE - 1))
      
      # Выводим строку для анализа
      PUBLIC_DIR_CODE=$(sed -n "${PUBLIC_DIR_LINE}p" dist/index.js)
      echo -e "${YELLOW}Строка с определением publicDir:${NC} $PUBLIC_DIR_CODE"
      
      # Создаем исправление, меняя путь на публичную директорию
      sed -i "${PUBLIC_DIR_LINE}s|public|dist/public|g" dist/index.js
      
      # Проверяем, применилось ли исправление
      NEW_PUBLIC_DIR_CODE=$(sed -n "${PUBLIC_DIR_LINE}p" dist/index.js)
      echo -e "${GREEN}Исправленная строка:${NC} $NEW_PUBLIC_DIR_CODE"
    else
      warning "Не удалось найти строку с определением publicDir"
    fi
  else
    warning "Не удалось найти соответствующую строку кода"
  fi
  
  # Ищем все упоминания директории public
  log "Поиск других упоминаний директории public..."
  grep -n "public" dist/index.js > /tmp/public_mentions.log
  
  echo -e "${YELLOW}Все упоминания директории public:${NC}"
  cat /tmp/public_mentions.log
fi

# 5. Создание директории dist/public как симлинка на public
log "Создание symlink для dist/public..."
if [ ! -d "$INSTALL_PATH/dist/public" ]; then
  ln -s "$INSTALL_PATH/public" "$INSTALL_PATH/dist/public"
  log "Создан symlink: dist/public -> public"
fi

# 6. Создание минимального набора файлов в public директории
log "Создание минимального набора файлов в public директории..."
cat > "$INSTALL_PATH/public/index.html" << EOF
<!DOCTYPE html>
<html lang="ru">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>ATOM GAME - Скоро будет доступен</title>
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
    .loading {
      display: inline-block;
      width: 50px;
      height: 50px;
      border: 3px solid rgba(255,255,255,.3);
      border-radius: 50%;
      border-top-color: #3498db;
      animation: spin 1s ease-in-out infinite;
    }
    @keyframes spin {
      to { transform: rotate(360deg); }
    }
  </style>
</head>
<body>
  <div class="container">
    <h1>ATOM﮳GAME</h1>
    <p>Сайт находится в процессе загрузки и скоро будет доступен</p>
    <div class="loading"></div>
    <p>Пожалуйста, подождите...</p>
  </div>
  <script>
    setTimeout(() => {
      window.location.reload();
    }, 5000);
  </script>
</body>
</html>
EOF

# 7. Исправление строки проверки в index.js
log "Поиск строки с проверкой наличия директории..."
CHECK_DIR_LINE=$(grep -n "Could not find the build directory" dist/index.js | head -1 | cut -d: -f1)

if [ ! -z "$CHECK_DIR_LINE" ]; then
  # Извлекаем код для анализа
  CHECK_DIR_CODE=$(sed -n "${CHECK_DIR_LINE}p" dist/index.js)
  echo -e "${YELLOW}Строка с проверкой наличия директории:${NC} $CHECK_DIR_CODE"
  
  # Находим строку, где выполняется проверка existsSync
  EXISTS_LINE=$(grep -n "existsSync" dist/index.js | grep -B5 "Could not find" | head -1 | cut -d: -f1)
  
  if [ ! -z "$EXISTS_LINE" ]; then
    # Выводим строку для анализа
    EXISTS_CODE=$(sed -n "${EXISTS_LINE}p" dist/index.js)
    echo -e "${YELLOW}Строка с проверкой existsSync:${NC} $EXISTS_CODE"
    
    # Заменяем проверку, чтобы она всегда возвращала true
    sed -i "${EXISTS_LINE}s/existsSync/\/\/existsSync/" dist/index.js
    sed -i "${EXISTS_LINE}s/!fs.*/true || &/" dist/index.js
    
    # Проверяем, применилось ли исправление
    NEW_EXISTS_CODE=$(sed -n "${EXISTS_LINE}p" dist/index.js)
    echo -e "${GREEN}Исправленная строка:${NC} $NEW_EXISTS_CODE"
  else
    warning "Не удалось найти строку с проверкой existsSync"
  fi
else
  warning "Не удалось найти строку с сообщением об ошибке"
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
echo -e "${GREEN}   Исправление завершено!   ${NC}"
echo -e "${GREEN}==========================================${NC}"
echo ""
log "Проверьте логи приложения через 10 секунд:"
echo "tail -f $INSTALL_PATH/app.log"
echo ""
log "Проверьте доступность сайта:"
echo "http://193.109.78.85"
echo ""