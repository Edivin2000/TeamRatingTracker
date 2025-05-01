#!/bin/bash

# Этот скрипт можно просто скопировать и вставить в консоль сервера строка за строкой

# Переменные настройки
DB_NAME="atomgame"
DB_USER="atomgame"
DB_PASSWORD="Atom&Game#2025!"
SESSION_SECRET="AtomGameSecretSession2025!"
ESCAPED_PASSWORD=$(echo $DB_PASSWORD | sed 's/&/%26/g; s/#/%23/g')
DATABASE_URL="postgresql://$DB_USER:$ESCAPED_PASSWORD@localhost:5432/$DB_NAME"

# Шаг 1: Остановка PM2 процессов
echo "Остановка всех PM2 процессов..."
pm2 delete all 2>/dev/null || true
echo "PM2 процессы остановлены."

# Шаг 2: Проверка и создание директории для загрузок
echo "Создание директории для загрузок..."
mkdir -p /var/www/atomgameblk/uploads
chmod 775 /var/www/atomgameblk/uploads
echo "Директория создана и права установлены."

# Шаг 3: Очистка и пересоздание базы данных
echo "Пересоздание базы данных..."
sudo -u postgres psql -c "DROP DATABASE IF EXISTS $DB_NAME;"
sudo -u postgres psql -c "DROP USER IF EXISTS $DB_USER;"
sudo -u postgres psql -c "CREATE USER $DB_USER WITH ENCRYPTED PASSWORD '$DB_PASSWORD';"
sudo -u postgres psql -c "CREATE DATABASE $DB_NAME OWNER $DB_USER;"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;"
echo "База данных создана заново."

# Шаг 4: Создание файла обновления базы данных
cat > /tmp/db-init.sql << 'SQLEOF'
-- Создание таблиц, если они не существуют

-- Пользователи
CREATE TABLE IF NOT EXISTS users (
  id SERIAL PRIMARY KEY,
  username TEXT NOT NULL UNIQUE,
  password TEXT NOT NULL,
  is_admin INTEGER NOT NULL DEFAULT 0
);

-- Команды
CREATE TABLE IF NOT EXISTS teams (
  id SERIAL PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  logo_url TEXT DEFAULT '',
  score INTEGER NOT NULL DEFAULT 0,
  excluded BOOLEAN DEFAULT FALSE
);

-- Партнеры
CREATE TABLE IF NOT EXISTS partners (
  id SERIAL PRIMARY KEY,
  name VARCHAR(100) NOT NULL UNIQUE,
  logo_url TEXT DEFAULT '',
  website TEXT DEFAULT '#',
  "order" INTEGER DEFAULT 0
);

-- Рекламные баннеры
CREATE TABLE IF NOT EXISTS ads (
  id SERIAL PRIMARY KEY,
  title VARCHAR(200) NOT NULL UNIQUE,
  description TEXT NOT NULL,
  logo_url TEXT DEFAULT '',
  bg_image TEXT DEFAULT '',
  bg_color VARCHAR(30) DEFAULT 'from-blue-600 to-indigo-700',
  button_text VARCHAR(50) DEFAULT 'Подробнее',
  button_link TEXT DEFAULT '#',
  active BOOLEAN DEFAULT TRUE,
  "order" INTEGER DEFAULT 0
);

-- Таймеры
CREATE TABLE IF NOT EXISTS timers (
  id SERIAL PRIMARY KEY,
  name VARCHAR(100) NOT NULL UNIQUE,
  end_date VARCHAR(30) NOT NULL,
  active BOOLEAN DEFAULT TRUE,
  display_name VARCHAR(100) DEFAULT '',
  color VARCHAR(30) DEFAULT 'from-blue-600 to-indigo-700'
);

-- Настройки сайта
CREATE TABLE IF NOT EXISTS site_settings (
  id SERIAL PRIMARY KEY,
  primary_color VARCHAR(30) NOT NULL DEFAULT '#0f172a',
  secondary_color VARCHAR(30) NOT NULL DEFAULT '#1e293b',
  accent_color VARCHAR(30) NOT NULL DEFAULT '#3b82f6',
  header_bg_color VARCHAR(30) NOT NULL DEFAULT '#0f172a',
  font_primary VARCHAR(30) NOT NULL DEFAULT 'Inter',
  border_radius VARCHAR(10) NOT NULL DEFAULT '0.5rem',
  button_style VARCHAR(30) NOT NULL DEFAULT 'default',
  table_bg_color VARCHAR(30) NOT NULL DEFAULT '#1e293b',
  card_bg_color VARCHAR(30) NOT NULL DEFAULT '#1e293b',
  podium_style VARCHAR(30) NOT NULL DEFAULT 'default',
  bg_pattern VARCHAR(30) NOT NULL DEFAULT 'none',
  logo_position VARCHAR(30) NOT NULL DEFAULT 'center',
  updated TEXT DEFAULT NOW()
);

-- Сессии
CREATE TABLE IF NOT EXISTS "session" (
  "sid" VARCHAR NOT NULL PRIMARY KEY,
  "sess" JSON NOT NULL,
  "expire" TIMESTAMP(6) NOT NULL
);
CREATE INDEX IF NOT EXISTS "IDX_session_expire" ON "session" ("expire");

-- Очистка старых данных, если нужно обновить
TRUNCATE users, teams, partners, ads, timers, site_settings, "session";

