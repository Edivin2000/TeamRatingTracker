#!/bin/bash

# ==========================================
# СКРИПТ ЗАПУСКА БАЗОВОГО СЕРВЕРА ATOM-GAME
# ==========================================
# Версия: 1.0.0
# Дата: 01.05.2025
# ==========================================

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Переменные настройки
DB_NAME="atomgame"
DB_USER="atomgame"
DB_PASSWORD="Atom&Game#2025!"
PROJECT_DIR="/var/www/atomgameblk"
ESCAPED_PASSWORD=$(echo $DB_PASSWORD | sed 's/&/%26/g; s/#/%23/g')
DATABASE_URL="postgresql://$DB_USER:$ESCAPED_PASSWORD@localhost:5432/$DB_NAME"
PORT=5000

# Функции для вывода
log() {
  echo -e "${BLUE}[ИНФО]${NC} $1"
}

success() {
  echo -e "${GREEN}[УСПЕХ]${NC} $1"
}

warn() {
  echo -e "${YELLOW}[ВНИМАНИЕ]${NC} $1"
}

error() {
  echo -e "${RED}[ОШИБКА]${NC} $1"
}

# Проверка запуска от root
if [ "$(id -u)" != "0" ]; then
   error "Этот скрипт должен быть запущен от имени root"
   error "Пожалуйста, используйте: sudo ./run-basic-server.sh"
   exit 1
fi

# Шаг 1: Остановка PM2 процессов
log "Остановка всех PM2 процессов..."
pm2 delete all 2>/dev/null || true
success "PM2 процессы остановлены."

# Шаг 2: Переход в директорию проекта
log "Переход в директорию проекта $PROJECT_DIR..."
if [ -d "$PROJECT_DIR" ]; then
  cd $PROJECT_DIR
  success "Перешли в директорию проекта."
else
  error "Директория проекта $PROJECT_DIR не существует!"
  exit 1
fi

# Шаг 3: Создание базового сервера
log "Создание файла базового сервера..."
cat > basic-server.js << 'EOF'
// basic-server.js
// Простой сервер для запуска в случае проблем с основным сервером

import express from 'express';
import path from 'path';
import fs from 'fs';
import pg from 'pg';
import { fileURLToPath } from 'url';

const { Pool } = pg;
const app = express();
const PORT = process.env.PORT || 5000;

// Получение текущей директории для ES модулей
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Настройка базы данных
const dbConfig = {
  user: process.env.PGUSER || 'atomgame',
  password: process.env.PGPASSWORD || 'Atom&Game#2025!',
  database: process.env.PGDATABASE || 'atomgame',
  host: process.env.PGHOST || 'localhost',
  port: process.env.PGPORT || 5432,
};

// Создание пула соединений
const pool = new Pool(dbConfig);

// Middleware для обработки JSON
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Настройка статических файлов
const staticPath = path.join(__dirname, 'dist');
if (fs.existsSync(staticPath)) {
  app.use(express.static(staticPath));
  console.log(`Serving static files from ${staticPath}`);
}

// Проверка соединения с базой данных
app.get('/api/db-status', async (req, res) => {
  try {
    const result = await pool.query('SELECT NOW()');
    res.json({ status: 'OK', time: result.rows[0].now });
  } catch (error) {
    console.error('Ошибка подключения к базе данных:', error);
    res.status(500).json({ status: 'ERROR', message: error.message });
  }
});

// Получение всех команд
app.get('/api/teams', async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM teams ORDER BY score DESC');
    res.json(result.rows);
  } catch (error) {
    console.error('Ошибка при получении команд:', error);
    res.status(500).json({ error: error.message });
  }
});

// Получение всех партнеров
app.get('/api/partners', async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM partners ORDER BY "order"');
    res.json(result.rows);
  } catch (error) {
    console.error('Ошибка при получении партнеров:', error);
    res.status(500).json({ error: error.message });
  }
});

// Получение всех рекламных баннеров
app.get('/api/ads', async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM ads WHERE active = true ORDER BY "order"');
    res.json(result.rows);
  } catch (error) {
    console.error('Ошибка при получении баннеров:', error);
    res.status(500).json({ error: error.message });
  }
});

// Получение настроек сайта
app.get('/api/site-settings', async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM site_settings LIMIT 1');
    res.json(result.rows[0] || {});
  } catch (error) {
    console.error('Ошибка при получении настроек сайта:', error);
    res.status(500).json({ error: error.message });
  }
});

// Обработка всех остальных GET запросов - отправка index.html
app.get('*', (req, res) => {
  const indexPath = path.join(staticPath, 'index.html');
  if (fs.existsSync(indexPath)) {
    res.sendFile(indexPath);
  } else {
    res.status(404).send('Файл index.html не найден');
  }
});

// Запуск сервера
app.listen(PORT, '0.0.0.0', () => {
  console.log(`Базовый сервер запущен на порту ${PORT}`);
  console.log(`Откройте http://localhost:${PORT} в браузере`);
});
EOF
success "Файл базового сервера создан."

# Шаг 4: Установка зависимостей для базового сервера
log "Установка необходимых зависимостей..."
npm install express pg
success "Зависимости установлены."

# Шаг 5: Экспорт переменных окружения
log "Экспорт переменных окружения для базы данных..."
export PGUSER=$DB_USER
export PGPASSWORD=$DB_PASSWORD
export PGDATABASE=$DB_NAME
export PGHOST=localhost
export PGPORT=5432
export DATABASE_URL=$DATABASE_URL
export PORT=$PORT

# Шаг 6: Запуск базового сервера
log "Запуск базового сервера..."
node basic-server.js &
SERVER_PID=$!
success "Базовый сервер запущен с PID: $SERVER_PID"
log "Для остановки сервера нажмите Ctrl+C или выполните: kill $SERVER_PID"

# Шаг 7: Ожидание запуска сервера
log "Ожидание запуска сервера..."
sleep 3

# Шаг 8: Проверка доступности сервера
log "Проверка доступности сервера..."
if curl -s http://localhost:$PORT > /dev/null; then
  success "Сервер успешно запущен и доступен!"
  log "Откройте http://localhost:$PORT в браузере для доступа к сайту."
else
  warn "Сервер запущен, но не отвечает на запросы. Проверьте логи для дополнительной информации."
fi

# Держим скрипт запущенным
log "Сервер работает. Нажмите Ctrl+C для остановки."
wait $SERVER_PID