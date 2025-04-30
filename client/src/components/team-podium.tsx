import { Trophy, Award, Medal } from "lucide-react";
import { Team } from "@shared/schema";

export default function TeamPodium({ teams }: { teams: Team[] }) {
  // Создаем массив из 3 позиций, заполненных командами или null
  const podiumPositions = Array(3)
    .fill(null)
    .map((_, index) => teams[index] || null);

  // Порядок позиций для сетки
  const positionOrders = ["order-2 md:order-1", "order-1 md:order-2", "order-3"];
  
  // Цветовые классы команд по позициям
  const teamColors = [
    {
      position: 2,
      bg: "bg-silver",
      border: "border-silver",
      text: "text-silver",
      label: "2",
      icon: Medal
    },
    {
      position: 1,
      bg: "bg-gold",
      border: "border-gold",
      text: "text-gold",
      label: "1",
      icon: Trophy
    },
    {
      position: 3,
      bg: "bg-bronze",
      border: "border-bronze",
      text: "text-bronze",
      label: "3",
      icon: Award
    }
  ];

  return (
    <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
      {podiumPositions.map((team, index) => {
        const colors = teamColors[index];
        const isFirst = index === 1;
        const Icon = colors.icon;
        
        return (
          <div key={index} className={positionOrders[index]}>
            {team ? (
              <div 
                className={`bg-white border-2 ${colors.border} rounded-lg shadow-md overflow-hidden transform hover:scale-105 transition duration-300 ${isFirst ? '-translate-y-4 md:-translate-y-8' : ''}`}
              >
                <div className={`${colors.bg} p-4 text-center relative`}>
                  <span className="inline-block bg-white text-dark text-lg font-bold rounded-full w-10 h-10 flex items-center justify-center">
                    {colors.label}
                  </span>
                  <Icon className={`absolute top-0 right-2 transform -translate-y-1/2 w-8 h-8 ${colors.text}`} />
                </div>
                <div className="p-6 text-center">
                  <div className={`mx-auto ${isFirst ? 'w-28 h-28' : 'w-24 h-24'} rounded-full bg-gray-100 mb-4 flex items-center justify-center overflow-hidden border-2 ${colors.border}`}>
                    {team.logoUrl ? (
                      <img 
                        src={team.logoUrl} 
                        alt={`${team.name} logo`} 
                        className="w-full h-full object-cover rounded-full" 
                      />
                    ) : (
                      <div className="text-gray-300 text-4xl font-bold">
                        {team.name.substring(0, 2).toUpperCase()}
                      </div>
                    )}
                  </div>
                  <h3 className={`font-heading font-bold ${isFirst ? 'text-2xl' : 'text-xl'} mb-2`}>
                    {team.name}
                  </h3>
                  <div className={`${isFirst ? 'text-4xl' : 'text-3xl'} font-bold ${colors.text}`}>
                    {team.score}
                  </div>
                  <div className="text-gray-500">очков</div>
                </div>
              </div>
            ) : (
              <div className="bg-white border-2 border-gray-200 rounded-lg shadow-md overflow-hidden h-full opacity-50">
                <div className="bg-gray-200 p-4 text-center relative">
                  <span className="inline-block bg-white text-dark text-lg font-bold rounded-full w-10 h-10 flex items-center justify-center">
                    {colors.label}
                  </span>
                  <Icon className="absolute top-0 right-2 transform -translate-y-1/2 w-6 h-6 text-gray-400" />
                </div>
                <div className="p-6 text-center">
                  <div className={`mx-auto ${isFirst ? 'w-28 h-28' : 'w-24 h-24'} rounded-full bg-gray-100 mb-4 flex items-center justify-center border-2 border-gray-200`}>
                    <span className="text-gray-300 text-4xl">?</span>
                  </div>
                  <h3 className="font-heading font-bold text-xl mb-2 text-gray-300">
                    Нет команды
                  </h3>
                  <div className="text-3xl font-bold text-gray-300">0</div>
                  <div className="text-gray-300">очков</div>
                </div>
              </div>
            )}
          </div>
        );
      })}
    </div>
  );
}
