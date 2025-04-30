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
  
  // Хранение полной истории рейтингов в локальном хранилище
  useEffect(() => {
    // Восстанавливаем предыдущие рейтинги из localStorage при первой загрузке
    const storedRankings = localStorage.getItem('teamRankings');
    const storedTimestamp = localStorage.getItem('rankingsTimestamp');
    
    // Используем сохраненные рейтинги, если они не старше 24 часов
    if (storedRankings && storedTimestamp) {
      const timestamp = parseInt(storedTimestamp);
      const now = Date.now();
      const isExpired = now - timestamp > 24 * 60 * 60 * 1000; // 24 часа
      
      if (!isExpired && Object.keys(teamRankings).length === 0) {
        try {
          const parsedRankings = JSON.parse(storedRankings);
          console.log("Восстановлены рейтинги из хранилища:", parsedRankings);
          setTeamRankings(parsedRankings);
        } catch (e) {
          console.error("Ошибка при разборе сохраненных рейтингов:", e);
        }
      }
    }
  }, []);
  
  // Сохраняем рейтинги в localStorage для их сохранения между сессиями
  useEffect(() => {
    if (Object.keys(teamRankings).length > 0) {
      localStorage.setItem('teamRankings', JSON.stringify(teamRankings));
      localStorage.setItem('rankingsTimestamp', Date.now().toString());
    }
  }, [teamRankings]);
  
  // Отслеживаем изменения в данных команд и обновляем рейтинги
  useEffect(() => {
    // Если нет активных команд или данные загружаются, ничего не делаем
    if (activeTeams.length === 0 || isLoading) return;
    
    console.log("Активные команды:", activeTeams.map(t => `${t.id}-${t.name}-${t.score}`));
    console.log("Предыдущие команды:", prevTeamsRef.current.map(t => `${t.id}-${t.name}-${t.score}`));
    
    // Записываем последние загруженные команды
    const lastLoadedTeams = [...prevTeamsRef.current];
    
    // Если предыдущих команд нет или это первая загрузка
    const isFirstLoad = lastLoadedTeams.length === 0;
    
    // Проверяем изменения позиций
    let hasPositionChanges = false;
    
    // Проверяем изменение счета
    if (!isFirstLoad) {
      // Сравниваем текущие команды с предыдущими
      for (const team of activeTeams) {
        const prevTeam = lastLoadedTeams.find(t => t.id === team.id);
        if (!prevTeam || prevTeam.score !== team.score) {
          hasPositionChanges = true;
          console.log(`Обнаружено изменение счета: ${team.name} с ${prevTeam?.score} на ${team.score}`);
          break;
        }
      }
    }
    
    // Формируем текущие ранги команд
    const currentRanks = new Map<number, number>();
    activeTeams.forEach((team, index) => {
      currentRanks.set(team.id, index + 1);
    });
    
    // Создаем или обновляем рейтинги
    const newRankings: TeamRankings = {};
    
    if (isFirstLoad || Object.keys(teamRankings).length === 0) {
      // Первая загрузка - устанавливаем начальные значения
      console.log("Инициализация рейтингов - первая загрузка или сброс");
      
      // Устанавливаем одинаковые начальные значения
      activeTeams.forEach((team) => {
        const currentRank = currentRanks.get(team.id) || 1;
        newRankings[team.id] = {
          previousRank: currentRank, 
          currentRank: currentRank,
        };
      });
      
      // Обновляем состояние
      setTeamRankings(newRankings);
    } 
    else if (hasPositionChanges) {
      // Обнаружены изменения - обновляем рейтинги
      console.log("Обнаружены изменения позиций команд");
      
      // Для каждой активной команды
      for (const team of activeTeams) {
        const currentRank = currentRanks.get(team.id) || 1;
        
        // Если команда уже была в рейтингах
        if (teamRankings[team.id]) {
          const oldRanking = teamRankings[team.id];
          const oldRank = oldRanking.currentRank;
          
          // Если рейтинг изменился
          if (currentRank !== oldRank) {
            newRankings[team.id] = {
              previousRank: oldRank, // Предыдущий ранг
              currentRank: currentRank, // Новый ранг
            };
            console.log(`Изменение позиции: ${team.name} с ${oldRank} на ${currentRank}`);
          } else {
            // Позиция не изменилась
            newRankings[team.id] = { ...oldRanking };
          }
        } else {
          // Новая команда
          newRankings[team.id] = {
            previousRank: currentRank,
            currentRank: currentRank,
          };
        }
      }
      
      // Обновляем состояние рейтингов только при наличии изменений
      if (Object.keys(newRankings).length > 0) {
        console.log("Обновление рейтингов:", newRankings);
        setTeamRankings(prev => {
          // Объединяем предыдущие рейтинги с новыми изменениями
          return { ...prev, ...newRankings };
        });
      }
    }
    
    // Сохраняем текущее состояние для следующего сравнения
    prevTeamsRef.current = [...activeTeams];
  }, [activeTeams, isLoading]);

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
