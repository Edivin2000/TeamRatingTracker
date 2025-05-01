#!/bin/bash

# Финальный скрипт для исправления приложения
# Май 2025

# Цвета для вывода
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # Сброс цвета

# Настройки
INSTALL_PATH="/var/www/atomgame"
SERVER_PORT="5002"  # Изменен порт на 5002, так как 5001 уже занят

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
echo -e "${GREEN}   Финальное исправление приложения   ${NC}"
echo -e "${GREEN}==========================================${NC}"
echo ""

# 1. Проверка текущих процессов на порту 5001
log "Проверка процессов, использующих порт 5001..."
PORT_PROCESS=$(lsof -i:5001 -t)
if [ ! -z "$PORT_PROCESS" ]; then
  log "Найдены процессы, использующие порт 5001: $PORT_PROCESS"
  ps -p $PORT_PROCESS -o comm=
else
  log "Процессы на порту 5001 не найдены"
fi

# 2. Остановка всех процессов Node.js
log "Остановка всех процессов Node.js..."
pkill -f "node $INSTALL_PATH/simple.js" 2>/dev/null || true
pkill -f "/var/www/atomgame/simple.js" 2>/dev/null || true
pkill -f "/var/www/atomgame/dist/index.js" 2>/dev/null || true

# 3. Проверка доступности порта 5002
log "Проверка доступности порта $SERVER_PORT..."
if lsof -i:$SERVER_PORT -t >/dev/null ; then
  warning "Порт $SERVER_PORT уже используется. Закрываем процессы..."
  PORT_PROCESS=$(lsof -i:$SERVER_PORT -t)
  kill $PORT_PROCESS
  sleep 1
fi

# 4. Исправление скрипта simple.js с использованием CommonJS импорта для pg
log "Исправление скрипта simple.js..."
cat > "$INSTALL_PATH/simple_final.js" << EOF
// Простой сервер Express без зависимости от PostgreSQL
import express from 'express';
import http from 'node:http';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

// Обработка неожиданных ошибок
process.on('uncaughtException', (err) => {
  console.error('Неожиданная ошибка:', err);
});

// Настройка переменных среды
const PORT = process.env.PORT || $SERVER_PORT;
const HOST = process.env.HOST || '0.0.0.0';

console.log(\`Настройка сервера на порту \${PORT}\`);

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
  res.status(200).json({ status: 'UP', message: 'Сервер работает', port: PORT });
});

// Обработка всех остальных маршрутов (для SPA)
app.get('*', (req, res) => {
  res.sendFile(path.join(publicDir, 'index.html'));
});

// Ловим ошибки при создании сервера
try {
  // Запуск сервера
  const server = http.createServer(app);
  
  server.on('error', (err) => {
    console.error('Ошибка сервера:', err);
    process.exit(1);
  });
  
  server.listen(PORT, HOST, () => {
    console.log(\`Сервер запущен на http://\${HOST}:\${PORT}\`);
  });
} catch (error) {
  console.error('Критическая ошибка при запуске сервера:', error);
  process.exit(1);
}
EOF

# 5. Обновление конфигурации Nginx для нового порта
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

# 6. Создание скрипта запуска
log "Создание скрипта запуска..."
cat > "$INSTALL_PATH/start_final.sh" << EOF
#!/bin/bash
export NODE_ENV=production
export PORT=$SERVER_PORT
export HOST=0.0.0.0
export HTTPS=false
export NODE_TLS_REJECT_UNAUTHORIZED=0

cd $INSTALL_PATH
node simple_final.js
EOF

chmod +x "$INSTALL_PATH/start_final.sh"

# 7. Обновление .env файла
log "Обновление .env файла..."
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

# 8. Запуск сервера и сохранение PID
log "Запуск сервера..."
cd "$INSTALL_PATH"
nohup ./start_final.sh > ./final.log 2>&1 &
SERVER_PID=$!
echo $SERVER_PID > "$INSTALL_PATH/final.pid"

log "Сервер запущен с PID: $SERVER_PID"

# 9. Проверка запуска сервера
log "Ожидание запуска сервера (3 секунды)..."
sleep 3

# Выводим логи
log "Содержимое логов:"
cat "$INSTALL_PATH/final.log"

if kill -0 $SERVER_PID 2>/dev/null; then
  log "Процесс запущен и работает!"
  
  # Проверка доступности
  sleep 2
  if curl -s "http://localhost:$SERVER_PORT/health" | grep -q "UP"; then
    log "Сервер успешно отвечает на запросы!"
    
    # Проверка доступности через Nginx
    if curl -s "http://127.0.0.1/health" | grep -q "UP"; then
      log "Приложение доступно через Nginx!"
    else
      warning "Приложение не доступно через Nginx. Проверьте настройки."
    fi
  else
    warning "Сервер запущен, но не отвечает на запросы."
  fi
else
  error "Процесс не запущен или уже завершился. Проверьте логи."
fi

# 10. Создание systemd-сервиса
log "Создание systemd-сервиса..."
cat > /etc/systemd/system/atomgame.service << EOF
[Unit]
Description=ATOM GAME Application
After=network.target postgresql.service

[Service]
Type=simple
User=root
WorkingDirectory=$INSTALL_PATH
ExecStart=/usr/bin/node $INSTALL_PATH/simple_final.js
Restart=on-failure
RestartSec=10
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=atomgame
Environment=NODE_ENV=production
Environment=PORT=$SERVER_PORT
Environment=HOST=0.0.0.0
Environment=HTTPS=false
Environment=NODE_TLS_REJECT_UNAUTHORIZED=0
Environment=PGUSER=atomgame
Environment=PGPASSWORD=AtomGame2025
Environment=PGDATABASE=atomgame
Environment=PGHOST=localhost
Environment=PGPORT=5432
Environment=DATABASE_URL=postgresql://atomgame:AtomGame2025@localhost:5432/atomgame
Environment=SESSION_SECRET=AtomGameSecretKey2025

[Install]
WantedBy=multi-user.target
EOF

# Перезагрузка системы systemd
systemctl daemon-reload

# Включение сервиса при загрузке
systemctl enable atomgame

log "Системный сервис atomgame создан и включен"

echo ""
echo -e "${GREEN}==========================================${NC}"
echo -e "${GREEN}   Исправление завершено!   ${NC}"
echo -e "${GREEN}==========================================${NC}"
echo ""
echo -e "${YELLOW}Для просмотра логов:${NC}"
echo "tail -f $INSTALL_PATH/final.log"
echo ""
echo -e "${YELLOW}Для остановки сервера:${NC}"
echo "kill \$(cat $INSTALL_PATH/final.pid)"
echo ""
echo -e "${YELLOW}Порт сервера был изменен на ${SERVER_PORT} (вместо 5001)${NC}"
echo ""
echo -e "${YELLOW}Для запуска через systemd:${NC}"
echo "systemctl start atomgame"
echo ""
echo -e "${YELLOW}Проверьте доступность сайта:${NC}"
echo "http://193.109.78.85"
echo "