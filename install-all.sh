#!/bin/bash

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Конфигурация
DOMAIN="atomgameblk.ru"
SERVER_IP="193.109.78.85"
PORT="5001"
APP_PATH="/var/www/atomgame"
NODE_VERSION="20"
DB_USER="atomgame"
DB_PASS="AtomGame2025!"
DB_NAME="atomgame"
ADMIN_USER="admin"
ADMIN_PASS="Atom&Game#2025!"

echo -e "${BOLD}${GREEN}=========================================================${NC}"
echo -e "${BOLD}${GREEN}       ATOM-GAME - Полная автоматическая установка       ${NC}"
echo -e "${BOLD}${GREEN}=========================================================${NC}"
echo -e "${YELLOW}Домен: ${DOMAIN}${NC}"
echo -e "${YELLOW}IP: ${SERVER_IP}${NC}"
echo -e "${YELLOW}Порт: ${PORT}${NC}"
echo -e "${YELLOW}Путь установки: ${APP_PATH}${NC}"
echo

# Проверка root прав
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}Скрипт должен быть запущен с правами root${NC}"
  echo -e "${YELLOW}Выполните: sudo bash $0${NC}"
  exit 1
fi

# 1. Обновление системы и установка необходимых пакетов
echo -e "\n${BOLD}${BLUE}[1/10] Обновление системы и установка пакетов...${NC}"
apt update && apt upgrade -y
apt install -y curl wget git unzip nginx certbot python3-certbot-nginx postgresql

# 2. Установка Node.js
echo -e "\n${BOLD}${BLUE}[2/10] Установка Node.js ${NODE_VERSION}...${NC}"
curl -fsSL https://deb.nodesource.com/setup_${NODE_VERSION}.x | bash -
apt install -y nodejs
npm install -g pm2 tsx

