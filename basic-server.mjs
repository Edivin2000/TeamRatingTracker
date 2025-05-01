// basic-server.mjs
// Простой сервер для запуска в случае проблем с основным сервером

import express from 'express';
import path from 'path';
import fs from 'fs';
import pg from 'pg';
import { fileURLToPath } from 'url';

const { Pool } = pg;
const app = express();
const PORT = process.env.PORT || 5000;

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

// Статические файлы (из папки dist)
app.use(express.static(path.join(__dirname, 'dist')));
app.use('/assets', express.static(path.join(__dirname, 'dist/assets')));
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

// Парсинг JSON
app.use(express.json());

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

// Получение списка таймеров
app.get('/api/timers/active', async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM timers WHERE active = true');
    res.json(result.rows);
  } catch (error) {
    console.error('Ошибка при запросе таймеров:', error);
    res.status(500).json({ error: 'Ошибка при запросе данных' });
  }
});

// Получение настроек сайта
app.get('/api/site-settings', async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM site_settings');
    if (result.rows.length > 0) {
      res.json(result.rows[0]);
    } else {
      res.status(404).json({ error: 'Настройки не найдены' });
    }
  } catch (error) {
    console.error('Ошибка при запросе настроек сайта:', error);
    res.status(500).json({ error: 'Ошибка при запросе данных' });
  }
});

// Маршрут для всех остальных запросов (SPA)
app.get('*', (req, res) => {
  res.sendFile(path.join(__dirname, 'dist/index.html'));
});

// Обработка ошибок
app.use((err, req, res, next) => {
  console.error('Ошибка сервера:', err);
  res.status(500).json({ error: 'Внутренняя ошибка сервера' });
});

// Запуск сервера
app.listen(PORT, '0.0.0.0', () => {
  console.log(`Базовый сервер запущен на порту ${PORT}`);
  console.log(`URL: http://localhost:${PORT}`);
});