import React from 'react';
import { useQuery, useMutation } from '@tanstack/react-query';
import { queryClient, apiRequest } from '@/lib/queryClient';
import { Button } from '@/components/ui/button';
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table';
import { Switch } from '@/components/ui/switch';
import { formatDistanceToNow, isAfter } from 'date-fns';
import { ru } from 'date-fns/locale';
import { useToast } from '@/hooks/use-toast';
import { Badge } from '@/components/ui/badge';
import { Timer } from '@shared/schema';
import { Loader2, Pencil, Trash2 } from 'lucide-react';

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

  // Мутация для обновления статуса active
  const toggleActiveMutation = useMutation({
    mutationFn: async ({ timer, active }: { timer: Timer, active: boolean }) => {
      const res = await apiRequest("PUT", `/api/timers/${timer.id}`, { 
        ...timer, 
        active 
      });
      return res.json();
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["/api/admin/timers"] });
      queryClient.invalidateQueries({ queryKey: ["/api/timers"] });
      toast({
        title: "Статус таймера обновлен",
        description: "Статус таймера успешно обновлен",
      });
    },
    onError: (error: Error) => {
      toast({
        title: "Ошибка",
        description: `Не удалось обновить статус таймера: ${error.message}`,
        variant: "destructive",
      });
    },
  });

  const handleToggleActive = (timer: Timer) => {
    toggleActiveMutation.mutate({ timer, active: !timer.active });
  };

  const isExpired = (endDate: string) => {
    const now = new Date();
    const end = new Date(endDate);
    return !isAfter(end, now);
  };

  if (!timers) {
    return (
      <div className="flex justify-center items-center py-8">
        <Loader2 className="h-8 w-8 animate-spin text-muted-foreground" />
      </div>
    );
  }

  if (timers.length === 0) {
    return (
      <div className="text-center py-8 text-muted-foreground">
        Таймеры не найдены
      </div>
    );
  }

  return (
    <div className="overflow-x-auto">
      <Table>
        <TableHeader>
          <TableRow>
            <TableHead className="w-16 text-center">ID</TableHead>
            <TableHead>Название</TableHead>
            <TableHead>Отображаемое название</TableHead>
            <TableHead>Дата окончания</TableHead>
            <TableHead>Статус</TableHead>
            <TableHead className="w-24 text-center">Активен</TableHead>
            <TableHead className="w-24 text-center">Цвет</TableHead>
            <TableHead className="w-32 text-right">Действия</TableHead>
          </TableRow>
        </TableHeader>
        <TableBody>
          {timers.map((timer) => (
            <TableRow key={timer.id}>
              <TableCell className="text-center">{timer.id}</TableCell>
              <TableCell>{timer.name}</TableCell>
              <TableCell>{timer.displayName || '-'}</TableCell>
              <TableCell>
                {formatDistanceToNow(new Date(timer.endDate), { 
                  addSuffix: true,
                  locale: ru 
                })}
              </TableCell>
              <TableCell>
                {isExpired(timer.endDate) ? (
                  <Badge variant="destructive">Истёк</Badge>
                ) : (
                  <Badge variant="outline">Активен</Badge>
                )}
              </TableCell>
              <TableCell className="text-center">
                <Switch 
                  checked={timer.active} 
                  onCheckedChange={() => handleToggleActive(timer)}
                  disabled={toggleActiveMutation.isPending}
                />
              </TableCell>
              <TableCell>
                <div className={`w-6 h-6 rounded-full bg-gradient-to-r ${timer.color} mx-auto`}></div>
              </TableCell>
              <TableCell className="text-right space-x-1">
                <Button 
                  variant="ghost" 
                  size="icon"
                  onClick={() => onEdit(timer)}
                >
                  <Pencil className="h-4 w-4" />
                </Button>
                <Button 
                  variant="ghost" 
                  size="icon"
                  onClick={() => onDelete(timer.id)}
                >
                  <Trash2 className="h-4 w-4 text-red-500" />
                </Button>
              </TableCell>
            </TableRow>
          ))}
        </TableBody>
      </Table>
    </div>
  );
}