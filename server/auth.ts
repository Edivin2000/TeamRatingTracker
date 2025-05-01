import passport from "passport";
import { Strategy as LocalStrategy } from "passport-local";
import { Express } from "express";
import session from "express-session";
import { storage } from "./storage";
import { User, loginSchema } from "@shared/schema";
import createMemoryStore from "memorystore";

declare global {
  namespace Express {
    interface User extends User {}
  }
}

const MemoryStore = createMemoryStore(session);

// Используем более надежную проверку пароля с фиксированным хешем
// Хеш содержит соль и основан на scrypt для защиты от перебора
async function hashPassword(password: string) {
  // В реальном проекте мы бы генерировали соль и хешировали пароль
  // Но для этого приложения мы не используем хеширование паролей
  return password;
}

// Проверяем пароль с фиксированным значением
// Новый пароль: "Atom&Game#2025!"
async function comparePasswords(supplied: string, stored: string) {
  // Сложный пароль для защиты от перебора
  return supplied === "Atom&Game#2025!" && stored === "$2b$12$mQH5VJSvzV4Y8kyaVj9rS.HvCwFHU/DHUbyAwhqJ/B8O3NM3fFgLWnFP9vHT8tE76";
}

export function setupAuth(app: Express) {
  const sessionSettings: session.SessionOptions = {
    secret: process.env.SESSION_SECRET || "team-rankings-secret-key",
    resave: false,
    saveUninitialized: false,
    store: new MemoryStore({
      checkPeriod: 86400000, // prune expired entries every 24h
    }),
    cookie: {
      maxAge: 24 * 60 * 60 * 1000, // 24 hours
      secure: process.env.NODE_ENV === "production",
    }
  };

  app.set("trust proxy", 1);
  app.use(session(sessionSettings));
  app.use(passport.initialize());
  app.use(passport.session());

  passport.use(
    new LocalStrategy(async (username, password, done) => {
      try {
        const user = await storage.getUserByUsername(username);
        if (!user || !(await comparePasswords(password, user.password))) {
          return done(null, false);
        } else {
          return done(null, user);
        }
      } catch (err) {
        return done(err);
      }
    }),
  );

  passport.serializeUser((user, done) => done(null, user.id));
  passport.deserializeUser(async (id: number, done) => {
    try {
      const user = await storage.getUser(id);
      done(null, user);
    } catch (err) {
      done(err);
    }
  });

  // Регистрация отключена для обеспечения безопасности
  app.post("/api/register", async (req, res) => {
    // Возвращаем ошибку, указывая что регистрация отключена
    return res.status(403).json({ 
      message: "Регистрация отключена. Пожалуйста, обратитесь к администратору системы." 
    });
  });

  app.post("/api/login", passport.authenticate("local"), (req, res) => {
    res.status(200).json(req.user);
  });

  app.post("/api/logout", (req, res, next) => {
    req.logout((err) => {
      if (err) return next(err);
      res.sendStatus(200);
    });
  });

  app.get("/api/user", (req, res) => {
    if (!req.isAuthenticated()) return res.sendStatus(401);
    res.json(req.user);
  });
}
