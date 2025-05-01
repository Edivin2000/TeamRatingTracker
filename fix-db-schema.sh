#!/bin/bash

# Скрипт для исправления структуры базы данных
# Автор: ATOM-GAME Team
# Версия: 1.0.0

# Цвета для вывода
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Исправляем структуру базы данных...${NC}"

# Настройки базы данных
DB_USER="atomgame"
DB_NAME="atomgame"
DB_PASSWORD="Atom&Game#2025!"

# Проверка существования и создание колонок
echo -e "${YELLOW}Проверяем и добавляем нужные колонки в таблицы...${NC}"

# Создаем временный SQL файл
cat > /tmp/fix-db.sql << 'EOF'
-- Убеждаемся, что в таблице users есть все нужные колонки
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'is_admin') THEN
        ALTER TABLE users ADD COLUMN is_admin BOOLEAN DEFAULT FALSE;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'created_at') THEN
        ALTER TABLE users ADD COLUMN created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP;
    END IF;
END $$;

-- Убеждаемся, что в таблице teams есть все нужные колонки
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'teams' AND column_name = 'logo_url') THEN
        ALTER TABLE teams ADD COLUMN logo_url TEXT;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'teams' AND column_name = 'score') THEN
        ALTER TABLE teams ADD COLUMN score INTEGER DEFAULT 0;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'teams' AND column_name = 'excluded') THEN
        ALTER TABLE teams ADD COLUMN excluded BOOLEAN DEFAULT FALSE;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'teams' AND column_name = 'created_at') THEN
        ALTER TABLE teams ADD COLUMN created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP;
    END IF;
END $$;

-- Убеждаемся, что в таблице partners есть все нужные колонки
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'partners' AND column_name = 'logo_url') THEN
        ALTER TABLE partners ADD COLUMN logo_url TEXT NOT NULL DEFAULT '';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'partners' AND column_name = 'website_url') THEN
        ALTER TABLE partners ADD COLUMN website_url TEXT;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'partners' AND column_name = 'created_at') THEN
        ALTER TABLE partners ADD COLUMN created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP;
    END IF;
END $$;

-- Убеждаемся, что в таблице ads есть все нужные колонки
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'ads' AND column_name = 'image_url') THEN
        ALTER TABLE ads ADD COLUMN image_url TEXT NOT NULL DEFAULT '';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'ads' AND column_name = 'link_url') THEN
        ALTER TABLE ads ADD COLUMN link_url TEXT;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'ads' AND column_name = 'created_at') THEN
        ALTER TABLE ads ADD COLUMN created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP;
    END IF;
END $$;

-- Убеждаемся, что в таблице timers есть все нужные колонки
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'timers' AND column_name = 'end_date') THEN
        ALTER TABLE timers ADD COLUMN end_date TIMESTAMP NOT NULL DEFAULT (NOW() + INTERVAL '30 days');
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'timers' AND column_name = 'active') THEN
        ALTER TABLE timers ADD COLUMN active BOOLEAN DEFAULT TRUE;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'timers' AND column_name = 'created_at') THEN
        ALTER TABLE timers ADD COLUMN created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP;
    END IF;
END $$;

-- Убеждаемся, что в таблице site_settings есть все нужные колонки
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'site_settings' AND column_name = 'site_name') THEN
        ALTER TABLE site_settings ADD COLUMN site_name VARCHAR(255) DEFAULT 'ATOM-GAME';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'site_settings' AND column_name = 'team_section_title') THEN
        ALTER TABLE site_settings ADD COLUMN team_section_title VARCHAR(255) DEFAULT 'Рейтинг команд';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'site_settings' AND column_name = 'footer_text') THEN
        ALTER TABLE site_settings ADD COLUMN footer_text TEXT DEFAULT 'Проект ATOM﮳GAME поддерживается Фондом «АТР АЭС» и АО «Концерн Росэнергоатом»';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'site_settings' AND column_name = 'logo_url') THEN
        ALTER TABLE site_settings ADD COLUMN logo_url TEXT;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'site_settings' AND column_name = 'primary_color') THEN
        ALTER TABLE site_settings ADD COLUMN primary_color VARCHAR(20) DEFAULT '#3b82f6';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'site_settings' AND column_name = 'secondary_color') THEN
        ALTER TABLE site_settings ADD COLUMN secondary_color VARCHAR(20) DEFAULT '#10b981';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'site_settings' AND column_name = 'text_color') THEN
        ALTER TABLE site_settings ADD COLUMN text_color VARCHAR(20) DEFAULT '#1f2937';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'site_settings' AND column_name = 'background_color') THEN
        ALTER TABLE site_settings ADD COLUMN background_color VARCHAR(20) DEFAULT '#ffffff';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'site_settings' AND column_name = 'updated_at') THEN
        ALTER TABLE site_settings ADD COLUMN updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP;
    END IF;
END $$;

-- Проверяем и создаем тестового пользователя admin, если его еще нет
INSERT INTO users (username, password, is_admin)
SELECT 'admin', '$2b$10$8eeZUlKwmeoKJj9x7hfn6OQlcD.fYCqX8vJOqYi4xLVf9BnqtMdYO', TRUE
WHERE NOT EXISTS (SELECT 1 FROM users WHERE username = 'admin');

-- Проверяем и создаем настройки сайта по умолчанию, если их нет
INSERT INTO site_settings (site_name, team_section_title, footer_text, logo_url, primary_color, secondary_color, text_color, background_color)
SELECT 'ATOM-GAME', 'Рейтинг команд', 'Проект ATOM﮳GAME поддерживается Фондом «АТР АЭС» и АО «Концерн Росэнергоатом»', '/assets/atom-game-logo-blue-zWFb6GXJ.png', '#3b82f6', '#10b981', '#1f2937', '#ffffff'
WHERE NOT EXISTS (SELECT 1 FROM site_settings);
EOF

# Запускаем SQL скрипт
export PGPASSWORD="$DB_PASSWORD"
psql -U "$DB_USER" -d "$DB_NAME" -f /tmp/fix-db.sql

# Проверяем результат
if [ $? -eq 0 ]; then
    echo -e "${GREEN}Структура базы данных успешно обновлена!${NC}"
else
    echo -e "${RED}Произошла ошибка при обновлении структуры базы данных.${NC}"
    exit 1
fi

# Удаляем временный файл
rm -f /tmp/fix-db.sql

# Перезапускаем сервер
echo -e "${YELLOW}Перезапускаем сервер...${NC}"
pm2 restart atom-game-server

echo -e "${GREEN}Готово! База данных исправлена и сервер перезапущен.${NC}"
echo -e "${GREEN}Данные для входа в админку:${NC}"
echo -e "  - Логин: ${GREEN}admin${NC}"
echo -e "  - Пароль: ${GREEN}Atom&Game#2025!${NC}"