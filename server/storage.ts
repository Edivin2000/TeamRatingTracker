import { users, teams, partners, ads, type User, type InsertUser, 
  type Team, type InsertTeam, type Partner, type InsertPartner, 
  type Ad, type InsertAd, type ScoreUpdate } from "@shared/schema";
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
  updateTeamScore(id: number, update: ScoreUpdate): Promise<Team>;
  deleteTeam(id: number): Promise<void>;
  
  // Partner methods
  getAllPartners(): Promise<Partner[]>;
  getPartner(id: number): Promise<Partner | undefined>;
  createPartner(partner: InsertPartner): Promise<Partner>;
  updatePartner(id: number, partner: InsertPartner): Promise<Partner>;
  deletePartner(id: number): Promise<void>;
  
  // Ad Banner methods
  getAllAds(): Promise<Ad[]>;
  getAd(id: number): Promise<Ad | undefined>;
  createAd(ad: InsertAd): Promise<Ad>;
  updateAd(id: number, ad: InsertAd): Promise<Ad>;
  deleteAd(id: number): Promise<void>;
  
  // Session store
  sessionStore: any;
}

// In-memory storage implementation
export class MemStorage implements IStorage {
  private users: Map<number, User>;
  private teams: Map<number, Team>;
  private partners: Map<number, Partner>;
  private ads: Map<number, Ad>;
  private userIdCounter: number;
  private teamIdCounter: number;
  private partnerIdCounter: number;
  private adIdCounter: number;
  sessionStore: any;

