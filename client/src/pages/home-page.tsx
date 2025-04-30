import { useState, useEffect } from "react";
import { useQuery } from "@tanstack/react-query";
import { Team } from "@shared/schema";
import Navbar from "@/components/layout/navbar";
import Footer from "@/components/layout/footer";
import TeamPodium from "@/components/team-podium";
import TeamTable from "@/components/team-table";
import AdBanner from "@/components/ad-banner";
import PartnersSection from "@/components/partners-section";
import { Skeleton } from "@/components/ui/skeleton";
import { ExternalLink } from "lucide-react";
import { Card, CardContent } from "@/components/ui/card";

// Тип для хранения предыдущих позиций команд
type TeamRankings = {
  [id: number]: {
    previousRank: number;
    currentRank: number;
  };
};

export default function HomePage() {
  const { data: teams, isLoading } = useQuery<Team[]>({
    queryKey: ["/api/teams"],
    refetchInterval: 30000, // Обновляем данные каждые 30 секунд
  });

  const [teamRankings, setTeamRankings] = useState<TeamRankings>({});
  
  // Сортируем команды по очкам и исключаем команды с флагом excluded
  const activeTeams = teams?.filter(team => !team.excluded).sort((a, b) => b.score - a.score) || [];
  const topThreeTeams = activeTeams.slice(0, 3);

  // Сохраняем предыдущие ранги при первой загрузке и обновляем при изменении данных
  useEffect(() => {
    if (activeTeams.length > 0) {
      const newRankings: TeamRankings = {};
      
      // При первой загрузке сохраняем начальные позиции
      if (Object.keys(teamRankings).length === 0) {
        // Если рейтингов нет, просто устанавливаем текущие позиции
        activeTeams.forEach((team, index) => {
          const currentRank = index + 1;
          newRankings[team.id] = {
            previousRank: currentRank, 
            currentRank: currentRank,
          };
        });
      } else {
        // Определяем текущие позиции для каждой команды
        activeTeams.forEach((team, index) => {
          const currentRank = index + 1;
          
          // Если команда была в предыдущих рейтингах, используем эти данные
          if (teamRankings[team.id]) {
            newRankings[team.id] = {
              // Сохраняем предыдущий ранг из текущего состояния
              previousRank: teamRankings[team.id].previousRank, 
              currentRank: currentRank,
            };
            
            // Если счёт изменился, обновляем предыдущий ранг
            // Сравниваем текущую позицию с сохраненной позицией
            if (currentRank !== teamRankings[team.id].currentRank) {
              newRankings[team.id].previousRank = teamRankings[team.id].currentRank;
            }
          } else {
            // Новая команда, устанавливаем одинаковые значения
            newRankings[team.id] = {
              previousRank: currentRank,
              currentRank: currentRank,
            };
          }
        });
      }
      
      // Обновляем состояние
      setTeamRankings(newRankings);
    }
  }, [activeTeams]);

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
            <TeamTable teams={activeTeams} rankings={teamRankings} />
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
