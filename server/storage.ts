import { users, teams, type User, type InsertUser, type Team, type InsertTeam } from "@shared/schema";
import session from "express-session";
import createMemoryStore from "memorystore";

const MemoryStore = createMemoryStore(session);

// Storage interface
export interface IStorage {
  // User methods
  getUser(id: number): Promise<User | undefined>;
  getUserByUsername(username: string): Promise<User | undefined>;
  createUser(user: InsertUser): Promise<User>;
  
  // Team methods
  getAllTeams(): Promise<Team[]>;
  getTeam(id: number): Promise<Team | undefined>;
  createTeam(team: InsertTeam): Promise<Team>;
  updateTeam(id: number, team: InsertTeam): Promise<Team>;
  deleteTeam(id: number): Promise<void>;
  
  // Session store
  sessionStore: session.SessionStore;
}

// In-memory storage implementation
export class MemStorage implements IStorage {
  private users: Map<number, User>;
  private teams: Map<number, Team>;
  private userIdCounter: number;
  private teamIdCounter: number;
  sessionStore: session.SessionStore;

  constructor() {
    this.users = new Map();
    this.teams = new Map();
    this.userIdCounter = 1;
    this.teamIdCounter = 1;
    
    this.sessionStore = new MemoryStore({
      checkPeriod: 86400000, // prune expired entries every 24h
    });
    
    // Create a default admin user
    this.createUser({
      username: "admin",
      password: "$2b$10$jQOWiMRqpj8EbmP6qDyl0ekWpJo0cM.zGUfCvA0xCNgcXRrIrZYf2.7efffd8fbc8a9f0e32875a85f6eee63ff", // "password" hashed
      isAdmin: 1,
    }).catch(console.error);
    
    // Create some sample teams
    const sampleTeams = [
      { name: "Phoenix Force", logoUrl: "", score: 89 },
      { name: "Thunderbolts", logoUrl: "", score: 72 },
      { name: "Storm Riders", logoUrl: "", score: 68 },
      { name: "Arctic Wolves", logoUrl: "", score: 55 },
      { name: "Shadow Tigers", logoUrl: "", score: 42 },
    ];
    
    sampleTeams.forEach(team => {
      this.createTeam(team).catch(console.error);
    });
  }

  // User methods
  async getUser(id: number): Promise<User | undefined> {
    return this.users.get(id);
  }

  async getUserByUsername(username: string): Promise<User | undefined> {
    return Array.from(this.users.values()).find(
      (user) => user.username === username,
    );
  }

  async createUser(user: InsertUser): Promise<User> {
    const id = this.userIdCounter++;
    const newUser: User = { ...user, id };
    this.users.set(id, newUser);
    return newUser;
  }

  // Team methods
  async getAllTeams(): Promise<Team[]> {
    return Array.from(this.teams.values());
  }

  async getTeam(id: number): Promise<Team | undefined> {
    return this.teams.get(id);
  }

  async createTeam(team: InsertTeam): Promise<Team> {
    const id = this.teamIdCounter++;
    const newTeam: Team = { ...team, id };
    this.teams.set(id, newTeam);
    return newTeam;
  }

  async updateTeam(id: number, team: InsertTeam): Promise<Team> {
    const existingTeam = this.teams.get(id);
    if (!existingTeam) {
      throw new Error(`Team with ID ${id} not found`);
    }
    
    const updatedTeam: Team = { ...team, id };
    this.teams.set(id, updatedTeam);
    return updatedTeam;
  }

  async deleteTeam(id: number): Promise<void> {
    if (!this.teams.has(id)) {
      throw new Error(`Team with ID ${id} not found`);
    }
    
    this.teams.delete(id);
  }
}

export const storage = new MemStorage();
