#!/bin/bash

# Скрипт для исправления запуска сервера
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
echo -e "${GREEN}   Исправление запуска сервера   ${NC}"
echo -e "${GREEN}==========================================${NC}"
echo ""

# 1. Проверка логов
log "Проверка логов сервера..."
if [ -f "$INSTALL_PATH/server.log" ]; then
  cat "$INSTALL_PATH/server.log"
else
  warning "Файл логов не найден"
fi

# 2. Остановка всех процессов Node.js
log "Остановка всех процессов Node.js..."
pkill -f "node $INSTALL_PATH/simple.js" 2>/dev/null || true
pkill -f "/var/www/atomgame/simple.js" 2>/dev/null || true
pkill -f "/var/www/atomgame/dist/index.js" 2>/dev/null || true

# 3. Проверка доступности PostgreSQL
log "Проверка доступности PostgreSQL..."
if systemctl is-active --quiet postgresql; then
  log "PostgreSQL запущен"
else
  log "Запуск PostgreSQL..."
  systemctl start postgresql
fi

# 4. Проверка пользователя и базы данных
log "Проверка пользователя и базы данных..."
su - postgres << EOF
psql -c "SELECT 1 FROM pg_roles WHERE rolname='atomgame'" | grep -q 1 || psql -c "CREATE USER atomgame WITH PASSWORD 'AtomGame2025';"
psql -c "SELECT 1 FROM pg_database WHERE datname='atomgame'" | grep -q 1 || psql -c "CREATE DATABASE atomgame OWNER atomgame;"
psql -c "GRANT ALL PRIVILEGES ON DATABASE atomgame TO atomgame;"
EOF

# 5. Установка пакета pg
log "Установка пакета pg..."
cd "$INSTALL_PATH"
npm install pg

# 6. Исправление скрипта simple.js, добавляем обработку ошибок
log "Исправление скрипта simple.js..."
cat > "$INSTALL_PATH/simple.js" << EOF
// Простой сервер Express без базы данных
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

# 7. Обновление скрипта запуска
log "Обновление скрипта запуска..."
cat > "$INSTALL_PATH/start_fixed.sh" << EOF
#!/bin/bash
export NODE_ENV=production
export PORT=$SERVER_PORT
export HOST=0.0.0.0
export HTTPS=false
export NODE_TLS_REJECT_UNAUTHORIZED=0

# Отладочная информация
echo "Запуск сервера..."
echo "Текущая директория: \$(pwd)"
echo "Содержимое директории:"
ls -la

# Запуск сервера
node simple.js
EOF

chmod +x "$INSTALL_PATH/start_fixed.sh"

# 8. Запуск сервера напрямую (не в фоновом режиме) для проверки ошибок
log "Запуск сервера для проверки ошибок..."
cd "$INSTALL_PATH"
node -e "console.log('Node.js работает, версия:', process.version)"

echo "Проверка simple.js на ошибки синтаксиса..."
# Используем --check для проверки синтаксиса
node --check simple.js

# 9. Запуск сервера в фоновом режиме
log "Запуск сервера в фоновом режиме..."
cd "$INSTALL_PATH"
nohup ./start_fixed.sh > ./server_fixed.log 2>&1 &

SERVER_PID=$!
echo $SERVER_PID > "$INSTALL_PATH/server_fixed.pid"

log "Сервер запущен с PID: $SERVER_PID"

# 10. Проверка, что сервер запустился
log "Ожидание запуска сервера (3 секунды)..."
sleep 3

# Выводим логи
log "Содержимое логов:"
cat "$INSTALL_PATH/server_fixed.log"

if kill -0 $SERVER_PID 2>/dev/null; then
  log "Процесс запущен и работает!"
  
  # Проверка доступности через curl
  sleep 2
  if curl -s "http://localhost:$SERVER_PORT/health" | grep -q "UP"; then
    log "Сервер успешно отвечает на запросы!"
  else
    warning "Сервер запущен, но не отвечает на запросы. Проверьте логи."
  fi
else
  error "Процесс не запущен или уже завершился. Проверьте логи."
fi

echo ""
echo -e "${GREEN}==========================================${NC}"
echo -e "${GREEN}   Исправление завершено!   ${NC}"
echo -e "${GREEN}==========================================${NC}"
echo ""
echo -e "${YELLOW}Для просмотра логов:${NC}"
echo "tail -f $INSTALL_PATH/server_fixed.log"
echo ""
echo -e "${YELLOW}Для остановки сервера:${NC}"
echo "kill \$(cat $INSTALL_PATH/server_fixed.pid)"
echo ""
echo -e "${YELLOW}Проверьте доступность сайта:${NC}"
echo "http://193.109.78.85"
echo "