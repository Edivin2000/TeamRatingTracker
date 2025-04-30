import { Team } from "@shared/schema";
import { Edit, Trash2 } from "lucide-react";
import { Button } from "@/components/ui/button";

interface AdminTeamTableProps {
  teams: Team[];
  onEdit: (team: Team) => void;
  onDelete: (teamId: number) => void;
}

export default function AdminTeamTable({ teams, onEdit, onDelete }: AdminTeamTableProps) {
  const sortedTeams = [...teams].sort((a, b) => b.score - a.score);
  
  return (
    <div className="overflow-x-auto">
      <table className="min-w-full divide-y divide-gray-200">
        <thead className="bg-gray-100">
          <tr>
            <th scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
              Команда
            </th>
            <th scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
              Очки
            </th>
            <th scope="col" className="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">
              Действия
            </th>
          </tr>
        </thead>
        <tbody className="bg-white divide-y divide-gray-200">
          {sortedTeams.length > 0 ? (
            sortedTeams.map((team) => (
              <tr key={team.id} className="hover:bg-gray-50">
                <td className="px-6 py-4 whitespace-nowrap">
                  <div className="flex items-center">
                    <div className="flex-shrink-0 h-10 w-10 bg-gray-100 rounded-full flex items-center justify-center overflow-hidden">
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
                      <div className="text-sm font-medium text-gray-900">
                        {team.name}
                      </div>
                    </div>
                  </div>
                </td>
                <td className="px-6 py-4 whitespace-nowrap">
                  <span className="font-bold text-dark">
                    {team.score}
                  </span>
                </td>
                <td className="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                  <Button 
                    variant="ghost" 
                    size="sm" 
                    className="text-indigo-600 hover:text-indigo-900 mr-2"
                    onClick={() => onEdit(team)}
                  >
                    <Edit className="w-4 h-4 mr-1" /> Изменить
                  </Button>
                  <Button 
                    variant="ghost" 
                    size="sm" 
                    className="text-red-600 hover:text-red-900"
                    onClick={() => onDelete(team.id)}
                  >
                    <Trash2 className="w-4 h-4 mr-1" /> Удалить
                  </Button>
                </td>
              </tr>
            ))
          ) : (
            <tr>
              <td colSpan={3} className="px-6 py-10 text-center text-gray-500">
                Нет доступных команд. Добавьте команду, чтобы начать.
              </td>
            </tr>
          )}
        </tbody>
      </table>
    </div>
  );
}
