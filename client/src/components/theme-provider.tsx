import { useEffect } from "react";
import { useSiteSettings } from "@/hooks/use-site-settings";

export function ThemeProvider({ children }: { children: React.ReactNode }) {
  const { settings, isLoading } = useSiteSettings();

  useEffect(() => {
    if (isLoading || !settings) return;

    // Применяем цвета и другие стили к :root CSS переменным
    const root = document.documentElement;
    
    // Цвета
    root.style.setProperty("--primary-color", settings.primaryColor);
    root.style.setProperty("--secondary-color", settings.secondaryColor);
    root.style.setProperty("--accent-color", settings.accentColor);
    root.style.setProperty("--header-bg-color", settings.headerBgColor);
    root.style.setProperty("--table-bg-color", settings.tableBgColor);
    root.style.setProperty("--card-bg-color", settings.cardBgColor);
    
    // Другие стили
    root.style.setProperty("--font-primary", settings.fontPrimary);
    root.style.setProperty("--border-radius", settings.borderRadius);
    
    // CSS класс для паттерна фона если не "none"
    if (settings.bgPattern !== "none") {
      document.body.classList.add(`pattern-${settings.bgPattern}`);
    } else {
      // Удаляем все классы паттернов
      document.body.classList.remove("pattern-dots", "pattern-grid", "pattern-lines");
    }
    
    // CSS класс для позиции логотипа
    document.body.setAttribute("data-logo-position", settings.logoPosition);
    
    // CSS класс для стиля кнопок
    document.body.setAttribute("data-button-style", settings.buttonStyle);
    
    // CSS класс для стиля подиума
    document.body.setAttribute("data-podium-style", settings.podiumStyle);
    
  }, [settings, isLoading]);

  return <>{children}</>;
}