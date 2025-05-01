#!/bin/bash

# Скрипт для полного исправления API и создания базы данных
# Автор: ATOM-GAME Team
# Версия: 2.0.0

# Цвета для вывода
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Запускаем полный фикс API и базы данных!${NC}"

# Переходим в директорию проекта
cd /var/www/atomgameblk

# Останавливаем все процессы PM2
echo -e "${YELLOW}Останавливаем все процессы PM2...${NC}"
pm2 delete all || true

# Проверяем и создаем таблицы базы данных
echo -e "${YELLOW}Проверяем и создаем необходимые таблицы в базе данных...${NC}"

psql -U atomgame -d atomgame << 'EOF'
-- Создаем таблицы, если они отсутствуют

-- Таблица пользователей
CREATE TABLE IF NOT EXISTS users (
  id SERIAL PRIMARY KEY,
  username VARCHAR(255) NOT NULL UNIQUE,
  password VARCHAR(255) NOT NULL,
  is_admin BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Таблица команд
CREATE TABLE IF NOT EXISTS teams (
  id SERIAL PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  logo_url TEXT,
  score INTEGER DEFAULT 0,
  excluded BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Таблица партнеров
CREATE TABLE IF NOT EXISTS partners (
  id SERIAL PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  logo_url TEXT NOT NULL,
  website_url TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Таблица баннеров
CREATE TABLE IF NOT EXISTS ads (
  id SERIAL PRIMARY KEY,
  title VARCHAR(255) NOT NULL,
  image_url TEXT NOT NULL,
  link_url TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Таблица таймеров
CREATE TABLE IF NOT EXISTS timers (
  id SERIAL PRIMARY KEY,
  title VARCHAR(255) NOT NULL,
  end_date TIMESTAMP NOT NULL,
  active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Таблица настроек сайта
CREATE TABLE IF NOT EXISTS site_settings (
  id SERIAL PRIMARY KEY,
  site_name VARCHAR(255) DEFAULT 'ATOM-GAME',
  team_section_title VARCHAR(255) DEFAULT 'Рейтинг команд',
  footer_text TEXT DEFAULT 'Проект ATOM﮳GAME поддерживается Фондом «АТР АЭС» и АО «Концерн Росэнергоатом»',
  logo_url TEXT,
  primary_color VARCHAR(20) DEFAULT '#3b82f6',
  secondary_color VARCHAR(20) DEFAULT '#10b981',
  text_color VARCHAR(20) DEFAULT '#1f2937',
  background_color VARCHAR(20) DEFAULT '#ffffff',
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Проверяем, есть ли данные в таблице пользователей, если нет - добавляем админа
INSERT INTO users (username, password, is_admin)
SELECT 'admin', '$2b$10$8eeZUlKwmeoKJj9x7hfn6OQlcD.fYCqX8vJOqYi4xLVf9BnqtMdYO', TRUE
WHERE NOT EXISTS (SELECT 1 FROM users WHERE username = 'admin');

-- Добавляем настройки по умолчанию, если их нет
INSERT INTO site_settings (site_name, team_section_title, footer_text, logo_url, primary_color, secondary_color, text_color, background_color)
SELECT 'ATOM-GAME', 'Рейтинг команд', 'Проект ATOM﮳GAME поддерживается Фондом «АТР АЭС» и АО «Концерн Росэнергоатом»', '/assets/atom-game-logo-blue-zWFb6GXJ.png', '#3b82f6', '#10b981', '#1f2937', '#ffffff'
WHERE NOT EXISTS (SELECT 1 FROM site_settings);

-- Создаём индексы для ускорения запросов
CREATE INDEX IF NOT EXISTS idx_teams_score ON teams(score DESC);
CREATE INDEX IF NOT EXISTS idx_timers_active ON timers(active);
EOF

# Создаём обновлённый basic-server.mjs
echo -e "${YELLOW}Создаём обновлённый сервер с полной поддержкой API...${NC}"

cat > basic-server.mjs << 'EOF'
// basic-server.mjs
// Полная версия сервера для API и фронтенда

import express from 'express';
import path from 'path';
import fs from 'fs';
import pg from 'pg';
import { fileURLToPath } from 'url';
import crypto from 'crypto';

const { Pool } = pg;
const app = express();
const PORT = process.env.PORT || 8080;

// Получение текущей директории для ES модулей
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Настройка базы данных
const dbConfig = {
  user: process.env.PGUSER || 'atomgame',
  password: process.env.PGPASSWORD || 'Atom&Game#2025!',
  database: process.env.PGDATABASE || 'atomgame',
  host: process.env.PGHOST || 'localhost',
  port: process.env.PGPORT || 5432,
  ssl: false
};

// Создание пула соединений
const pool = new Pool(dbConfig);

// Проверка соединения
pool.query('SELECT NOW()', (err, res) => {
  if (err) {
    console.error('Ошибка соединения с базой данных:', err);
  } else {
    console.log('Соединение с базой данных успешно установлено:', res.rows[0]);
  }
});

// Логирование запросов
app.use((req, res, next) => {
  console.log(`[${new Date().toISOString()}] ${req.method} ${req.url}`);
  next();
});

// Настройка папки uploads если она не существует
const uploadsDir = path.join(__dirname, 'uploads');
if (!fs.existsSync(uploadsDir)) {
  fs.mkdirSync(uploadsDir, { recursive: true });
}

// Настройка статических файлов
app.use(express.static(path.join(__dirname, 'dist/public')));
app.use('/assets', express.static(path.join(__dirname, 'dist/public/assets')));
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

// Парсинг JSON
app.use(express.json({ limit: '50mb' }));

// Простая имитация авторизации
app.post('/api/login', async (req, res) => {
  try {
    const { username, password } = req.body;
    
    // В целях безопасности для тестового сервера всегда авторизуем как админа
    if (username === 'admin' && password === 'Atom&Game#2025!') {
      const result = await pool.query('SELECT id, username, is_admin, created_at FROM users WHERE username = $1', [username]);
      
      if (result.rows.length > 0) {
        const user = result.rows[0];
        res.json({
          id: user.id,
          username: user.username,
          isAdmin: user.is_admin,
          createdAt: user.created_at
        });
      } else {
        // Если по какой-то причине пользователя нет в базе
        res.json({
          id: 1,
          username: 'admin',
          isAdmin: true,
          createdAt: new Date().toISOString()
        });
      }
    } else {
      res.status(401).json({ error: 'Неверное имя пользователя или пароль' });
    }
  } catch (error) {
    console.error('Ошибка при авторизации:', error);
    res.status(500).json({ error: 'Ошибка при авторизации' });
  }
});

// Имитация текущего пользователя
app.get('/api/user', async (req, res) => {
  try {
    // Для тестового сервера всегда возвращаем админа
    const result = await pool.query('SELECT id, username, is_admin, created_at FROM users WHERE username = $1', ['admin']);
    
    if (result.rows.length > 0) {
      const user = result.rows[0];
      res.json({
        id: user.id,
        username: user.username,
        isAdmin: user.is_admin,
        createdAt: user.created_at
      });
    } else {
      // Если по какой-то причине пользователя нет в базе
      res.json({
        id: 1,
        username: 'admin',
        isAdmin: true,
        createdAt: new Date().toISOString()
      });
    }
  } catch (error) {
    console.error('Ошибка при получении пользователя:', error);
    res.status(500).json({ error: 'Ошибка при получении пользователя' });
  }
});

// Выход из системы
app.post('/api/logout', (req, res) => {
  res.status(200).json({ message: 'Выход выполнен успешно' });
});

// Получение списка команд
app.get('/api/teams', async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM teams ORDER BY score DESC');
    res.json(result.rows);
  } catch (error) {
    console.error('Ошибка при запросе команд:', error);
    res.status(500).json({ error: 'Ошибка при запросе данных' });
  }
});

// Получение одной команды
app.get('/api/teams/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const result = await pool.query('SELECT * FROM teams WHERE id = $1', [id]);
    
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Команда не найдена' });
    }
    
    res.json(result.rows[0]);
  } catch (error) {
    console.error('Ошибка при запросе команды:', error);
    res.status(500).json({ error: 'Ошибка при запросе данных' });
  }
});

// Создание команды
app.post('/api/teams', async (req, res) => {
  try {
    const { name, logoUrl, score = 0, excluded = false } = req.body;
    
    const result = await pool.query(
      'INSERT INTO teams (name, logo_url, score, excluded) VALUES ($1, $2, $3, $4) RETURNING *',
      [name, logoUrl, score, excluded]
    );
    
    res.status(201).json(result.rows[0]);
  } catch (error) {
    console.error('Ошибка при создании команды:', error);
    res.status(500).json({ error: 'Ошибка при создании команды' });
  }
});

// Обновление команды
app.patch('/api/teams/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const { name, logoUrl, score, excluded } = req.body;
    
    const result = await pool.query(
      'UPDATE teams SET name = $1, logo_url = $2, score = $3, excluded = $4 WHERE id = $5 RETURNING *',
      [name, logoUrl, score, excluded, id]
    );
    
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Команда не найдена' });
    }
    
    res.json(result.rows[0]);
  } catch (error) {
    console.error('Ошибка при обновлении команды:', error);
    res.status(500).json({ error: 'Ошибка при обновлении команды' });
  }
});

