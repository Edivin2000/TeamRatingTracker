import { useState } from "react";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { z } from "zod";
import { insertSiteSettingsSchema, type SiteSettings } from "@shared/schema";
import { useToast } from "@/hooks/use-toast";
import { useMutation } from "@tanstack/react-query";
import { apiRequest, queryClient } from "@/lib/queryClient";

// Компоненты UI
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Input } from "@/components/ui/input";
import { Button } from "@/components/ui/button";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Label } from "@/components/ui/label";
import { FormField, FormItem, FormLabel, FormControl, FormMessage, Form } from "@/components/ui/form";
import { Separator } from "@/components/ui/separator";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Loader2, RefreshCw } from "lucide-react";

interface SiteSettingsFormProps {
  settings: SiteSettings | null;
  onClose: () => void;
}

const formSchema = insertSiteSettingsSchema.extend({
  primaryColor: z.string().min(3, "Выберите основной цвет"),
  secondaryColor: z.string().min(3, "Выберите второстепенный цвет"),
  accentColor: z.string().min(3, "Выберите акцентный цвет"),
  headerBgColor: z.string().min(3, "Выберите цвет фона заголовка"),
  tableBgColor: z.string().min(3, "Выберите цвет фона таблицы"),
  cardBgColor: z.string().min(3, "Выберите цвет фона карточек"),
  borderRadius: z.string().min(1, "Укажите радиус скругления"),
  podiumStyle: z.string().min(1, "Выберите стиль подиума"),
  buttonStyle: z.string().min(1, "Выберите стиль кнопок"),
  fontPrimary: z.string().min(1, "Выберите основной шрифт"),
  bgPattern: z.string().min(1, "Выберите паттерн фона"),
  logoPosition: z.string().min(1, "Выберите позицию логотипа")
});

type FormData = z.infer<typeof formSchema>;

