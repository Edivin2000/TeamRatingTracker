#!/bin/bash

# Скрипт для быстрого исправления и запуска сервера
# Автор: ATOM-GAME Team
# Версия: 1.0.0

# Цвета для вывода
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Фикс-скрипт запущен! Исправляем все проблемы и запускаем сайт...${NC}"

# Переходим в директорию проекта
cd /var/www/atomgameblk

# Останавливаем все процессы PM2
echo -e "${YELLOW}Останавливаем все процессы PM2...${NC}"
pm2 delete all || true

# Пересобираем проект
echo -e "${YELLOW}Пересобираем проект...${NC}"
npm run build

# Проверяем, что директория dist/public существует и содержит index.html
if [ ! -f "dist/public/index.html" ]; then
  echo -e "${RED}ОШИБКА: dist/public/index.html не найден! Сборка не удалась.${NC}"
  exit 1
fi

# Запускаем базовый сервер с помощью PM2
echo -e "${YELLOW}Запускаем базовый сервер через PM2...${NC}"
pm2 start basic-server.mjs --name "atom-game-basic"
pm2 save

# Проверяем, что PM2 запустил процесс
if pm2 list | grep -q "atom-game-basic" && pm2 list | grep -q "online"; then
  echo -e "${GREEN}Сервер успешно запущен через PM2!${NC}"
  echo -e "${GREEN}Сайт теперь доступен по адресу: http://193.109.78.85${NC}"
  echo ""
  echo -e "Полезные команды:"
  echo -e "  - ${YELLOW}pm2 status${NC} - посмотреть статус сервера"
  echo -e "  - ${YELLOW}pm2 logs atom-game-basic${NC} - посмотреть логи сервера"
  echo -e "  - ${YELLOW}pm2 restart atom-game-basic${NC} - перезапустить сервер"
else
  echo -e "${RED}Что-то пошло не так при запуске PM2. Запускаем в обычном режиме...${NC}"
  node basic-server.mjs
fi