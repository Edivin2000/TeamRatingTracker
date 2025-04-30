import { Team } from "@shared/schema";
import { 
  Edit, 
  Trash2, 
  PlusCircle, 
  MinusCircle, 
  EyeOff, 
  Eye,
  BarChart
} from "lucide-react";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { useMutation } from "@tanstack/react-query";
import { apiRequest, queryClient } from "@/lib/queryClient";
import { useToast } from "@/hooks/use-toast";

interface AdminTeamTableProps {
  teams: Team[];
  onEdit: (team: Team) => void;
  onDelete: (teamId: number) => void;
  onScoreEdit?: (team: Team) => void;
}

export default function AdminTeamTable({ 
  teams, 
  onEdit, 
  onDelete, 
  onScoreEdit 
}: AdminTeamTableProps) {
  const { toast } = useToast();
  const sortedTeams = [...teams].sort((a, b) => b.score - a.score);
  
  // Мутация для изменения статуса исключения команды
  const toggleExcludedMutation = useMutation({
    mutationFn: async ({ team, excluded }: { team: Team, excluded: boolean }) => {
      const res = await apiRequest("PUT", `/api/teams/${team.id}`, {
        ...team,
        excluded
      });
      return await res.json();
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["/api/teams"] });
      toast({
        title: "Статус команды обновлен",
        description: "Статус исключения команды успешно изменен",
      });
    },
    onError: (error) => {
      toast({
        title: "Ошибка",
        description: `Не удалось обновить статус команды: ${error.message}`,
        variant: "destructive",
      });
    },
  });

  // Обработчик переключения статуса исключения
  const handleToggleExcluded = (team: Team) => {
    toggleExcludedMutation.mutate({ 
      team, 
      excluded: !team.excluded 
    });
  };
  
  return (
    <div className="overflow-x-auto">
      <table className="min-w-full divide-y divide-gray-200">
        <thead className="bg-gray-100">
          <tr>
            <th scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
              Команда
            </th>
            <th scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
              Статус
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
              <tr key={team.id} className={`hover:bg-gray-50 ${team.excluded ? 'bg-gray-50 opacity-70' : ''}`}>
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
                  {team.excluded ? (
                    <Badge variant="outline" className="text-gray-500 border-gray-300">
                      Исключена из рейтинга
                    </Badge>
                  ) : (
                    <Badge variant="outline" className="text-green-600 border-green-200 bg-green-50">
                      В рейтинге
                    </Badge>
                  )}
                </td>
                <td className="px-6 py-4 whitespace-nowrap">
                  <div className="flex items-center">
                    <span className="font-bold text-dark mr-2">
                      {team.score}
                    </span>
                    {onScoreEdit && (
                      <Button 
                        variant="ghost" 
                        size="sm" 
                        className="text-blue-600 hover:text-blue-900 p-1 h-auto"
                        onClick={() => onScoreEdit(team)}
                      >
                        <BarChart className="w-4 h-4" />
                      </Button>
                    )}
                  </div>
                </td>
                <td className="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                  <Button 
                    variant="ghost" 
                    size="sm" 
                    className={team.excluded ? "text-green-600 hover:text-green-900 mr-2" : "text-amber-600 hover:text-amber-900 mr-2"}
                    onClick={() => handleToggleExcluded(team)}
                    title={team.excluded ? "Включить в рейтинг" : "Исключить из рейтинга"}
                  >
                    {team.excluded ? <Eye className="w-4 h-4" /> : <EyeOff className="w-4 h-4" />}
                  </Button>
                  
                  <Button 
                    variant="ghost" 
                    size="sm" 
                    className="text-indigo-600 hover:text-indigo-900 mr-2"
                    onClick={() => onEdit(team)}
                    title="Редактировать команду"
                  >
                    <Edit className="w-4 h-4" />
                  </Button>
                  
                  <Button 
                    variant="ghost" 
                    size="sm" 
                    className="text-red-600 hover:text-red-900"
                    onClick={() => onDelete(team.id)}
                    title="Удалить команду"
                  >
                    <Trash2 className="w-4 h-4" />
                  </Button>
                </td>
              </tr>
            ))
          ) : (
            <tr>
              <td colSpan={4} className="px-6 py-10 text-center text-gray-500">
                Нет доступных команд. Добавьте команду, чтобы начать.
              </td>
            </tr>
          )}
        </tbody>
      </table>
    </div>
  );
}