# 3. Подготовка директории приложения
echo -e "\n${BOLD}${BLUE}[3/10] Подготовка директории приложения...${NC}"
mkdir -p ${APP_PATH}
rm -rf ${APP_PATH}/*

# 4. Клонирование репозитория
echo -e "\n${BOLD}${BLUE}[4/10] Клонирование репозитория...${NC}"
git clone https://github.com/Edivin2000/TeamRatingTracker.git ${APP_PATH}
if [ $? -ne 0 ]; then
  echo -e "${RED}Ошибка клонирования репозитория. Установка прервана.${NC}"
  exit 1
fi

# 5. Настройка базы данных PostgreSQL
echo -e "\n${BOLD}${BLUE}[5/10] Настройка базы данных PostgreSQL...${NC}"
# Проверяем, существует ли уже пользователь
sudo -u postgres psql -tAc "SELECT 1 FROM pg_roles WHERE rolname='${DB_USER}'" | grep -q 1
if [ $? -ne 0 ]; then
  sudo -u postgres psql -c "CREATE USER ${DB_USER} WITH PASSWORD '${DB_PASS}';"
  echo -e "${GREEN}Пользователь базы данных ${DB_USER} создан${NC}"
else
  echo -e "${YELLOW}Пользователь ${DB_USER} уже существует${NC}"
fi

# Проверяем, существует ли уже база данных
sudo -u postgres psql -tAc "SELECT 1 FROM pg_database WHERE datname='${DB_NAME}'" | grep -q 1
if [ $? -ne 0 ]; then
  sudo -u postgres psql -c "CREATE DATABASE ${DB_NAME} OWNER ${DB_USER};"
  echo -e "${GREEN}База данных ${DB_NAME} создана${NC}"
else
  echo -e "${YELLOW}База данных ${DB_NAME} уже существует${NC}"
fi

sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE ${DB_NAME} TO ${DB_USER};"

# 6. Создание файла .env
echo -e "\n${BOLD}${BLUE}[6/10] Создание конфигурационного файла .env...${NC}"
cat > ${APP_PATH}/.env << EOF
# Настройки сервера
NODE_ENV=production
PORT=${PORT}
HOST=0.0.0.0
DOMAIN=${DOMAIN}

# Настройки базы данных
DATABASE_URL=postgresql://${DB_USER}:${DB_PASS}@localhost:5432/${DB_NAME}
PGHOST=localhost
PGPORT=5432
PGDATABASE=${DB_NAME}
PGUSER=${DB_USER}
PGPASSWORD=${DB_PASS}

# Секретный ключ для сессий
SESSION_SECRET=$(openssl rand -hex 32)
EOF

# 7. Настройка Nginx
echo -e "\n${BOLD}${BLUE}[7/10] Настройка Nginx...${NC}"
cat > /etc/nginx/sites-available/${DOMAIN} << EOF
server {
    listen 80;
    server_name ${DOMAIN} www.${DOMAIN};
    
    location / {
        proxy_pass http://localhost:${PORT};
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    # Кэширование статических файлов
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
        proxy_pass http://localhost:${PORT};
        expires 30d;
        add_header Cache-Control "public, no-transform";
    }
    
    # Увеличиваем лимит размера загружаемых файлов
    client_max_body_size 10M;
}
EOF

# Включаем сайт и проверяем конфигурацию
ln -sf /etc/nginx/sites-available/${DOMAIN} /etc/nginx/sites-enabled/
nginx -t && systemctl restart nginx

# 8. Настройка SSL с помощью Certbot
echo -e "\n${BOLD}${BLUE}[8/10] Настройка SSL-сертификата...${NC}"
certbot --nginx -d ${DOMAIN} -d www.${DOMAIN} --non-interactive --agree-tos --email admin@${DOMAIN}

# 9. Установка и настройка проекта
echo -e "\n${BOLD}${BLUE}[9/10] Установка зависимостей и настройка проекта...${NC}"
cd ${APP_PATH}

# Создание конфигурации PM2
cat > ${APP_PATH}/ecosystem.config.js << EOF
module.exports = {
  apps: [
    {
      name: 'atom-game-server',
      script: 'server/index.ts',
      interpreter: 'node',
      interpreter_args: '-r tsx',
      env: {
        NODE_ENV: 'production',
        PORT: ${PORT},
        HOST: '0.0.0.0',
        DOMAIN: '${DOMAIN}'
      },
      watch: false,
      max_memory_restart: '512M',
      exec_mode: 'fork',
      instances: 1,
      restart_delay: 3000
    }
  ]
};
EOF

# Установка зависимостей проекта
echo -e "${YELLOW}Установка зависимостей npm...${NC}"
npm install

# Инициализация базы данных
echo -e "${YELLOW}Инициализация базы данных...${NC}"
npm run db:push

# 10. Запуск приложения через PM2
echo -e "\n${BOLD}${BLUE}[10/10] Запуск приложения...${NC}"
pm2 start ecosystem.config.js
pm2 save
pm2 startup
systemctl enable pm2-root

# Создание скрипта обновления SSL
cat > ${APP_PATH}/renew-ssl.sh << 'EOF'
#!/bin/bash
certbot renew --quiet
systemctl restart nginx
EOF

chmod +x ${APP_PATH}/renew-ssl.sh

# Добавляем обновление сертификата в crontab
echo "0 3 * * * ${APP_PATH}/renew-ssl.sh" > /etc/cron.d/certbot-renew

# Изменение файлов компонентов для правильной работы с изображениями
echo -e "\n${YELLOW}Применение исправлений для загрузки изображений...${NC}"

# Исправление для partner-form.tsx если файл существует
if [ -f "${APP_PATH}/client/src/components/partner-form.tsx" ]; then
  sed -i 's/logoUrl: logoPreview || data.logoUrl || "",/logoUrl: logoPreview || "",/g' ${APP_PATH}/client/src/components/partner-form.tsx
  echo -e "${GREEN}Исправлен компонент формы партнеров${NC}"
fi

# Исправление для team-form.tsx если файл существует  
if [ -f "${APP_PATH}/client/src/components/team-form.tsx" ]; then
  sed -i 's/logoUrl: logoPreview || data.logoUrl || "",/logoUrl: logoPreview || "",/g' ${APP_PATH}/client/src/components/team-form.tsx
  echo -e "${GREEN}Исправлен компонент формы команд${NC}"
fi

# Исправление для ad-banner-form.tsx если файл существует
if [ -f "${APP_PATH}/client/src/components/ad-banner-form.tsx" ]; then
  sed -i 's/logoUrl: logoPreview || data.logoUrl || "",/logoUrl: logoPreview || "",/g' ${APP_PATH}/client/src/components/ad-banner-form.tsx
  echo -e "${GREEN}Исправлен компонент формы баннеров${NC}"
fi

# Перезапуск сервера с новыми исправлениями
pm2 restart atom-game-server

echo -e "\n${BOLD}${GREEN}=========================================================${NC}"
echo -e "${BOLD}${GREEN}       ATOM-GAME успешно установлен и запущен!           ${NC}"
echo -e "${BOLD}${GREEN}=========================================================${NC}"
echo -e "${GREEN}Сайт доступен по адресу: https://${DOMAIN}${NC}"
echo -e "${GREEN}Данные для входа в админ-панель:${NC}"
echo -e "${GREEN}Логин: ${ADMIN_USER}${NC}"
echo -e "${GREEN}Пароль: ${ADMIN_PASS}${NC}"
echo -e "\n${YELLOW}Полезные команды:${NC}"
echo -e "${YELLOW}* Перезапуск приложения: pm2 restart atom-game-server${NC}"
echo -e "${YELLOW}* Просмотр логов: pm2 logs atom-game-server${NC}"
echo -e "${YELLOW}* Статус приложения: pm2 status${NC}"
echo -e "${YELLOW}* Остановка приложения: pm2 stop atom-game-server${NC}"