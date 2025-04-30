import { useState, useEffect } from "react";
import { useQuery } from "@tanstack/react-query";
import { Team } from "@shared/schema";
import Navbar from "@/components/layout/navbar";
import Footer from "@/components/layout/footer";
import TeamPodium from "@/components/team-podium";
import TeamTable from "@/components/team-table";
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

// Данные о партнерах
const partners = [
  {
    id: 1,
    name: "Фонд АТР АЭС",
    logo: "https://via.placeholder.com/160x80?text=ATR_AES",
    website: "#"
  },
  {
    id: 2,
    name: "АО 'Концерн Росэнергоатом'",
    logo: "https://via.placeholder.com/160x80?text=ROSATOM",
    website: "#"
  },
  {
    id: 3,
    name: "Патриотический клуб «Атом»",
    logo: "https://via.placeholder.com/160x80?text=ATOM",
    website: "#"
  },
  {
    id: 4,
    name: "Развитие",
    logo: "https://via.placeholder.com/160x80?text=SPONSOR",
    website: "#"
  }
];

export default function HomePage() {
  const { data: teams, isLoading } = useQuery<Team[]>({
    queryKey: ["/api/teams"],
    refetchInterval: 30000, // Обновляем данные каждые 30 секунд
  });

  const [teamRankings, setTeamRankings] = useState<TeamRankings>({});
  
  // Сортируем команды по очкам
  const sortedTeams = teams?.sort((a, b) => b.score - a.score) || [];
  const topThreeTeams = sortedTeams.slice(0, 3);

  // Обновляем позиции команд при изменении данных
  useEffect(() => {
    if (sortedTeams.length > 0) {
      const newRankings: TeamRankings = {};
      
      // Определяем текущие позиции
      sortedTeams.forEach((team, index) => {
        const currentRank = index + 1;
        const previousRank = teamRankings[team.id]?.currentRank || currentRank;
        
        newRankings[team.id] = {
          previousRank: previousRank,
          currentRank: currentRank,
        };
      });
      
      // Обновляем на следующем рендеринге для отображения изменений
      setTimeout(() => {
        setTeamRankings(newRankings);
      }, 100);
    }
  }, [sortedTeams]);

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
          <div className="bg-gradient-to-r from-blue-600 to-indigo-700 rounded-xl shadow-md overflow-hidden">
            <div className="px-6 py-8 sm:p-10 sm:flex sm:items-center">
              <div className="sm:flex-1">
                <h3 className="text-xl font-extrabold text-white sm:text-2xl">
                  Турнир ATOM﮳GAME 2025
                </h3>
                <p className="mt-2 text-white text-sm sm:text-base leading-relaxed">
                  Не пропустите грандиозный турнир по киберспорту среди молодежи атомных городов России!
                  Соревнования в дисциплинах Dota 2, CS2, и FIFA с участием команд из разных регионов.
                </p>
                <div className="mt-4">
                  <a
                    href="#" 
                    className="inline-flex items-center px-4 py-2 border border-white text-sm font-medium rounded-md text-white hover:bg-white hover:bg-opacity-10 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-offset-blue-600 focus:ring-white transition"
                  >
                    Подробнее <ExternalLink className="ml-2 h-4 w-4" />
                  </a>
                </div>
              </div>
              <div className="mt-6 sm:mt-0 sm:ml-10 sm:flex-shrink-0">
                <img 
                  src="https://via.placeholder.com/120x120?text=ATOM" 
                  alt="ATOM﮳GAME Logo" 
                  className="h-24 w-24 object-cover object-center rounded-md border-2 border-white"
                />
              </div>
            </div>
          </div>
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
            <TeamTable teams={sortedTeams} rankings={teamRankings} />
          )}
        </div>

        {/* Секция партнеров */}
        <div className="mb-8">
          <h3 className="font-heading font-semibold text-xl text-dark mb-6">Наши Партнеры</h3>
          <div className="bg-white rounded-xl shadow-md p-6">
            <div className="grid grid-cols-2 md:grid-cols-4 gap-6">
              {partners.map((partner) => (
                <a 
                  key={partner.id} 
                  href={partner.website} 
                  target="_blank" 
                  rel="noopener noreferrer"
                  className="block"
                >
                  <Card className="border-0 transition-all duration-200 hover:shadow-md">
                    <CardContent className="flex items-center justify-center p-4 h-24">
                      <img 
                        src={partner.logo}
                        alt={`${partner.name} logo`}
                        className="max-h-16 max-w-full"
                      />
                    </CardContent>
                  </Card>
                  <div className="mt-2 text-center text-sm text-gray-600">
                    {partner.name}
                  </div>
                </a>
              ))}
            </div>
            <div className="mt-6 text-center text-sm text-gray-500">
              <p>Разработчик: <span className="font-medium">ATOM﮳GAME Team</span></p>
            </div>
          </div>
        </div>
      </main>
      
      <Footer />
    </div>
  );
}
