#!/bin/bash

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Полное исправление сервера...${NC}"

# 1. Исправляем порт в index.ts
echo -e "${YELLOW}[1/5] Установка порта 5001 в index.ts...${NC}"
cat > server/index.ts << 'EOF'
import express, { type Request, Response, NextFunction } from "express";
import { registerRoutes } from "./routes";
import { setupVite, serveStatic, log } from "./vite";

const app = express();
// Увеличиваем лимит размера запроса до 10MB для загрузки изображений
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: false, limit: '10mb' }));

app.use((req, res, next) => {
  const start = Date.now();
  const path = req.path;
  let capturedJsonResponse: Record<string, any> | undefined = undefined;

  const originalResJson = res.json;
  res.json = function (bodyJson, ...args) {
    capturedJsonResponse = bodyJson;
    return originalResJson.apply(res, [bodyJson, ...args]);
  };

  res.on("finish", () => {
    const duration = Date.now() - start;
    if (path.startsWith("/api")) {
      let logLine = `${req.method} ${path} ${res.statusCode} in ${duration}ms`;
      if (capturedJsonResponse) {
        logLine += ` :: ${JSON.stringify(capturedJsonResponse)}`;
      }

      if (logLine.length > 80) {
        logLine = logLine.slice(0, 79) + "…";
      }

      log(logLine);
    }
  });

  next();
});

(async () => {
  const server = await registerRoutes(app);

  app.use((err: any, _req: Request, res: Response, _next: NextFunction) => {
    const status = err.status || err.statusCode || 500;
    const message = err.message || "Internal Server Error";

    res.status(status).json({ message });
    throw err;
  });

  // importantly only setup vite in development and after
  // setting up all the other routes so the catch-all route
  // doesn't interfere with the other routes
  if (app.get("env") === "development") {
    await setupVite(app, server);
  } else {
    serveStatic(app);
  }

  // Явно указываем порт 5001
  const port = 5001;
  const host = "0.0.0.0";
  const domain = process.env.DOMAIN || "localhost";
  
  server.listen({
    port,
    host,
    reusePort: true,
  }, () => {
    const baseUrl = process.env.NODE_ENV === "production" ? 
      `http://${domain}` : 
      `http://${host === '0.0.0.0' ? 'localhost' : host}:${port}`;
    
    log(`Server running at ${baseUrl} (port: ${port})`);
  });
})();
EOF

# 2. Исправляем базу данных
echo -e "${YELLOW}[2/5] Исправление подключения к базе данных...${NC}"
cat > server/db.ts << 'EOF'
import { Pool, neonConfig } from '@neondatabase/serverless';
import { drizzle } from 'drizzle-orm/neon-serverless';
import * as schema from "@shared/schema";
import ws from 'ws';

// Configure WebSocket for Neon Database
neonConfig.webSocketConstructor = ws;

// Получение строки подключения из переменных окружения
const DATABASE_URL = process.env.DATABASE_URL;
console.log('Подключение к базе данных...');

// Создание пула соединений
const pool = new Pool({ 
  connectionString: DATABASE_URL,
});

// Тестирование соединения
pool.query('SELECT NOW()', (err, res) => {
  if (err) {
    console.error('Ошибка соединения с базой данных:', err);
  } else {
    console.log('Подключение к базе данных успешно:', res.rows[0]);
  }
});

// Создание экземпляра Drizzle ORM
const db = drizzle({ client: pool, schema });
console.log('Database connection pool created successfully');

export { pool, db };
EOF

# 3. Исправляем формы для сохранения изображений (partner-form.tsx)
echo -e "${YELLOW}[3/5] Исправление форм для сохранения изображений...${NC}"
cat > tmp_fix_partner.sh << 'EOF'
#!/bin/bash
sed -i 's/logoUrl: logoPreview || data.logoUrl || "",/logoUrl: logoPreview || "",/g' client/src/components/partner-form.tsx
sed -i 's/const optimizeImage = async (file: File, maxWidth = 200, maxHeight = 100): Promise<string> => {/const optimizeImage = async (file: File, maxWidth = 200, maxHeight = 100): Promise<string> => {\n    if (!file) return "";/g' client/src/components/partner-form.tsx
EOF
chmod +x tmp_fix_partner.sh
./tmp_fix_partner.sh

# 4. Исправляем формы для сохранения изображений (team-form.tsx)
cat > tmp_fix_team.sh << 'EOF'
#!/bin/bash
sed -i 's/logoUrl: logoPreview || data.logoUrl || "",/logoUrl: logoPreview || "",/g' client/src/components/team-form.tsx
sed -i 's/const optimizeImage = async (file: File, maxWidth = 300, maxHeight = 300): Promise<string> => {/const optimizeImage = async (file: File, maxWidth = 300, maxHeight = 300): Promise<string> => {\n    if (!file) return "";/g' client/src/components/team-form.tsx
EOF
chmod +x tmp_fix_team.sh
./tmp_fix_team.sh

# 5. Исправляем формы для сохранения изображений (ad-banner-form.tsx)
cat > tmp_fix_ad.sh << 'EOF'
#!/bin/bash
sed -i 's/logoUrl: logoPreview || data.logoUrl || "",/logoUrl: logoPreview || "",/g' client/src/components/ad-banner-form.tsx
EOF
chmod +x tmp_fix_ad.sh
./tmp_fix_ad.sh

# Удаляем временные скрипты
rm tmp_fix_partner.sh tmp_fix_team.sh tmp_fix_ad.sh

echo -e "${GREEN}Все исправления успешно применены!${NC}"
echo -e "${YELLOW}Сервер будет запущен на порту 5001${NC}"
echo -e "${YELLOW}Изображения теперь будут корректно сохраняться в админ-панели${NC}"

echo -e "\n${GREEN}Готово! Перезапустите сервер командой: npm run dev${NC}"