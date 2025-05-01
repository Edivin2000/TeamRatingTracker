// Использование ES модулей вместо CommonJS
import http from 'http';
import fs from 'fs';
import { fileURLToPath } from 'url';
import path from 'path';
import { dirname } from 'path';

// Получение текущего пути файла в ES модулях
const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

const PORT = 3000;

const server = http.createServer((req, res) => {
  console.log(`${new Date().toISOString()} - Request: ${req.method} ${req.url}`);
  
  if (req.url === '/' || req.url === '/index.html') {
    const htmlPath = path.join(__dirname, 'public', 'index.html');
    fs.readFile(htmlPath, (err, content) => {
      if (err) {
        res.writeHead(500);
        res.end('Ошибка сервера: ' + err.message);
        console.error(err);
      } else {
        res.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8' });
        res.end(content);
      }
    });
  } else {
    res.writeHead(404);
    res.end('Страница не найдена');
  }
});

server.listen(PORT, '0.0.0.0', () => {
  console.log(`Сервер запущен на http://0.0.0.0:${PORT}`);
});

// Обработка исключений
process.on('uncaughtException', (error) => {
  console.error('Непойманное исключение:', error);
});

process.on('unhandledRejection', (reason, promise) => {
  console.error('Необработанное отклонение promise:', reason);
});