-- Создание админа (пароль: Atom&Game#2025!)
INSERT INTO users (username, password, is_admin) 
VALUES ('admin', '$2b$12$mQH5VJSvzV4Y8kyaVj9rS.HvCwFHU/DHUbyAwhqJ/B8O3NM3fFgLWnFP9vHT8tE76', 1);

-- Создание примеров команд
INSERT INTO teams (name, logo_url, score, excluded) VALUES
('Phoenix Force', 'https://placehold.co/100x100/orange/white?text=PF', 89, false),
('Thunderbolts', 'https://placehold.co/100x100/blue/white?text=TB', 72, false),
('Storm Riders', 'https://placehold.co/100x100/purple/white?text=SR', 68, false),
('Arctic Wolves', 'https://placehold.co/100x100/teal/white?text=AW', 55, true),
('Shadow Tigers', 'https://placehold.co/100x100/gray/white?text=ST', 42, false);

-- Создание примеров партнеров
INSERT INTO partners (name, logo_url, website, "order") VALUES
('Росэнергоатом', 'https://placehold.co/200x100/blue/white?text=Росэнергоатом', 'https://www.rosenergoatom.ru/', 1),
('Фонд АТР АЭС', 'https://placehold.co/200x100/green/white?text=Фонд+АТР+АЭС', 'https://atompsy.ru/', 2),
('ATOM﮳GAME', 'https://placehold.co/200x100/orange/white?text=ATOM﮳GAME', 'https://atomgame.ru/', 3);

-- Создание примеров рекламных баннеров
INSERT INTO ads (title, description, logo_url, bg_image, bg_color, button_text, button_link, active, "order") VALUES
('Технологический конкурс ATOM﮳GAME', 'Примите участие в технологическом конкурсе и выиграйте ценные призы', 'https://placehold.co/120x80/white/black?text=ATOM﮳GAME', '', 'from-blue-600 to-indigo-700', 'Подробнее', 'https://atomgame.ru/', true, 1),
('Росэнергоатом приглашает', 'Карьера в атомной энергетике для молодых специалистов', 'https://placehold.co/120x80/white/blue?text=Росэнергоатом', '', 'from-teal-600 to-teal-800', 'Узнать больше', 'https://www.rosenergoatom.ru/', true, 2);

-- Создание примеров таймеров
INSERT INTO timers (name, end_date, active, display_name, color) VALUES
('Регистрации на конкурс', '2025-06-01T23:59:59.999Z', true, 'До конца регистрации', 'from-blue-600 to-indigo-700'),
('Регистрации на сезон 2025', '2025-08-01T23:59:59.999Z', true, 'Новый сезон', 'from-green-600 to-emerald-700');

-- Создание настроек сайта
INSERT INTO site_settings (id, primary_color, secondary_color, accent_color, header_bg_color, font_primary, border_radius, button_style, table_bg_color, card_bg_color, podium_style, bg_pattern, logo_position, updated) 
VALUES (1, '#000000', '#1e293b', '#3b82f6', '#0f172a', 'Inter', '0.5rem', 'default', '#1e293b', '#1e293b', 'default', 'none', 'center', NOW()::text);
SQLEOF

# Шаг 5: Применение скрипта SQL к базе данных
echo "Применение SQL скрипта..."
sudo -u postgres psql -d $DB_NAME -f /tmp/db-init.sql
echo "SQL скрипт успешно выполнен."

# Шаг 6: Обновление файла db.ts для правильного подключения к базе данных
cat > /var/www/atomgameblk/server/db.ts << 'EOF'
import { Pool, neonConfig } from '@neondatabase/serverless';
import { drizzle } from 'drizzle-orm/neon-serverless';
import * as schema from "@shared/schema";
import ws from 'ws';

// Configure WebSocket for Neon Database
neonConfig.webSocketConstructor = ws;

// Получение строки подключения из переменных окружения
const DATABASE_URL = process.env.DATABASE_URL || 'postgresql://atomgame:Atom%26Game%232025!@localhost:5432/atomgame';
console.log('Connecting to database using URL:', DATABASE_URL);

// Создание пула соединений
const pool = new Pool({ 
  connectionString: DATABASE_URL,
});

// Создание экземпляра Drizzle ORM
const db = drizzle({ client: pool, schema });
console.log('Database connection pool created successfully');

export { pool, db };
EOF
echo "Файл подключения к базе данных обновлен."

# Шаг 7: Создание файла .env
cat > /var/www/atomgameblk/.env << EOF
# Основные настройки
NODE_ENV=production
PORT=5000

# База данных PostgreSQL
PGUSER=$DB_USER
PGPASSWORD=$DB_PASSWORD
PGDATABASE=$DB_NAME
PGHOST=localhost
PGPORT=5432
DATABASE_URL=$DATABASE_URL

# Безопасность
SESSION_SECRET=$SESSION_SECRET

# Пути
UPLOADS_DIR=/var/www/atomgameblk/uploads
EOF
echo "Файл .env создан."

# Шаг 8: Установка необходимых NPM пакетов
cd /var/www/atomgameblk
echo "Установка необходимых NPM пакетов..."
npm install ws @neondatabase/serverless connect-pg-simple bcrypt multer uuid --save
echo "Пакеты установлены."

# Шаг 9: Исправление прав доступа
echo "Исправление прав доступа..."
chown -R www-data:www-data /var/www/atomgameblk
chmod -R 755 /var/www/atomgameblk
echo "Права доступа исправлены."

# Шаг 10: Запуск PM2
echo "Запуск приложения через PM2..."
cd /var/www/atomgameblk
pm2 start ecosystem.config.js
pm2 save
echo "Приложение запущено через PM2."

echo "САЙТ УСПЕШНО ВОССТАНОВЛЕН И ГОТОВ К РАБОТЕ!"
echo "Логин админа: admin"
echo "Пароль админа: Atom&Game#2025!"