// Обновление очков команды
app.patch('/api/teams/:id/score', async (req, res) => {
  try {
    const { id } = req.params;
    const { score } = req.body;
    
    const result = await pool.query(
      'UPDATE teams SET score = $1 WHERE id = $2 RETURNING *',
      [score, id]
    );
    
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Команда не найдена' });
    }
    
    res.json(result.rows[0]);
  } catch (error) {
    console.error('Ошибка при обновлении очков команды:', error);
    res.status(500).json({ error: 'Ошибка при обновлении очков команды' });
  }
});

// Удаление команды
app.delete('/api/teams/:id', async (req, res) => {
  try {
    const { id } = req.params;
    
    const result = await pool.query('DELETE FROM teams WHERE id = $1 RETURNING *', [id]);
    
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Команда не найдена' });
    }
    
    res.json({ message: 'Команда успешно удалена' });
  } catch (error) {
    console.error('Ошибка при удалении команды:', error);
    res.status(500).json({ error: 'Ошибка при удалении команды' });
  }
});

// Получение списка партнеров
app.get('/api/partners', async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM partners');
    res.json(result.rows);
  } catch (error) {
    console.error('Ошибка при запросе партнеров:', error);
    res.status(500).json({ error: 'Ошибка при запросе данных' });
  }
});

