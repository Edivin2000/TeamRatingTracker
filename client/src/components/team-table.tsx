import { Team } from "@shared/schema";
import { ChevronDown, ChevronUp, Minus, Medal } from "lucide-react";

// Тип для хранения рейтинга команд
type TeamRankings = {
  [id: number]: {
    previousRank: number;
    currentRank: number;
  };
};

interface TeamTableProps {
  teams: Team[];
  rankings?: TeamRankings;
}

export default function TeamTable({ teams, rankings = {} }: TeamTableProps) {
  // Исключаем команды с флагом excluded
  const activeTeams = teams.filter(team => !team.excluded).sort((a, b) => b.score - a.score);
  // Функция для отображения изменения позиции
  const renderPositionChange = (teamId: number, currentIndex: number) => {
    const teamRanking = rankings[teamId];
    
    if (!teamRanking) return null;
    
    const diff = teamRanking.previousRank - teamRanking.currentRank;
    
    if (diff > 0) {
      // Поднялись в рейтинге
      return (
        <div className="flex items-center text-green-600 text-xs font-medium">
          <ChevronUp className="h-4 w-4 mr-1" />
          <span>+{diff}</span>
        </div>
      );
    } else if (diff < 0) {
      // Опустились в рейтинге
      return (
        <div className="flex items-center text-red-600 text-xs font-medium">
          <ChevronDown className="h-4 w-4 mr-1" />
          <span>{diff}</span>
        </div>
      );
    } else {
      // Позиция не изменилась
      return (
        <div className="flex items-center text-gray-400 text-xs font-medium">
          <Minus className="h-3 w-3 mr-1" />
          <span>0</span>
        </div>
      );
    }
  };

  // Функция для отображения медали для топ-3 команд
  const renderRankBadge = (index: number) => {
    if (index === 0) {
      return (
        <div className="flex-shrink-0 flex items-center justify-center rounded-full h-8 w-8 bg-gold text-white font-bold">
          1
        </div>
      );
    } else if (index === 1) {
      return (
        <div className="flex-shrink-0 flex items-center justify-center rounded-full h-8 w-8 bg-silver text-white font-bold">
          2
        </div>
      );
    } else if (index === 2) {
      return (
        <div className="flex-shrink-0 flex items-center justify-center rounded-full h-8 w-8 bg-bronze text-white font-bold">
          3
        </div>
      );
    } else {
      return (
        <div className="flex-shrink-0 flex items-center justify-center rounded-full h-8 w-8 bg-gray-300 text-gray-700 font-bold">
          {index + 1}
        </div>
      );
    }
  };

  return (
    <div className="bg-white rounded-xl shadow-md overflow-hidden">
      <div className="overflow-x-auto">
        <table className="min-w-full divide-y divide-gray-200">
          <thead className="bg-gray-100">
            <tr className="text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
              <th scope="col" className="px-4 py-3 sm:px-6 sm:py-4 w-16 text-center">
                Место
              </th>
              <th scope="col" className="px-2 py-3 sm:px-6 sm:py-4 w-20 hidden sm:table-cell">
                Изменение
              </th>
              <th scope="col" className="px-4 py-3 sm:px-6 sm:py-4">
                Команда
              </th>
              <th scope="col" className="px-4 py-3 sm:px-6 sm:py-4 text-right">
                Очки
              </th>
            </tr>
          </thead>
          <tbody className="bg-white divide-y divide-gray-200">
            {activeTeams.length > 0 ? (
              activeTeams.map((team, index) => (
                <tr key={team.id} className={`hover:bg-gray-50 ${index < 3 ? 'bg-gray-50' : ''}`}>
                  <td className="px-4 sm:px-6 py-3 sm:py-4 whitespace-nowrap text-center">
                    <div className="flex justify-center">
                      {renderRankBadge(index)}
                    </div>
                  </td>
                  <td className="px-2 sm:px-6 py-3 sm:py-4 whitespace-nowrap hidden sm:table-cell">
                    {renderPositionChange(team.id, index)}
                  </td>
                  <td className="px-4 sm:px-6 py-3 sm:py-4 whitespace-nowrap">
                    <div className="flex items-center">
                      <div className={`flex-shrink-0 h-10 w-10 bg-gray-100 rounded-full flex items-center justify-center overflow-hidden ${index < 3 ? 'border-2 border-primary' : ''}`}>
                        {team.logoUrl ? (
                          <img 
                            src={team.logoUrl} 
                            alt={`${team.name} logo`} 
                            className="h-full w-full object-cover rounded-full" 
                          />
                        ) : (
                          <div className="text-gray-300 text-lg font-semibold">
                            {team.name.substring(0, 2).toUpperCase()}
                          </div>
                        )}
                      </div>
                      <div className="ml-4">
                        <div className={`text-sm font-medium ${index < 3 ? 'text-primary font-semibold' : 'text-gray-900'}`}>
                          {team.name}
                        </div>
                        <div className="text-xs text-green-600 sm:hidden flex items-center mt-1">
                          {renderPositionChange(team.id, index)}
                        </div>
                      </div>
                    </div>
                  </td>
                  <td className="px-4 sm:px-6 py-3 sm:py-4 whitespace-nowrap text-right">
                    <span className={`inline-flex items-center justify-center font-bold text-dark px-3 sm:px-4 py-1 rounded-full ${index < 3 ? 'bg-blue-100' : 'bg-gray-100'}`}>
                      {team.score}
                    </span>
                  </td>
                </tr>
              ))
            ) : (
              <tr>
                <td colSpan={4} className="px-6 py-10 text-center text-gray-500">
                  Нет доступных команд. Добавьте команды, чтобы увидеть их здесь.
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}
