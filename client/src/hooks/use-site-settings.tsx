import { createContext, ReactNode, useContext } from "react";
import { useQuery } from "@tanstack/react-query";
import { type SiteSettings } from "@shared/schema";

type SiteSettingsContextType = {
  settings: SiteSettings | null;
  isLoading: boolean;
  error: Error | null;
};

export const SiteSettingsContext = createContext<SiteSettingsContextType | null>(null);

export function SiteSettingsProvider({ children }: { children: ReactNode }) {
  const {
    data: settings,
    error,
    isLoading,
  } = useQuery<SiteSettings>({
    queryKey: ["/api/site-settings"],
  });

  return (
    <SiteSettingsContext.Provider
      value={{
        settings: settings || null,
        isLoading,
        error: error as Error | null,
      }}
    >
      {children}
    </SiteSettingsContext.Provider>
  );
}

export function useSiteSettings() {
  const context = useContext(SiteSettingsContext);
  if (!context) {
    throw new Error("useSiteSettings must be used within a SiteSettingsProvider");
  }
  return context;
}