#!/bin/bash

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

echo -e "${BOLD}${GREEN}=========================================================${NC}"
echo -e "${BOLD}${GREEN}       ATOM-GAME - Сборка клиента и запуск              ${NC}"
echo -e "${BOLD}${GREEN}=========================================================${NC}"

# Конфигурационные параметры
APP_PATH="/var/www/atomgame"
PORT="5001"
DOMAIN="atomgameblk.ru"

# Проверка root прав
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}Скрипт должен быть запущен с правами root${NC}"
  echo -e "${YELLOW}Выполните: sudo bash $0${NC}"
  exit 1
fi

# Переходим в директорию приложения
cd ${APP_PATH}

# Останавливаем текущий сервер
echo -e "\n${YELLOW}Останавливаем текущий сервер...${NC}"
pm2 delete atom-game-server 2>/dev/null || true

# Проверяем package.json на наличие скрипта сборки
echo -e "\n${YELLOW}Проверяем наличие скрипта сборки в package.json...${NC}"
if grep -q '"build"' package.json; then
  echo -e "${GREEN}Скрипт сборки найден, запускаем...${NC}"
  
  # Устанавливаем все зависимости, если это не было сделано
  if [ ! -d "node_modules" ] || [ "$(ls -A node_modules 2>/dev/null)" == "" ]; then
    echo -e "${YELLOW}Установка зависимостей npm...${NC}"
    npm install
  fi
  
  # Запускаем сборку клиента
  echo -e "${YELLOW}Запуск сборки клиента...${NC}"
  npm run build
else
  echo -e "${RED}Скрипт сборки не найден в package.json${NC}"
  echo -e "${YELLOW}Создаем каталог для статических файлов вручную...${NC}"
  mkdir -p ${APP_PATH}/public
fi

# Обновляем скрипт запуска, чтобы включить сборку клиента перед запуском
echo -e "\n${YELLOW}Обновляем скрипт запуска...${NC}"
cat > ${APP_PATH}/start-server.cjs << 'EOF'
// Скрипт для запуска сервера через CommonJS
const { exec, spawn } = require('child_process');
const fs = require('fs');
const path = require('path');

// Установка переменных окружения
process.env.PORT = 5001;
process.env.HOST = '0.0.0.0';
process.env.NODE_ENV = 'production';
process.env.DOMAIN = 'atomgameblk.ru';

console.log('Запуск ATOM-GAME сервера с настройками:');
console.log(`PORT: ${process.env.PORT}`);
console.log(`HOST: ${process.env.HOST}`);
console.log(`NODE_ENV: ${process.env.NODE_ENV}`);

// Проверяем наличие директории public для статических файлов
const publicDir = path.join(process.cwd(), 'public');
if (!fs.existsSync(publicDir)) {
  console.log('Создание директории public для статических файлов...');
  fs.mkdirSync(publicDir, { recursive: true });
}

// Создаем файл-заглушку для проверки работоспособности
const indexFile = path.join(publicDir, 'index.html');
if (!fs.existsSync(indexFile)) {
  console.log('Создание файла-заглушки index.html...');
  fs.writeFileSync(indexFile, `
    <!DOCTYPE html>
    <html>
    <head>
      <title>ATOM-GAME</title>
      <style>
        body { font-family: Arial, sans-serif; text-align: center; padding: 50px; }
        h1 { color: #333; }
        .loading { margin: 20px 0; }
        .spinner { border: 4px solid #f3f3f3; border-top: 4px solid #3498db; border-radius: 50%; width: 30px; height: 30px; animation: spin 2s linear infinite; margin: 20px auto; }
        @keyframes spin { 0% { transform: rotate(0deg); } 100% { transform: rotate(360deg); } }
      </style>
    </head>
    <body>
      <h1>ATOM-GAME загружается...</h1>
      <div class="loading">
        <div class="spinner"></div>
        <p>Пожалуйста, подождите, сервер запускается</p>
      </div>
    </body>
    </html>
  `);
}

// Функция для изменения порта в server/index.ts если он жестко прописан
const patchServerFile = () => {
  const serverFile = path.join(process.cwd(), 'server', 'index.ts');
  if (fs.existsSync(serverFile)) {
    let content = fs.readFileSync(serverFile, 'utf8');
    
    // Заменяем жестко прописанный порт 8080 на 5001
    if (content.includes('process.env.PORT || 8080')) {
      console.log('Исправляем порт в server/index.ts с 8080 на 5001');
      content = content.replace('process.env.PORT || 8080', 'process.env.PORT || 5001');
      fs.writeFileSync(serverFile, content);
    }
    
    // Проверяем пути к статическим файлам
    const viteFile = path.join(process.cwd(), 'server', 'vite.ts');
    if (fs.existsSync(viteFile)) {
      let viteContent = fs.readFileSync(viteFile, 'utf8');
      
      // Исправляем путь к директории статических файлов
      if (viteContent.includes('server/public')) {
        console.log('Исправляем путь к статическим файлам в server/vite.ts');
        viteContent = viteContent.replace(/server\/public/g, 'public');
        fs.writeFileSync(viteFile, viteContent);
      }
    }
  }
};

// Патчим файлы сервера
patchServerFile();

// Запускаем сервер как дочерний процесс
const server = spawn('node', ['-r', 'tsx', 'server/index.ts'], {
  env: process.env,
  stdio: 'inherit',
  cwd: process.cwd()
});

// Обработка завершения
server.on('close', (code) => {
  console.log(`Сервер завершил работу с кодом ${code}`);
});

server.on('error', (err) => {
  console.error('Ошибка при запуске сервера:', err);
});
EOF

# Запускаем сервер
echo -e "\n${YELLOW}Запускаем сервер...${NC}"
pm2 start start-server.cjs --name atom-game-server
pm2 save

# Проверка статуса
echo -e "\n${BOLD}${BLUE}Проверка статуса запущенных сервисов:${NC}"
pm2 status
echo -e "\n${YELLOW}Первые 15 строк логов:${NC}"
sleep 3
pm2 logs atom-game-server --lines 15

echo -e "\n${BOLD}${GREEN}=========================================================${NC}"
echo -e "${BOLD}${GREEN}       Сборка завершена, сервер запущен!                ${NC}"
echo -e "${BOLD}${GREEN}=========================================================${NC}"
echo -e "${GREEN}Сайт должен быть доступен по адресу: https://${DOMAIN}${NC}"
echo -e "${YELLOW}Если возникают проблемы, проверьте логи сервера:${NC}"
echo -e "${YELLOW}pm2 logs atom-game-server${NC}"