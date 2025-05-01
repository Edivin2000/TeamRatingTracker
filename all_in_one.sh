#!/bin/bash

# Комплексный скрипт развертывания и настройки приложения ATOM GAME
# Версия 2.0 - Май 2025

# Цвета для вывода
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # Сброс цвета

# Настройки
INSTALL_PATH="/var/www/atomgame"
SERVER_PORT="5001"
GITHUB_REPO="https://github.com/Edivin2000/TeamRatingTracker.git"
BRANCH="main"

# Функции вывода
log() {
  echo -e "${GREEN}[УСТАНОВКА]${NC} $1"
}

error() {
  echo -e "${RED}[ОШИБКА]${NC} $1"
  exit 1
}

warning() {
  echo -e "${YELLOW}[ВНИМАНИЕ]${NC} $1"
}

info() {
  echo -e "${BLUE}[ИНФО]${NC} $1"
}

# Проверка прав суперпользователя
if [ "$(id -u)" != "0" ]; then
   error "Этот скрипт должен быть запущен с правами root. Используйте sudo."
fi

# Вывод заголовка
clear
echo -e "${GREEN}==========================================${NC}"
echo -e "${GREEN}   ATOM GAME - Комплексная установка     ${NC}"
echo -e "${GREEN}               Версия 2.0                ${NC}"
echo -e "${GREEN}==========================================${NC}"
echo ""

# Проверка наличия необходимых команд
check_command() {
  command -v $1 >/dev/null 2>&1 || { error "Команда $1 не установлена. Пожалуйста, установите сначала необходимые зависимости."; }
}

# Функция для установки Node.js
install_nodejs() {
  log "Установка Node.js 18.x..."
  
  # Проверка, установлен ли уже Node.js
  if command -v node &> /dev/null; then
    NODE_VERSION=$(node -v)
    info "Node.js $NODE_VERSION уже установлен"
    
    # Проверка версии
    if [[ $NODE_VERSION == v18* ]]; then
      info "Версия Node.js совместима с приложением"
      return 0
    else
      warning "Рекомендуется Node.js версии 18.x, текущая версия: $NODE_VERSION"
      read -p "Продолжить с текущей версией? (y/n): " -n 1 -r
      echo
      if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log "Установка рекомендуемой версии Node.js 18.x..."
      else
        info "Продолжаем с текущей версией Node.js"
        return 0
      fi
    fi
  fi
  
  # Установка Node.js
  apt-get update
  apt-get install -y ca-certificates curl gnupg
  mkdir -p /etc/apt/keyrings
  curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
  echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_18.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list
  apt-get update
  apt-get install -y nodejs
  
  # Проверка установки
  NODE_VERSION=$(node -v)
  if [[ $NODE_VERSION == v18* ]]; then
    log "Node.js $NODE_VERSION успешно установлен"
  else
    error "Не удалось установить Node.js 18.x"
  fi
}

# Функция настройки Nginx
setup_nginx() {
  log "Настройка Nginx..."
  
  # Установка Nginx если он не установлен
  if ! command -v nginx &> /dev/null; then
    apt-get update
    apt-get install -y nginx
  fi
  
  # Создание конфигурации
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
  
  # Активация конфигурации
  if [ ! -f /etc/nginx/sites-enabled/atomgame ]; then
    ln -s /etc/nginx/sites-available/atomgame /etc/nginx/sites-enabled/
  fi
  
  # Удаление дефолтного сайта
  rm -f /etc/nginx/sites-enabled/default
  
  # Проверка конфигурации и перезапуск
  if nginx -t; then
    systemctl restart nginx
    log "Nginx успешно настроен и перезапущен"
  else
    error "Ошибка в конфигурации Nginx"
  fi
}

