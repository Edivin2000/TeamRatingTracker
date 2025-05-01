# Подробная инструкция по установке ATOM-GAME на ваш сервер

Эта инструкция поможет вам установить вашу рейтинговую систему ATOM-GAME с нуля на любой Linux-сервер.

## Что понадобится

- Сервер с Linux (лучше всего Ubuntu 20.04 или новее)
- Пользователь с root-правами
- Ваше доменное имя, уже направленное на IP-адрес сервера

## Шаг 1: Подготовка сервера

Подключитесь к вашему серверу через SSH и выполните:

```bash
# Обновление системы
sudo apt update && sudo apt upgrade -y

# Установка необходимых программ
sudo apt install -y curl git nginx postgresql postgresql-contrib build-essential
```

## Шаг 2: Установка Node.js

```bash
# Добавление репозитория Node.js
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -

# Установка Node.js
sudo apt install -y nodejs

# Проверка установки
node -v  # Должно показать v18.x.x
npm -v   # Должно показать 8.x.x или выше
```

## Шаг 3: Настройка базы данных PostgreSQL

```bash
# Создание пользователя и базы данных
sudo -u postgres psql -c "CREATE USER atomgame WITH ENCRYPTED PASSWORD 'ВашСложныйПароль123';"
sudo -u postgres psql -c "CREATE DATABASE atomgame OWNER atomgame;"
```

❗ Обязательно замените `ВашСложныйПароль123` на действительно сложный пароль и запомните его.

## Шаг 4: Копирование файлов проекта

```bash
# Создание директории для проекта
sudo mkdir -p /var/www/atomgame
sudo chown -R $USER:$USER /var/www/atomgame

# Переход в директорию
cd /var/www/atomgame
```

Теперь вам нужно скопировать файлы с Replit на ваш сервер. Есть несколько способов:

### Вариант 1: Загрузка через архив (самый простой)
1. На Replit нажмите кнопку "Download as zip" в меню проекта
2. Загрузите архив на ваш компьютер
3. Используйте SCP для загрузки архива на сервер:
   ```bash
   # Выполните эту команду на своём компьютере, не на сервере
   scp ваш_архив.zip пользователь@адрес_сервера:/var/www/atomgame/
   ```
4. На сервере распакуйте архив:
   ```bash
   cd /var/www/atomgame
   unzip ваш_архив.zip
   ```

### Вариант 2: Использование Git (если у вас есть Git-репозиторий)
```bash
git clone ваш-репозиторий-url .
```

## Шаг 5: Установка зависимостей проекта

```bash
# Установка менеджера процессов PM2
sudo npm install -g pm2

# Установка зависимостей проекта
cd /var/www/atomgame
npm install
```

## Шаг 6: Настройка переменных окружения

Создайте файл `.env` с настройками:

```bash
cat > .env << EOF
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

❗ Замените:
- `ВашСложныйПароль123` на пароль, который вы создали в шаге 3
- `ОченьСекретныйКлюч123` на другую случайную строку для безопасности сессий

## Шаг 7: Миграция базы данных и сборка проекта

```bash
# Перейдите в директорию проекта
cd /var/www/atomgame

# Применение схемы базы данных
npm run db:push

# Сборка проекта
npm run build
```

## Шаг 8: Создание конфигурации Nginx

Создайте файл конфигурации Nginx:

```bash
sudo nano /etc/nginx/sites-available/atomgame
```

Скопируйте и вставьте следующую конфигурацию (замените ваш-домен.ру на ваше доменное имя):

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

Сохраните файл (Ctrl+X, затем Y).

Активируйте конфигурацию:

```bash
sudo ln -sf /etc/nginx/sites-available/atomgame /etc/nginx/sites-enabled/
sudo nginx -t  # Проверка конфигурации
sudo systemctl reload nginx  # Применение конфигурации
```

## Шаг 9: Настройка PM2 для запуска и автозапуска

Создайте файл конфигурации PM2:

```bash
cat > /var/www/atomgame/ecosystem.config.js << EOF
module.exports = {
  apps: [
    {
      name: "atomgame",
      script: "dist/index.js",
      instances: 1,
      autorestart: true,
      watch: false,
      env: {
        NODE_ENV: "production",
        PORT: 3000,
        HOST: "0.0.0.0",
      },
      max_memory_restart: "500M",
      error_file: "logs/error.log",
      out_file: "logs/output.log",
      log_date_format: "YYYY-MM-DD HH:mm Z",
    },
  ],
};
EOF
```

Создайте директорию для логов:

```bash
mkdir -p /var/www/atomgame/logs
```

Запустите приложение:

```bash
cd /var/www/atomgame
pm2 start ecosystem.config.js

# Настройка автозапуска
pm2 startup
# Выполните команду, которую выведет предыдущая команда
pm2 save
```

## Шаг 10: Настройка HTTPS (SSL)

```bash
# Установка Certbot
sudo apt install -y certbot python3-certbot-nginx

# Получение сертификата
sudo certbot --nginx -d ваш-домен.ру -d www.ваш-домен.ру

# Следуйте инструкциям на экране
```

## Шаг 11: Проверка

Откройте в браузере ваш домен (https://ваш-домен.ру) и убедитесь, что сайт работает корректно.

## Полезные команды для управления

### Перезапуск приложения
```bash
pm2 restart atomgame
```

### Просмотр логов
```bash
pm2 logs atomgame
```

### Обновление приложения
```bash
cd /var/www/atomgame
git pull  # если используете Git
# или загрузите новые файлы

npm install  # установка новых зависимостей
npm run db:push  # обновление базы данных
npm run build  # пересборка проекта
pm2 restart atomgame  # перезапуск
```

### Резервное копирование базы данных
```bash
mkdir -p /var/backups/atomgame
pg_dump -U atomgame atomgame > /var/backups/atomgame/backup_$(date +"%Y%m%d").sql
```

## Решение проблем

Если сайт не работает:

1. Проверьте логи приложения: `pm2 logs atomgame`
2. Проверьте логи Nginx: `sudo tail -f /var/log/nginx/atomgame.error.log`
3. Проверьте статус сервисов:
   ```bash
   sudo systemctl status nginx
   sudo systemctl status postgresql
   pm2 status
   ```

Если возникнут вопросы по установке, сообщите мне!