// Получение одного партнера
app.get('/api/partners/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const result = await pool.query('SELECT * FROM partners WHERE id = $1', [id]);
    
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Партнер не найден' });
    }
    
    res.json(result.rows[0]);
  } catch (error) {
    console.error('Ошибка при запросе партнера:', error);
    res.status(500).json({ error: 'Ошибка при запросе данных' });
  }
});

// Создание партнера
app.post('/api/partners', async (req, res) => {
  try {
    const { name, logoUrl, websiteUrl } = req.body;
    
    const result = await pool.query(
      'INSERT INTO partners (name, logo_url, website_url) VALUES ($1, $2, $3) RETURNING *',
      [name, logoUrl, websiteUrl]
    );
    
    res.status(201).json(result.rows[0]);
  } catch (error) {
    console.error('Ошибка при создании партнера:', error);
    res.status(500).json({ error: 'Ошибка при создании партнера' });
  }
});

// Обновление партнера
app.patch('/api/partners/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const { name, logoUrl, websiteUrl } = req.body;
    
    const result = await pool.query(
      'UPDATE partners SET name = $1, logo_url = $2, website_url = $3 WHERE id = $4 RETURNING *',
      [name, logoUrl, websiteUrl, id]
    );
    
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Партнер не найден' });
    }
    
    res.json(result.rows[0]);
  } catch (error) {
    console.error('Ошибка при обновлении партнера:', error);
    res.status(500).json({ error: 'Ошибка при обновлении партнера' });
  }
});

// Удаление партнера
app.delete('/api/partners/:id', async (req, res) => {
  try {
    const { id } = req.params;
    
    const result = await pool.query('DELETE FROM partners WHERE id = $1 RETURNING *', [id]);
    
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Партнер не найден' });
    }
    
    res.json({ message: 'Партнер успешно удален' });
  } catch (error) {
    console.error('Ошибка при удалении партнера:', error);
    res.status(500).json({ error: 'Ошибка при удалении партнера' });
  }
});

// Получение списка баннеров
app.get('/api/ads', async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM ads');
    res.json(result.rows);
  } catch (error) {
    console.error('Ошибка при запросе баннеров:', error);
    res.status(500).json({ error: 'Ошибка при запросе данных' });
  }
});

// Получение одного баннера
app.get('/api/ads/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const result = await pool.query('SELECT * FROM ads WHERE id = $1', [id]);
    
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Баннер не найден' });
    }
    
    res.json(result.rows[0]);
  } catch (error) {
    console.error('Ошибка при запросе баннера:', error);
    res.status(500).json({ error: 'Ошибка при запросе данных' });
  }
});

