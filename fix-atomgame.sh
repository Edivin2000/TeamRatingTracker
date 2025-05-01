#!/bin/bash

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

echo -e "${BOLD}${GREEN}=========================================================${NC}"
echo -e "${BOLD}${GREEN}       ATOM-GAME - Полное исправление системы            ${NC}"
echo -e "${BOLD}${GREEN}=========================================================${NC}"

# Конфигурационные параметры
APP_PATH="/var/www/atomgame"
PORT="5001"
DOMAIN="atomgameblk.ru"
GIT_REPO="https://github.com/Edivin2000/TeamRatingTracker.git"
DB_NAME="atomgame"
DB_USER="atomgame"
DB_PASS="AtomGame2025!"
ADMIN_USER="admin"
ADMIN_PASS="Atom&Game#2025!"

# Проверка root прав
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}Скрипт должен быть запущен с правами root${NC}"
  echo -e "${YELLOW}Выполните: sudo bash $0${NC}"
  exit 1
fi

# Шаг 1: Остановка сервисов и очистка
echo -e "\n${BOLD}${BLUE}[1/8] Остановка сервисов и очистка...${NC}"
# Остановка PM2 процессов
pm2 list | grep -q "atom-game-server"
if [ $? -eq 0 ]; then
  echo -e "${YELLOW}Останавливаем PM2 процессы...${NC}"
  pm2 delete atom-game-server
  pm2 save
fi

