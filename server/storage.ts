import { users, teams, partners, ads, timers, siteSettings, type User, type InsertUser, 
  type Team, type InsertTeam, type Partner, type InsertPartner, 
  type Ad, type InsertAd, type Timer, type InsertTimer, type ScoreUpdate,
  type SiteSettings, type InsertSiteSettings } from "@shared/schema";
import session from "express-session";
import createMemoryStore from "memorystore";
import connectPg from "connect-pg-simple";
import { db } from './db';
import { pool } from './db';
import { eq, desc, asc } from 'drizzle-orm';

const MemoryStore = createMemoryStore(session);
const PostgresSessionStore = connectPg(session);

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
  
  // Timer methods
  getAllTimers(): Promise<Timer[]>;
  getActiveTimers(): Promise<Timer[]>;
  getTimer(id: number): Promise<Timer | undefined>;
  createTimer(timer: InsertTimer): Promise<Timer>;
  updateTimer(id: number, timer: InsertTimer): Promise<Timer>;
  deleteTimer(id: number): Promise<void>;
  
  // Site Settings methods
  getSiteSettings(): Promise<SiteSettings | undefined>;
  updateSiteSettings(settings: InsertSiteSettings): Promise<SiteSettings>;
  
  // Session store
  sessionStore: any;
}

// In-memory storage implementation
export class MemStorage implements IStorage {
  private users: Map<number, User>;
  private teams: Map<number, Team>;
  private partners: Map<number, Partner>;
  private ads: Map<number, Ad>;
  private timers: Map<number, Timer>;
  private siteSettings: SiteSettings | undefined;
  private userIdCounter: number;
  private teamIdCounter: number;
  private partnerIdCounter: number;
  private adIdCounter: number;
  private timerIdCounter: number;
  sessionStore: any;

  constructor() {
    this.users = new Map();
    this.teams = new Map();
    this.partners = new Map();
    this.ads = new Map();
    this.timers = new Map();
    this.userIdCounter = 1;
    this.teamIdCounter = 1;
    this.partnerIdCounter = 1;
    this.adIdCounter = 1;
    this.timerIdCounter = 1;
    
    this.sessionStore = new MemoryStore({
      checkPeriod: 86400000, // prune expired entries every 24h
    });
    
    // Инициализация настроек сайта по умолчанию
    this.siteSettings = {
      id: 1,
      primaryColor: "#0f172a",
      secondaryColor: "#1e293b",
      accentColor: "#3b82f6",
      headerBgColor: "#0f172a",
      fontPrimary: "Inter",
      borderRadius: "0.5rem",
      buttonStyle: "default",
      tableBgColor: "#1e293b",
      cardBgColor: "#1e293b",
      podiumStyle: "default",
      bgPattern: "none",
      logoPosition: "center",
      updated: new Date().toISOString()
    };
    
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
  
  // Timer methods - заглушки для соответствия интерфейсу
  async getAllTimers(): Promise<Timer[]> {
    return [];
  }
  
  async getActiveTimers(): Promise<Timer[]> {
    return [];
  }
  
  async getTimer(id: number): Promise<Timer | undefined> {
    return undefined;
  }
  
  async createTimer(timer: InsertTimer): Promise<Timer> {
    throw new Error("Таймеры не поддерживаются в версии с хранением в памяти");
  }
  
  async updateTimer(id: number, timer: InsertTimer): Promise<Timer> {
    throw new Error("Таймеры не поддерживаются в версии с хранением в памяти");
  }
  
  async deleteTimer(id: number): Promise<void> {
    throw new Error("Таймеры не поддерживаются в версии с хранением в памяти");
  }
  
  // Site Settings methods
  async getSiteSettings(): Promise<SiteSettings | undefined> {
    return this.siteSettings;
  }

  async updateSiteSettings(settings: InsertSiteSettings): Promise<SiteSettings> {
    this.siteSettings = {
      ...this.siteSettings!,
      ...settings,
      updated: new Date().toISOString()
    };
    return this.siteSettings;
  }
}

// Class for database storage
export class DatabaseStorage implements IStorage {
  sessionStore: any;

  constructor() {
    this.sessionStore = new PostgresSessionStore({ 
      pool, 
      createTableIfMissing: true,
      tableName: 'session' 
    });
    
    // Ensure admin user exists (setup once)
    this.initializeDatabase();
  }

