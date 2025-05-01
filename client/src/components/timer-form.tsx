import React from 'react';
import { zodResolver } from "@hookform/resolvers/zod";
import { useForm } from "react-hook-form";
import { z } from "zod";
import { format } from 'date-fns';
import { useMutation } from '@tanstack/react-query';
import { insertTimerSchema } from '@shared/schema';
import { queryClient, apiRequest } from '@/lib/queryClient';
import { Button } from "@/components/ui/button";
import { Form, FormControl, FormField, FormItem, FormLabel, FormMessage } from "@/components/ui/form";
import { Input } from "@/components/ui/input";
import { useToast } from "@/hooks/use-toast";
import { Switch } from "@/components/ui/switch";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { X } from 'lucide-react';

interface TimerFormProps {
  timer: any | null;
  onClose: () => void;
}

// Расширяем схему для валидации формы
const formSchema = insertTimerSchema.extend({
  endDate: z.string().min(1, "Дата окончания обязательна"),
  name: z.string().min(1, "Название обязательно"),
  displayName: z.string().optional(),
  color: z.string().min(1, "Цвет обязателен"),
  active: z.boolean().default(true),
});

type FormData = z.infer<typeof formSchema>;

const colors = [
  { value: "from-blue-600 to-indigo-700", label: "Синий" },
  { value: "from-green-600 to-green-800", label: "Зеленый" },
  { value: "from-red-600 to-red-800", label: "Красный" },
  { value: "from-purple-600 to-purple-800", label: "Фиолетовый" },
  { value: "from-orange-500 to-amber-700", label: "Оранжевый" },
  { value: "from-teal-600 to-teal-800", label: "Бирюзовый" },
  { value: "from-gray-700 to-gray-900", label: "Серый" },
  { value: "from-pink-600 to-rose-700", label: "Розовый" },
];

export default function TimerForm({ timer, onClose }: TimerFormProps) {
  const { toast } = useToast();
  
  const defaultValues: Partial<FormData> = {
    name: timer?.name || "",
    displayName: timer?.displayName || "",
    endDate: timer?.endDate || format(new Date(Date.now() + 24 * 60 * 60 * 1000), "yyyy-MM-dd'T'HH:mm"),
    color: timer?.color || "from-blue-600 to-indigo-700",
    active: timer?.active !== undefined ? timer.active : true,
  };

  const form = useForm<FormData>({
    resolver: zodResolver(formSchema),
    defaultValues,
  });

  const mutation = useMutation({
    mutationFn: async (data: FormData) => {
      const endpoint = timer ? `/api/timers/${timer.id}` : "/api/timers";
      const method = timer ? "PUT" : "POST";
      const res = await apiRequest(method, endpoint, data);
      return res.json();
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["/api/timers"] });
      queryClient.invalidateQueries({ queryKey: ["/api/admin/timers"] });
      toast({
        title: timer ? "Таймер обновлен" : "Таймер создан",
        description: timer ? "Таймер успешно обновлен" : "Таймер успешно создан",
      });
      onClose();
    },
    onError: (error: Error) => {
      toast({
        title: "Ошибка",
        description: `Не удалось ${timer ? "обновить" : "создать"} таймер: ${error.message}`,
        variant: "destructive",
      });
    },
  });

  const onSubmit = (data: FormData) => {
    mutation.mutate(data);
  };

  return (
    <div className="bg-white p-4 rounded-lg shadow-lg max-w-md w-full max-h-[90vh] overflow-y-auto">
      <div className="flex justify-between items-center mb-4">
        <h2 className="text-xl font-bold">{timer ? "Редактировать таймер" : "Новый таймер"}</h2>
        <Button variant="ghost" size="icon" onClick={onClose}>
          <X className="h-4 w-4" />
        </Button>
      </div>

      <Form {...form}>
        <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-4">
          <FormField
            control={form.control}
            name="name"
            render={({ field }) => (
              <FormItem>
                <FormLabel>Название (внутреннее)</FormLabel>
                <FormControl>
                  <Input placeholder="Например: Финал конкурса" {...field} />
                </FormControl>
                <FormMessage />
              </FormItem>
            )}
          />

          <FormField
            control={form.control}
            name="displayName"
            render={({ field }) => (
              <FormItem>
                <FormLabel>Отображаемое название</FormLabel>
                <FormControl>
                  <Input placeholder="Например: До конца финала осталось" {...field} />
                </FormControl>
                <FormMessage />
              </FormItem>
            )}
          />

          <FormField
            control={form.control}
            name="endDate"
            render={({ field }) => (
              <FormItem>
                <FormLabel>Дата и время окончания</FormLabel>
                <FormControl>
                  <Input type="datetime-local" {...field} />
                </FormControl>
                <FormMessage />
              </FormItem>
            )}
          />

          <FormField
            control={form.control}
            name="color"
            render={({ field }) => (
              <FormItem>
                <FormLabel>Цвет</FormLabel>
                <Select onValueChange={field.onChange} defaultValue={field.value}>
                  <FormControl>
                    <SelectTrigger className="w-full">
                      <SelectValue placeholder="Выберите цвет" />
                    </SelectTrigger>
                  </FormControl>
                  <SelectContent>
                    {colors.map((color) => (
                      <SelectItem key={color.value} value={color.value}>
                        {color.label}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
                <FormMessage />
              </FormItem>
            )}
          />

          <FormField
            control={form.control}
            name="active"
            render={({ field }) => (
              <FormItem className="flex flex-row items-center justify-between rounded-lg border p-3">
                <div className="space-y-0.5">
                  <FormLabel>Активен</FormLabel>
                </div>
                <FormControl>
                  <Switch
                    checked={field.value}
                    onCheckedChange={field.onChange}
                  />
                </FormControl>
                <FormMessage />
              </FormItem>
            )}
          />

          <div className="flex justify-end space-x-2 pt-4">
            <Button type="button" variant="outline" onClick={onClose}>
              Отмена
            </Button>
            <Button type="submit" disabled={mutation.isPending}>
              {mutation.isPending ? "Сохранение..." : "Сохранить"}
            </Button>
          </div>
        </form>
      </Form>
    </div>
  );
}