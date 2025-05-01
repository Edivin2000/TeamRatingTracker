# ATOM-GAME Балаково

Система рейтинга команд и управления для ATOM-GAME Балаково 2025 с призовым фондом 150,000 рублей.

## Особенности системы

- Публичная страница с рейтингом команд
- Визуальное выделение топ-3 команд
- Индикаторы изменения позиций
- Блок с лого партнеров
- Ротация рекламных баннеров
- Таймер обратного отсчета до начала регистрации
- Панель администратора для управления всем контентом

## Развертывание на сервере

### Требования
- Node.js 18 или выше
- PostgreSQL 13 или выше 
- PM2 для управления процессами (установка: `npm install -g pm2`)
- Nginx (для настройки домена и SSL)

### Автоматическое развертывание

В проекте есть готовый скрипт для автоматического развертывания:

```bash
git clone <url-вашего-репозитория>
cd atom-game-blk
chmod +x deploy.sh
./deploy.sh
```

Скрипт выполнит все необходимые шаги:
1. Установит зависимости
2. Создаст файл .env с конфигурацией
3. Запросит параметры подключения к базе данных
4. Соберет проект
5. Запустит миграции базы данных
6. Настроит PM2
7. Настроит Nginx и SSL (если они установлены)

### Ручное развертывание

1. Клонируйте репозиторий:
```bash
git clone <url-вашего-репозитория>
cd atom-game-blk
```

2. Установите зависимости:
```bash
npm install
```

3. Создайте и настройте .env файл:
```
NODE_ENV=production
PORT=3000
HOST=0.0.0.0
DOMAIN=atomgameblk.ru
SESSION_SECRET=Atom&Game#2025!SecretKey
DATABASE_URL=postgres://username:password@localhost:5432/atomgame
```

4. Соберите проект:
```bash
npm run build
```

5. Запустите миграции базы данных:
```bash
npm run db:push
```

6. Запустите приложение с помощью PM2:
```bash
pm2 start ecosystem.config.js
pm2 startup
pm2 save
```

7. Настройте Nginx:
```bash
sudo cp nginx.conf /etc/nginx/sites-available/atomgameblk.ru
sudo ln -sf /etc/nginx/sites-available/atomgameblk.ru /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

8. Настройте SSL с Certbot:
```bash
sudo apt install certbot python3-certbot-nginx
sudo certbot --nginx -d atomgameblk.ru -d www.atomgameblk.ru
```

## Управление сервером

### Обновление приложения

Для обновления приложения используйте скрипт:

```bash
chmod +x update.sh
./update.sh
```

Скрипт выполнит:
1. Создание резервной копии базы данных
2. Скачивание последних изменений из репозитория
3. Обновление зависимостей
4. Сборку проекта
5. Обновление схемы базы данных
6. Перезапуск приложения

### Резервное копирование и восстановление

Для управления резервными копиями используйте скрипт:

```bash
chmod +x backup.sh
./backup.sh backup     # Создать резервную копию
./backup.sh restore <файл>   # Восстановить из резервной копии
```

Резервные копии сохраняются в директории `./backups`.

## Мониторинг и управление

Для мониторинга приложения:
```bash
pm2 status           # Статус приложения
pm2 logs             # Просмотр логов
pm2 monit            # Интерактивный мониторинг
```

## Доступ к панели администратора

Панель администратора доступна по адресу: http://atomgameblk.ru/admin

**Учетные данные администратора:**
- Имя пользователя: `admin`  
- Пароль: `Atom&Game#2025!`

## Технические детали
- Frontend: React, TailwindCSS, Shadcn UI
- Backend: Express.js
- База данных: PostgreSQL с Drizzle ORM
- Аутентификация: Passport.js
- Деплой: PM2, Nginx, Let's Encrypt