  private async initializeDatabase() {
    try {
      // Check if admin user exists
      const adminUser = await this.getUserByUsername("admin");
      if (!adminUser) {
        console.log("Creating admin user...");
        await this.createUser({
          username: "admin",
          // Hardcoded password just for authentication simplification
          password: "$2b$12$mQH5VJSvzV4Y8kyaVj9rS.HvCwFHU/DHUbyAwhqJ/B8O3NM3fFgLWnFP9vHT8tE76", // "Atom&Game#2025!" hashed
          isAdmin: 1,
        });
      }

      // Check if any teams exist
      const allTeams = await this.getAllTeams();
      if (allTeams.length === 0) {
        console.log("Creating sample teams...");
        const sampleTeams = [
          { name: "Phoenix Force", logoUrl: "https://placehold.co/100x100/orange/white?text=PF", score: 89, excluded: false },
          { name: "Thunderbolts", logoUrl: "https://placehold.co/100x100/blue/white?text=TB", score: 72, excluded: false },
          { name: "Storm Riders", logoUrl: "https://placehold.co/100x100/purple/white?text=SR", score: 68, excluded: false },
          { name: "Arctic Wolves", logoUrl: "https://placehold.co/100x100/teal/white?text=AW", score: 55, excluded: true },
          { name: "Shadow Tigers", logoUrl: "https://placehold.co/100x100/gray/white?text=ST", score: 42, excluded: false },
        ];
        
        for (const team of sampleTeams) {
          await this.createTeam(team);
        }
      }

      // Check if any partners exist
      const allPartners = await this.getAllPartners();
      if (allPartners.length === 0) {
        console.log("Creating sample partners...");
        const samplePartners = [
          { name: "Росэнергоатом", logoUrl: "https://placehold.co/200x100/blue/white?text=Росэнергоатом", website: "https://www.rosenergoatom.ru/", order: 1 },
          { name: "Фонд АТР АЭС", logoUrl: "https://placehold.co/200x100/green/white?text=Фонд+АТР+АЭС", website: "https://atompsy.ru/", order: 2 },
          { name: "ATOM﮳GAME", logoUrl: "https://placehold.co/200x100/orange/white?text=ATOM﮳GAME", website: "https://atomgame.ru/", order: 3 },
        ];
        
        for (const partner of samplePartners) {
          await this.createPartner(partner);
        }
      }

      // Check if any ads exist
      const allAds = await this.getAllAds();
      if (allAds.length === 0) {
        console.log("Creating sample ads...");
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
        
        for (const ad of sampleAds) {
          await this.createAd(ad);
        }
      }
    } catch (error) {
      console.error("Error initializing database:", error);
    }
  }

  // User methods
  async getUser(id: number): Promise<User | undefined> {
    const [user] = await db.select().from(users).where(eq(users.id, id));
    return user;
  }

  async getUserByUsername(username: string): Promise<User | undefined> {
    const [user] = await db.select().from(users).where(eq(users.username, username));
    return user;
  }

  async createUser(user: InsertUser): Promise<User> {
    const [newUser] = await db.insert(users).values(user).returning();
    return newUser;
  }

  // Team methods
  async getAllTeams(): Promise<Team[]> {
    return await db.select().from(teams);
  }

  async getTeam(id: number): Promise<Team | undefined> {
    const [team] = await db.select().from(teams).where(eq(teams.id, id));
    return team;
  }

  async createTeam(team: InsertTeam): Promise<Team> {
    const [newTeam] = await db.insert(teams).values(team).returning();
    return newTeam;
  }

  async updateTeam(id: number, team: InsertTeam): Promise<Team> {
    const [updatedTeam] = await db
      .update(teams)
      .set(team)
      .where(eq(teams.id, id))
      .returning();

    if (!updatedTeam) {
      throw new Error(`Команда с ID ${id} не найдена`);
    }
    
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
    
    const [updatedTeam] = await db
      .update(teams)
      .set({ score: newScore })
      .where(eq(teams.id, id))
      .returning();
      
    return updatedTeam;
  }

  async deleteTeam(id: number): Promise<void> {
    await db.delete(teams).where(eq(teams.id, id));
  }
  
  // Partner methods
  async getAllPartners(): Promise<Partner[]> {
    return await db.select().from(partners).orderBy(asc(partners.order));
  }

  async getPartner(id: number): Promise<Partner | undefined> {
    const [partner] = await db.select().from(partners).where(eq(partners.id, id));
    return partner;
  }

  async createPartner(partner: InsertPartner): Promise<Partner> {
    const [newPartner] = await db.insert(partners).values(partner).returning();
    return newPartner;
  }

  async updatePartner(id: number, partner: InsertPartner): Promise<Partner> {
    const [updatedPartner] = await db
      .update(partners)
      .set(partner)
      .where(eq(partners.id, id))
      .returning();
      
    if (!updatedPartner) {
      throw new Error(`Партнер с ID ${id} не найден`);
    }
    
    return updatedPartner;
  }

  async deletePartner(id: number): Promise<void> {
    await db.delete(partners).where(eq(partners.id, id));
  }
  
  // Ad Banner methods
  async getAllAds(): Promise<Ad[]> {
    return await db
      .select()
      .from(ads)
      .where(eq(ads.active, true))
      .orderBy(asc(ads.order));
  }

  async getAd(id: number): Promise<Ad | undefined> {
    const [ad] = await db.select().from(ads).where(eq(ads.id, id));
    return ad;
  }

