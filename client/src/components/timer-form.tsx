import { useState } from "react";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { Timer, insertTimerSchema } from "@shared/schema";
import { useMutation } from "@tanstack/react-query";
import { apiRequest, queryClient } from "@/lib/queryClient";
import { z } from "zod";
import { useToast } from "@/hooks/use-toast";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import { Switch } from "@/components/ui/switch";
import { X } from "lucide-react";

// Расширяем схему с дополнительной валидацией
const formSchema = insertTimerSchema.extend({
  name: z.string().min(1, "Название таймера обязательно"),
  endDate: z.string().min(1, "Дата окончания обязательна"),
});

interface TimerFormProps {
  timer: Timer | null;
  onClose: () => void;
}

type FormData = z.infer<typeof formSchema>;

export default function TimerForm({ timer, onClose }: TimerFormProps) {
  const { toast } = useToast();
  const [isSubmitting, setIsSubmitting] = useState(false);

  // Настройка формы
  const {
    register,
    handleSubmit,
    formState: { errors },
    setValue,
    watch,
  } = useForm<FormData>({
    resolver: zodResolver(formSchema),
    defaultValues: timer
      ? {
          name: timer.name,
          displayName: timer.displayName || "",
          endDate: timer.endDate,
          active: timer.active ?? false,
          color: timer.color || "",
        }
      : {
          name: "",
          displayName: "",
          endDate: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString().split('T')[0] + "T23:59:59",
          active: true,
          color: "from-blue-600 to-indigo-700",
        },
  });

  // Мутация для создания/обновления таймера
  const saveMutation = useMutation({
    mutationFn: async (data: FormData) => {
      if (timer) {
        // Обновление существующего таймера
        return await apiRequest("PATCH", `/api/timers/${timer.id}`, data);
      } else {
        // Создание нового таймера
        return await apiRequest("POST", "/api/timers", data);
      }
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["/api/admin/timers"] });
      queryClient.invalidateQueries({ queryKey: ["/api/timers"] });
      toast({
        title: timer ? "Таймер обновлен" : "Таймер создан",
        description: timer
          ? "Таймер был успешно обновлен."
          : "Новый таймер был успешно создан.",
      });
      onClose();
    },
    onError: (error: Error) => {
      toast({
        title: "Ошибка",
        description: error.message,
        variant: "destructive",
      });
      setIsSubmitting(false);
    },
  });

  const onSubmit = (data: FormData) => {
    setIsSubmitting(true);
    saveMutation.mutate(data);
  };

  const watchActive = watch("active") as boolean;

  // Обработчик переключения активности
  const handleToggleActive = () => {
    setValue("active", !watchActive);
  };

  return (
    <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
      <div className="bg-white rounded-lg shadow-lg w-full max-w-lg max-h-[90vh] overflow-auto">
        <div className="flex justify-between items-center p-4 border-b">
          <h2 className="text-xl font-semibold">
            {timer ? "Редактировать таймер" : "Создать таймер"}
          </h2>
          <Button
            variant="ghost"
            size="icon"
            onClick={onClose}
            className="hover:bg-gray-100"
          >
            <X className="h-5 w-5" />
          </Button>
        </div>

        <form onSubmit={handleSubmit(onSubmit)} className="p-4 space-y-4">
          <div className="space-y-2">
            <Label htmlFor="name" className={errors.name ? "text-red-500" : ""}>
              Системное название таймера
            </Label>
            <Input
              id="name"
              placeholder="Введите название таймера"
              {...register("name")}
              className={errors.name ? "border-red-500" : ""}
            />
            {errors.name && (
              <p className="text-red-500 text-xs">{errors.name.message}</p>
            )}
          </div>

          <div className="space-y-2">
            <Label htmlFor="displayName">Отображаемое название (необязательно)</Label>
            <Input
              id="displayName"
              placeholder="Название для отображения пользователю"
              {...register("displayName")}
            />
          </div>

          <div className="space-y-2">
            <Label htmlFor="endDate" className={errors.endDate ? "text-red-500" : ""}>
              Дата окончания
            </Label>
            <Input
              id="endDate"
              type="datetime-local"
              {...register("endDate")}
              className={errors.endDate ? "border-red-500" : ""}
            />
            {errors.endDate && (
              <p className="text-red-500 text-xs">{errors.endDate.message}</p>
            )}
          </div>

          <div className="space-y-2">
            <Label htmlFor="color">Цвет (необязательно)</Label>
            <Input
              id="color"
              placeholder="CSS класс цвета, например 'from-blue-600 to-indigo-700'"
              {...register("color")}
            />
          </div>

          <div className="flex items-center space-x-2 pt-2">
            <Switch
              id="active"
              checked={watchActive}
              onCheckedChange={handleToggleActive}
            />
            <Label htmlFor="active">Активный таймер</Label>
          </div>

          <div className="border-t pt-4 flex justify-end space-x-2 mt-4">
            <Button type="button" variant="outline" onClick={onClose}>
              Отмена
            </Button>
            <Button type="submit" disabled={isSubmitting}>
              {isSubmitting ? "Сохранение..." : timer ? "Сохранить" : "Создать"}
            </Button>
          </div>
        </form>
      </div>
    </div>
  );
}