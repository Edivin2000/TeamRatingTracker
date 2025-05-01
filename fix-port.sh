#!/bin/bash

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

echo -e "${BOLD}${GREEN}====================================================${NC}"
echo -e "${BOLD}${GREEN}       Исправление порта ATOM-GAME                  ${NC}"
echo -e "${BOLD}${GREEN}====================================================${NC}"

# Переходим в директорию приложения
cd /var/www/atomgame

# Останавливаем текущий сервер
echo -e "\n${YELLOW}Останавливаем текущий сервер...${NC}"
pm2 delete atom-game-server 2>/dev/null || true

# Проверяем, что порт 5001 указан в .env файле
if grep -q "PORT=5001" .env; then
  echo -e "\n${GREEN}Порт 5001 уже указан в .env файле${NC}"
else
  echo -e "\n${YELLOW}Обновляем переменные окружения в .env файле...${NC}"
  sed -i 's/PORT=.*/PORT=5001/' .env
  if ! grep -q "PORT=" .env; then
    echo "PORT=5001" >> .env
  fi
fi

# Проверяем файл server/index.ts
echo -e "\n${YELLOW}Проверяем файл server/index.ts...${NC}"
if grep -q "process.env.PORT || 8080" server/index.ts; then
  echo -e "\n${YELLOW}Исправляем порт в server/index.ts...${NC}"
  sed -i 's/process.env.PORT || 8080/process.env.PORT || 5001/' server/index.ts
  echo -e "${GREEN}Порт в server/index.ts исправлен${NC}"
fi

# Обновляем скрипт запуска
echo -e "\n${YELLOW}Обновляем скрипт запуска...${NC}"
cat > start-server.js << 'EOFJS'
import { spawn } from 'child_process';

console.log('Запуск ATOM-GAME сервера...');

const env = {
  ...process.env,
  NODE_ENV: 'production',
  PORT: 5001,
  HOST: '0.0.0.0',
  DOMAIN: 'atomgameblk.ru'
};

// Выводим настройки
console.log('Запуск с настройками:');
console.log(`PORT: ${env.PORT}`);
console.log(`HOST: ${env.HOST}`);
console.log(`NODE_ENV: ${env.NODE_ENV}`);

// Запускаем сервер с нужными параметрами
const server = spawn('node', ['-r', 'tsx', 'server/index.ts'], { 
  env: env,
  stdio: 'inherit',
  cwd: process.cwd()
});

// Обработка выхода процесса
server.on('close', (code) => {
  console.log(`Процесс сервера завершил работу с кодом ${code}`);
});

// Обработка ошибок
server.on('error', (err) => {
  console.error('Ошибка при запуске сервера:', err);
});
EOFJS

# Запуск сервера
echo -e "\n${YELLOW}Запускаем сервер...${NC}"
pm2 start start-server.js --name atom-game-server
pm2 save

# Перезапуск Nginx
echo -e "\n${YELLOW}Перезапускаем Nginx...${NC}"
nginx -t && systemctl restart nginx

echo -e "\n${BOLD}${GREEN}====================================================${NC}"
echo -e "${BOLD}${GREEN}       Порт исправлен, сервер запущен!               ${NC}"
echo -e "${BOLD}${GREEN}====================================================${NC}"
echo -e "${GREEN}Для перезапуска сервера используйте:${NC}"
echo -e "${YELLOW}cd /var/www/atomgame && ./restart-server.sh${NC}"
echo -e "\n${GREEN}Для просмотра логов:${NC}"
echo -e "${YELLOW}pm2 logs atom-game-server${NC}"