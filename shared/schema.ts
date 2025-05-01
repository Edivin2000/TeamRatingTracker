import { pgTable, text, serial, integer, varchar, boolean } from "drizzle-orm/pg-core";
import { createInsertSchema } from "drizzle-zod";
import { z } from "zod";

// User schema
export const users = pgTable("users", {
  id: serial("id").primaryKey(),
  username: text("username").notNull().unique(),
  password: text("password").notNull(),
  isAdmin: integer("is_admin").default(0).notNull(),
});

export const insertUserSchema = createInsertSchema(users).pick({
  username: true,
  password: true,
  isAdmin: true,
});

export type InsertUser = z.infer<typeof insertUserSchema>;
export type User = typeof users.$inferSelect;

// Team schema
export const teams = pgTable("teams", {
  id: serial("id").primaryKey(),
  name: varchar("name", { length: 100 }).notNull(),
  logoUrl: text("logo_url").default(""),
  score: integer("score").default(0).notNull(),
  excluded: boolean("excluded").default(false),
});

export const insertTeamSchema = createInsertSchema(teams).pick({
  name: true,
  logoUrl: true,
  score: true,
  excluded: true,
});

export type InsertTeam = z.infer<typeof insertTeamSchema>;
export type Team = typeof teams.$inferSelect;

// Partners schema
export const partners = pgTable("partners", {
  id: serial("id").primaryKey(),
  name: varchar("name", { length: 100 }).notNull(),
  logoUrl: text("logo_url").default(""),
  website: text("website").default("#"),
  order: integer("order").default(0),
});

export const insertPartnerSchema = createInsertSchema(partners).pick({
  name: true,
  logoUrl: true,
  website: true,
  order: true,
});

export type InsertPartner = z.infer<typeof insertPartnerSchema>;
export type Partner = typeof partners.$inferSelect;

// Ad Banners schema
export const ads = pgTable("ads", {
  id: serial("id").primaryKey(),
  title: varchar("title", { length: 200 }).notNull(),
  description: text("description").notNull(),
  logoUrl: text("logo_url").default(""),
  bgImage: text("bg_image").default(""),
  bgColor: varchar("bg_color", { length: 30 }).default("from-blue-600 to-indigo-700"),
  buttonText: varchar("button_text", { length: 50 }).default("Подробнее"),
  buttonLink: text("button_link").default("#"),
  active: boolean("active").default(true),
  order: integer("order").default(0),
});

export const insertAdSchema = createInsertSchema(ads).pick({
  title: true,
  description: true,
  logoUrl: true,
  bgImage: true,
  bgColor: true,
  buttonText: true,
  buttonLink: true,
  active: true,
  order: true,
});

export type InsertAd = z.infer<typeof insertAdSchema>;
export type Ad = typeof ads.$inferSelect;

// Login schema
export const loginSchema = z.object({
  username: z.string().min(1, "Имя пользователя обязательно"),
  password: z.string().min(1, "Пароль обязателен"),
});

// Score Update schema
export const scoreUpdateSchema = z.object({
  operation: z.enum(["add", "subtract", "set"]),
  value: z.number().int().min(0, "Значение должно быть положительным числом"),
});

// Таймер схема
export const timers = pgTable("timers", {
  id: serial("id").primaryKey(),
  name: varchar("name", { length: 100 }).notNull(),
  endDate: varchar("end_date", { length: 30 }).notNull(), // ISO datetime string
  active: boolean("active").default(true),
  displayName: varchar("display_name", { length: 100 }).default(""),
  color: varchar("color", { length: 30 }).default("from-blue-600 to-indigo-700"),
});

export const insertTimerSchema = createInsertSchema(timers).pick({
  name: true,
  endDate: true,
  active: true,
  displayName: true,
  color: true,
});

export type InsertTimer = z.infer<typeof insertTimerSchema>;
export type Timer = typeof timers.$inferSelect;

// Схема настроек сайта
export const siteSettings = pgTable("site_settings", {
  id: serial("id").primaryKey(),
  primaryColor: varchar("primary_color", { length: 30 }).default("#0f172a").notNull(),
  secondaryColor: varchar("secondary_color", { length: 30 }).default("#1e293b").notNull(),
  accentColor: varchar("accent_color", { length: 30 }).default("#3b82f6").notNull(),
  headerBgColor: varchar("header_bg_color", { length: 30 }).default("#0f172a").notNull(),
  fontPrimary: varchar("font_primary", { length: 30 }).default("Inter").notNull(),
  borderRadius: varchar("border_radius", { length: 10 }).default("0.5rem").notNull(),
  buttonStyle: varchar("button_style", { length: 30 }).default("default").notNull(),
  tableBgColor: varchar("table_bg_color", { length: 30 }).default("#1e293b").notNull(),
  cardBgColor: varchar("card_bg_color", { length: 30 }).default("#1e293b").notNull(),
  podiumStyle: varchar("podium_style", { length: 30 }).default("default").notNull(),
  bgPattern: varchar("bg_pattern", { length: 30 }).default("none").notNull(),
  logoPosition: varchar("logo_position", { length: 30 }).default("center").notNull(),
  updated: text("updated").default(new Date().toISOString()),
});

export const insertSiteSettingsSchema = createInsertSchema(siteSettings).pick({
  primaryColor: true,
  secondaryColor: true,
  accentColor: true,
  headerBgColor: true,
  fontPrimary: true,
  borderRadius: true,
  buttonStyle: true,
  tableBgColor: true,
  cardBgColor: true,
  podiumStyle: true,
  bgPattern: true,
  logoPosition: true,
});

export type InsertSiteSettings = z.infer<typeof insertSiteSettingsSchema>;
export type SiteSettings = typeof siteSettings.$inferSelect;

export type ScoreUpdate = z.infer<typeof scoreUpdateSchema>;
export type LoginData = z.infer<typeof loginSchema>;
