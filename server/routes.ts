import type { Express, Request, Response } from "express";
import { createServer, type Server } from "http";
import { setupAuth } from "./auth";
import { storage } from "./storage";
import { z } from "zod";
import { insertTeamSchema, insertPartnerSchema, insertAdSchema, insertTimerSchema, scoreUpdateSchema } from "@shared/schema";

// Middleware to check if user is authenticated and admin
const isAdmin = (req: Request, res: Response, next: Function) => {
  if (!req.isAuthenticated()) {
    return res.status(401).json({ message: "Unauthorized" });
  }
  
  if (!req.user.isAdmin) {
    return res.status(403).json({ message: "Forbidden: Admin access required" });
  }
  
  next();
};

export async function registerRoutes(app: Express): Promise<Server> {
  // Setup authentication routes
  setupAuth(app);

  // Team routes
  // Get all teams - public
  app.get("/api/teams", async (req, res) => {
    try {
      const teams = await storage.getAllTeams();
      res.json(teams);
    } catch (error) {
      res.status(500).json({ message: "Failed to fetch teams" });
    }
  });

  // Get a single team by ID - public
  app.get("/api/teams/:id", async (req, res) => {
    try {
      const id = parseInt(req.params.id);
      if (isNaN(id)) {
        return res.status(400).json({ message: "Invalid team ID" });
      }

      const team = await storage.getTeam(id);
      if (!team) {
        return res.status(404).json({ message: "Team not found" });
      }

      res.json(team);
    } catch (error) {
      res.status(500).json({ message: "Failed to fetch team" });
    }
  });

  // Create a new team - admin only
  app.post("/api/teams", isAdmin, async (req, res) => {
    try {
      // Validate request body
      const result = insertTeamSchema.safeParse(req.body);
      if (!result.success) {
        return res.status(400).json({ message: "Invalid team data" });
      }

      const newTeam = await storage.createTeam(req.body);
      res.status(201).json(newTeam);
    } catch (error) {
      res.status(500).json({ message: "Failed to create team" });
    }
  });

  // Update an existing team - admin only
  app.put("/api/teams/:id", isAdmin, async (req, res) => {
    try {
      const id = parseInt(req.params.id);
      if (isNaN(id)) {
        return res.status(400).json({ message: "Invalid team ID" });
      }

      // Validate request body
      const result = insertTeamSchema.safeParse(req.body);
      if (!result.success) {
        return res.status(400).json({ message: "Invalid team data" });
      }

      const team = await storage.getTeam(id);
      if (!team) {
        return res.status(404).json({ message: "Team not found" });
      }

      const updatedTeam = await storage.updateTeam(id, req.body);
      res.json(updatedTeam);
    } catch (error) {
      res.status(500).json({ message: "Failed to update team" });
    }
  });

  // Delete a team - admin only
  app.delete("/api/teams/:id", isAdmin, async (req, res) => {
    try {
      const id = parseInt(req.params.id);
      if (isNaN(id)) {
        return res.status(400).json({ message: "Invalid team ID" });
      }

      const team = await storage.getTeam(id);
      if (!team) {
        return res.status(404).json({ message: "Team not found" });
      }

      await storage.deleteTeam(id);
      res.sendStatus(204);
    } catch (error) {
      res.status(500).json({ message: "Failed to delete team" });
    }
  });
  
  // Update team score - admin only
  app.post("/api/teams/:id/score", isAdmin, async (req, res) => {
    try {
      const id = parseInt(req.params.id);
      if (isNaN(id)) {
        return res.status(400).json({ message: "Неверный ID команды" });
      }

      // Validate request body
      const result = scoreUpdateSchema.safeParse(req.body);
      if (!result.success) {
        return res.status(400).json({ message: "Неверные данные очков" });
      }

      const team = await storage.getTeam(id);
      if (!team) {
        return res.status(404).json({ message: "Команда не найдена" });
      }

      const updatedTeam = await storage.updateTeamScore(id, req.body);
      res.json(updatedTeam);
    } catch (error) {
      res.status(500).json({ message: "Не удалось обновить очки команды" });
    }
  });
  
  // Partner routes
  // Get all partners - public
  app.get("/api/partners", async (req, res) => {
    try {
      const partners = await storage.getAllPartners();
      res.json(partners);
    } catch (error) {
      res.status(500).json({ message: "Не удалось получить список партнеров" });
    }
  });

  // Get a single partner by ID - public
  app.get("/api/partners/:id", async (req, res) => {
    try {
      const id = parseInt(req.params.id);
      if (isNaN(id)) {
        return res.status(400).json({ message: "Неверный ID партнера" });
      }

      const partner = await storage.getPartner(id);
      if (!partner) {
        return res.status(404).json({ message: "Партнер не найден" });
      }

      res.json(partner);
    } catch (error) {
      res.status(500).json({ message: "Не удалось получить информацию о партнере" });
    }
  });

  // Create a new partner - admin only
  app.post("/api/partners", isAdmin, async (req, res) => {
    try {
      // Validate request body
      const result = insertPartnerSchema.safeParse(req.body);
      if (!result.success) {
        return res.status(400).json({ message: "Неверные данные партнера" });
      }

      const newPartner = await storage.createPartner(req.body);
      res.status(201).json(newPartner);
    } catch (error) {
      res.status(500).json({ message: "Не удалось создать партнера" });
    }
  });

  // Update an existing partner - admin only
  app.put("/api/partners/:id", isAdmin, async (req, res) => {
    try {
      const id = parseInt(req.params.id);
      if (isNaN(id)) {
        return res.status(400).json({ message: "Неверный ID партнера" });
      }

      // Validate request body
      const result = insertPartnerSchema.safeParse(req.body);
      if (!result.success) {
        return res.status(400).json({ message: "Неверные данные партнера" });
      }

      const partner = await storage.getPartner(id);
      if (!partner) {
        return res.status(404).json({ message: "Партнер не найден" });
      }

      const updatedPartner = await storage.updatePartner(id, req.body);
      res.json(updatedPartner);
    } catch (error) {
      res.status(500).json({ message: "Не удалось обновить данные партнера" });
    }
  });

  // Delete a partner - admin only
  app.delete("/api/partners/:id", isAdmin, async (req, res) => {
    try {
      const id = parseInt(req.params.id);
      if (isNaN(id)) {
        return res.status(400).json({ message: "Неверный ID партнера" });
      }

      const partner = await storage.getPartner(id);
      if (!partner) {
        return res.status(404).json({ message: "Партнер не найден" });
      }

      await storage.deletePartner(id);
      res.sendStatus(204);
    } catch (error) {
      res.status(500).json({ message: "Не удалось удалить партнера" });
    }
  });
  
  // Ad Banner routes
  // Get all ad banners - public
  app.get("/api/ads", async (req, res) => {
    try {
      const ads = await storage.getAllAds();
      res.json(ads);
    } catch (error) {
      res.status(500).json({ message: "Не удалось получить список рекламных баннеров" });
    }
  });

  // Get a single ad banner by ID - public
  app.get("/api/ads/:id", async (req, res) => {
    try {
      const id = parseInt(req.params.id);
      if (isNaN(id)) {
        return res.status(400).json({ message: "Неверный ID баннера" });
      }

      const ad = await storage.getAd(id);
      if (!ad) {
        return res.status(404).json({ message: "Баннер не найден" });
      }

      res.json(ad);
    } catch (error) {
      res.status(500).json({ message: "Не удалось получить данные баннера" });
    }
  });

  // Create a new ad banner - admin only
  app.post("/api/ads", isAdmin, async (req, res) => {
    try {
      // Validate request body
      const result = insertAdSchema.safeParse(req.body);
      if (!result.success) {
        return res.status(400).json({ message: "Неверные данные баннера" });
      }

      const newAd = await storage.createAd(req.body);
      res.status(201).json(newAd);
    } catch (error) {
      res.status(500).json({ message: "Не удалось создать баннер" });
    }
  });

  // Update an existing ad banner - admin only
  app.put("/api/ads/:id", isAdmin, async (req, res) => {
    try {
      const id = parseInt(req.params.id);
      if (isNaN(id)) {
        return res.status(400).json({ message: "Неверный ID баннера" });
      }

      // Validate request body
      const result = insertAdSchema.safeParse(req.body);
      if (!result.success) {
        return res.status(400).json({ message: "Неверные данные баннера" });
      }

      const ad = await storage.getAd(id);
      if (!ad) {
        return res.status(404).json({ message: "Баннер не найден" });
      }

      const updatedAd = await storage.updateAd(id, req.body);
      res.json(updatedAd);
    } catch (error) {
      res.status(500).json({ message: "Не удалось обновить баннер" });
    }
  });

  // Delete an ad banner - admin only
  app.delete("/api/ads/:id", isAdmin, async (req, res) => {
    try {
      const id = parseInt(req.params.id);
      if (isNaN(id)) {
        return res.status(400).json({ message: "Неверный ID баннера" });
      }

      const ad = await storage.getAd(id);
      if (!ad) {
        return res.status(404).json({ message: "Баннер не найден" });
      }

      await storage.deleteAd(id);
      res.sendStatus(204);
    } catch (error) {
      res.status(500).json({ message: "Не удалось удалить баннер" });
    }
  });
  
  // Timer routes
  // Get all active timers - public
  app.get("/api/timers", async (req, res) => {
    try {
      const timers = await storage.getActiveTimers();
      res.json(timers);
    } catch (error) {
      res.status(500).json({ message: "Не удалось получить список таймеров" });
    }
  });

  // Get a single timer by ID - public
  app.get("/api/timers/:id", async (req, res) => {
    try {
      const id = parseInt(req.params.id);
      if (isNaN(id)) {
        return res.status(400).json({ message: "Неверный ID таймера" });
      }

      const timer = await storage.getTimer(id);
      if (!timer) {
        return res.status(404).json({ message: "Таймер не найден" });
      }

      res.json(timer);
    } catch (error) {
      res.status(500).json({ message: "Не удалось получить данные таймера" });
    }
  });

  // Get all timers (active and inactive) - admin only
  app.get("/api/admin/timers", isAdmin, async (req, res) => {
    try {
      const timers = await storage.getAllTimers();
      res.json(timers);
    } catch (error) {
      res.status(500).json({ message: "Не удалось получить список всех таймеров" });
    }
  });

  // Create a new timer - admin only
  app.post("/api/timers", isAdmin, async (req, res) => {
    try {
      // Validate request body
      const result = insertTimerSchema.safeParse(req.body);
      if (!result.success) {
        return res.status(400).json({ message: "Неверные данные таймера" });
      }

      const newTimer = await storage.createTimer(req.body);
      res.status(201).json(newTimer);
    } catch (error) {
      res.status(500).json({ message: "Не удалось создать таймер" });
    }
  });

  // Update an existing timer - admin only
  app.put("/api/timers/:id", isAdmin, async (req, res) => {
    try {
      const id = parseInt(req.params.id);
      if (isNaN(id)) {
        return res.status(400).json({ message: "Неверный ID таймера" });
      }

      // Validate request body
      const result = insertTimerSchema.safeParse(req.body);
      if (!result.success) {
        return res.status(400).json({ message: "Неверные данные таймера" });
      }

      const timer = await storage.getTimer(id);
      if (!timer) {
        return res.status(404).json({ message: "Таймер не найден" });
      }

      const updatedTimer = await storage.updateTimer(id, req.body);
      res.json(updatedTimer);
    } catch (error) {
      res.status(500).json({ message: "Не удалось обновить таймер" });
    }
  });

  // Delete a timer - admin only
  app.delete("/api/timers/:id", isAdmin, async (req, res) => {
    try {
      const id = parseInt(req.params.id);
      if (isNaN(id)) {
        return res.status(400).json({ message: "Неверный ID таймера" });
      }

      const timer = await storage.getTimer(id);
      if (!timer) {
        return res.status(404).json({ message: "Таймер не найден" });
      }

      await storage.deleteTimer(id);
      res.sendStatus(204);
    } catch (error) {
      res.status(500).json({ message: "Не удалось удалить таймер" });
    }
  });

  const httpServer = createServer(app);

  return httpServer;
}