// Создание баннера
app.post('/api/ads', async (req, res) => {
  try {
    const { title, imageUrl, linkUrl } = req.body;
    
    const result = await pool.query(
      'INSERT INTO ads (title, image_url, link_url) VALUES ($1, $2, $3) RETURNING *',
      [title, imageUrl, linkUrl]
    );
    
    res.status(201).json(result.rows[0]);
  } catch (error) {
    console.error('Ошибка при создании баннера:', error);
    res.status(500).json({ error: 'Ошибка при создании баннера' });
  }
});

// Обновление баннера
app.patch('/api/ads/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const { title, imageUrl, linkUrl } = req.body;
    
    const result = await pool.query(
      'UPDATE ads SET title = $1, image_url = $2, link_url = $3 WHERE id = $4 RETURNING *',
      [title, imageUrl, linkUrl, id]
    );
    
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Баннер не найден' });
    }
    
    res.json(result.rows[0]);
  } catch (error) {
    console.error('Ошибка при обновлении баннера:', error);
    res.status(500).json({ error: 'Ошибка при обновлении баннера' });
  }
});

// Удаление баннера
app.delete('/api/ads/:id', async (req, res) => {
  try {
    const { id } = req.params;
    
    const result = await pool.query('DELETE FROM ads WHERE id = $1 RETURNING *', [id]);
    
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Баннер не найден' });
    }
    
    res.json({ message: 'Баннер успешно удален' });
  } catch (error) {
    console.error('Ошибка при удалении баннера:', error);
    res.status(500).json({ error: 'Ошибка при удалении баннера' });
  }
});

// Получение списка таймеров
app.get('/api/timers', async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM timers');
    res.json(result.rows);
  } catch (error) {
    console.error('Ошибка при запросе таймеров:', error);
    res.status(500).json({ error: 'Ошибка при запросе данных' });
  }
});

// Получение активных таймеров
app.get('/api/timers/active', async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM timers WHERE active = true');
    res.json(result.rows);
  } catch (error) {
    console.error('Ошибка при запросе активных таймеров:', error);
    res.status(500).json({ error: 'Ошибка при запросе данных' });
  }
});

// Получение одного таймера
app.get('/api/timers/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const result = await pool.query('SELECT * FROM timers WHERE id = $1', [id]);
    
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Таймер не найден' });
    }
    
    res.json(result.rows[0]);
  } catch (error) {
    console.error('Ошибка при запросе таймера:', error);
    res.status(500).json({ error: 'Ошибка при запросе данных' });
  }
});

// Создание таймера
app.post('/api/timers', async (req, res) => {
  try {
    const { title, endDate, active = true } = req.body;
    
    const result = await pool.query(
      'INSERT INTO timers (title, end_date, active) VALUES ($1, $2, $3) RETURNING *',
      [title, endDate, active]
    );
    
    res.status(201).json(result.rows[0]);
  } catch (error) {
    console.error('Ошибка при создании таймера:', error);
    res.status(500).json({ error: 'Ошибка при создании таймера' });
  }
});

// Обновление таймера
app.patch('/api/timers/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const { title, endDate, active } = req.body;
    
    const result = await pool.query(
      'UPDATE timers SET title = $1, end_date = $2, active = $3 WHERE id = $4 RETURNING *',
      [title, endDate, active, id]
    );
    
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Таймер не найден' });
    }
    
    res.json(result.rows[0]);
  } catch (error) {
    console.error('Ошибка при обновлении таймера:', error);
    res.status(500).json({ error: 'Ошибка при обновлении таймера' });
  }
});

// Удаление таймера
app.delete('/api/timers/:id', async (req, res) => {
  try {
    const { id } = req.params;
    
    const result = await pool.query('DELETE FROM timers WHERE id = $1 RETURNING *', [id]);
    
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Таймер не найден' });
    }
    
    res.json({ message: 'Таймер успешно удален' });
  } catch (error) {
    console.error('Ошибка при удалении таймера:', error);
    res.status(500).json({ error: 'Ошибка при удалении таймера' });
  }
});