# Функция для настройки базы данных PostgreSQL
setup_database() {
  log "Настройка базы данных PostgreSQL..."
  
  # Установка PostgreSQL, если он не установлен
  if ! command -v psql &> /dev/null; then
    apt-get update
    apt-get install -y postgresql postgresql-contrib
  fi
  
  # Проверка статуса PostgreSQL
  if ! systemctl is-active --quiet postgresql; then
    systemctl start postgresql
  fi
  
  # Создание пользователя и базы данных
  log "Создание пользователя и базы данных..."
  su - postgres << EOF
psql -c "SELECT 1 FROM pg_roles WHERE rolname='atomgame'" | grep -q 1 || psql -c "CREATE USER atomgame WITH PASSWORD 'AtomGame2025';"
psql -c "SELECT 1 FROM pg_database WHERE datname='atomgame'" | grep -q 1 || psql -c "CREATE DATABASE atomgame OWNER atomgame;"
psql -c "GRANT ALL PRIVILEGES ON DATABASE atomgame TO atomgame;"
EOF
  
  log "База данных успешно настроена"
}

# Функция клонирования/обновления репозитория
setup_repository() {
  log "Настройка репозитория приложения..."
  
  # Создание директории, если она не существует
  mkdir -p "$INSTALL_PATH"
  
  # Переход в директорию установки
  cd "$INSTALL_PATH" || error "Не удалось перейти в директорию $INSTALL_PATH"
  
  # Проверка, существует ли репозиторий
  if [ -d ".git" ]; then
    log "Репозиторий уже существует, обновляем..."
    git fetch origin
    git reset --hard origin/$BRANCH
    
    if [ $? -eq 0 ]; then
      log "Репозиторий успешно обновлен"
    else
      error "Ошибка при обновлении репозитория"
    fi
  else
    log "Клонирование репозитория..."
    # Очистка директории, если она не пуста
    if [ "$(ls -A $INSTALL_PATH)" ]; then
      warning "Директория $INSTALL_PATH не пуста. Создаем резервную копию..."
      timestamp=$(date +"%Y%m%d%H%M%S")
      mkdir -p "${INSTALL_PATH}_backup_${timestamp}"
      cp -r "$INSTALL_PATH"/* "${INSTALL_PATH}_backup_${timestamp}/"
      log "Резервная копия создана в ${INSTALL_PATH}_backup_${timestamp}"
      rm -rf "$INSTALL_PATH"/*
    fi
    
    git clone -b $BRANCH "$GITHUB_REPO" .
    
    if [ $? -eq 0 ]; then
      log "Репозиторий успешно клонирован"
    else
      error "Ошибка при клонировании репозитория"
    fi
  fi
  
  # Установка зависимостей
  log "Установка зависимостей npm..."
  npm ci
  
  if [ $? -eq 0 ]; then
    log "Зависимости успешно установлены"
  else
    warning "Возникли проблемы при установке зависимостей, пробуем npm install..."
    npm install
    
    if [ $? -eq 0 ]; then
      log "Зависимости успешно установлены через npm install"
    else
      error "Не удалось установить зависимости"
    fi
  fi
  
  # Сборка проекта
  log "Сборка проекта..."
  npm run build
  
  if [ $? -eq 0 ]; then
    log "Проект успешно собран"
  else
    error "Ошибка при сборке проекта"
  fi
}

# Функция создания и настройки временного сервера
setup_temp_server() {
  log "Настройка временного сервера Express..."
  
  # Создание простого сервера Express
  cat > "$INSTALL_PATH/simple.js" << EOF
// Простой сервер Express
import express from 'express';
import http from 'node:http';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { Pool } from 'pg';

// Настройка переменных среды
const PORT = process.env.PORT || 5001;
const HOST = process.env.HOST || '0.0.0.0';

// Подключение к базе данных
const pool = new Pool({
  user: process.env.PGUSER || 'atomgame',
  host: process.env.PGHOST || 'localhost',
  database: process.env.PGDATABASE || 'atomgame',
  password: process.env.PGPASSWORD || 'AtomGame2025',
  port: process.env.PGPORT || 5432,
});

// Тестирование подключения к базе данных
pool.query('SELECT NOW()', (err, res) => {
  if (err) {
    console.error('Ошибка подключения к базе данных:', err);
  } else {
    console.log('Успешное подключение к базе данных. Время сервера:', res.rows[0].now);
  }
});

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

// Базовые API маршруты из базы данных или с заглушками в случае ошибок
const getTeamsFromDB = async () => {
  try {
    const result = await pool.query('SELECT * FROM teams ORDER BY score DESC');
    return result.rows;
  } catch (err) {
    console.error('Ошибка при получении команд из БД:', err);
    return [
      { id: 1, name: "Phoenix Force", logoUrl: "https://placehold.co/100x100/orange/white?text=PF", score: 89, excluded: false },
      { id: 2, name: "Thunderbolts", logoUrl: "https://placehold.co/100x100/blue/white?text=TB", score: 72, excluded: false },
      { id: 3, name: "Storm Riders", logoUrl: "https://placehold.co/100x100/purple/white?text=SR", score: 68, excluded: false },
      { id: 4, name: "Arctic Wolves", logoUrl: "https://placehold.co/100x100/teal/white?text=AW", score: 95, excluded: false },
      { id: 5, name: "Shadow Tigers", logoUrl: "https://placehold.co/100x100/gray/white?text=ST", score: 42, excluded: false },
      { id: 6, name: "Dragon Warriors", logoUrl: "https://placehold.co/100x100/red/white?text=DW", score: 38, excluded: false }
    ];
  }
};

const getTimersFromDB = async () => {
  try {
    const result = await pool.query('SELECT * FROM timers WHERE active = true');
    return result.rows;
  } catch (err) {
    console.error('Ошибка при получении таймеров из БД:', err);
    return [
      { id: 3, name: "Регистрации на сезон 2025", endDate: "2025-08-31T23:59:59.999Z", active: true }
    ];
  }
};

const getPartnersFromDB = async () => {
  try {
    const result = await pool.query('SELECT * FROM partners ORDER BY "order"');
    return result.rows;
  } catch (err) {
    console.error('Ошибка при получении партнеров из БД:', err);
    return [
      { id: 1, name: "Росэнергоатом", logoUrl: "https://placehold.co/200x100/blue/white?text=Росэнергоатом", website: "https://www.rosenergoatom.ru/", order: 1 },
      { id: 2, name: "Фонд АТР АЭС", logoUrl: "https://placehold.co/200x100/green/white?text=Фонд+АТР+АЭС", website: "https://atompsy.ru/", order: 2 },
      { id: 3, name: "ATOM﮳GAME", logoUrl: "https://placehold.co/200x100/orange/white?text=ATOM﮳GAME", website: "https://atomgame.ru/", order: 3 }
    ];
  }
};

const getAdsFromDB = async () => {
  try {
    const result = await pool.query('SELECT * FROM ads WHERE enabled = true');
    return result.rows;
  } catch (err) {
    console.error('Ошибка при получении рекламы из БД:', err);
    return [
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
  }
};

const getSiteSettingsFromDB = async () => {
  try {
    const result = await pool.query('SELECT * FROM site_settings LIMIT 1');
    return result.rows[0] || {};
  } catch (err) {
    console.error('Ошибка при получении настроек из БД:', err);
    return {
      id: 1,
      primaryColor: "#000000",
      secondaryColor: "#3498db",
      siteName: "ATOM﮳GAME",
      logoUrl: "https://placehold.co/200x100/orange/white?text=ATOM﮳GAME",
      registrationEnabled: true
    };
  }
};

// API маршруты
app.get('/api/teams', async (req, res) => {
  const teams = await getTeamsFromDB();
  res.json(teams);
});

app.get('/api/timers', async (req, res) => {
  const timers = await getTimersFromDB();
  res.json(timers);
});

app.get('/api/partners', async (req, res) => {
  const partners = await getPartnersFromDB();
  res.json(partners);
});

app.get('/api/ads', async (req, res) => {
  const ads = await getAdsFromDB();
  res.json(ads);
});

app.get('/api/site-settings', async (req, res) => {
  const settings = await getSiteSettingsFromDB();
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

  # Создание директории public
  mkdir -p "$INSTALL_PATH/public"
  
  # Создание простого файла index.html
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

  log "Временный сервер создан успешно"
}

# Функция для создания .env и запуска приложения
setup_environment() {
  log "Настройка переменных окружения..."
  
  # Создание файла .env
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

  # Создание скрипта запуска
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
  
  log "Переменные окружения и скрипт запуска настроены"
}

# Функция запуска сервера
start_server() {
  log "Запуск сервера..."
  
  # Остановка всех предыдущих процессов
  if command -v pm2 &> /dev/null; then
    pm2 delete all 2>/dev/null || true
  fi
  
  if systemctl is-active --quiet atomgame; then
    systemctl stop atomgame
  fi
  
  # Проверяем, есть ли активные процессы node
  pkill -f "/var/www/atomgame/dist/index.js" 2>/dev/null || true
  pkill -f "/var/www/atomgame/simple.js" 2>/dev/null || true
  
  # Запуск серверного скрипта в фоновом режиме
  nohup "$INSTALL_PATH/start_server.sh" > "$INSTALL_PATH/server.log" 2>&1 &
  
  SERVER_PID=$!
  echo $SERVER_PID > "$INSTALL_PATH/server.pid"
  
  log "Сервер запущен с PID: $SERVER_PID"
  
  # Проверка успешного запуска
  sleep 5
  if kill -0 $SERVER_PID 2>/dev/null; then
    log "Сервер успешно запущен и работает!"
    
    # Проверка доступности
    if curl -s "http://localhost:$SERVER_PORT/health" | grep -q "UP"; then
      log "Сервер отвечает на запросы!"
    else
      warning "Сервер запущен, но не отвечает на запросы проверки работоспособности"
    fi
  else
    error "Ошибка при запуске сервера"
  fi
}

# Функция создания системного сервиса
create_systemd_service() {
  log "Создание systemd сервиса..."
  
  # Создание файла сервиса
  cat > /etc/systemd/system/atomgame.service << EOF
[Unit]
Description=ATOM GAME Application
After=network.target postgresql.service

[Service]
Type=simple
User=root
WorkingDirectory=$INSTALL_PATH
ExecStart=/usr/bin/node $INSTALL_PATH/simple.js
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
}

# Главная функция установки
main() {
  log "Начинаем установку..."
  
  # 1. Проверка и установка зависимостей
  check_command curl
  check_command git
  install_nodejs
  
  # 2. Настройка базы данных
  setup_database
  
  # 3. Настройка Nginx
  setup_nginx
  
  # 4. Настройка временного сервера (опционально)
  setup_temp_server
  
  # 5. Настройка переменных окружения
  setup_environment
  
  # 6. Запуск сервера
  start_server
  
  # 7. Вывод информации
  echo ""
  echo -e "${GREEN}==========================================${NC}"
  echo -e "${GREEN}   Установка успешно завершена!   ${NC}"
  echo -e "${GREEN}==========================================${NC}"
  echo ""
  echo -e "${YELLOW}Вебсайт доступен по адресу:${NC}"
  echo "http://193.109.78.85"
  echo ""
  echo -e "${YELLOW}Для просмотра логов:${NC}"
  echo "tail -f $INSTALL_PATH/server.log"
  echo ""
  echo -e "${YELLOW}Для остановки сервера:${NC}"
  echo "kill \$(cat $INSTALL_PATH/server.pid)"
  echo ""
  echo -e "${YELLOW}Для автоматического запуска после перезагрузки:${NC}"
  echo "sudo systemctl enable --now atomgame"
  echo ""
  echo -e "${YELLOW}Для мониторинга работы сервера:${NC}"
  echo "curl http://localhost:$SERVER_PORT/health"
  echo ""
  
  # Предложение создать системный сервис
  read -p "Создать системный сервис для автозапуска? (y/n): " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    create_systemd_service
    echo -e "${GREEN}Системный сервис создан. Вы можете управлять им командами:${NC}"
    echo "sudo systemctl start atomgame"
    echo "sudo systemctl stop atomgame"
    echo "sudo systemctl restart atomgame"
    echo "sudo systemctl status atomgame"
  fi
}

# Запуск основной функции
main