export default function SiteSettingsForm({ settings, onClose }: SiteSettingsFormProps) {
  const { toast } = useToast();
  const [activeTab, setActiveTab] = useState("colors");

  // Настройка хука формы с дефолтными значениями из пропсов
  const form = useForm<FormData>({
    resolver: zodResolver(formSchema),
    defaultValues: settings ? {
      primaryColor: settings.primaryColor,
      secondaryColor: settings.secondaryColor, 
      accentColor: settings.accentColor,
      headerBgColor: settings.headerBgColor,
      fontPrimary: settings.fontPrimary,
      borderRadius: settings.borderRadius,
      buttonStyle: settings.buttonStyle,
      tableBgColor: settings.tableBgColor,
      cardBgColor: settings.cardBgColor,
      podiumStyle: settings.podiumStyle,
      bgPattern: settings.bgPattern,
      logoPosition: settings.logoPosition,
    } : {
      primaryColor: "#0f172a",
      secondaryColor: "#1e293b", 
      accentColor: "#3b82f6",
      headerBgColor: "#0f172a",
      fontPrimary: "Inter",
      borderRadius: "0.5rem",
      buttonStyle: "default",
      tableBgColor: "#1e293b",
      cardBgColor: "#1e293b",
      podiumStyle: "default",
      bgPattern: "none",
      logoPosition: "center",
    }
  });

  // Мутация для обновления настроек
  const updateSettingsMutation = useMutation({
    mutationFn: async (data: FormData) => {
      const res = await apiRequest("PUT", "/api/site-settings", data);
      const updatedSettings = await res.json();
      return updatedSettings;
    },
    onSuccess: () => {
      toast({
        title: "Настройки обновлены",
        description: "Изменения дизайна сайта успешно сохранены",
      });
      queryClient.invalidateQueries({ queryKey: ["/api/site-settings"] });
      onClose();
    },
    onError: (error: Error) => {
      toast({
        title: "Ошибка при обновлении настроек",
        description: `Не удалось сохранить изменения: ${error.message}`,
        variant: "destructive",
      });
    },
  });

  // Обработчик отправки формы
  const onSubmit = (data: FormData) => {
    updateSettingsMutation.mutate(data);
  };

  // Функция для сброса настроек к значениям по умолчанию
  const resetToDefaults = () => {
    form.reset({
      primaryColor: "#0f172a",
      secondaryColor: "#1e293b", 
      accentColor: "#3b82f6",
      headerBgColor: "#0f172a",
      fontPrimary: "Inter",
      borderRadius: "0.5rem",
      buttonStyle: "default",
      tableBgColor: "#1e293b",
      cardBgColor: "#1e293b",
      podiumStyle: "default",
      bgPattern: "none",
      logoPosition: "center",
    });
  };

  // Превью настроек (стилей)
  const previewStyle = {
    backgroundColor: form.watch("secondaryColor"),
    color: "#fff",
    borderRadius: form.watch("borderRadius"),
    boxShadow: "0 4px 6px -1px rgba(0, 0, 0, 0.1), 0 2px 4px -1px rgba(0, 0, 0, 0.06)",
    border: "1px solid rgba(255, 255, 255, 0.1)",
    padding: "1rem",
    textAlign: "center" as const,
    marginBottom: "1rem",
  };

  const buttonPreviewStyle = {
    backgroundColor: form.watch("accentColor"),
    borderRadius: form.watch("borderRadius"),
    padding: "0.5rem 1rem",
    border: "none",
    color: "#fff",
    cursor: "pointer",
    fontWeight: "bold" as const,
    marginTop: "0.5rem"
  };

  return (
    <div className="flex flex-col space-y-4 max-w-3xl">
      <div className="flex justify-between items-center">
        <h2 className="text-2xl font-bold">Настройки дизайна сайта</h2>
        <Button variant="outline" size="sm" onClick={resetToDefaults}>
          <RefreshCw className="h-4 w-4 mr-2" />
          Сбросить
        </Button>
      </div>
      
      <Tabs value={activeTab} onValueChange={setActiveTab}>
        <TabsList className="grid grid-cols-3">
          <TabsTrigger value="colors">Цвета</TabsTrigger>
          <TabsTrigger value="layout">Макет</TabsTrigger>
          <TabsTrigger value="preview">Предпросмотр</TabsTrigger>
        </TabsList>
        
        <Form {...form}>
          <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-4">
            <TabsContent value="colors" className="space-y-4">
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <FormField
                  control={form.control}
                  name="primaryColor"
                  render={({ field }) => (
                    <FormItem>
                      <FormLabel>Основной цвет фона</FormLabel>
                      <FormControl>
                        <div className="flex gap-2 items-center">
                          <Input
                            {...field}
                            type="text"
                            placeholder="#0f172a"
                          />
                          <Input
                            type="color"
                            value={field.value}
                            onChange={(e) => field.onChange(e.target.value)}
                            className="w-12 h-9 p-1"
                          />
                        </div>
                      </FormControl>
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
                      <FormControl>
                        <div className="flex gap-2 items-center">
                          <Input
                            {...field}
                            type="text"
                            placeholder="#1e293b"
                          />
                          <Input
                            type="color"
                            value={field.value}
                            onChange={(e) => field.onChange(e.target.value)}
                            className="w-12 h-9 p-1"
                          />
                        </div>
                      </FormControl>
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
                      <FormControl>
                        <div className="flex gap-2 items-center">
                          <Input
                            {...field}
                            type="text"
                            placeholder="#3b82f6"
                          />
                          <Input
                            type="color"
                            value={field.value}
                            onChange={(e) => field.onChange(e.target.value)}
                            className="w-12 h-9 p-1"
                          />
                        </div>
                      </FormControl>
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
                      <FormControl>
                        <div className="flex gap-2 items-center">
                          <Input
                            {...field}
                            type="text"
                            placeholder="#0f172a"
                          />
                          <Input
                            type="color"
                            value={field.value}
                            onChange={(e) => field.onChange(e.target.value)}
                            className="w-12 h-9 p-1"
                          />
                        </div>
                      </FormControl>
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
                      <FormControl>
                        <div className="flex gap-2 items-center">
                          <Input
                            {...field}
                            type="text"
                            placeholder="#1e293b"
                          />
                          <Input
                            type="color"
                            value={field.value}
                            onChange={(e) => field.onChange(e.target.value)}
                            className="w-12 h-9 p-1"
                          />
                        </div>
                      </FormControl>
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
                      <FormControl>
                        <div className="flex gap-2 items-center">
                          <Input
                            {...field}
                            type="text"
                            placeholder="#1e293b"
                          />
                          <Input
                            type="color"
                            value={field.value}
                            onChange={(e) => field.onChange(e.target.value)}
                            className="w-12 h-9 p-1"
                          />
                        </div>
                      </FormControl>
                      <FormMessage />
                    </FormItem>
                  )}
                />
              </div>
            </TabsContent>
            
            <TabsContent value="layout" className="space-y-4">
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <FormField
                  control={form.control}
                  name="fontPrimary"
                  render={({ field }) => (
                    <FormItem>
                      <FormLabel>Основной шрифт</FormLabel>
                      <FormControl>
                        <Select
                          value={field.value}
                          onValueChange={field.onChange}
                        >
                          <SelectTrigger>
                            <SelectValue placeholder="Выберите шрифт" />
                          </SelectTrigger>
                          <SelectContent>
                            <SelectItem value="Inter">Inter</SelectItem>
                            <SelectItem value="Roboto">Roboto</SelectItem>
                            <SelectItem value="Open Sans">Open Sans</SelectItem>
                            <SelectItem value="PT Sans">PT Sans</SelectItem>
                            <SelectItem value="Montserrat">Montserrat</SelectItem>
                          </SelectContent>
                        </Select>
                      </FormControl>
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
                      <FormControl>
                        <Select
                          value={field.value}
                          onValueChange={field.onChange}
                        >
                          <SelectTrigger>
                            <SelectValue placeholder="Выберите радиус" />
                          </SelectTrigger>
                          <SelectContent>
                            <SelectItem value="0">Нет (0)</SelectItem>
                            <SelectItem value="0.25rem">Маленький (0.25rem)</SelectItem>
                            <SelectItem value="0.5rem">Средний (0.5rem)</SelectItem>
                            <SelectItem value="0.75rem">Большой (0.75rem)</SelectItem>
                            <SelectItem value="1rem">Очень большой (1rem)</SelectItem>
                          </SelectContent>
                        </Select>
                      </FormControl>
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
                      <FormControl>
                        <Select
                          value={field.value}
                          onValueChange={field.onChange}
                        >
                          <SelectTrigger>
                            <SelectValue placeholder="Выберите стиль" />
                          </SelectTrigger>
                          <SelectContent>
                            <SelectItem value="default">Стандартный</SelectItem>
                            <SelectItem value="gradient">Градиент</SelectItem>
                            <SelectItem value="outline">Контурный</SelectItem>
                            <SelectItem value="flat">Плоский</SelectItem>
                          </SelectContent>
                        </Select>
                      </FormControl>
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
                      <FormControl>
                        <Select
                          value={field.value}
                          onValueChange={field.onChange}
                        >
                          <SelectTrigger>
                            <SelectValue placeholder="Выберите стиль подиума" />
                          </SelectTrigger>
                          <SelectContent>
                            <SelectItem value="default">Стандартный</SelectItem>
                            <SelectItem value="gradient">Градиент</SelectItem>
                            <SelectItem value="flat">Плоский</SelectItem>
                            <SelectItem value="minimalist">Минималистичный</SelectItem>
                          </SelectContent>
                        </Select>
                      </FormControl>
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
                      <FormControl>
                        <Select
                          value={field.value}
                          onValueChange={field.onChange}
                        >
                          <SelectTrigger>
                            <SelectValue placeholder="Выберите паттерн" />
                          </SelectTrigger>
                          <SelectContent>
                            <SelectItem value="none">Нет</SelectItem>
                            <SelectItem value="grid">Сетка</SelectItem>
                            <SelectItem value="dots">Точки</SelectItem>
                            <SelectItem value="circles">Круги</SelectItem>
                            <SelectItem value="waves">Волны</SelectItem>
                          </SelectContent>
                        </Select>
                      </FormControl>
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
                      <FormControl>
                        <Select
                          value={field.value}
                          onValueChange={field.onChange}
                        >
                          <SelectTrigger>
                            <SelectValue placeholder="Выберите позицию" />
                          </SelectTrigger>
                          <SelectContent>
                            <SelectItem value="left">Слева</SelectItem>
                            <SelectItem value="center">По центру</SelectItem>
                            <SelectItem value="right">Справа</SelectItem>
                          </SelectContent>
                        </Select>
                      </FormControl>
                      <FormMessage />
                    </FormItem>
                  )}
                />
              </div>
            </TabsContent>
            
            <TabsContent value="preview" className="space-y-4">
              <div className="flex flex-col space-y-4">
                <h3 className="text-xl font-bold">Предпросмотр настроек</h3>
                
                <div style={{ backgroundColor: form.watch("primaryColor"), padding: "1rem", borderRadius: form.watch("borderRadius"), minHeight: "400px" }}>
                  <div 
                    style={{ 
                      backgroundColor: form.watch("headerBgColor"),
                      padding: "1rem",
                      borderRadius: form.watch("borderRadius"),
                      marginBottom: "1rem",
                      display: "flex",
                      justifyContent: form.watch("logoPosition") === "center" ? "center" : form.watch("logoPosition") === "left" ? "flex-start" : "flex-end"
                    }}
                  >
                    <div className="text-white font-bold">ATOM﮳GAME LOGO</div>
                  </div>
                  
                  <div style={previewStyle}>
                    <h4 className="text-lg font-bold mb-2">Пример карточки</h4>
                    <p className="text-sm opacity-80">Это пример элемента с выбранными настройками дизайна. Вы можете увидеть, как будет выглядеть ваш сайт.</p>
                    <button style={buttonPreviewStyle}>Кнопка</button>
                  </div>
                  
                  <div style={{ ...previewStyle, backgroundColor: form.watch("tableBgColor") }}>
                    <h4 className="text-lg font-bold mb-2">Пример таблицы</h4>
                    <div className="border border-white/10 rounded overflow-hidden">
                      <table className="w-full">
                        <thead className="bg-black/30">
                          <tr>
                            <th className="p-2 text-left">Команда</th>
                            <th className="p-2 text-right">Очки</th>
                          </tr>
                        </thead>
                        <tbody>
                          <tr className="border-t border-white/10">
                            <td className="p-2">Команда A</td>
                            <td className="p-2 text-right">100</td>
                          </tr>
                          <tr className="border-t border-white/10">
                            <td className="p-2">Команда B</td>
                            <td className="p-2 text-right">85</td>
                          </tr>
                        </tbody>
                      </table>
                    </div>
                  </div>
                </div>
              </div>
            </TabsContent>
            
            <div className="flex justify-end space-x-2 pt-4 mt-4 border-t">
              <Button 
                type="button" 
                variant="outline" 
                onClick={onClose}
                disabled={updateSettingsMutation.isPending}
              >
                Отмена
              </Button>
              <Button 
                type="submit" 
                disabled={updateSettingsMutation.isPending}
              >
                {updateSettingsMutation.isPending ? (
                  <>
                    <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                    Сохранение...
                  </>
                ) : (
                  "Сохранить настройки"
                )}
              </Button>
            </div>
          </form>
        </Form>
      </Tabs>
    </div>
  );
}