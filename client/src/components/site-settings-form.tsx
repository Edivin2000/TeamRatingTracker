import { useState } from "react";
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogFooter } from "@/components/ui/dialog";
import { Button } from "@/components/ui/button";
import { Form, FormControl, FormDescription, FormField, FormItem, FormLabel, FormMessage } from "@/components/ui/form";
import { Input } from "@/components/ui/input";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { z } from "zod";
import { zodResolver } from "@hookform/resolvers/zod";
import { useForm } from "react-hook-form";
import { useMutation, useQueryClient } from "@tanstack/react-query";
import { type SiteSettings } from "@shared/schema";
import { apiRequest } from "@/lib/queryClient";
import { Loader2 } from "lucide-react";
import { useToast } from "@/hooks/use-toast";

interface SiteSettingsFormProps {
  settings: SiteSettings | null;
  onClose: () => void;
}

const formSchema = z.object({
  primaryColor: z.string().min(3, {
    message: "Основной цвет должен быть не менее 3 символов",
  }),
  secondaryColor: z.string().min(3, {
    message: "Второстепенный цвет должен быть не менее 3 символов",
  }),
  accentColor: z.string().min(3, {
    message: "Акцентный цвет должен быть не менее 3 символов",
  }),
  headerBgColor: z.string().min(3, {
    message: "Цвет заголовка должен быть не менее 3 символов",
  }),
  fontPrimary: z.string().min(1, {
    message: "Выберите шрифт",
  }),
  borderRadius: z.string().min(1, {
    message: "Выберите радиус скругления",
  }),
  buttonStyle: z.string().min(1, {
    message: "Выберите стиль кнопок",
  }),
  tableBgColor: z.string().min(3, {
    message: "Цвет фона таблицы должен быть не менее 3 символов",
  }),
  cardBgColor: z.string().min(3, {
    message: "Цвет фона карточек должен быть не менее 3 символов",
  }),
  podiumStyle: z.string().min(1, {
    message: "Выберите стиль подиума",
  }),
  bgPattern: z.string().min(1, {
    message: "Выберите паттерн фона",
  }),
  logoPosition: z.string().min(1, {
    message: "Выберите позицию логотипа",
  }),
});

type FormData = z.infer<typeof formSchema>;

