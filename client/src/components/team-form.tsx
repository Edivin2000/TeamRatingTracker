import { useState } from "react";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { z } from "zod";
import { useMutation } from "@tanstack/react-query";
import { Team, insertTeamSchema } from "@shared/schema";
import { apiRequest, queryClient } from "@/lib/queryClient";
import { useToast } from "@/hooks/use-toast";
import { X, Upload, Loader2 } from "lucide-react";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";

interface TeamFormProps {
  team: Team | null;
  onClose: () => void;
}

export default function TeamForm({ team, onClose }: TeamFormProps) {
  const { toast } = useToast();
  const [logoPreview, setLogoPreview] = useState<string | null>(team?.logoUrl || null);
  
  const formSchema = insertTeamSchema.extend({
    logoFile: z.instanceof(FileList).optional().transform(val => val && val.length > 0 ? val[0] : undefined),
  });

  type FormData = z.infer<typeof formSchema>;

  const {
    register,
    handleSubmit,
    setValue,
    formState: { errors },
  } = useForm<FormData>({
    resolver: zodResolver(formSchema),
    defaultValues: {
      name: team?.name || "",
      score: team?.score || 0,
      logoUrl: team?.logoUrl || "",
    },
  });

  const createTeamMutation = useMutation({
    mutationFn: async (data: FormData) => {
      // Обрабатываем загрузку логотипа, если он присутствует или есть URL
      let logoUrl = data.logoUrl || "";
      
      // Проверяем, если есть файл, он имеет приоритет над URL
      if (data.logoFile) {
        // Проверяем размер файла (не более 2MB)
        if (data.logoFile.size > 2 * 1024 * 1024) {
          throw new Error("Размер файла не должен превышать 2MB");
        }
        
        // Проверяем тип файла (только изображения)
        if (!data.logoFile.type.startsWith('image/')) {
          throw new Error("Файл должен быть изображением");
        }
        
        try {
          // Конвертируем в base64 для хранения в памяти
          const reader = new FileReader();
          
          // Создаем промис для ожидания FileReader
          const base64Promise = new Promise<string>((resolve, reject) => {
            reader.onloadend = () => {
              if (reader.result) {
                resolve(reader.result as string);
              } else {
                reject(new Error("Ошибка чтения файла"));
              }
            };
            reader.onerror = () => {
              reject(new Error("Ошибка загрузки файла"));
            };
          });
          
          reader.readAsDataURL(data.logoFile);
          logoUrl = await base64Promise;
          
          // Логируем для отладки
          console.log("Изображение успешно преобразовано в base64");
        } catch (error) {
          console.error("Ошибка при обработке изображения:", error);
          throw new Error("Не удалось обработать загруженное изображение");
        }
      } 
      
      // Если файл не выбран, но у нас есть предпросмотр из состояния, используем его
      else if (logoPreview && logoPreview !== team?.logoUrl) {
        logoUrl = logoPreview;
      }
      
      const teamData = {
        name: data.name,
        score: data.score,
        logoUrl,
      };
      
      if (team) {
        // Обновляем существующую команду
        const res = await apiRequest("PUT", `/api/teams/${team.id}`, teamData);
        return res.json();
      } else {
        // Создаем новую команду
        const res = await apiRequest("POST", "/api/teams", teamData);
        return res.json();
      }
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["/api/teams"] });
      toast({
        title: team ? "Команда обновлена" : "Команда создана",
        description: team
          ? "Команда была успешно обновлена."
          : "Команда была успешно создана.",
      });
      onClose();
    },
    onError: (error) => {
      toast({
        title: team ? "Не удалось обновить команду" : "Не удалось создать команду",
        description: error.message,
        variant: "destructive",
      });
    },
  });

  const onSubmit = (data: FormData) => {
    createTeamMutation.mutate(data);
  };

  // Функция для оптимизации изображения перед загрузкой
  const optimizeImage = async (file: File, maxWidth = 300, maxHeight = 300): Promise<string> => {
    return new Promise((resolve, reject) => {
      try {
        // Создаем URL для файла
        const imageUrl = URL.createObjectURL(file);
        
        // Создаем изображение для получения его размеров
        const img = new Image();
        img.onload = () => {
          // Освобождаем объект URL
          URL.revokeObjectURL(imageUrl);
          
          // Определяем размеры
          let width = img.width;
          let height = img.height;
          
          // Уменьшаем размер изображения, если оно больше максимальных размеров
          if (width > maxWidth || height > maxHeight) {
            const ratio = Math.min(maxWidth / width, maxHeight / height);
            width = Math.floor(width * ratio);
            height = Math.floor(height * ratio);
          }
          
          // Создаем канвас для ресайза изображения
          const canvas = document.createElement('canvas');
          canvas.width = width;
          canvas.height = height;
          
          // Рисуем изображение на канвасе
          const ctx = canvas.getContext('2d');
          if (!ctx) {
            reject(new Error('Не удалось создать 2D контекст'));
            return;
          }
          
          ctx.drawImage(img, 0, 0, width, height);
          
          // Преобразуем канвас в Data URL
          // Уменьшаем качество JPEG до 0.7
          const optimizedImageData = canvas.toDataURL('image/jpeg', 0.7);
          
          // Логируем размер оптимизированного изображения
          console.log("Размер оптимизированного изображения (символов):", optimizedImageData.length);
          
          resolve(optimizedImageData);
        };
        
        img.onerror = () => {
          URL.revokeObjectURL(imageUrl);
          reject(new Error('Не удалось загрузить изображение'));
        };
        
        img.src = imageUrl;
      } catch (error) {
        reject(error);
      }
    });
  };

  const handleFileChange = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (file) {
      try {
        // Проверяем размер файла (не более 5MB)
        if (file.size > 5 * 1024 * 1024) {
          toast({
            title: "Файл слишком большой",
            description: "Максимальный размер файла 5MB",
            variant: "destructive",
          });
          return;
        }
        
        // Проверяем тип файла (только изображения)
        if (!file.type.startsWith('image/')) {
          toast({
            title: "Неверный формат файла",
            description: "Пожалуйста, загрузите изображение",
            variant: "destructive",
          });
          return;
        }
        
        // Показываем индикатор загрузки
        toast({
          title: "Обработка изображения",
          description: "Пожалуйста, подождите...",
        });
        
        // Оптимизируем изображение
        const optimizedImageData = await optimizeImage(file);
        
        // Устанавливаем предпросмотр и обновляем значение в форме
        setLogoPreview(optimizedImageData);
        setValue("logoUrl", optimizedImageData);
        
        toast({
          title: "Изображение загружено",
          description: "Изображение успешно обработано",
        });
      } catch (error) {
        console.error("Ошибка при обработке файла:", error);
        toast({
          title: "Ошибка",
          description: "Не удалось обработать файл",
          variant: "destructive",
        });
      }
    }
  };

  return (
    <Dialog open={true} onOpenChange={onClose}>
      <DialogContent className="sm:max-w-md">
        <DialogHeader>
          <DialogTitle>{team ? "Редактировать Команду" : "Добавить Новую Команду"}</DialogTitle>
        </DialogHeader>
        
        <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
          <input type="hidden" {...register("logoUrl")} />
          
          <div className="space-y-2">
            <Label htmlFor="name">Название Команды</Label>
            <Input 
              id="name" 
              type="text" 
              {...register("name")} 
              placeholder="Введите название команды" 
            />
            {errors.name && (
              <p className="text-sm text-red-500">{errors.name.message}</p>
            )}
          </div>
          
          <div className="space-y-2">
            <Label htmlFor="score">Очки Команды</Label>
            <Input 
              id="score" 
              type="number" 
              {...register("score", { valueAsNumber: true })} 
              placeholder="Введите очки команды" 
            />
            {errors.score && (
              <p className="text-sm text-red-500">{errors.score.message}</p>
            )}
          </div>
          
          <div className="space-y-2">
            <Label>Логотип Команды</Label>
            <div className="flex items-center space-x-4">
              <div className="w-16 h-16 bg-gray-100 rounded-full flex items-center justify-center overflow-hidden">
                {logoPreview ? (
                  <img 
                    src={logoPreview} 
                    alt="Предпросмотр логотипа" 
                    className="w-full h-full object-cover" 
                  />
                ) : (
                  <div className="text-gray-300 text-xl">
                    {team?.name.substring(0, 2).toUpperCase() || ""}
                  </div>
                )}
              </div>
              <div>
                <Label 
                  htmlFor="logoFile" 
                  className="cursor-pointer inline-flex items-center px-4 py-2 bg-gray-200 hover:bg-gray-300 rounded-md text-sm font-medium transition"
                >
                  <Upload className="w-4 h-4 mr-2" />
                  Загрузить Логотип
                </Label>
                <input
                  type="file"
                  id="logoFile"
                  className="hidden"
                  accept="image/*"
                  {...register("logoFile")}
                  onChange={handleFileChange}
                />
              </div>
            </div>
          </div>
          
          <div className="flex justify-end space-x-2 pt-4">
            <Button
              type="button"
              variant="outline"
              onClick={onClose}
            >
              Отмена
            </Button>
            <Button 
              type="submit"
              disabled={createTeamMutation.isPending}
            >
              {createTeamMutation.isPending && (
                <Loader2 className="w-4 h-4 mr-2 animate-spin" />
              )}
              {team ? "Обновить" : "Создать"} Команду
            </Button>
          </div>
        </form>
      </DialogContent>
    </Dialog>
  );
}