// Получение настроек сайта
app.get('/api/site-settings', async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM site_settings LIMIT 1');
    
    if (result.rows.length > 0) {
      const settings = result.rows[0];
      res.json({
        id: settings.id,
        siteName: settings.site_name,
        teamSectionTitle: settings.team_section_title,
        footerText: settings.footer_text,
        logoUrl: settings.logo_url,
        primaryColor: settings.primary_color,
        secondaryColor: settings.secondary_color,
        textColor: settings.text_color,
        backgroundColor: settings.background_color
      });
    } else {
      // Создаем настройки по умолчанию
      const defaultSettings = {
        siteName: 'ATOM-GAME',
        teamSectionTitle: 'Рейтинг команд',
        footerText: 'Проект ATOM﮳GAME поддерживается Фондом «АТР АЭС» и АО «Концерн Росэнергоатом»',
        logoUrl: '/assets/atom-game-logo-blue-zWFb6GXJ.png',
        primaryColor: '#3b82f6',
        secondaryColor: '#10b981',
        textColor: '#1f2937',
        backgroundColor: '#ffffff'
      };
      
      const insertResult = await pool.query(
        'INSERT INTO site_settings (site_name, team_section_title, footer_text, logo_url, primary_color, secondary_color, text_color, background_color) VALUES ($1, $2, $3, $4, $5, $6, $7, $8) RETURNING *',
        [
          defaultSettings.siteName,
          defaultSettings.teamSectionTitle,
          defaultSettings.footerText,
          defaultSettings.logoUrl,
          defaultSettings.primaryColor,
          defaultSettings.secondaryColor,
          defaultSettings.textColor,
          defaultSettings.backgroundColor
        ]
      );
      
      const settings = insertResult.rows[0];
      res.json({
        id: settings.id,
        siteName: settings.site_name,
        teamSectionTitle: settings.team_section_title,
        footerText: settings.footer_text,
        logoUrl: settings.logo_url,
        primaryColor: settings.primary_color,
        secondaryColor: settings.secondary_color,
        textColor: settings.text_color,
        backgroundColor: settings.background_color
      });
    }
  } catch (error) {
    console.error('Ошибка при получении настроек сайта:', error);
    
    // Возвращаем настройки по умолчанию в случае ошибки
    res.json({
      id: 1,
      siteName: 'ATOM-GAME',
      teamSectionTitle: 'Рейтинг команд',
      footerText: 'Проект ATOM﮳GAME поддерживается Фондом «АТР АЭС» и АО «Концерн Росэнергоатом»',
      logoUrl: '/assets/atom-game-logo-blue-zWFb6GXJ.png',
      primaryColor: '#3b82f6',
      secondaryColor: '#10b981',
      textColor: '#1f2937',
      backgroundColor: '#ffffff'
    });
  }
});

// Обновление настроек сайта
app.patch('/api/site-settings', async (req, res) => {
  try {
    const {
      siteName,
      teamSectionTitle,
      footerText,
      logoUrl,
      primaryColor,
      secondaryColor,
      textColor,
      backgroundColor
    } = req.body;
    
    // Проверяем, существуют ли настройки
    const checkResult = await pool.query('SELECT id FROM site_settings LIMIT 1');
    
    if (checkResult.rows.length > 0) {
      // Обновляем настройки
      const result = await pool.query(
        'UPDATE site_settings SET site_name = $1, team_section_title = $2, footer_text = $3, logo_url = $4, primary_color = $5, secondary_color = $6, text_color = $7, background_color = $8, updated_at = NOW() WHERE id = $9 RETURNING *',
        [
          siteName,
          teamSectionTitle,
          footerText,
          logoUrl,
          primaryColor,
          secondaryColor,
          textColor,
          backgroundColor,
          checkResult.rows[0].id
        ]
      );
      
      const settings = result.rows[0];
      res.json({
        id: settings.id,
        siteName: settings.site_name,
        teamSectionTitle: settings.team_section_title,
        footerText: settings.footer_text,
        logoUrl: settings.logo_url,
        primaryColor: settings.primary_color,
        secondaryColor: settings.secondary_color,
        textColor: settings.text_color,
        backgroundColor: settings.background_color
      });
    } else {
      // Создаем настройки
      const result = await pool.query(
        'INSERT INTO site_settings (site_name, team_section_title, footer_text, logo_url, primary_color, secondary_color, text_color, background_color) VALUES ($1, $2, $3, $4, $5, $6, $7, $8) RETURNING *',
        [
          siteName,
          teamSectionTitle,
          footerText,
          logoUrl,
          primaryColor,
          secondaryColor,
          textColor,
          backgroundColor
        ]
      );
      
      const settings = result.rows[0];
      res.json({
        id: settings.id,
        siteName: settings.site_name,
        teamSectionTitle: settings.team_section_title,
        footerText: settings.footer_text,
        logoUrl: settings.logo_url,
        primaryColor: settings.primary_color,
        secondaryColor: settings.secondary_color,
        textColor: settings.text_color,
        backgroundColor: settings.background_color
      });
    }
  } catch (error) {
    console.error('Ошибка при обновлении настроек сайта:', error);
    res.status(500).json({ error: 'Ошибка при обновлении настроек' });
  }
});

