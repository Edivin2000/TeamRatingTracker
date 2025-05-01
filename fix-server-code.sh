#!/bin/bash

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

echo -e "${BOLD}${GREEN}=========================================================${NC}"
echo -e "${BOLD}${GREEN}       ATOM-GAME - Исправление кода сервера              ${NC}"
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

# Создаем бэкап
echo -e "\n${YELLOW}Создаем резервные копии файлов...${NC}"
cp -f server/vite.ts server/vite.ts.bak
cp -f server/index.ts server/index.ts.bak

# Исправляем файл vite.ts
echo -e "\n${YELLOW}Модифицируем server/vite.ts...${NC}"
cat > server/vite.ts << 'EOF'
import { Express, Request, Response, NextFunction, static as expressStatic } from "express";
import { createServer as createViteServer, ViteDevServer } from "vite";
import { Server } from "http";
import path from "path";
import fs from "fs";

export function log(message: string, source = "express") {
  console.log(`[${new Date().toISOString()}] ${message}`);
}

export async function setupVite(app: Express, server: Server) {
  if (process.env.NODE_ENV === "development") {
    await setupDevServer(app, server);
  } else {
    serveStatic(app);
  }
}

async function setupDevServer(app: Express, server: Server) {
  const vite = await createViteServer({
    server: { middlewareMode: true },
    appType: "spa",
  });

  app.use(vite.middlewares);

  app.use("*", async (req: Request, res: Response, next: NextFunction) => {
    try {
      const url = req.originalUrl;

      if (url.startsWith("/api") || url.startsWith("/socket.io")) {
        return next();
      }

      let template = fs.readFileSync(path.resolve("./client/index.html"), "utf-8");
      template = await vite.transformIndexHtml(url, template);

      res.status(200).set({ "Content-Type": "text/html" }).end(template);
    } catch (e: any) {
      const error = e as Error;
      vite.ssrFixStacktrace(error);
      console.error(error.stack);
      res.status(500).end(error.stack);
    }
  });

  return vite;
}

export function serveStatic(app: Express) {
  const buildDir = path.resolve("./public");
  const clientBuildDir = path.resolve("./client/dist");
  const fallbackHtml = `
  <!DOCTYPE html>
  <html lang="en">
  <head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>ATOM-GAME - Система Рейтинга Команд</title>
    <style>
      body { font-family: Arial, sans-serif; background-color: #f5f5f5; margin: 0; padding: 0; display: flex; justify-content: center; align-items: center; height: 100vh; }
      .container { text-align: center; padding: 2rem; max-width: 600px; background-color: white; border-radius: 10px; box-shadow: 0 4px 6px rgba(0,0,0,0.1); }
      h1 { color: #333; margin-bottom: 1rem; }
      p { color: #666; margin-bottom: 2rem; }
      .loading { display: flex; flex-direction: column; align-items: center; }
      .spinner { border: 4px solid #f3f3f3; border-top: 4px solid #3498db; border-radius: 50%; width: 40px; height: 40px; animation: spin 2s linear infinite; margin-bottom: 1rem; }
      @keyframes spin { 0% { transform: rotate(0deg); } 100% { transform: rotate(360deg); } }
    </style>
  </head>
  <body>
    <div class="container">
      <h1>ATOM-GAME</h1>
      <p>Система для отслеживания рейтинга команд</p>
      <div class="loading">
        <div class="spinner"></div>
        <p>Сервер запускается, пожалуйста подождите...</p>
      </div>
    </div>
  </body>
  </html>
  `;

  try {
    // Проверяем наличие директории для статики
    if (!fs.existsSync(buildDir)) {
      console.log(`Creating public directory as fallback...`);
      fs.mkdirSync(buildDir, { recursive: true });
      fs.writeFileSync(path.join(buildDir, "index.html"), fallbackHtml);
    }

    // Проверяем наличие сборки клиента
    if (fs.existsSync(clientBuildDir)) {
      console.log(`Serving client build from ${clientBuildDir}`);
      app.use(expressStatic(clientBuildDir));
    } else {
      console.log(`Serving from fallback public directory: ${buildDir}`);
      app.use(expressStatic(buildDir));
    }

    app.get("*", (req: Request, res: Response) => {
      if (req.originalUrl.startsWith("/api")) {
        return;
      }

      const indexPath = fs.existsSync(path.join(clientBuildDir, "index.html")) 
        ? path.join(clientBuildDir, "index.html") 
        : path.join(buildDir, "index.html");
      
      res.sendFile(indexPath);
    });
  } catch (error) {
    console.error("Error setting up static file serving:", error);
    
    // Создаем запасной вариант на случай ошибки
    app.get("*", (req: Request, res: Response) => {
      if (req.originalUrl.startsWith("/api")) {
        return;
      }
      res.status(200).type("html").send(fallbackHtml);
    });
  }
}
EOF

