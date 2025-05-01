#!/bin/bash

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

echo -e "${BOLD}${GREEN}=========================================================${NC}"
echo -e "${BOLD}${GREEN}       Сборка клиентской части ATOM-GAME                 ${NC}"
echo -e "${BOLD}${GREEN}=========================================================${NC}"

# Конфигурационные параметры
APP_PATH="/var/www/atomgame"

# Проверка root прав
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}Скрипт должен быть запущен с правами root${NC}"
  echo -e "${YELLOW}Выполните: sudo bash $0${NC}"
  exit 1
fi

# Переходим в директорию приложения
cd ${APP_PATH}

# Проверяем наличие директории client
if [ ! -d "client" ]; then
  echo -e "${RED}Директория client не найдена!${NC}"
  exit 1
fi

# Проверяем наличие package.json в директории client
if [ ! -f "client/package.json" ]; then
  echo -e "${RED}Файл client/package.json не найден!${NC}"
  exit 1
fi

# Проверяем тип проекта и метод сборки
echo -e "\n${YELLOW}Проверка типа проекта...${NC}"
if grep -q "\"build\"" client/package.json; then
  echo -e "${GREEN}Найден скрипт build в package.json, используем его...${NC}"
  BUILD_COMMAND="npm run build"
  BUILD_DIR="client/dist"
elif grep -q "\"dev\"" client/package.json; then
  echo -e "${YELLOW}Скрипт build не найден, но найден скрипт dev. Используем npm run dev...${NC}"
  BUILD_COMMAND="npm run dev -- --build"
  BUILD_DIR="client/dist"
else
  echo -e "${YELLOW}Стандартные скрипты сборки не найдены, используем vite build...${NC}"
  BUILD_COMMAND="cd client && npx vite build"
  BUILD_DIR="client/dist"
fi

# Устанавливаем зависимости для клиента
echo -e "\n${YELLOW}Установка зависимостей для клиента...${NC}"
cd ${APP_PATH}/client
npm install

# Собираем клиентскую часть
echo -e "\n${YELLOW}Сборка клиентской части...${NC}"
echo -e "${YELLOW}Выполняем: ${BUILD_COMMAND}${NC}"
eval ${BUILD_COMMAND}

# Проверяем, была ли успешной сборка
if [ ! -d "${BUILD_DIR}" ]; then
  echo -e "${RED}Директория сборки ${BUILD_DIR} не создана. Сборка не удалась!${NC}"
  exit 1
fi

# Копируем статические файлы в директорию public
echo -e "\n${YELLOW}Копирование статических файлов в директорию public...${NC}"
mkdir -p ${APP_PATH}/public
cp -r ${APP_PATH}/${BUILD_DIR}/* ${APP_PATH}/public/

# Перезапускаем сервер
echo -e "\n${YELLOW}Перезапуск сервера...${NC}"
cd ${APP_PATH}
pm2 restart atom-game-server

echo -e "\n${BOLD}${GREEN}=========================================================${NC}"
echo -e "${BOLD}${GREEN}       Сборка клиентской части завершена!                ${NC}"
echo -e "${BOLD}${GREEN}=========================================================${NC}"
echo -e "${GREEN}Статические файлы размещены в директории ${APP_PATH}/public${NC}"
echo -e "${GREEN}Сервер перезапущен, обновите страницу сайта${NC}"
echo -e "${GREEN}Для мониторинга логов используйте: pm2 logs atom-game-server${NC}"