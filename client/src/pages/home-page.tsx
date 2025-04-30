import { useState, useEffect, useRef } from "react";
import { useQuery } from "@tanstack/react-query";
import { Team } from "@shared/schema";
import Navbar from "@/components/layout/navbar";
import Footer from "@/components/layout/footer";
import TeamPodium from "@/components/team-podium";
import TeamTable from "@/components/team-table";
import AdBanner from "@/components/ad-banner";
import PartnersSection from "@/components/partners-section";
import { Skeleton } from "@/components/ui/skeleton";
import { Card, CardContent } from "@/components/ui/card";

// Тип для хранения предыдущих позиций команд
type TeamRankings = {
  [id: number]: {
    previousRank: number;
    currentRank: number;
  };
};

// Ключ для хранения состояния рейтингов в localStorage
const RANKINGS_STORAGE_KEY = 'teamRankingsData';

export default function HomePage() {
  // Получаем данные команд с сервера
  const { data: teams, isLoading } = useQuery<Team[]>({
    queryKey: ["/api/teams"],
    refetchInterval: 30000, // Обновляем данные каждые 30 секунд
  });

  // Состояние для хранения рейтингов
  const [rankings, setRankings] = useState<TeamRankings>({});
  
  // Сохраняем последние команды для отслеживания изменений
  const prevTeamsRef = useRef<Team[]>([]);
  
  // Обрабатываем активные команды (без исключенных, отсортированные по очкам)
  const activeTeams = teams?.filter(team => !team.excluded).sort((a, b) => b.score - a.score) || [];
  const topThreeTeams = activeTeams.slice(0, 3);
  
  // Восстановление рейтингов из localStorage при первом рендере
  useEffect(() => {
    try {
      const savedData = localStorage.getItem(RANKINGS_STORAGE_KEY);
      if (savedData) {
        const parsed = JSON.parse(savedData);
        setRankings(parsed);
        console.log("Восстановлены сохраненные рейтинги:", parsed);
      }
    } catch (error) {
      console.error("Ошибка при восстановлении рейтингов:", error);
    }
  }, []);
  
  // Отслеживаем изменения команд и обновляем рейтинги
  useEffect(() => {
    // Пропускаем обработку, если нет данных или идет загрузка
    if (!teams || isLoading || activeTeams.length === 0) return;
    
    // Получаем текущие ранги команд
    const currentRanks = new Map<number, number>();
    activeTeams.forEach((team, index) => {
      currentRanks.set(team.id, index + 1);
    });
    
    // Проверяем, есть ли какие-то изменения в очках команд
    let scoresChanged = false;
    const prevTeams = prevTeamsRef.current;
    
    // Если есть предыдущее состояние, проверяем изменения
    if (prevTeams.length > 0) {
      for (const team of activeTeams) {
        const prevTeam = prevTeams.find(t => t.id === team.id);
        if (!prevTeam || prevTeam.score !== team.score) {
          scoresChanged = true;
          console.log(`Изменение очков: команда ${team.name} (${prevTeam?.score || 'новая'} -> ${team.score})`);
          break;
        }
      }
    }
    
    // Создаем объект для новых или измененных позиций
    let newRankings: TeamRankings = {};
    
    // Проверяем, нужно ли обновлять рейтинги
    if (scoresChanged) {
      // Для каждой активной команды определяем предыдущий и текущий ранг
      activeTeams.forEach(team => {
        const currentRank = currentRanks.get(team.id) || 1;
        
        // Для новой команды
        if (!rankings[team.id]) {
          newRankings[team.id] = {
            previousRank: currentRank, // Начальное значение равно текущему
            currentRank: currentRank
          };
        } else {
          // Для существующей команды
          const oldRank = rankings[team.id].currentRank;
          const previousRank = rankings[team.id].previousRank;
          
          if (oldRank !== currentRank) {
            // Позиция изменилась
            newRankings[team.id] = {
              previousRank: oldRank,
              currentRank: currentRank
            };
            console.log(`Изменение позиции: команда ${team.name} (${oldRank} -> ${currentRank})`);
          } else {
            // Позиция не изменилась, сохраняем такой же рейтинг (включая предыдущие изменения)
            newRankings[team.id] = {
              previousRank: previousRank,
              currentRank: currentRank
            };
          }
        }
      });
      
      // Обновляем состояние рейтингов
      setRankings(newRankings);
      
      // Сохраняем в localStorage для будущих сессий
      localStorage.setItem(RANKINGS_STORAGE_KEY, JSON.stringify(newRankings));
    } else if (prevTeams.length === 0) {
      // Если это первая загрузка и нет сохраненных рейтингов, 
      // инициализируем с текущими позициями
      activeTeams.forEach(team => {
        const currentRank = currentRanks.get(team.id) || 1;
        if (!rankings[team.id]) {
          newRankings[team.id] = {
            previousRank: currentRank,
            currentRank: currentRank
          };
        } else {
          // Используем сохраненные данные, если они есть
          newRankings[team.id] = {...rankings[team.id]};
        }
      });
      
      // Только если были добавлены новые команды, обновляем состояние
      if (Object.keys(newRankings).length > 0) {
        const updatedRankings = {...rankings, ...newRankings};
        setRankings(updatedRankings);
        localStorage.setItem(RANKINGS_STORAGE_KEY, JSON.stringify(updatedRankings));
      }
    }
    
    // Сохраняем текущее состояние команд для следующего сравнения
    prevTeamsRef.current = [...activeTeams];
    
  }, [teams, isLoading, activeTeams]);
  
  return (
    <div className="flex flex-col min-h-screen">
      <Navbar />
      
      <main className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8 flex-grow">
        {/* Заголовок страницы */}
        <div className="text-center mb-10">
          <h2 className="font-heading font-bold text-3xl sm:text-4xl text-dark mb-2">Рейтинг Команд</h2>
          <p className="text-gray-600 max-w-2xl mx-auto">Текущий рейтинг всех команд на основе набранных очков</p>
        </div>

        {/* Рекламный блок */}
        <div className="mb-12">
          <AdBanner />
        </div>

        {/* Секция пьедестала */}
        <div className="mb-12">
          <h3 className="font-heading font-semibold text-xl text-dark mb-6">Лучшие Команды</h3>
          
          {isLoading ? (
            <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
              {[...Array(3)].map((_, i) => (
                <div key={i} className="flex flex-col items-center space-y-4">
                  <Skeleton className="h-40 w-full rounded-lg" />
                </div>
              ))}
            </div>
          ) : (
            <TeamPodium teams={topThreeTeams} />
          )}
        </div>

        {/* Таблица рейтинга */}
        <div className="mb-12">
          <h3 className="font-heading font-semibold text-xl text-dark mb-6">Полный Рейтинг</h3>
          
          {isLoading ? (
            <Skeleton className="h-64 w-full rounded-xl" />
          ) : (
            <TeamTable teams={activeTeams} rankings={rankings} />
          )}
        </div>

        {/* Секция партнеров */}
        <div className="mb-8">
          <h3 className="font-heading font-semibold text-xl text-dark mb-6">Наши Партнеры</h3>
          <PartnersSection />
        </div>
      </main>
      
      <Footer />
    </div>
  );
}
