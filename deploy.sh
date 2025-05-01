#!/bin/bash

# Скрипт для автоматического развертывания ATOM-GAME рейтинговой системы
# Автор: Atom-Game Team
# Дата: 01.05.2025

set -e

echo "=== Начало установки ATOM-GAME платформы ==="

# Проверка и установка требуемых пакетов
echo "Проверка зависимостей..."
packages=("nodejs" "npm" "postgresql" "nginx" "git" "curl" "certbot" "python3-certbot-nginx")

for pkg in "${packages[@]}"; do
  if ! dpkg-query -W -f='${Status}' $pkg 2>/dev/null | grep -q "ok installed"; then
    echo "Установка $pkg..."
    apt-get install -y $pkg
  else
    echo "$pkg уже установлен"
  fi
done

# Обновление NodeJS до нужной версии
echo "Обновление NodeJS до версии 18.x..."
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt-get install -y nodejs

# Создание директории проекта
PROJECT_DIR="/var/www/atomgameblk"
echo "Создание директории проекта в $PROJECT_DIR..."
mkdir -p $PROJECT_DIR
cd $PROJECT_DIR

# Клонирование или обновление репозитория
if [ -d ".git" ]; then
  echo "Git репозиторий обнаружен, обновление..."
  git pull
else
  echo "Клонирование репозитория..."
  # Замените URL на ваш репозиторий
  git clone https://github.com/yourusername/atom-game-rating.git .
fi

# Установка зависимостей NodeJS
echo "Установка NPM зависимостей..."
npm install

# Настройка переменных окружения
echo "Настройка переменных окружения..."
if [ ! -f ".env" ]; then
  echo "Создание файла .env..."
  cat > .env << EOF
# Основные настройки
NODE_ENV=production
PORT=5000

# База данных PostgreSQL
PGUSER=atomgame
PGPASSWORD=Atom&Game#2025!
PGDATABASE=atomgame
PGHOST=localhost
PGPORT=5432
DATABASE_URL=postgresql://atomgame:Atom%26Game%232025%21@localhost:5432/atomgame

# Безопасность
SESSION_SECRET=AtomGameSecretSession2025!
EOF
fi

# Настройка базы данных PostgreSQL
echo "Настройка базы данных PostgreSQL..."
if sudo -u postgres psql -lqt | cut -d \| -f 1 | grep -qw atomgame; then
  echo "База данных atomgame уже существует."
else
  echo "Создание пользователя и базы данных..."
  sudo -u postgres psql -c "CREATE USER atomgame WITH ENCRYPTED PASSWORD 'Atom&Game#2025!';"
  sudo -u postgres psql -c "CREATE DATABASE atomgame OWNER atomgame;"
  echo "База данных успешно создана."
fi

# Миграция схемы базы данных
echo "Применение миграций базы данных..."
npm run db:push

# Сборка приложения для продакшена
echo "Сборка приложения..."
npm run build

# Настройка PM2 для управления процессами
echo "Настройка менеджера процессов PM2..."
if ! command -v pm2 &> /dev/null; then
  npm install -g pm2
fi

# Копирование файла экосистемы PM2
if [ -f "ecosystem.config.js" ]; then
  echo "Файл конфигурации PM2 найден."
else
  echo "Создание файла экосистемы PM2..."
  cat > ecosystem.config.js << EOF
module.exports = {
  apps: [{
    name: 'atom-game',
    script: 'dist/index.js',
    instances: 'max',
    exec_mode: 'cluster',
    env: {
      NODE_ENV: 'production',
      PORT: 5000
    },
    max_memory_restart: '500M'
  }]
};
EOF
fi

# Запуск через PM2
echo "Запуск приложения через PM2..."
pm2 start ecosystem.config.js
pm2 save
pm2 startup

# Настройка Nginx
echo "Настройка Nginx как обратного прокси..."
cat > /etc/nginx/sites-available/atomgameblk << EOF
server {
    listen 80;
    server_name atomgameblk.ru www.atomgameblk.ru;

    location / {
        proxy_pass http://localhost:5000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
    }
}
EOF

# Активация конфигурации Nginx
ln -sf /etc/nginx/sites-available/atomgameblk /etc/nginx/sites-enabled/
nginx -t && systemctl restart nginx

# Настройка SSL с Let's Encrypt
echo "Настройка SSL сертификата с Let's Encrypt..."
certbot --nginx -d atomgameblk.ru -d www.atomgameblk.ru --non-interactive --agree-tos -m admin@atomgameblk.ru

# Настройка автообновления
echo "Настройка автоматического обновления..."
cat > /etc/cron.daily/update-atomgame << EOF
#!/bin/bash
cd $PROJECT_DIR
git pull
npm install
npm run build
pm2 reload atom-game
EOF

chmod +x /etc/cron.daily/update-atomgame

echo "=== Установка ATOM-GAME платформы завершена! ==="
echo "Сайт доступен по адресу: https://atomgameblk.ru"