  constructor() {
    this.users = new Map();
    this.teams = new Map();
    this.partners = new Map();
    this.ads = new Map();
    this.userIdCounter = 1;
    this.teamIdCounter = 1;
    this.partnerIdCounter = 1;
    this.adIdCounter = 1;
    
    this.sessionStore = new MemoryStore({
      checkPeriod: 86400000, // prune expired entries every 24h
    });
    
    // Create a default admin user with new secure password
    this.createUser({
      username: "admin",
      password: "$2b$12$mQH5VJSvzV4Y8kyaVj9rS.HvCwFHU/DHUbyAwhqJ/B8O3NM3fFgLWnFP9vHT8tE76", // "Atom&Game#2025!" hashed
      isAdmin: 1,
    }).catch(console.error);
    
    // Create some sample teams
    const sampleTeams = [
      { name: "Phoenix Force", logoUrl: "https://placehold.co/100x100/orange/white?text=PF", score: 89, excluded: false },
      { name: "Thunderbolts", logoUrl: "https://placehold.co/100x100/blue/white?text=TB", score: 72, excluded: false },
      { name: "Storm Riders", logoUrl: "https://placehold.co/100x100/purple/white?text=SR", score: 68, excluded: false },
      { name: "Arctic Wolves", logoUrl: "https://placehold.co/100x100/teal/white?text=AW", score: 55, excluded: true },
      { name: "Shadow Tigers", logoUrl: "https://placehold.co/100x100/gray/white?text=ST", score: 42, excluded: false },
    ];
    
    sampleTeams.forEach(team => {
      this.createTeam(team).catch(console.error);
    });
    
    // Create some sample partners
    const samplePartners = [
      { name: "Росэнергоатом", logoUrl: "https://placehold.co/200x100/blue/white?text=Росэнергоатом", website: "https://www.rosenergoatom.ru/", order: 1 },
      { name: "Фонд АТР АЭС", logoUrl: "https://placehold.co/200x100/green/white?text=Фонд+АТР+АЭС", website: "https://atompsy.ru/", order: 2 },
      { name: "ATOM﮳GAME", logoUrl: "https://placehold.co/200x100/orange/white?text=ATOM﮳GAME", website: "https://atomgame.ru/", order: 3 },
    ];

    samplePartners.forEach(partner => {
      this.createPartner(partner).catch(console.error);
    });
    
    // Create some sample ads
    const sampleAds = [
      { 
        title: "Технологический конкурс ATOM﮳GAME", 
        description: "Примите участие в технологическом конкурсе и выиграйте ценные призы", 
        logoUrl: "https://placehold.co/120x80/white/black?text=ATOM﮳GAME", 
        bgImage: "",
        bgColor: "from-blue-600 to-indigo-700",
        buttonText: "Подробнее",
        buttonLink: "https://atomgame.ru/",
        active: true,
        order: 1
      },
      { 
        title: "Росэнергоатом приглашает", 
        description: "Карьера в атомной энергетике для молодых специалистов", 
        logoUrl: "https://placehold.co/120x80/white/blue?text=Росэнергоатом", 
        bgImage: "",
        bgColor: "from-teal-600 to-teal-800",
        buttonText: "Узнать больше",
        buttonLink: "https://www.rosenergoatom.ru/",
        active: true,
        order: 2
      },
    ];

    sampleAds.forEach(ad => {
      this.createAd(ad).catch(console.error);
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
      throw new Error(`Команда с ID ${id} не найдена`);
    }
    
    const updatedTeam: Team = { ...team, id };
    this.teams.set(id, updatedTeam);
    return updatedTeam;
  }
  
  async updateTeamScore(id: number, update: ScoreUpdate): Promise<Team> {
    const team = await this.getTeam(id);
    if (!team) {
      throw new Error(`Команда с ID ${id} не найдена`);
    }
    
    let newScore = team.score;
    
    if (update.operation === "add") {
      newScore += update.value;
    } else if (update.operation === "subtract") {
      newScore = Math.max(0, newScore - update.value);
    } else if (update.operation === "set") {
      newScore = update.value;
    }
    
    const updatedTeam: Team = { ...team, score: newScore };
    this.teams.set(id, updatedTeam);
    return updatedTeam;
  }

  async deleteTeam(id: number): Promise<void> {
    if (!this.teams.has(id)) {
      throw new Error(`Команда с ID ${id} не найдена`);
    }
    
    this.teams.delete(id);
  }
  
  // Partner methods
  async getAllPartners(): Promise<Partner[]> {
    return Array.from(this.partners.values()).sort((a, b) => a.order - b.order);
  }

  async getPartner(id: number): Promise<Partner | undefined> {
    return this.partners.get(id);
  }

  async createPartner(partner: InsertPartner): Promise<Partner> {
    const id = this.partnerIdCounter++;
    const newPartner: Partner = { ...partner, id };
    this.partners.set(id, newPartner);
    return newPartner;
  }

  async updatePartner(id: number, partner: InsertPartner): Promise<Partner> {
    const existingPartner = await this.getPartner(id);
    if (!existingPartner) {
      throw new Error(`Партнер с ID ${id} не найден`);
    }
    
    const updatedPartner: Partner = { ...partner, id };
    this.partners.set(id, updatedPartner);
    return updatedPartner;
  }

  async deletePartner(id: number): Promise<void> {
    if (!this.partners.has(id)) {
      throw new Error(`Партнер с ID ${id} не найден`);
    }
    
    this.partners.delete(id);
  }
  
  // Ad Banner methods
  async getAllAds(): Promise<Ad[]> {
    return Array.from(this.ads.values())
      .filter(ad => ad.active)
      .sort((a, b) => a.order - b.order);
  }

  async getAd(id: number): Promise<Ad | undefined> {
    return this.ads.get(id);
  }

  async createAd(ad: InsertAd): Promise<Ad> {
    const id = this.adIdCounter++;
    const newAd: Ad = { ...ad, id };
    this.ads.set(id, newAd);
    return newAd;
  }

  async updateAd(id: number, ad: InsertAd): Promise<Ad> {
    const existingAd = await this.getAd(id);
    if (!existingAd) {
      throw new Error(`Рекламный баннер с ID ${id} не найден`);
    }
    
    const updatedAd: Ad = { ...ad, id };
    this.ads.set(id, updatedAd);
    return updatedAd;
  }

  async deleteAd(id: number): Promise<void> {
    if (!this.ads.has(id)) {
      throw new Error(`Рекламный баннер с ID ${id} не найден`);
    }
    
    this.ads.delete(id);
  }
}

export const storage = new MemStorage();
