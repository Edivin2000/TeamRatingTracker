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

  // Храним идентификатор сеанса для сброса истории при перезагрузке
  const [sessionId] = useState(() => Date.now());

  // Хранение предыдущего состояния рейтинга для сравнения между обновлениями
  const prevTeamsRef = useRef<Team[]>([]);
  
  // Сохраняем предыдущие ранги при первой загрузке и обновляем при изменении данных
  useEffect(() => {
    // Если нет активных команд или данные загружаются, ничего не делаем
    if (activeTeams.length === 0 || isLoading) return;
    
    console.log("Активные команды:", activeTeams.map(t => `${t.id}-${t.name}-${t.score}`));
    console.log("Предыдущие команды:", prevTeamsRef.current.map(t => `${t.id}-${t.name}-${t.score}`));
    
    // Создаем новые рейтинги
    const newRankings: TeamRankings = {};
    
    // При первой загрузке (после очистки рейтингов)
    if (Object.keys(teamRankings).length === 0) {
      console.log("Первая загрузка данных - инициализация рейтингов");
      
      // Устанавливаем начальные позиции (равные текущим)
      activeTeams.forEach((team, index) => {
        const currentRank = index + 1;
        newRankings[team.id] = {
          previousRank: currentRank, 
          currentRank: currentRank,
        };
      });
      
      // Сохраняем начальное состояние
      setTeamRankings(newRankings);
      prevTeamsRef.current = [...activeTeams];
    } 
    // При обновлении данных
    else {
      // Проверяем, изменился ли счет команд
      let hasTeamScoreChanged = false;
      
      // Сравниваем текущие команды с предыдущим известным состоянием
      for (const team of activeTeams) {
        const prevTeam = prevTeamsRef.current.find(t => t.id === team.id);
        if (!prevTeam || prevTeam.score !== team.score) {
          hasTeamScoreChanged = true;
          console.log(`Команда ${team.name} (id:${team.id}): изменение счета с ${prevTeam?.score} на ${team.score}`);
          break;
        }
      }
      
      if (hasTeamScoreChanged) {
        console.log("Обнаружено изменение счета команд - обновляем рейтинги");
        
        // Текущие ранги всех команд (по индексу в отсортированном массиве)
        const currentRanks = new Map<number, number>();
        activeTeams.forEach((team, index) => {
          currentRanks.set(team.id, index + 1);
        });
        
        // Обновляем рейтинги каждой команды
        for (const team of activeTeams) {
          const currentRank = currentRanks.get(team.id) || 1;
          
          // Если команда уже была в рейтингах
          if (teamRankings[team.id]) {
            const oldRanking = teamRankings[team.id];
            const oldRank = oldRanking.currentRank;
            
            // Если позиция изменилась
            if (currentRank !== oldRank) {
              console.log(`Команда ${team.name} (id:${team.id}): изменение ранга с ${oldRank} на ${currentRank}`);
              newRankings[team.id] = {
                previousRank: oldRank,
                currentRank: currentRank
              };
            } else {
              // Если позиция не изменилась, сохраняем старые данные
              newRankings[team.id] = { ...oldRanking };
            }
          } 
          // Новая команда - устанавливаем одинаковые значения для рангов
          else {
            newRankings[team.id] = {
              previousRank: currentRank,
              currentRank: currentRank
            };
          }
        }
        
        // Обновляем состояние и сохраняем текущий список команд
        console.log("Новые рейтинги:", newRankings);
        setTeamRankings(newRankings);
        prevTeamsRef.current = [...activeTeams];
      }
    }
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