# Исправляем файл index.ts, чтобы убедиться, что он использует порт 5001
echo -e "\n${YELLOW}Проверяем и исправляем порт в server/index.ts...${NC}"
sed -i 's/process.env.PORT || 8080/process.env.PORT || 5001/g' server/index.ts

# Создаем простую версию start-server.js
echo -e "\n${YELLOW}Создаем простой запускной скрипт...${NC}"
cat > start-server.cjs << 'EOF'
// Простой скрипт запуска сервера через CommonJS
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

// Создаем публичную директорию, если она не существует
const publicDir = path.join(process.cwd(), 'public');
if (!fs.existsSync(publicDir)) {
  console.log('Создание директории public для статических файлов...');
  fs.mkdirSync(publicDir, { recursive: true });
  
  // Создаем простой файл index.html
  const indexHtml = `
  <!DOCTYPE html>
  <html lang="en">
  <head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>ATOM-GAME - Система Рейтинга Команд</title>
    <style>
      body { font-family: Arial, sans-serif; background-color: #f5f5f5; margin: 0; padding: 0; display: flex; justify-content: center; align-items: center; height: 100vh; }
      .container { text-align: center; padding: 2rem; max-width: 600px; background-color: white; border-radius: 10px; box-shadow: 0 4px 6px rgba(0,0,0,0.1); }
      h1 { color: #333; margin-bottom: 1rem; }
      p { color: #666; margin-bottom: 2rem; }
      .loading { display: flex; flex-direction: column; align-items: center; }
      .spinner { border: 4px solid #f3f3f3; border-top: 4px solid #3498db; border-radius: 50%; width: 40px; height: 40px; animation: spin 2s linear infinite; margin-bottom: 1rem; }
      @keyframes spin { 0% { transform: rotate(0deg); } 100% { transform: rotate(360deg); } }
    </style>
  </head>
  <body>
    <div class="container">
      <h1>ATOM-GAME</h1>
      <p>Система для отслеживания рейтинга команд</p>
      <div class="loading">
        <div class="spinner"></div>
        <p>Сервер запускается, пожалуйста подождите...</p>
      </div>
    </div>
  </body>
  </html>
  `;
  
  fs.writeFileSync(path.join(publicDir, 'index.html'), indexHtml);
}

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
echo -e "\n${YELLOW}Проверка логов через 5 секунд...${NC}"
sleep 5
pm2 logs atom-game-server --lines 20

echo -e "\n${BOLD}${GREEN}=========================================================${NC}"
echo -e "${BOLD}${GREEN}       Исправления внесены в код сервера!                ${NC}"
echo -e "${BOLD}${GREEN}=========================================================${NC}"
echo -e "${GREEN}Сайт должен быть доступен по адресу: https://${DOMAIN}${NC}"
echo -e "${YELLOW}Если возникают проблемы, проверьте логи сервера:${NC}"
echo -e "${YELLOW}pm2 logs atom-game-server${NC}"
echo -e "\n${YELLOW}Резервные копии файлов сохранены в:${NC}"
echo -e "${YELLOW}${APP_PATH}/server/vite.ts.bak${NC}"
echo -e "${YELLOW}${APP_PATH}/server/index.ts.bak${NC}"