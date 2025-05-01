#!/bin/bash

# Скрипт для развертывания приложения ATOM-GAME Балаково
# ВНИМАНИЕ: Запускать с sudo если нужны права для nginx и certbot

echo "=== Развертывание ATOM-GAME Балаково ==="
echo "Домен: atomgameblk.ru"

# Проверка наличия Node.js и npm
if ! command -v node &> /dev/null || ! command -v npm &> /dev/null; then
  echo "Node.js и npm должны быть установлены."
  echo "Установите их с помощью: apt update && apt install -y nodejs npm"
  exit 1
fi

# Проверка наличия PM2
if ! command -v pm2 &> /dev/null; then
  echo "Установка PM2..."
  npm install -g pm2
fi

# Установка зависимостей
echo "Установка зависимостей проекта..."
npm install

# Проверка наличия переменных окружения
if [ ! -f .env ]; then
  echo "Создание файла .env..."
  cat > .env << EOF
NODE_ENV=production
PORT=3000
HOST=0.0.0.0
DOMAIN=atomgameblk.ru
SESSION_SECRET=Atom&Game#2025!SecretKey
EOF
  echo "Файл .env создан."
fi

# Запрос параметров базы данных, если они не указаны
if ! grep -q "DATABASE_URL" .env; then
  echo "Настройка подключения к базе данных PostgreSQL"
  read -p "Введите имя пользователя PostgreSQL: " PGUSER
  read -sp "Введите пароль PostgreSQL: " PGPASSWORD
  echo ""
  read -p "Введите имя базы данных (по умолчанию: atomgame): " PGDATABASE
  PGDATABASE=${PGDATABASE:-atomgame}
  read -p "Введите хост PostgreSQL (по умолчанию: localhost): " PGHOST
  PGHOST=${PGHOST:-localhost}
  read -p "Введите порт PostgreSQL (по умолчанию: 5432): " PGPORT
  PGPORT=${PGPORT:-5432}
  
  # Добавление URL базы данных в .env
  echo "DATABASE_URL=postgres://$PGUSER:$PGPASSWORD@$PGHOST:$PGPORT/$PGDATABASE" >> .env
  echo "Настройки базы данных сохранены в .env"
fi

# Сборка проекта
echo "Сборка проекта..."
npm run build

# Запуск миграций
echo "Запуск миграций базы данных..."
npm run db:push

# Настройка PM2
echo "Настройка PM2..."
pm2 start ecosystem.config.js
pm2 save
pm2 startup | tail -n 1

# Настройка Nginx если он установлен
if command -v nginx &> /dev/null; then
  echo "Создание конфигурации Nginx..."
  
  # Создание конфигурации сайта
  sudo cp nginx.conf /etc/nginx/sites-available/atomgameblk.ru.conf
  
  # Создание символической ссылки
  sudo ln -sf /etc/nginx/sites-available/atomgameblk.ru.conf /etc/nginx/sites-enabled/
  
  # Проверка синтаксиса Nginx
  sudo nginx -t
  
  if [ $? -eq 0 ]; then
    # Перезапуск Nginx
    sudo systemctl reload nginx
    echo "Nginx настроен."
    
    # Настройка SSL с Certbot, если доступен
    if command -v certbot &> /dev/null; then
      echo "Хотите настроить SSL-сертификат с помощью Let's Encrypt? (y/n)"
      read ssl_choice
      
      if [ "$ssl_choice" = "y" ]; then
        sudo certbot --nginx -d atomgameblk.ru -d www.atomgameblk.ru
      fi
    else
      echo "Certbot не установлен. Установите его для настройки SSL."
      echo "sudo apt install certbot python3-certbot-nginx"
    fi
  else
    echo "Ошибка в конфигурации Nginx. Исправьте ошибки и перезапустите Nginx вручную."
  fi
else
  echo "Nginx не установлен. Установите его для настройки веб-сервера."
  echo "sudo apt install nginx"
fi

echo ""
echo "=== Развертывание завершено ==="
echo "Сайт должен быть доступен по адресу: http://atomgameblk.ru"
echo "Для доступа к панели администратора: http://atomgameblk.ru/admin"
echo "Логин: admin"
echo "Пароль: Atom&Game#2025!"
echo ""
echo "Для мониторинга приложения используйте: pm2 status"
echo "Для просмотра логов: pm2 logs"