# Проверяем директорию
if [ -d "$APP_PATH" ]; then
  echo -e "${YELLOW}Очистка директории $APP_PATH...${NC}"
  rm -rf ${APP_PATH}/*
else
  echo -e "${YELLOW}Создание директории $APP_PATH...${NC}"
  mkdir -p ${APP_PATH}
fi

# Шаг 2: Загрузка новой версии кода
echo -e "\n${BOLD}${BLUE}[2/8] Загрузка новой версии кода...${NC}"
echo -e "${YELLOW}Клонирование репозитория во временную директорию...${NC}"
TMP_DIR="/tmp/atom-temp-$(date +%s)"
git clone ${GIT_REPO} ${TMP_DIR}
if [ $? -ne 0 ]; then
  echo -e "${RED}Ошибка клонирования репозитория. Установка прервана.${NC}"
  exit 1
fi

echo -e "${YELLOW}Копирование файлов в директорию $APP_PATH...${NC}"
cp -R ${TMP_DIR}/* ${APP_PATH}/
rm -rf ${TMP_DIR}

# Шаг 3: Настройка базы данных
echo -e "\n${BOLD}${BLUE}[3/8] Настройка базы данных PostgreSQL...${NC}"
# Проверяем существующую базу
echo -e "${YELLOW}Проверка существующей базы данных...${NC}"
sudo -u postgres psql -tAc "SELECT 1 FROM pg_database WHERE datname='${DB_NAME}'" | grep -q 1
if [ $? -eq 0 ]; then
  echo -e "${YELLOW}Пересоздание базы данных ${DB_NAME}...${NC}"
  
  # Отключаем все соединения с базой
  sudo -u postgres psql -c "SELECT pg_terminate_backend(pg_stat_activity.pid) FROM pg_stat_activity WHERE pg_stat_activity.datname = '${DB_NAME}' AND pid <> pg_backend_pid();"
  
  # Удаляем базу данных
  sudo -u postgres psql -c "DROP DATABASE IF EXISTS ${DB_NAME};"
  
  # Удаляем пользователя, если он существует
  sudo -u postgres psql -tAc "SELECT 1 FROM pg_roles WHERE rolname='${DB_USER}'" | grep -q 1
  if [ $? -eq 0 ]; then
    sudo -u postgres psql -c "DROP ROLE IF EXISTS ${DB_USER};"
  fi
fi

# Создаем пользователя и базу заново
sudo -u postgres psql -c "CREATE USER ${DB_USER} WITH PASSWORD '${DB_PASS}';"
sudo -u postgres psql -c "CREATE DATABASE ${DB_NAME} OWNER ${DB_USER};"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE ${DB_NAME} TO ${DB_USER};"
echo -e "${GREEN}База данных настроена${NC}"

# Шаг 4: Создание файла .env
echo -e "\n${BOLD}${BLUE}[4/8] Создание конфигурационного файла .env...${NC}"
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
echo -e "${GREEN}Конфигурационный файл создан${NC}"

# Шаг 5: Настройка запуска через CommonJS
echo -e "\n${BOLD}${BLUE}[5/8] Настройка скрипта запуска...${NC}"
cat > ${APP_PATH}/start-server.cjs << 'EOF'
// Простой скрипт запуска сервера напрямую через CommonJS
const { exec, spawn } = require('child_process');

// Установка переменных окружения
process.env.PORT = 5001;
process.env.HOST = '0.0.0.0';
process.env.NODE_ENV = 'production';
process.env.DOMAIN = 'atomgameblk.ru';

console.log('Запуск ATOM-GAME сервера с настройками:');
console.log(`PORT: ${process.env.PORT}`);
console.log(`HOST: ${process.env.HOST}`);
console.log(`NODE_ENV: ${process.env.NODE_ENV}`);

// Функция для изменения порта в server/index.ts если он жестко прописан
const patchServerFile = () => {
  const fs = require('fs');
  const path = require('path');
  
  const serverFile = path.join(process.cwd(), 'server', 'index.ts');
  if (fs.existsSync(serverFile)) {
    let content = fs.readFileSync(serverFile, 'utf8');
    
    // Заменяем жестко прописанный порт 8080 на 5001
    if (content.includes('process.env.PORT || 8080')) {
      console.log('Исправляем порт в server/index.ts с 8080 на 5001');
      content = content.replace('process.env.PORT || 8080', 'process.env.PORT || 5001');
      fs.writeFileSync(serverFile, content);
    }
  }
};

// Патчим файл сервера
patchServerFile();

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

# Создание скрипта для перезапуска
cat > ${APP_PATH}/restart-server.sh << 'EOF'
#!/bin/bash

# Цвета для вывода
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Перезапуск ATOM-GAME сервера...${NC}"

# Переходим в директорию проекта
cd /var/www/atomgame

# Останавливаем PM2 процесс
echo -e "${YELLOW}Останавливаем текущий сервер...${NC}"
pm2 delete atom-game-server 2>/dev/null || true

# Запускаем сервер
echo -e "${YELLOW}Запускаем сервер...${NC}"
pm2 start start-server.cjs --name atom-game-server

# Сохраняем конфигурацию PM2
pm2 save

echo -e "${GREEN}Сервер успешно перезапущен${NC}"
echo -e "${YELLOW}Проверьте статус: pm2 status${NC}"
echo -e "${YELLOW}Логи: pm2 logs atom-game-server${NC}"
EOF

# Установка прав на выполнение
chmod +x ${APP_PATH}/restart-server.sh
echo -e "${GREEN}Скрипты для запуска созданы${NC}"

# Шаг 6: Настройка Nginx
echo -e "\n${BOLD}${BLUE}[6/8] Настройка Nginx...${NC}"
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

# Настройка SSL с помощью Certbot
echo -e "\n${BOLD}${BLUE}[7/8] Настройка SSL-сертификата...${NC}"
certbot --nginx -d ${DOMAIN} -d www.${DOMAIN} --non-interactive --agree-tos --email admin@${DOMAIN}

# Шаг 8: Установка зависимостей и запуск
echo -e "\n${BOLD}${BLUE}[8/8] Установка зависимостей и запуск сервера...${NC}"
cd ${APP_PATH}

# Установка зависимостей
echo -e "${YELLOW}Установка зависимостей npm...${NC}"
npm install

# Инициализация базы данных
echo -e "${YELLOW}Инициализация базы данных...${NC}"
npm run db:push

# Запуск сервера
echo -e "${YELLOW}Запуск сервера...${NC}"
pm2 delete atom-game-server 2>/dev/null || true
pm2 start start-server.cjs --name atom-game-server
pm2 save
pm2 startup
systemctl enable pm2-root

# Применение исправлений для загрузки изображений
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

# Финальная информация
echo -e "\n${BOLD}${GREEN}=========================================================${NC}"
echo -e "${BOLD}${GREEN}       ATOM-GAME успешно установлен и запущен!           ${NC}"
echo -e "${BOLD}${GREEN}=========================================================${NC}"
echo -e "${GREEN}Сайт доступен по адресу: https://${DOMAIN}${NC}"
echo -e "${GREEN}Данные для входа в админ-панель:${NC}"
echo -e "${GREEN}Логин: ${ADMIN_USER}${NC}"
echo -e "${GREEN}Пароль: ${ADMIN_PASS}${NC}"
echo -e "\n${YELLOW}Полезные команды:${NC}"
echo -e "${YELLOW}* Перезапуск приложения: cd ${APP_PATH} && ./restart-server.sh${NC}"
echo -e "${YELLOW}* Просмотр логов: pm2 logs atom-game-server${NC}"
echo -e "${YELLOW}* Статус приложения: pm2 status${NC}"
echo -e "${YELLOW}* Остановка приложения: pm2 stop atom-game-server${NC}"

# Проверка статуса
echo -e "\n${BOLD}${BLUE}Проверка статуса запущенных сервисов:${NC}"
pm2 status
echo -e "\n${YELLOW}Первые 10 строк логов:${NC}"
pm2 logs atom-game-server --lines 10 | head -n 10