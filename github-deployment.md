# Инструкция по развертыванию ATOM-GAME через GitHub

Эта инструкция поможет вам загрузить проект ATOM-GAME на GitHub и затем развернуть его на вашем сервере.

## Шаг 1: Загрузка проекта на GitHub

### 1.1 Создание репозитория на GitHub

1. Перейдите на [GitHub](https://github.com/) и войдите в свой аккаунт.
2. Нажмите на кнопку "+" в правом верхнем углу и выберите "New repository".
3. Заполните информацию о репозитории:
   - **Repository name**: `atom-game` (или любое другое имя)
   - **Description**: `ATOM-GAME рейтинговая система`
   - **Visibility**: Выберите `Private` (приватный), чтобы ваш код не был публичным
   - Не ставьте галочку "Initialize this repository with a README"
4. Нажмите кнопку "Create repository"

### 1.2 Подготовка проекта в Replit к загрузке на GitHub

1. В Replit создайте файл `.gitignore` со следующим содержимым:

```
node_modules/
.env
dist/
logs/
backups/
.DS_Store
```

2. Инициализируйте Git-репозиторий и загрузите файлы на GitHub:

```bash
# В терминале Replit выполните следующие команды
git init
git add .
git commit -m "Первоначальная загрузка"
git branch -M main

# Подключение к удаленному репозиторию (замените YOUR_USERNAME и YOUR_REPO на ваши данные)
git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPO.git

# Загрузка файлов на GitHub
git push -u origin main
```

При запросе учетных данных введите ваше имя пользователя GitHub и пароль (или токен доступа).

## Шаг 2: Настройка сервера и клонирование репозитория

### 2.1 Подготовка сервера

1. Подключитесь к вашему серверу через SSH:

```bash
ssh ваш_пользователь@адрес_вашего_сервера
```

2. Обновите пакеты и установите необходимые зависимости:

```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y git curl nginx postgresql postgresql-contrib build-essential nodejs npm
```

### 2.2 Установка Node.js 18.x

```bash
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install -y nodejs
```

### 2.3 Клонирование репозитория с GitHub

```bash
# Создайте директорию для проекта
sudo mkdir -p /var/www/atomgame
sudo chown -R $USER:$USER /var/www/atomgame

# Клонирование репозитория из GitHub
cd /var/www/atomgame
git clone https://github.com/YOUR_USERNAME/YOUR_REPO.git .
```

## Шаг 3: Настройка базы данных и установка зависимостей

### 3.1 Настройка PostgreSQL

```bash
# Создание пользователя и базы данных
sudo -u postgres psql -c "CREATE USER atomgame WITH ENCRYPTED PASSWORD 'ВашСложныйПароль123';"
sudo -u postgres psql -c "CREATE DATABASE atomgame OWNER atomgame;"
```

### 3.2 Настройка переменных окружения

```bash
# Создание файла .env
cat > /var/www/atomgame/.env << EOF
# Основные настройки
NODE_ENV=production
PORT=3000

# База данных PostgreSQL
PGUSER=atomgame
PGPASSWORD=ВашСложныйПароль123
PGDATABASE=atomgame
PGHOST=localhost
PGPORT=5432
DATABASE_URL=postgresql://atomgame:ВашСложныйПароль123@localhost:5432/atomgame

# Безопасность
SESSION_SECRET=ОченьСекретныйКлюч123
EOF
```

Замените `ВашСложныйПароль123` и `ОченьСекретныйКлюч123` на свои безопасные значения.

### 3.3 Установка зависимостей и запуск миграций

```bash
# Установка PM2 глобально
sudo npm install -g pm2

# Установка зависимостей проекта
cd /var/www/atomgame
npm install

# Миграция базы данных
npm run db:push

# Сборка проекта
npm run build
```

## Шаг 4: Настройка PM2 и Nginx

### 4.1 Настройка PM2

```bash
# Создание директории для логов
mkdir -p /var/www/atomgame/logs

# Запуск приложения с PM2
cd /var/www/atomgame
pm2 start ecosystem.config.js

# Настройка автозапуска
pm2 startup
# Выполните команду, которую выведет предыдущая команда
pm2 save
```

### 4.2 Настройка Nginx

```bash
# Создание конфигурации Nginx
sudo nano /etc/nginx/sites-available/atomgame
```

Вставьте следующую конфигурацию (замените `ваш-домен.ру` на ваш домен):

```
server {
    listen 80;
    server_name ваш-домен.ру www.ваш-домен.ру;
    
    # Корневая директория с файлами
    root /var/www/atomgame/dist;
    
    # Файлы логов
    access_log /var/log/nginx/atomgame.access.log;
    error_log /var/log/nginx/atomgame.error.log;
    
    # Включение сжатия
    gzip on;
    gzip_types text/plain application/javascript application/x-javascript text/javascript text/xml text/css;
    
    # Проксирование API запросов
    location /api {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }
    
    # Для остальных запросов (фронтенд SPA)
    location / {
        try_files $uri $uri/ /index.html;
        add_header Cache-Control "public, max-age=3600";
    }
    
    # Кэширование статических файлов
    location ~* \.(jpg|jpeg|png|gif|ico|css|js|svg)$ {
        expires 7d;
        add_header Cache-Control "public, max-age=604800";
    }
}
```

Активируйте конфигурацию:

```bash
sudo ln -sf /etc/nginx/sites-available/atomgame /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

### 4.3 Настройка SSL (HTTPS)

```bash
sudo apt install -y certbot python3-certbot-nginx
sudo certbot --nginx -d ваш-домен.ру -d www.ваш-домен.ру
```

## Шаг 5: Настройка автоматического обновления через GitHub

### 5.1 Создание скрипта обновления из GitHub

```bash
cat > /var/www/atomgame/update-from-github.sh << 'EOF'
#!/bin/bash

# Скрипт обновления ATOM-GAME из GitHub репозитория
set -e

echo "=== Начало обновления из GitHub ==="

# Проверка директории проекта
if [ ! -d "/var/www/atomgame" ]; then
  echo "Ошибка: Директория проекта не найдена!"
  exit 1
fi

# Переход в директорию проекта
cd /var/www/atomgame

# Создание резервной копии
echo "Создание резервной копии базы данных..."
mkdir -p backups
source <(grep -v '^#' .env | sed 's/^/export /')
BACKUP_FILE="backups/backup_$(date +"%Y%m%d_%H%M%S").sql"
PGPASSWORD=$PGPASSWORD pg_dump -U $PGUSER -h $PGHOST -p $PGPORT $PGDATABASE > $BACKUP_FILE
echo "Резервная копия создана: $BACKUP_FILE"

# Остановка приложения
echo "Остановка приложения..."
pm2 stop atomgame

# Сохранение файла .env
cp .env .env.backup

# Получение последних изменений из GitHub
echo "Получение обновлений из GitHub..."
git fetch
git stash
git pull

# Восстановление файла .env
cp .env.backup .env

# Установка зависимостей
echo "Обновление зависимостей..."
npm install

# Миграция базы данных
echo "Обновление базы данных..."
npm run db:push

# Сборка проекта
echo "Пересборка проекта..."
npm run build

# Запуск приложения
echo "Запуск приложения..."
pm2 restart atomgame

echo "=== Обновление завершено ==="
EOF

chmod +x /var/www/atomgame/update-from-github.sh
```

### 5.2 Настройка автоматического обновления по webhook

Если вы хотите настроить автоматическое обновление при push в репозиторий, вы можете использовать webhook с GitHub:

1. Установите необходимые пакеты:

```bash
cd /var/www/atomgame
npm install github-webhook-handler
```

2. Создайте файл webhook-server.js:

```bash
cat > /var/www/atomgame/webhook-server.js << 'EOF'
const http = require('http');
const createHandler = require('github-webhook-handler');
const { exec } = require('child_process');

// Замените на свой секретный ключ
const handler = createHandler({ path: '/webhook', secret: 'ваш_секретный_ключ' });

http.createServer((req, res) => {
  handler(req, res, (err) => {
    res.statusCode = 404;
    res.end('no such location');
  });
}).listen(7777);

handler.on('error', (err) => {
  console.error('Ошибка:', err.message);
});

handler.on('push', (event) => {
  console.log('Получено событие push из GitHub');
  
  if (event.payload.ref === 'refs/heads/main') {
    console.log('Запуск скрипта обновления...');
    exec('./update-from-github.sh', (error, stdout, stderr) => {
      if (error) {
        console.error(`Ошибка: ${error.message}`);
        return;
      }
      if (stderr) {
        console.error(`Stderr: ${stderr}`);
      }
      console.log(`Вывод: ${stdout}`);
    });
  }
});

console.log('Webhook-сервер запущен на порту 7777');
EOF
```

3. Настройте PM2 для запуска webhook-сервера:

```bash
pm2 start webhook-server.js --name="github-webhook"
pm2 save
```

4. Добавьте webhook в настройках вашего GitHub репозитория:
   - Перейдите в Settings > Webhooks > Add webhook
   - Payload URL: `http://ваш-домен.ру:7777/webhook`
   - Content type: `application/json`
   - Secret: тот же секретный ключ, что вы указали в webhook-server.js
   - Выберите: "Just the push event"
   - Активируйте webhook

## Шаг 6: Обновление проекта с вашего компьютера

После настройки репозитория на GitHub, вы можете обновлять проект, работая с ним на своем компьютере:

1. Клонируйте репозиторий на ваш компьютер:

```bash
git clone https://github.com/YOUR_USERNAME/YOUR_REPO.git atom-game
cd atom-game
```

2. Внесите изменения в проект на вашем компьютере
3. Загрузите изменения на GitHub:

```bash
git add .
git commit -m "Описание ваших изменений"
git push
```

4. Обновите сайт на сервере:
   - Если вы настроили webhook, сайт обновится автоматически
   - Если нет, подключитесь к серверу и выполните:
   ```bash
   cd /var/www/atomgame
   ./update-from-github.sh
   ```

## Шаг 7: Проверка работы сайта

Откройте ваш сайт в браузере по адресу `https://ваш-домен.ру` и убедитесь, что он работает корректно.

## Полезные команды для управления сайтом

### Проверка состояния приложения
```bash
pm2 status
```

### Просмотр логов
```bash
pm2 logs atomgame
```

### Перезапуск приложения
```bash
pm2 restart atomgame
```

### Проверка состояния Nginx
```bash
sudo systemctl status nginx
```

### Обновление SSL-сертификата (автоматически происходит раз в 90 дней)
```bash
sudo certbot renew
```