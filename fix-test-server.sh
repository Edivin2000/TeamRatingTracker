#!/bin/bash

# ==========================================
# СКРИПТ ИСПРАВЛЕНИЯ ТЕСТОВОГО СЕРВЕРА
# ==========================================
# Версия: 1.0.0
# Дата: 01.05.2025
# Автор: ATOM-GAME Team
# ==========================================

set -e

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Переменные настройки
PROJECT_DIR="/var/www/atomgameblk"
APP_PORT=3000  # Меняем порт на 3000 для теста

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
   error "Пожалуйста, используйте: sudo ./fix-test-server.sh"
   exit 1
fi

# Остановка всех PM2 процессов
log "Остановка всех PM2 процессов..."
pm2 delete all || true
success "Все PM2 процессы остановлены"

# Проверка доступности порта
log "Проверка доступности порта $APP_PORT..."
if netstat -tuln | grep -q ":$APP_PORT "; then
  warn "Порт $APP_PORT уже используется. Процесс будет завершен."
  PID=$(netstat -tuln | grep ":$APP_PORT " | awk '{print $7}' | cut -d'/' -f1)
  if [ -n "$PID" ]; then
    log "Завершение процесса PID: $PID"
    kill -9 $PID || true
  fi
fi
success "Порт $APP_PORT свободен"

# Создание простого HTML файла для теста
log "Создание простого HTML файла для теста..."
mkdir -p $PROJECT_DIR/public
cat > $PROJECT_DIR/public/index.html << EOF
<!DOCTYPE html>
<html lang="ru">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>ATOM-GAME | БАЛАКОВО</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 0;
            padding: 20px;
            background: linear-gradient(135deg, #f5f7fa 0%, #c3cfe2 100%);
            min-height: 100vh;
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: center;
            text-align: center;
            color: #333;
        }
        h1 {
            font-size: 2.5rem;
            margin-bottom: 1rem;
            background: linear-gradient(to right, #00b09b, #96c93d);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
        }
        p {
            font-size: 1.2rem;
            margin-bottom: 2rem;
            max-width: 800px;
        }
        .logo {
            max-width: 300px;
            margin-bottom: 2rem;
        }
        .countdown {
            font-size: 1.5rem;
            font-weight: bold;
            margin-bottom: 1.5rem;
            background: linear-gradient(to right, #4caf50, #2196f3);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
        }
        .partners {
            margin-top: 3rem;
            font-size: 1rem;
            color: #666;
        }
        .footer {
            margin-top: 2rem;
            font-size: 0.9rem;
            color: #777;
        }
    </style>
</head>
<body>
    <div class="logo">ATOM-GAME</div>
    <h1>ATOM-GAME | БАЛАКОВО ОТКРЫВАЕТ РЕГИСТРАЦИЮ НА СЕЗОН 2025!</h1>
    <p>🏆 Создай бренд своей команды и сражайся за 150 000 рублей!</p>
    
    <div class="countdown">Осталось до начала регистрации: 30 дней</div>
    
    <p>Следите за обновлениями на нашем сайте и будьте готовы к новому сезону соревнований!</p>
    
    <div class="partners">
        <p>Партнеры: Фонд «АТР АЭС» и АО «Концерн Росэнергоатом»</p>
    </div>
    
    <div class="footer">
        <p>© 2025 ATOM﮳GAME. Проект поддерживается Фондом «АТР АЭС» и АО «Концерн Росэнергоатом»</p>
    </div>
</body>
</html>
EOF
success "HTML файл создан"

# Создание нового простого сервера
log "Создание сверхпростого тестового сервера..."
cat > $PROJECT_DIR/simple-server.js << EOF
const http = require('http');
const fs = require('fs');
const path = require('path');

const PORT = $APP_PORT;

const server = http.createServer((req, res) => {
  console.log(\`\${new Date().toISOString()} - Request: \${req.method} \${req.url}\`);
  
  if (req.url === '/' || req.url === '/index.html') {
    const htmlPath = path.join(__dirname, 'public', 'index.html');
    fs.readFile(htmlPath, (err, content) => {
      if (err) {
        res.writeHead(500);
        res.end('Ошибка сервера');
        console.error(err);
      } else {
        res.writeHead(200, { 'Content-Type': 'text/html' });
        res.end(content);
      }
    });
  } else {
    res.writeHead(404);
    res.end('Страница не найдена');
  }
});

server.listen(PORT, '0.0.0.0', () => {
  console.log(\`Сервер запущен на http://0.0.0.0:\${PORT}\`);
});

// Обработка исключений
process.on('uncaughtException', (error) => {
  console.error('Непойманное исключение:', error);
});

process.on('unhandledRejection', (reason, promise) => {
  console.error('Необработанное отклонение promise:', reason);
});
EOF
success "Сверхпростой сервер создан"

# Обновление конфигурации Nginx
log "Обновление конфигурации Nginx..."
cat > /etc/nginx/sites-available/atomgameblk.ru << EOF
server {
    listen 80;
    server_name atomgameblk.ru www.atomgameblk.ru 193.109.78.85;

    location / {
        proxy_pass http://localhost:$APP_PORT;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
        proxy_read_timeout 300;
        proxy_connect_timeout 300;
    }

    access_log /var/log/nginx/atomgameblk.ru-access.log;
    error_log /var/log/nginx/atomgameblk.ru-error.log;
}
EOF

# Удаление дефолтного конфига
rm -f /etc/nginx/sites-enabled/default

# Создание символической ссылки и проверка конфигурации
ln -sf /etc/nginx/sites-available/atomgameblk.ru /etc/nginx/sites-enabled/
nginx -t && systemctl restart nginx
success "Nginx настроен на порт $APP_PORT"

# Запуск сервера через PM2
log "Запуск сервера через PM2..."
cd $PROJECT_DIR
pm2 start simple-server.js --name atom-simple-server
pm2 save
success "Простой сервер запущен через PM2"

# Проверка статуса
log "Проверка статуса сервера..."
sleep 3
if pm2 list | grep -q "atom-simple-server" && pm2 list | grep -q "online"; then
  success "Сервер запущен и находится в статусе online"
else
  warn "Сервер может быть не запущен. Проверьте логи: pm2 logs atom-simple-server"
fi

# Проверка открытых портов
log "Проверка открытых портов..."
netstat -tulpn | grep $APP_PORT || warn "Порт $APP_PORT не прослушивается"

echo "=================================================================="
echo "        НАСТРОЙКА ПРОСТОГО СЕРВЕРА ЗАВЕРШЕНА!"
echo "=================================================================="
echo ""
echo "Проверьте доступность сайта по адресам:"
echo "  http://atomgameblk.ru"
echo "  http://193.109.78.85"
echo ""
echo "Для просмотра логов сервера:"
echo "  pm2 logs atom-simple-server"
echo ""
echo "После подтверждения работы сервера можно вернуться к настройке"
echo "полной версии приложения."
echo "=================================================================="