  async createAd(ad: InsertAd): Promise<Ad> {
    const [newAd] = await db.insert(ads).values(ad).returning();
    return newAd;
  }

  async updateAd(id: number, ad: InsertAd): Promise<Ad> {
    const [updatedAd] = await db
      .update(ads)
      .set(ad)
      .where(eq(ads.id, id))
      .returning();
      
    if (!updatedAd) {
      throw new Error(`Рекламный баннер с ID ${id} не найден`);
    }
    
    return updatedAd;
  }

  async deleteAd(id: number): Promise<void> {
    await db.delete(ads).where(eq(ads.id, id));
  }
  
  // Timer methods
  async getAllTimers(): Promise<Timer[]> {
    try {
      return await db.select()
        .from(timers)
        .orderBy(asc(timers.id));
    } catch (error) {
      console.error('Error getting all timers:', error);
      throw new Error('Не удалось получить список таймеров');
    }
  }
  
  async getActiveTimers(): Promise<Timer[]> {
    try {
      return await db.select()
        .from(timers)
        .where(eq(timers.active, true))
        .orderBy(asc(timers.id));
    } catch (error) {
      console.error('Error getting active timers:', error);
      throw new Error('Не удалось получить список активных таймеров');
    }
  }
  
  async getTimer(id: number): Promise<Timer | undefined> {
    try {
      const results = await db.select()
        .from(timers)
        .where(eq(timers.id, id));
      return results[0];
    } catch (error) {
      console.error('Error getting timer:', error);
      throw new Error(`Не удалось получить таймер с ID ${id}`);
    }
  }
  
  async createTimer(timer: InsertTimer): Promise<Timer> {
    try {
      const [result] = await db.insert(timers)
        .values(timer)
        .returning();
      return result;
    } catch (error) {
      console.error('Error creating timer:', error);
      throw new Error('Не удалось создать таймер');
    }
  }
  
  async updateTimer(id: number, timer: InsertTimer): Promise<Timer> {
    try {
      const [result] = await db.update(timers)
        .set(timer)
        .where(eq(timers.id, id))
        .returning();
      
      if (!result) {
        throw new Error(`Таймер с ID ${id} не найден`);
      }
      
      return result;
    } catch (error) {
      console.error('Error updating timer:', error);
      throw new Error(`Не удалось обновить таймер с ID ${id}`);
    }
  }
  
  async deleteTimer(id: number): Promise<void> {
    try {
      await db.delete(timers)
        .where(eq(timers.id, id));
    } catch (error) {
      console.error('Error deleting timer:', error);
      throw new Error(`Не удалось удалить таймер с ID ${id}`);
    }
  }
  
  // Site Settings methods
  async getSiteSettings(): Promise<SiteSettings | undefined> {
    try {
      // Прямой запрос без дополнительной логики
      const result = await db.select().from(siteSettings);
      if (result.length > 0) {
        return result[0];
      }
      return undefined;
    } catch (error) {
      console.error('Error getting site settings:', error);
      return undefined;
    }
  }

  async createDefaultSiteSettings(): Promise<SiteSettings | undefined> {
    try {
      const defaultSettings = {
        primaryColor: "#0f172a",
        secondaryColor: "#1e293b",
        accentColor: "#3b82f6",
        headerBgColor: "#0f172a",
        fontPrimary: "Inter",
        borderRadius: "0.5rem",
        buttonStyle: "default",
        tableBgColor: "#1e293b",
        cardBgColor: "#1e293b",
        podiumStyle: "default",
        bgPattern: "none",
        logoPosition: "center",
        updated: new Date().toISOString()
      };
      
      const [newSettings] = await db
        .insert(siteSettings)
        .values(defaultSettings)
        .returning();
        
      return newSettings;
    } catch (error) {
      console.error('Error creating default site settings:', error);
      return undefined;
    }
  }

  async updateSiteSettings(settings: InsertSiteSettings): Promise<SiteSettings> {
    try {
      // Сначала проверяем, существуют ли настройки, напрямую через базу данных
      const existingSettings = await db.select().from(siteSettings);
      
      // Устанавливаем текущую дату обновления
      const dataToSave = { 
        ...settings, 
        updated: new Date().toISOString() 
      };
      
      if (existingSettings.length > 0) {
        // Обновляем существующие настройки
        const [updated] = await db
          .update(siteSettings)
          .set(dataToSave)
          .where(eq(siteSettings.id, existingSettings[0].id))
          .returning();
          
        return updated;
      } else {
        // Создаем новые настройки
        const [newSettings] = await db
          .insert(siteSettings)
          .values(dataToSave)
          .returning();
          
        return newSettings;
      }
    } catch (error) {
      console.error('Error updating site settings:', error);
      throw new Error('Не удалось обновить настройки сайта');
    }
  }
}

// Export DatabaseStorage instead of MemStorage
export const storage = new DatabaseStorage();
