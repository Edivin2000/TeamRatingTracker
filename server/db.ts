import { Pool } from '@neondatabase/serverless';
import { drizzle } from 'drizzle-orm/neon-serverless';
import * as schema from "@shared/schema";

// Получение строки подключения из переменных окружения
const DATABASE_URL = process.env.DATABASE_URL || 'postgresql://atomgame:Atom%26Game%232025!@localhost:5432/atomgame';
console.log('Connecting to database using URL:', DATABASE_URL);

// Создание пула соединений
const pool = new Pool({ 
  connectionString: DATABASE_URL,
  ssl: false
});

// Создание экземпляра Drizzle ORM
const db = drizzle({ client: pool, schema });
console.log('Database connection pool created successfully');

export { pool, db };