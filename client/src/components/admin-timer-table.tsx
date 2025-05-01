import { useState } from "react";
import { useMutation } from "@tanstack/react-query";
import { apiRequest, queryClient } from "@/lib/queryClient";
import { Timer } from "@shared/schema";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { format } from "date-fns";
import { ru } from "date-fns/locale";
import { Edit, Trash2, Clock } from "lucide-react";
import { useToast } from "@/hooks/use-toast";

interface AdminTimerTableProps {
  timers: Timer[];
  onEdit: (timer: Timer) => void;
  onDelete: (timerId: number) => void;
}

export default function AdminTimerTable({ 
  timers,
  onEdit,
  onDelete
}: AdminTimerTableProps) {
  const { toast } = useToast();
  
  // Мутация для изменения статуса активности таймера
  const toggleActiveMutation = useMutation({
    mutationFn: async ({ timer, active }: { timer: Timer, active: boolean }) => {
      return await apiRequest("PATCH", `/api/timers/${timer.id}`, { 
        ...timer,
        active
      });
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["/api/admin/timers"] });
      queryClient.invalidateQueries({ queryKey: ["/api/timers"] });
      toast({
        title: "Статус таймера изменен",
        description: "Статус активности таймера был успешно обновлен.",
      });
    },
    onError: (error: Error) => {
      toast({
        title: "Ошибка при изменении статуса",
        description: error.message,
        variant: "destructive",
      });
    },
  });

  // Обработчик изменения статуса активности таймера
  const handleToggleActive = (timer: Timer) => {
    const newActive = !(timer.active ?? false);
    toggleActiveMutation.mutate({ timer, active: newActive });
  };

  const formatDate = (dateString: string) => {
    try {
      return format(new Date(dateString), "d MMMM yyyy, HH:mm", { locale: ru });
    } catch (e) {
      return "Некорректная дата";
    }
  };

  return (
    <div className="overflow-x-auto">
      <table className="min-w-full divide-y divide-gray-200">
        <thead className="bg-gray-100">
          <tr>
            <th scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
              Название
            </th>
            <th scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
              Дата окончания
            </th>
            <th scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
              Статус
            </th>
            <th scope="col" className="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">
              Действия
            </th>
          </tr>
        </thead>
        <tbody className="bg-white divide-y divide-gray-200">
          {timers && timers.length > 0 ? (
            [...timers]
              .sort((a, b) => {
                // Сортировка: сначала активные, затем по дате окончания
                if ((a.active ?? false) !== (b.active ?? false)) {
                  return (a.active ?? false) ? -1 : 1;
                }
                
                // По дате - более ранняя дата вначале
                const dateA = new Date(a.endDate).getTime();
                const dateB = new Date(b.endDate).getTime();
                return dateA - dateB;
              })
              .map((timer) => (
                <tr key={timer.id} className="hover:bg-gray-50">
                  <td className="px-6 py-4 whitespace-nowrap">
                    <div className="flex items-center">
                      <div className="flex-shrink-0 h-10 w-10 bg-gray-100 rounded-full flex items-center justify-center">
                        <Clock className="h-5 w-5 text-primary" />
                      </div>
                      <div className="ml-4">
                        <div className="text-sm font-medium text-gray-900">
                          {timer.title}
                        </div>
                        {timer.description && (
                          <div className="text-xs text-gray-500 max-w-md truncate">
                            {timer.description}
                          </div>
                        )}
                      </div>
                    </div>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <span className="text-sm text-gray-900">
                      {formatDate(timer.endDate)}
                    </span>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <Badge 
                      className={`cursor-pointer ${timer.active ? "bg-green-100 text-green-800 hover:bg-green-200" : "bg-gray-100 text-gray-800 hover:bg-gray-200"}`}
                      onClick={() => handleToggleActive(timer)}
                    >
                      {timer.active ? "Активен" : "Неактивен"}
                    </Badge>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                    <Button 
                      variant="ghost" 
                      size="sm" 
                      className="text-indigo-600 hover:text-indigo-900 mr-2"
                      onClick={() => onEdit(timer)}
                    >
                      <Edit className="w-4 h-4 mr-1" /> Изменить
                    </Button>
                    <Button 
                      variant="ghost" 
                      size="sm" 
                      className="text-red-600 hover:text-red-900"
                      onClick={() => onDelete(timer.id)}
                    >
                      <Trash2 className="w-4 h-4 mr-1" /> Удалить
                    </Button>
                  </td>
                </tr>
              ))
          ) : (
            <tr>
              <td colSpan={4} className="px-6 py-10 text-center text-gray-500">
                Нет доступных таймеров. Добавьте таймер, чтобы начать.
              </td>
            </tr>
          )}
        </tbody>
      </table>
    </div>
  );
}