// Обработка загрузки изображений
app.post('/api/upload', (req, res) => {
  try {
    const { base64Data, fileName } = req.body;
    
    if (!base64Data || !fileName) {
      return res.status(400).json({ error: 'Отсутствуют данные для загрузки' });
    }
    
    // Удаляем префикс из base64 (например, 'data:image/png;base64,')
    const base64Image = base64Data.split(';base64,').pop();
    
    // Генерируем уникальное имя файла
    const timestamp = Date.now();
    const hash = crypto.createHash('md5').update(timestamp + fileName).digest('hex').substring(0, 8);
    const fileNameParts = fileName.split('.');
    const ext = fileNameParts.pop();
    const name = fileNameParts.join('.');
    const uniqueFileName = `${name}-${hash}.${ext}`;
    
    // Создаем путь для сохранения файла
    const filePath = path.join(uploadsDir, uniqueFileName);
    
    // Сохраняем файл
    fs.writeFileSync(filePath, base64Image, { encoding: 'base64' });
    
    // Возвращаем URL для доступа к файлу
    res.json({ url: `/uploads/${uniqueFileName}` });
  } catch (error) {
    console.error('Ошибка при загрузке файла:', error);
    res.status(500).json({ error: 'Ошибка при загрузке файла' });
  }
});

// Fallback для необработанных API
app.all('/api/*', (req, res) => {
  console.log(`Необработанный API запрос: ${req.method} ${req.url}`);
  res.status(404).json({ error: 'API не найден' });
});

// Маршрут для всех остальных запросов (SPA)
app.get('*', (req, res) => {
  res.sendFile(path.join(__dirname, 'dist/public/index.html'));
});

// Обработка ошибок
app.use((err, req, res, next) => {
  console.error('Ошибка сервера:', err);
  res.status(500).json({ error: 'Внутренняя ошибка сервера' });
});

// Запуск сервера
app.listen(PORT, '0.0.0.0', () => {
  console.log(`Сервер запущен на порту ${PORT}`);
  console.log(`URL: http://localhost:${PORT}`);
});
EOF

# Обновляем конфигурацию Nginx
echo -e "${YELLOW}Обновляем конфигурацию Nginx...${NC}"
cat > /etc/nginx/sites-available/atomgameblk.ru << EOF
server {
    listen 80;
    server_name atomgameblk.ru www.atomgameblk.ru 193.109.78.85;

    client_max_body_size 100M;

    location / {
        proxy_pass http://localhost:8080;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
        proxy_read_timeout 300;
        proxy_connect_timeout 300;
    }

    access_log /var/log/nginx/atomgameblk.ru-access.log;
    error_log /var/log/nginx/atomgameblk.ru-error.log;
}
EOF

# Проверяем и перезапускаем Nginx
nginx -t && systemctl restart nginx

# Запускаем базовый сервер с помощью PM2
echo -e "${YELLOW}Запускаем сервер с полной поддержкой API через PM2...${NC}"
pm2 start basic-server.mjs --name "atom-game-server"
pm2 save

# Проверяем, что PM2 запустил процесс
if pm2 list | grep -q "atom-game-server" && pm2 list | grep -q "online"; then
  echo -e "${GREEN}Сервер успешно запущен через PM2!${NC}"
  echo -e "${GREEN}Сайт теперь доступен по адресу: http://193.109.78.85${NC}"
  echo ""
  echo -e "Полезные команды:"
  echo -e "  - ${YELLOW}pm2 status${NC} - посмотреть статус сервера"
  echo -e "  - ${YELLOW}pm2 logs atom-game-server${NC} - посмотреть логи сервера"
  echo -e "  - ${YELLOW}pm2 restart atom-game-server${NC} - перезапустить сервер"
  echo ""
  echo -e "Данные для входа в админку:"
  echo -e "  - Логин: ${GREEN}admin${NC}"
  echo -e "  - Пароль: ${GREEN}Atom&Game#2025!${NC}"
else
  echo -e "${RED}Что-то пошло не так при запуске PM2. Проверьте логи.${NC}"
fi