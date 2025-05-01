#!/bin/bash

# Скрипт для исправления ошибки с path.resolve
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
echo -e "${GREEN}   Исправление ошибки path.resolve   ${NC}"
echo -e "${GREEN}==========================================${NC}"
echo ""

# 1. Остановка сервиса
log "Остановка приложения..."
systemctl stop atomgame 2>/dev/null || true

# 2. Переходим в директорию приложения
log "Переходим в директорию приложения $INSTALL_PATH..."
cd "$INSTALL_PATH" || error "Не удалось перейти в директорию $INSTALL_PATH"

# 3. Создание резервной копии index.js
log "Создание резервной копии index.js..."
cp dist/index.js dist/index.js.backup || error "Не удалось создать резервную копию"

# 4. Поиск строки с ошибкой path.resolve
log "Поиск строки с ошибкой path.resolve (около строки 910)..."
LINE_NUMBER=$(grep -n "path.resolve" dist/index.js | grep -v "__dirname" | head -1 | cut -d: -f1)

if [ -z "$LINE_NUMBER" ]; then
  warning "Не удалось найти строку с path.resolve. Пробуем другой подход..."
  
  # Попробуем найти непосредственно вызов path.resolve
  LINE_NUMBER=$(grep -n -A5 -B5 "TypeError \[ERR_INVALID_ARG_TYPE\]" app.log 2>/dev/null | grep "at file:///var/www/atomgame/dist/index.js:" | head -1 | grep -o ":[0-9]*:" | tr -d :)
  
  if [ -z "$LINE_NUMBER" ]; then
    warning "Не удалось определить строку с ошибкой. Будем искать все вызовы path.resolve..."
    grep -n "resolve(" dist/index.js > /tmp/pathresolve.log
    cat /tmp/pathresolve.log
    
    # Запрашиваем номер строки вручную
    echo ""
    echo -e "${YELLOW}Введите номер строки с ошибкой (используйте информацию выше):${NC}"
    read -p "Номер строки: " LINE_NUMBER
  fi
fi

log "Найдена строка с ошибкой: $LINE_NUMBER"

# 5. Исправление ошибки в строке 910
if [ ! -z "$LINE_NUMBER" ]; then
  log "Просмотр строки $LINE_NUMBER в файле index.js..."
  ERROR_LINE=$(sed -n "${LINE_NUMBER}p" dist/index.js)
  echo "Оригинальная строка: $ERROR_LINE"
  
  # Создаем исправление, проверяя разные паттерны
  if [[ "$ERROR_LINE" == *"path.resolve("* ]]; then
    # Заменяем вызов path.resolve, добавляя проверку на undefined
    sed -i "${LINE_NUMBER}s/path.resolve(/path.resolve(process.cwd(), /g" dist/index.js
    FIXED_LINE=$(sed -n "${LINE_NUMBER}p" dist/index.js)
    log "Исправленная строка: $FIXED_LINE"
  else
    # Если это не простой вызов path.resolve, нужен более сложный подход
    warning "Требуется ручное исправление. Создаем временный скрипт..."
    
    # Создаем файл для ручного редактирования
    cat > /tmp/fix_line.js << EOF
// Оригинальная строка:
$ERROR_LINE

// Исправленная строка:
// Здесь нужно добавить проверку аргументов перед вызовом path.resolve
// Например:
const arg1 = somePath || process.cwd();
const result = path.resolve(arg1, someOtherPath);

// Или альтернативный вариант:
try {
  const result = somePath ? path.resolve(somePath, someOtherPath) : path.resolve(process.cwd(), someOtherPath);
} catch (err) {
  console.error('Ошибка в path.resolve:', err);
  // Используем запасной вариант
  const result = process.cwd();
}
EOF
    
    echo ""
    echo -e "${YELLOW}Создан файл /tmp/fix_line.js с примерами исправлений.${NC}"
    echo -e "${YELLOW}Отредактируйте строку вручную в файле dist/index.js (строка $LINE_NUMBER)${NC}"
    echo ""
    
    # Предлагаем открыть редактор
    read -p "Хотите открыть файл в редакторе? (y/n): " OPEN_EDITOR
    if [[ "$OPEN_EDITOR" == "y" ]]; then
      if command -v nano &> /dev/null; then
        nano +$LINE_NUMBER dist/index.js
      else
        vi +$LINE_NUMBER dist/index.js
      fi
    fi
  fi
else
  error "Не удалось найти строку с ошибкой в файле"
fi

# 6. Создаем заплатку для всех вызовов path.resolve
log "Применяем общую заплатку для всех вызовов path.resolve..."
cat > /tmp/path_patch.js << EOF
// Создаем обертку для path.resolve
const originalPathResolve = path.resolve;
path.resolve = function() {
  // Проверяем аргументы
  const args = Array.from(arguments).filter(arg => arg !== undefined && arg !== null);
  
  // Если нет аргументов, используем текущую директорию
  if (args.length === 0) {
    return originalPathResolve(process.cwd());
  }
  
  // Вызываем оригинальную функцию с проверенными аргументами
  return originalPathResolve.apply(this, args);
};

// Остальной код приложения
EOF

# Получаем номер строки, где импортируется модуль path
PATH_IMPORT_LINE=$(grep -n "import.*path" dist/index.js | head -1 | cut -d: -f1)

if [ ! -z "$PATH_IMPORT_LINE" ]; then
  # Определяем следующую строку после импорта
  NEXT_LINE=$((PATH_IMPORT_LINE + 1))
  
  # Вставляем заплатку после импорта path
  sed -i "${NEXT_LINE}i\\\n// Patch для path.resolve, чтобы избежать TypeError [ERR_INVALID_ARG_TYPE]\nconst originalPathResolve = path.resolve;\npath.resolve = function() {\n  // Проверяем аргументы\n  const args = Array.from(arguments).filter(arg => arg !== undefined && arg !== null);\n  \n  // Если нет аргументов, используем текущую директорию\n  if (args.length === 0) {\n    return originalPathResolve(process.cwd());\n  }\n  \n  // Вызываем оригинальную функцию с проверенными аргументами\n  return originalPathResolve.apply(this, args);\n};" dist/index.js
  
  log "Добавлена заплатка для path.resolve после строки $PATH_IMPORT_LINE"
else
  warning "Не удалось найти импорт path. Заплатка не была применена"
fi

# 7. Перезапуск службы
log "Перезапуск приложения..."
systemctl restart atomgame

# 8. Проверка статуса
log "Проверка статуса приложения..."
sleep 5
systemctl status atomgame --no-pager

echo ""
echo -e "${GREEN}==========================================${NC}"
echo -e "${GREEN}   Исправление завершено!   ${NC}"
echo -e "${GREEN}==========================================${NC}"
echo ""
echo -e "${YELLOW}Если проблема сохраняется, проверьте логи:${NC}"
echo "tail -f $INSTALL_PATH/app.log"
echo ""
echo -e "${YELLOW}Резервная копия сохранена:${NC}"
echo "$INSTALL_PATH/dist/index.js.backup"
echo ""