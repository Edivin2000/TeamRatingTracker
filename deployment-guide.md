# Руководство по развертыванию ATOM-GAME на вашем сервере

Это пошаговое руководство поможет вам установить и запустить ATOM-GAME на вашем сервере.

## Необходимые условия

- Linux сервер (Ubuntu 20.04+ или Debian 11+ рекомендуется)
- Root-доступ или пользователь с sudo правами
- Доменное имя, настроенное на ваш сервер (если вы планируете использовать SSL)

## Шаг 1: Подготовка сервера

Подключитесь к серверу через SSH и обновите систему:

```bash
sudo apt update
sudo apt upgrade -y
```

Установите необходимые пакеты:

```bash
sudo apt install -y curl git nginx postgresql postgresql-contrib
```

## Шаг 2: Установка Node.js

Установите Node.js версии 18.x:

```bash
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install -y nodejs
```

Проверьте установку:

```bash
node -v  # Должно показать v18.x.x
npm -v   # Должно показать 8.x.x или выше
```

## Шаг 3: Настройка PostgreSQL

Создайте пользователя и базу данных:

```bash
sudo -u postgres psql -c "CREATE USER atomgame WITH ENCRYPTED PASSWORD 'Создайте_сложный_пароль';"
sudo -u postgres psql -c "CREATE DATABASE atomgame OWNER atomgame;"
```

## Шаг 4: Загрузка проекта

Создайте директорию для проекта и клонируйте репозиторий (или скопируйте файлы с Replit):

```bash
sudo mkdir -p /var/www/atomgameblk
sudo chown -R $USER:$USER /var/www/atomgameblk
cd /var/www/atomgameblk

# Если у вас есть Git репозиторий:
git clone ваш-репозиторий-url .

# Или скопируйте файлы с Replit
# (Вам нужно будет загрузить файлы на сервер через scp, rsync, или другой метод)
```

## Шаг 5: Установка зависимостей

Установите PM2 глобально и установите зависимости проекта:

```bash
sudo npm install -g pm2
cd /var/www/atomgameblk
npm install
```

## Шаг 6: Настройка переменных окружения

Создайте файл .env:

```bash
cat > .env << EOF
# Основные настройки
NODE_ENV=production
PORT=3000

# База данных PostgreSQL
PGUSER=atomgame
PGPASSWORD=Создайте_сложный_пароль
PGDATABASE=atomgame
PGHOST=localhost
PGPORT=5432
DATABASE_URL=postgresql://atomgame:Создайте_сложный_пароль@localhost:5432/atomgame

# Безопасность
SESSION_SECRET=Генерируйте_случайную_строку
EOF
```

Замените `Создайте_сложный_пароль` и `Генерируйте_случайную_строку` своими значениями.

## Шаг 7: Миграция базы данных и сборка проекта

Выполните миграцию базы данных и соберите проект:

```bash
cd /var/www/atomgameblk
npm run db:push
npm run build
```

## Шаг 8: Настройка PM2

Убедитесь, что файл ecosystem.config.js содержит правильные настройки:

```js
module.exports = {
  apps: [
    {
      name: "atom-game-blk",
      script: "dist/index.js",
      instances: 1,
      autorestart: true,
      watch: false,
      env: {
        NODE_ENV: "production",
        PORT: 3000,
        HOST: "0.0.0.0",
      },
      exp_backoff_restart_delay: 100,
      max_memory_restart: "500M",
      time: true,
      merge_logs: true,
      error_file: "logs/pm2_error.log",
      out_file: "logs/pm2_output.log",
      log_date_format: "YYYY-MM-DD HH:mm Z",
    },
  ],
};
```

Создайте директорию для логов:

```bash
mkdir -p /var/www/atomgameblk/logs
```

Запустите приложение с помощью PM2:

```bash
cd /var/www/atomgameblk
pm2 start ecosystem.config.js
pm2 startup
pm2 save
```

## Шаг 9: Настройка Nginx

Скопируйте конфигурационный файл nginx:

```bash
sudo cp /var/www/atomgameblk/nginx.conf /etc/nginx/sites-available/atomgameblk
```

Отредактируйте файл, изменив доменное имя на ваше:

```bash
sudo nano /etc/nginx/sites-available/atomgameblk
```

Замените `your-domain.com` в конфигурации на ваше доменное имя.

Активируйте конфигурацию и перезапустите Nginx:

```bash
sudo ln -sf /etc/nginx/sites-available/atomgameblk /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

## Шаг 10: Настройка SSL (опционально, но рекомендуется)

Установите Certbot:

```bash
sudo apt install -y certbot python3-certbot-nginx
```

Получите SSL-сертификат:

```bash
sudo certbot --nginx -d ваш-домен.com -d www.ваш-домен.com
```

Следуйте инструкциям Certbot для завершения установки.

## Шаг 11: Проверка развертывания

Откройте в браузере ваш домен и убедитесь, что приложение работает правильно.

## Обновление приложения

Для обновления приложения вы можете использовать следующий процесс:

1. Остановите приложение: `pm2 stop atom-game-blk`
2. Обновите код (с git или копированием файлов)
3. Установите новые зависимости: `npm install`
4. Внесите изменения в базу данных (если нужно): `npm run db:push`
5. Пересоберите проект: `npm run build`
6. Перезапустите приложение: `pm2 restart atom-game-blk`

## Резервное копирование

Регулярно создавайте резервные копии базы данных:

```bash
# Создайте директорию для резервных копий
mkdir -p /var/backups/atomgame

# Создайте резервную копию базы данных
pg_dump -U atomgame atomgame > /var/backups/atomgame/backup_$(date +"%Y%m%d").sql
```

Вы можете настроить автоматическое резервное копирование с помощью cron.

## Устранение неполадок

### Проверка логов приложения

```bash
pm2 logs atom-game-blk
```

### Проверка логов Nginx

```bash
sudo tail -f /var/log/nginx/atomgameblk.error.log
```

### Перезапуск сервисов

```bash
# Перезапуск приложения
pm2 restart atom-game-blk

# Перезапуск Nginx
sudo systemctl restart nginx

# Перезапуск PostgreSQL
sudo systemctl restart postgresql
```

Если у вас возникнут другие вопросы по развертыванию, пожалуйста, обращайтесь!