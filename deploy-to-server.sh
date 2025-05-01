#!/bin/bash

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

DOMAIN="atomgameblk.ru"
SERVER_IP="193.109.78.85"
PORT="5001"
APP_PATH="/var/www/atomgame"
NODE_VERSION="20"

echo -e "${BOLD}${GREEN}=========================================================${NC}"
echo -e "${BOLD}${GREEN}       ATOM-GAME - Установка и настройка сервера         ${NC}"
echo -e "${BOLD}${GREEN}=========================================================${NC}"
echo -e "${YELLOW}Данный скрипт установит и настроит сервер ATOM-GAME${NC}"
echo -e "${YELLOW}Домен: ${DOMAIN}${NC}"
echo -e "${YELLOW}IP: ${SERVER_IP}${NC}"
echo -e "${YELLOW}Порт: ${PORT}${NC}"
echo -e "${YELLOW}Установка будет произведена в: ${APP_PATH}${NC}"
echo ""

# Проверка если скрипт запущен с правами root
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}Этот скрипт должен быть запущен с правами root${NC}"
  echo -e "${YELLOW}Выполните: sudo bash $0${NC}"
  exit 1
fi

# Шаг 1: Обновление системы
echo -e "\n${BLUE}[1/9] Обновление системы...${NC}"
apt update && apt upgrade -y

# Шаг 2: Установка необходимых пакетов
echo -e "\n${BLUE}[2/9] Установка необходимых пакетов...${NC}"
apt install -y curl wget git unzip nginx certbot python3-certbot-nginx postgresql

# Шаг 3: Установка Node.js
echo -e "\n${BLUE}[3/9] Установка Node.js ${NODE_VERSION}...${NC}"
curl -fsSL https://deb.nodesource.com/setup_${NODE_VERSION}.x | bash -
apt install -y nodejs
npm install -g pm2

# Шаг 4: Клонирование репозитория
echo -e "\n${BLUE}[4/9] Создание директории приложения...${NC}"
mkdir -p ${APP_PATH}
echo -e "${YELLOW}Примечание: Вам нужно скопировать файлы проекта в ${APP_PATH}${NC}"
echo -e "${YELLOW}Используйте команду: git clone [ваш-репозиторий] ${APP_PATH}${NC}"

# Шаг 5: Настройка PostgreSQL
echo -e "\n${BLUE}[5/9] Настройка базы данных PostgreSQL...${NC}"
# Создание пользователя и БД
sudo -u postgres psql -c "CREATE USER atomgame WITH PASSWORD 'AtomGame2025!';"
sudo -u postgres psql -c "CREATE DATABASE atomgame OWNER atomgame;"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE atomgame TO atomgame;"

# Настройка файла .env
cat > ${APP_PATH}/.env << EOF
# Настройки сервера
NODE_ENV=production
PORT=${PORT}
HOST=0.0.0.0
DOMAIN=${DOMAIN}

# Настройки базы данных
DATABASE_URL=postgresql://atomgame:AtomGame2025!@localhost:5432/atomgame
PGHOST=localhost
PGPORT=5432
PGDATABASE=atomgame
PGUSER=atomgame
PGPASSWORD=AtomGame2025!

# Секретный ключ для сессий
SESSION_SECRET=$(openssl rand -hex 32)
EOF

# Шаг 6: Настройка Nginx
echo -e "\n${BLUE}[6/9] Настройка Nginx...${NC}"
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

# Шаг 7: Настройка SSL с помощью Certbot
echo -e "\n${BLUE}[7/9] Настройка SSL-сертификата...${NC}"
certbot --nginx -d ${DOMAIN} -d www.${DOMAIN} --non-interactive --agree-tos --email admin@${DOMAIN}

# Шаг 8: Настройка PM2 для запуска приложения
echo -e "\n${BLUE}[8/9] Настройка PM2 для приложения...${NC}"
cat > ${APP_PATH}/ecosystem.config.js << EOF
module.exports = {
  apps: [
    {
      name: 'atom-game-server',
      script: 'server/index.ts',
      interpreter: 'tsx',
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

# Шаг 9: Инструкции по завершению установки
echo -e "\n${BLUE}[9/9] Создание скрипта для завершения установки...${NC}"
cat > ${APP_PATH}/finish-setup.sh << 'EOF'
#!/bin/bash

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

APP_DIR=$(dirname "$(readlink -f "$0")")
cd "$APP_DIR"

echo -e "${BOLD}${GREEN}===============================================${NC}"
echo -e "${BOLD}${GREEN}       ATOM-GAME - Завершение установки        ${NC}"
echo -e "${BOLD}${GREEN}===============================================${NC}"

# Установка зависимостей
echo -e "\n${BLUE}[1/4] Установка зависимостей проекта...${NC}"
npm install

# Настройка базы данных
echo -e "\n${BLUE}[2/4] Настройка базы данных...${NC}"
npm run db:push

# Сборка проекта
echo -e "\n${BLUE}[3/4] Сборка проекта...${NC}"
npm run build

# Запуск приложения через PM2
echo -e "\n${BLUE}[4/4] Запуск приложения...${NC}"
pm2 start ecosystem.config.js
pm2 save

echo -e "\n${GREEN}=========================================================${NC}"
echo -e "${GREEN}Установка ATOM-GAME успешно завершена!${NC}"
echo -e "${GREEN}Сайт доступен по адресу: https://atomgameblk.ru${NC}"
echo -e "${GREEN}Логин админа: admin${NC}"
echo -e "${GREEN}Пароль админа: Atom&Game#2025!${NC}"
echo -e "${GREEN}=========================================================${NC}"

echo -e "\n${YELLOW}Полезные команды:${NC}"
echo -e "${YELLOW}* Перезапуск приложения: pm2 restart atom-game-server${NC}"
echo -e "${YELLOW}* Просмотр логов: pm2 logs atom-game-server${NC}"
echo -e "${YELLOW}* Статус приложения: pm2 status${NC}"
echo -e "${YELLOW}* Остановка приложения: pm2 stop atom-game-server${NC}"
EOF

chmod +x ${APP_PATH}/finish-setup.sh

# Добавляем скрипт для обновления SSL-сертификатов
cat > ${APP_PATH}/renew-ssl.sh << 'EOF'
#!/bin/bash
certbot renew --quiet
systemctl restart nginx
EOF

chmod +x ${APP_PATH}/renew-ssl.sh

# Добавляем в crontab задачу для обновления сертификатов
echo "0 3 * * * ${APP_PATH}/renew-ssl.sh" > /etc/cron.d/certbot-renew

echo -e "\n${GREEN}======================================================================${NC}"
echo -e "${GREEN}Базовая настройка сервера успешно завершена!${NC}"
echo -e "${GREEN}======================================================================${NC}"
echo -e "\n${YELLOW}Следующие шаги:${NC}"
echo -e "${YELLOW}1. Скопируйте файлы вашего приложения в ${APP_PATH}${NC}"
echo -e "${YELLOW}   Например: git clone https://github.com/ваш-репозиторий.git ${APP_PATH}${NC}"
echo -e "${YELLOW}2. Перейдите в директорию приложения: cd ${APP_PATH}${NC}"
echo -e "${YELLOW}3. Запустите скрипт завершения установки: sudo bash ./finish-setup.sh${NC}"
echo -e "\n${YELLOW}После этого ваш сайт будет доступен по адресу: https://${DOMAIN}${NC}"