export default function SiteSettingsForm({ settings, onClose }: SiteSettingsFormProps) {
  const { toast } = useToast();
  const queryClient = useQueryClient();
  const [isSubmitting, setIsSubmitting] = useState(false);

  const form = useForm<FormData>({
    resolver: zodResolver(formSchema),
    defaultValues: {
      primaryColor: settings?.primaryColor || "#0f172a",
      secondaryColor: settings?.secondaryColor || "#1e293b",
      accentColor: settings?.accentColor || "#3b82f6",
      headerBgColor: settings?.headerBgColor || "#0f172a",
      fontPrimary: settings?.fontPrimary || "Inter",
      borderRadius: settings?.borderRadius || "0.5rem",
      buttonStyle: settings?.buttonStyle || "default",
      tableBgColor: settings?.tableBgColor || "#1e293b",
      cardBgColor: settings?.cardBgColor || "#1e293b",
      podiumStyle: settings?.podiumStyle || "default",
      bgPattern: settings?.bgPattern || "none",
      logoPosition: settings?.logoPosition || "center",
    },
  });

  const mutation = useMutation({
    mutationFn: async (data: FormData) => {
      const res = await apiRequest("PUT", "/api/site-settings", data);
      return await res.json();
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["/api/site-settings"] });
      toast({
        title: "Настройки сохранены",
        description: "Настройки сайта успешно обновлены",
      });
      onClose();
    },
    onError: (error: Error) => {
      toast({
        title: "Ошибка при сохранении",
        description: error.message || "Не удалось сохранить настройки сайта",
        variant: "destructive",
      });
    },
  });

  const onSubmit = (data: FormData) => {
    setIsSubmitting(true);
    mutation.mutate(data);
  };

  return (
    <Dialog open={true} onOpenChange={onClose}>
      <DialogContent className="sm:max-w-[700px] max-h-[90vh] overflow-y-auto">
        <DialogHeader>
          <DialogTitle>Настройки дизайна сайта</DialogTitle>
        </DialogHeader>

        <Form {...form}>
          <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-6">
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              {/* Цвета */}
              <div className="space-y-4">
                <h3 className="text-lg font-medium">Цветовая схема</h3>
                
                <FormField
                  control={form.control}
                  name="primaryColor"
                  render={({ field }) => (
                    <FormItem>
                      <FormLabel>Основной цвет</FormLabel>
                      <div className="flex space-x-2">
                        <input
                          type="color"
                          className="h-10 w-10 border cursor-pointer"
                          value={field.value}
                          onChange={(e) => field.onChange(e.target.value)}
                        />
                        <FormControl>
                          <Input {...field} />
                        </FormControl>
                      </div>
                      <FormDescription>
                        Основной цвет фона сайта
                      </FormDescription>
                      <FormMessage />
                    </FormItem>
                  )}
                />

                <FormField
                  control={form.control}
                  name="secondaryColor"
                  render={({ field }) => (
                    <FormItem>
                      <FormLabel>Второстепенный цвет</FormLabel>
                      <div className="flex space-x-2">
                        <input
                          type="color"
                          className="h-10 w-10 border cursor-pointer"
                          value={field.value}
                          onChange={(e) => field.onChange(e.target.value)}
                        />
                        <FormControl>
                          <Input {...field} />
                        </FormControl>
                      </div>
                      <FormDescription>
                        Цвет для карточек и секций
                      </FormDescription>
                      <FormMessage />
                    </FormItem>
                  )}
                />

                <FormField
                  control={form.control}
                  name="accentColor"
                  render={({ field }) => (
                    <FormItem>
                      <FormLabel>Акцентный цвет</FormLabel>
                      <div className="flex space-x-2">
                        <input
                          type="color"
                          className="h-10 w-10 border cursor-pointer"
                          value={field.value}
                          onChange={(e) => field.onChange(e.target.value)}
                        />
                        <FormControl>
                          <Input {...field} />
                        </FormControl>
                      </div>
                      <FormDescription>
                        Цвет для кнопок и выделенных элементов
                      </FormDescription>
                      <FormMessage />
                    </FormItem>
                  )}
                />

                <FormField
                  control={form.control}
                  name="headerBgColor"
                  render={({ field }) => (
                    <FormItem>
                      <FormLabel>Цвет заголовка</FormLabel>
                      <div className="flex space-x-2">
                        <input
                          type="color"
                          className="h-10 w-10 border cursor-pointer"
                          value={field.value}
                          onChange={(e) => field.onChange(e.target.value)}
                        />
                        <FormControl>
                          <Input {...field} />
                        </FormControl>
                      </div>
                      <FormDescription>
                        Цвет верхней панели навигации
                      </FormDescription>
                      <FormMessage />
                    </FormItem>
                  )}
                />
                
                <FormField
                  control={form.control}
                  name="tableBgColor"
                  render={({ field }) => (
                    <FormItem>
                      <FormLabel>Цвет фона таблицы</FormLabel>
                      <div className="flex space-x-2">
                        <input
                          type="color"
                          className="h-10 w-10 border cursor-pointer"
                          value={field.value}
                          onChange={(e) => field.onChange(e.target.value)}
                        />
                        <FormControl>
                          <Input {...field} />
                        </FormControl>
                      </div>
                      <FormDescription>
                        Цвет фона для таблицы команд
                      </FormDescription>
                      <FormMessage />
                    </FormItem>
                  )}
                />
                
                <FormField
                  control={form.control}
                  name="cardBgColor"
                  render={({ field }) => (
                    <FormItem>
                      <FormLabel>Цвет фона карточек</FormLabel>
                      <div className="flex space-x-2">
                        <input
                          type="color"
                          className="h-10 w-10 border cursor-pointer"
                          value={field.value}
                          onChange={(e) => field.onChange(e.target.value)}
                        />
                        <FormControl>
                          <Input {...field} />
                        </FormControl>
                      </div>
                      <FormDescription>
                        Цвет фона для карточек
                      </FormDescription>
                      <FormMessage />
                    </FormItem>
                  )}
                />
              </div>
              
              {/* Стили */}
              <div className="space-y-4">
                <h3 className="text-lg font-medium">Шрифты и стили</h3>
                
                <FormField
                  control={form.control}
                  name="fontPrimary"
                  render={({ field }) => (
                    <FormItem>
                      <FormLabel>Основной шрифт</FormLabel>
                      <Select onValueChange={field.onChange} defaultValue={field.value}>
                        <FormControl>
                          <SelectTrigger>
                            <SelectValue placeholder="Выберите шрифт" />
                          </SelectTrigger>
                        </FormControl>
                        <SelectContent>
                          <SelectItem value="Inter">Inter</SelectItem>
                          <SelectItem value="Roboto">Roboto</SelectItem>
                          <SelectItem value="Open Sans">Open Sans</SelectItem>
                          <SelectItem value="Montserrat">Montserrat</SelectItem>
                          <SelectItem value="Nunito">Nunito</SelectItem>
                        </SelectContent>
                      </Select>
                      <FormDescription>
                        Основной шрифт для всего сайта
                      </FormDescription>
                      <FormMessage />
                    </FormItem>
                  )}
                />
                
                <FormField
                  control={form.control}
                  name="borderRadius"
                  render={({ field }) => (
                    <FormItem>
                      <FormLabel>Радиус скругления</FormLabel>
                      <Select onValueChange={field.onChange} defaultValue={field.value}>
                        <FormControl>
                          <SelectTrigger>
                            <SelectValue placeholder="Выберите радиус" />
                          </SelectTrigger>
                        </FormControl>
                        <SelectContent>
                          <SelectItem value="0">Без скругления</SelectItem>
                          <SelectItem value="0.25rem">Небольшое (0.25rem)</SelectItem>
                          <SelectItem value="0.5rem">Среднее (0.5rem)</SelectItem>
                          <SelectItem value="0.75rem">Большое (0.75rem)</SelectItem>
                          <SelectItem value="1rem">Очень большое (1rem)</SelectItem>
                        </SelectContent>
                      </Select>
                      <FormDescription>
                        Радиус скругления для кнопок и карточек
                      </FormDescription>
                      <FormMessage />
                    </FormItem>
                  )}
                />
                
                <FormField
                  control={form.control}
                  name="buttonStyle"
                  render={({ field }) => (
                    <FormItem>
                      <FormLabel>Стиль кнопок</FormLabel>
                      <Select onValueChange={field.onChange} defaultValue={field.value}>
                        <FormControl>
                          <SelectTrigger>
                            <SelectValue placeholder="Выберите стиль кнопок" />
                          </SelectTrigger>
                        </FormControl>
                        <SelectContent>
                          <SelectItem value="default">Стандартный</SelectItem>
                          <SelectItem value="flat">Плоский</SelectItem>
                          <SelectItem value="gradient">Градиент</SelectItem>
                          <SelectItem value="outline">С обводкой</SelectItem>
                        </SelectContent>
                      </Select>
                      <FormDescription>
                        Визуальный стиль для кнопок
                      </FormDescription>
                      <FormMessage />
                    </FormItem>
                  )}
                />
                
                <FormField
                  control={form.control}
                  name="podiumStyle"
                  render={({ field }) => (
                    <FormItem>
                      <FormLabel>Стиль подиума</FormLabel>
                      <Select onValueChange={field.onChange} defaultValue={field.value}>
                        <FormControl>
                          <SelectTrigger>
                            <SelectValue placeholder="Выберите стиль подиума" />
                          </SelectTrigger>
                        </FormControl>
                        <SelectContent>
                          <SelectItem value="default">Стандартный</SelectItem>
                          <SelectItem value="flat">Плоский</SelectItem>
                          <SelectItem value="gradient">Градиент</SelectItem>
                          <SelectItem value="glass">Стеклянный</SelectItem>
                        </SelectContent>
                      </Select>
                      <FormDescription>
                        Визуальный стиль для подиума команд
                      </FormDescription>
                      <FormMessage />
                    </FormItem>
                  )}
                />
                
                <FormField
                  control={form.control}
                  name="bgPattern"
                  render={({ field }) => (
                    <FormItem>
                      <FormLabel>Паттерн фона</FormLabel>
                      <Select onValueChange={field.onChange} defaultValue={field.value}>
                        <FormControl>
                          <SelectTrigger>
                            <SelectValue placeholder="Выберите паттерн фона" />
                          </SelectTrigger>
                        </FormControl>
                        <SelectContent>
                          <SelectItem value="none">Без паттерна</SelectItem>
                          <SelectItem value="dots">Точки</SelectItem>
                          <SelectItem value="grid">Сетка</SelectItem>
                          <SelectItem value="waves">Волны</SelectItem>
                          <SelectItem value="hexagons">Шестиугольники</SelectItem>
                        </SelectContent>
                      </Select>
                      <FormDescription>
                        Паттерн фона для страницы
                      </FormDescription>
                      <FormMessage />
                    </FormItem>
                  )}
                />
                
                <FormField
                  control={form.control}
                  name="logoPosition"
                  render={({ field }) => (
                    <FormItem>
                      <FormLabel>Позиция логотипа</FormLabel>
                      <Select onValueChange={field.onChange} defaultValue={field.value}>
                        <FormControl>
                          <SelectTrigger>
                            <SelectValue placeholder="Выберите позицию логотипа" />
                          </SelectTrigger>
                        </FormControl>
                        <SelectContent>
                          <SelectItem value="left">Слева</SelectItem>
                          <SelectItem value="center">По центру</SelectItem>
                          <SelectItem value="right">Справа</SelectItem>
                        </SelectContent>
                      </Select>
                      <FormDescription>
                        Позиция логотипа в шапке сайта
                      </FormDescription>
                      <FormMessage />
                    </FormItem>
                  )}
                />
              </div>
            </div>

            <DialogFooter>
              <Button variant="outline" onClick={onClose} type="button">
                Отмена
              </Button>
              <Button type="submit" disabled={isSubmitting}>
                {isSubmitting ? (
                  <>
                    <Loader2 className="mr-2 h-4 w-4 animate-spin" /> Сохранение...
                  </>
                ) : (
                  "Сохранить настройки"
                )}
              </Button>
            </DialogFooter>
          </form>
        </Form>
      </DialogContent>
    </Dialog>
  );
}