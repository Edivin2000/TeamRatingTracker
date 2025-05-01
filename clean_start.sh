#!/bin/bash

# Скрипт для полной очистки и запуска приложения
# Май 2025

# Цвета для вывода
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # Сброс цвета

# Настройки
INSTALL_PATH="/var/www/atomgame"
SERVER_PORT="5001"

# Функции вывода
log() {
  echo -e "${GREEN}[ЧИСТЫЙ ЗАПУСК]${NC} $1"
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
echo -e "${GREEN}   Полная очистка и запуск приложения   ${NC}"
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

# Убиваем все процессы node, связанные с приложением
pkill -f "/var/www/atomgame/dist/index.js" 2>/dev/null || true

# 2. Переходим в директорию приложения
log "Переходим в директорию приложения $INSTALL_PATH..."
cd "$INSTALL_PATH" || error "Не удалось перейти в директорию $INSTALL_PATH"

# 3. Создание простого index.js без патчей
log "Создание простого index.js..."
cat > "$INSTALL_PATH/simple.js" << EOF
// Простой сервер Express
import express from 'express';
import http from 'node:http';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

// Настройка переменных среды
const PORT = process.env.PORT || 5001;
const HOST = process.env.HOST || '0.0.0.0';

// Создание приложения Express
const app = express();
app.use(express.json());

// Настройка путей
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const publicDir = path.join(__dirname, 'public');

// Проверка наличия публичной директории
if (!fs.existsSync(publicDir)) {
  fs.mkdirSync(publicDir, { recursive: true });
  // Создаем базовую страницу
  fs.writeFileSync(path.join(publicDir, 'index.html'), \`
<!DOCTYPE html>
<html lang="ru">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>ATOM GAME</title>
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
    .btn {
      display: inline-block;
      background-color: #3498db;
      color: white;
      padding: 0.8rem 1.5rem;
      border-radius: 4px;
      text-decoration: none;
      font-weight: bold;
      transition: background-color 0.3s;
    }
    .btn:hover {
      background-color: #2980b9;
    }
  </style>
</head>
<body>
  <div class="container">
    <h1>ATOM﮳GAME</h1>
    <p>Сервер работает. Ведется настройка приложения.</p>
    <p>Скоро здесь появится полноценное приложение.</p>
  </div>
</body>
</html>
  \`);
}

// Обслуживание статических файлов
app.use(express.static(publicDir));

// API маршруты
app.get('/api/teams', (req, res) => {
  const teams = [
    { id: 1, name: "Phoenix Force", logoUrl: "https://placehold.co/100x100/orange/white?text=PF", score: 89, excluded: false },
    { id: 2, name: "Thunderbolts", logoUrl: "https://placehold.co/100x100/blue/white?text=TB", score: 72, excluded: false },
    { id: 3, name: "Storm Riders", logoUrl: "https://placehold.co/100x100/purple/white?text=SR", score: 68, excluded: false },
    { id: 4, name: "Arctic Wolves", logoUrl: "https://placehold.co/100x100/teal/white?text=AW", score: 95, excluded: false },
    { id: 5, name: "Shadow Tigers", logoUrl: "https://placehold.co/100x100/gray/white?text=ST", score: 42, excluded: false },
    { id: 6, name: "Dragon Warriors", logoUrl: "https://placehold.co/100x100/red/white?text=DW", score: 38, excluded: false }
  ];
  res.json(teams);
});

app.get('/api/timers', (req, res) => {
  const timers = [
    { id: 3, name: "Регистрации на сезон 2025", endDate: "2025-08-31T23:59:59.999Z", active: true }
  ];
  res.json(timers);
});

app.get('/api/partners', (req, res) => {
  const partners = [
    { id: 1, name: "Росэнергоатом", logoUrl: "https://placehold.co/200x100/blue/white?text=Росэнергоатом", website: "https://www.rosenergoatom.ru/", order: 1 },
    { id: 2, name: "Фонд АТР АЭС", logoUrl: "https://placehold.co/200x100/green/white?text=Фонд+АТР+АЭС", website: "https://atompsy.ru/", order: 2 },
    { id: 3, name: "ATOM﮳GAME", logoUrl: "https://placehold.co/200x100/orange/white?text=ATOM﮳GAME", website: "https://atomgame.ru/", order: 3 }
  ];
  res.json(partners);
});

app.get('/api/ads', (req, res) => {
  const ads = [
    {
      id: 1,
      title: "ATOM﮳GAME",
      description: "Примите участие в технологическом конкурсе и выиграйте ценные призы",
      buttonText: "Подробнее",
      buttonLink: "https://atomgame.ru/",
      logoUrl: "https://placehold.co/120x80/white/black?text=ATOM﮳GAME",
      enabled: true
    },
    {
      id: 2,
      title: "Росэнергоатом",
      description: "Ведущая энергетическая компания России",
      buttonText: "Посетить сайт",
      buttonLink: "https://www.rosenergoatom.ru/",
      logoUrl: "https://placehold.co/120x80/white/blue?text=Росэнергоатом",
      enabled: true
    }
  ];
  res.json(ads);
});

app.get('/api/site-settings', (req, res) => {
  const settings = {
    id: 1,
    primaryColor: "#000000",
    secondaryColor: "#3498db",
    siteName: "ATOM﮳GAME",
    logoUrl: "https://placehold.co/200x100/orange/white?text=ATOM﮳GAME",
    registrationEnabled: true
  };
  res.json(settings);
});

// Маршрут для проверки работоспособности
app.get('/health', (req, res) => {
  res.status(200).json({ status: 'UP', message: 'Сервер работает' });
});

// Обработка всех остальных маршрутов (для SPA)
app.get('*', (req, res) => {
  res.sendFile(path.join(publicDir, 'index.html'));
});

// Запуск сервера
const server = http.createServer(app);
server.listen(PORT, HOST, () => {
  console.log(\`Сервер запущен на http://\${HOST}:\${PORT}\`);
});
EOF

# 4. Создание директории public
log "Создание директории public..."
mkdir -p "$INSTALL_PATH/public"

# 5. Создание простого index.html
log "Создание простого index.html..."
cat > "$INSTALL_PATH/public/index.html" << EOF
<!DOCTYPE html>
<html lang="ru">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>ATOM GAME</title>
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
    .btn {
      display: inline-block;
      background-color: #3498db;
      color: white;
      padding: 0.8rem 1.5rem;
      border-radius: 4px;
      text-decoration: none;
      font-weight: bold;
      transition: background-color 0.3s;
    }
    .btn:hover {
      background-color: #2980b9;
    }
  </style>
</head>
<body>
  <div class="container">
    <h1>ATOM﮳GAME</h1>
    <p>Сервер работает. Ведется настройка приложения.</p>
    <p>Скоро здесь появится полноценное приложение.</p>
  </div>
</body>
</html>
EOF

# 6. Настройка .env файла
log "Настройка .env файла..."
cat > "$INSTALL_PATH/.env" << EOF
# Основные настройки
NODE_ENV=production
PORT=$SERVER_PORT
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

# 7. Обновление настроек Nginx
log "Обновление конфигурации Nginx..."
cat > /etc/nginx/sites-available/atomgame << EOF
server {
    listen 80;
    server_name 193.109.78.85;
    
    # Файлы логов
    access_log /var/log/nginx/atomgame.access.log;
    error_log /var/log/nginx/atomgame.error.log debug;
    
    # Включение сжатия
    gzip on;
    gzip_types text/plain application/javascript application/x-javascript text/javascript text/xml text/css;
    
    # Проксирование всех запросов на приложение Node.js
    location / {
        proxy_pass http://127.0.0.1:$SERVER_PORT;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto http;
        proxy_cache_bypass \$http_upgrade;
        proxy_read_timeout 300;
        proxy_connect_timeout 300;
        proxy_send_timeout 300;
    }
}
EOF

# Перезапуск Nginx
nginx -t && systemctl restart nginx

# 8. Создание скрипта для запуска
log "Создание скрипта для запуска..."
cat > "$INSTALL_PATH/start_server.sh" << EOF
#!/bin/bash
export NODE_ENV=production
export PORT=$SERVER_PORT
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

cd $INSTALL_PATH
node simple.js
EOF

chmod +x "$INSTALL_PATH/start_server.sh"

# 9. Запуск сервера в фоновом режиме
log "Запуск сервера в фоновом режиме..."
nohup "$INSTALL_PATH/start_server.sh" > "$INSTALL_PATH/server.log" 2>&1 &

SERVER_PID=$!
echo $SERVER_PID > "$INSTALL_PATH/server.pid"

log "Сервер запущен с PID: $SERVER_PID"

# 10. Проверка, что сервер запустился
log "Ожидание запуска сервера (5 секунд)..."
sleep 5

if kill -0 $SERVER_PID 2>/dev/null; then
  log "Процесс запущен и работает!"
  
  # Проверка доступности
  if curl -s "http://localhost:$SERVER_PORT/health" | grep -q "UP"; then
    log "Сервер успешно отвечает на запросы!"
  else
    warning "Сервер запущен, но не отвечает на запросы"
  fi
else
  warning "Процесс не запущен или уже завершился"
  
  # Выводим логи
  log "Содержимое логов:"
  cat "$INSTALL_PATH/server.log"
fi

echo ""
echo -e "${GREEN}==========================================${NC}"
echo -e "${GREEN}   Запуск завершен!   ${NC}"
echo -e "${GREEN}==========================================${NC}"
echo ""
echo -e "${YELLOW}Для просмотра логов:${NC}"
echo "tail -f $INSTALL_PATH/server.log"
echo ""
echo -e "${YELLOW}Для остановки сервера:${NC}"
echo "kill \$(cat $INSTALL_PATH/server.pid)"
echo ""
echo -e "${YELLOW}Проверьте доступность сайта:${NC}"
echo "http://193.109.78.85"
echo ""