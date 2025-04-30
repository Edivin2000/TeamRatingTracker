import type { Express, Request, Response } from "express";
import { createServer, type Server } from "http";
import { setupAuth } from "./auth";
import { storage } from "./storage";
import { z } from "zod";
import { insertTeamSchema } from "@shared/schema";

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

  const httpServer = createServer(app);

  return httpServer;
}
