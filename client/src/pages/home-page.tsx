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

  // Храним предыдущий список команд для отслеживания изменений
  const [prevTeams, setPrevTeams] = useState<Team[]>([]);

  // Сохраняем предыдущие ранги при первой загрузке и обновляем при изменении данных
  useEffect(() => {
    // Если нет активных команд или данные загружаются, ничего не делаем
    if (activeTeams.length === 0 || isLoading) return;

    // Создаем новые рейтинги
    let newRankings: TeamRankings = {};

    // При первой загрузке просто инициализируем рейтинги
    if (Object.keys(teamRankings).length === 0) {
      activeTeams.forEach((team, index) => {
        const currentRank = index + 1;
        newRankings[team.id] = {
          previousRank: currentRank, 
          currentRank: currentRank,
        };
      });
      
      // Устанавливаем начальное состояние
      setTeamRankings(newRankings);
      setPrevTeams([...activeTeams]);
    } 
    // При последующих обновлениях обновляем только при изменении данных
    else {
      // Проверяем, изменились ли команды или их рейтинги
      const hasScoreChanged = activeTeams.some((team, index) => {
        const prevTeam = prevTeams.find(t => t.id === team.id);
        return !prevTeam || prevTeam.score !== team.score;
      });

      if (hasScoreChanged) {
        console.log("Обнаружено изменение счета/рейтинга");
        
        // Создаем новые рейтинги на основе текущих позиций
        activeTeams.forEach((team, index) => {
          const currentRank = index + 1;
          const prevRanking = teamRankings[team.id];
          
          if (prevRanking) {
            // Если рейтинг изменился, обновляем previousRank
            if (currentRank !== prevRanking.currentRank) {
              newRankings[team.id] = {
                previousRank: prevRanking.currentRank,
                currentRank: currentRank
              };
              console.log(`Команда ${team.name}: изменение с ${prevRanking.currentRank} на ${currentRank}`);
            } else {
              // Если рейтинг не изменился, сохраняем предыдущие значения
              newRankings[team.id] = { ...prevRanking };
            }
          } else {
            // Новая команда, устанавливаем одинаковые значения
            newRankings[team.id] = {
              previousRank: currentRank,
              currentRank: currentRank,
            };
          }
        });
        
        // Обновляем состояние только если есть изменения
        if (Object.keys(newRankings).length > 0) {
          setTeamRankings(newRankings);
          setPrevTeams([...activeTeams]);
        }
      }
    }
  // Зависимость только от teams, чтобы эффект срабатывал только при изменении данных с сервера
  }, [teams, isLoading]);

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
