#!/bin/bash

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

echo -e "${BOLD}${GREEN}====================================================${NC}"
echo -e "${BOLD}${GREEN}       Исправление и запуск ATOM-GAME                ${NC}"
echo -e "${BOLD}${GREEN}====================================================${NC}"

# Переход в директорию приложения
cd /var/www/atomgame

# Создание JavaScript файла для запуска через PM2
echo -e "\n${BLUE}[1/4] Создание файла для запуска сервера...${NC}"
cat > start-server.js << 'EOFJS'
const { spawn } = require('child_process');

console.log('Запуск ATOM-GAME сервера...');

const env = {
  ...process.env,
  NODE_ENV: 'production',
  PORT: 5001,
  HOST: '0.0.0.0',
  DOMAIN: 'atomgameblk.ru'
};

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

# Создание скрипта перезапуска
echo -e "\n${BLUE}[2/4] Создание скрипта перезапуска...${NC}"
cat > restart-server.sh << 'EOFSH'
#!/bin/bash

# Цвета для вывода
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Перезапуск ATOM-GAME сервера...${NC}"

# Переходим в директорию проекта
cd /var/www/atomgame

# Останавливаем PM2 процесс
echo -e "${YELLOW}Останавливаем текущий сервер...${NC}"
pm2 delete atom-game-server 2>/dev/null || true

# Запускаем сервер
echo -e "${YELLOW}Запускаем сервер...${NC}"
pm2 start start-server.js --name atom-game-server

# Сохраняем конфигурацию PM2
pm2 save

echo -e "${GREEN}Сервер успешно перезапущен${NC}"
echo -e "${YELLOW}Проверьте статус: pm2 status${NC}"
echo -e "${YELLOW}Логи: pm2 logs atom-game-server${NC}"
EOFSH

# Делаем скрипты исполняемыми
echo -e "\n${BLUE}[3/4] Установка прав на исполнение...${NC}"
chmod +x start-server.js
chmod +x restart-server.sh

# Запуск сервера
echo -e "\n${BLUE}[4/4] Запуск сервера...${NC}"
pm2 delete atom-game-server 2>/dev/null || true
pm2 start start-server.js --name atom-game-server
pm2 save

echo -e "\n${BOLD}${GREEN}====================================================${NC}"
echo -e "${BOLD}${GREEN}       ATOM-GAME сервер успешно запущен!             ${NC}"
echo -e "${BOLD}${GREEN}====================================================${NC}"
echo -e "${GREEN}Для перезапуска сервера используйте:${NC}"
echo -e "${YELLOW}./restart-server.sh${NC}"
echo -e "\n${GREEN}Для просмотра логов:${NC}"
echo -e "${YELLOW}pm2 logs atom-game-server${NC}"