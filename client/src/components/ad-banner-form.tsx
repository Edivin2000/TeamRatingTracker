import { useState } from "react";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { z } from "zod";
import { useMutation } from "@tanstack/react-query";
import { Ad, insertAdSchema } from "@shared/schema";
import { apiRequest, queryClient } from "@/lib/queryClient";
import { useToast } from "@/hooks/use-toast";
import { Dialog, DialogContent, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { Form, FormControl, FormField, FormItem, FormLabel, FormMessage } from "@/components/ui/form";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Textarea } from "@/components/ui/textarea";
import { Checkbox } from "@/components/ui/checkbox";
import { Label } from "@/components/ui/label";
import { Loader2 } from "lucide-react";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";

interface AdBannerFormProps {
  ad: Ad | null;
  onClose: () => void;
}

// Расширяем схему для валидации формы
const formSchema = insertAdSchema.extend({
  title: z.string().min(2, "Заголовок должен содержать не менее 2 символов"),
  description: z.string().min(5, "Описание должно содержать не менее 5 символов"),
  logoUrl: z.string().url("Должен быть валидный URL").or(z.literal("")),
  bgImage: z.string().url("Должен быть валидный URL").or(z.literal("")),
  bgColor: z.string(),
  buttonText: z.string().min(1, "Текст кнопки не может быть пустым"),
  buttonLink: z.string().url("Должен быть валидный URL").or(z.literal("#")),
  active: z.boolean(),
  order: z.coerce.number().int().min(0, "Порядок должен быть положительным числом"),
});

type FormData = z.infer<typeof formSchema>;

// Доступные градиенты для фона
const backgroundGradients = [
  { value: "from-blue-600 to-indigo-700", label: "Синий - Индиго" },
  { value: "from-green-600 to-teal-700", label: "Зеленый - Бирюзовый" },
  { value: "from-orange-600 to-red-700", label: "Оранжевый - Красный" },
  { value: "from-purple-600 to-pink-700", label: "Пурпурный - Розовый" },
  { value: "from-gray-700 to-gray-900", label: "Серый - Темно-серый" },
];

export default function AdBannerForm({ ad, onClose }: AdBannerFormProps) {
  const { toast } = useToast();
  const [isOpen, setIsOpen] = useState(true);

  const form = useForm<FormData>({
    resolver: zodResolver(formSchema),
    defaultValues: ad 
      ? {
          title: ad.title,
          description: ad.description,
          logoUrl: ad.logoUrl || "",
          bgImage: ad.bgImage || "",
          bgColor: ad.bgColor || "from-blue-600 to-indigo-700",
          buttonText: ad.buttonText || "Подробнее",
          buttonLink: ad.buttonLink || "#",
          active: ad.active,
          order: ad.order || 0,
        }
      : {
          title: "",
          description: "",
          logoUrl: "",
          bgImage: "",
          bgColor: "from-blue-600 to-indigo-700",
          buttonText: "Подробнее",
          buttonLink: "#",
          active: true,
          order: 0,
        },
  });

  const mutation = useMutation({
    mutationFn: async (data: FormData) => {
      if (ad) {
        const res = await apiRequest("PUT", `/api/ads/${ad.id}`, data);
        return await res.json();
      } else {
        const res = await apiRequest("POST", "/api/ads", data);
        return await res.json();
      }
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["/api/ads"] });
      toast({
        title: ad ? "Баннер обновлен" : "Баннер добавлен",
        description: ad 
          ? "Рекламный баннер успешно обновлен" 
          : "Новый рекламный баннер успешно добавлен",
      });
      handleClose();
    },
    onError: (error) => {
      toast({
        title: "Ошибка",
        description: `Не удалось ${ad ? 'обновить' : 'добавить'} рекламный баннер: ${error.message}`,
        variant: "destructive",
      });
    },
  });

  const onSubmit = (data: FormData) => {
    mutation.mutate(data);
  };

  const handleClose = () => {
    setIsOpen(false);
    onClose();
  };

  const handlePreviewImage = (field: "logoUrl" | "bgImage") => {
    const url = form.getValues(field);
    if (url) {
      window.open(url, "_blank");
    }
  };

  // Предпросмотр баннера
  const previewData = form.watch();
  const hasBgImage = !!previewData.bgImage;

  return (
    <Dialog open={isOpen} onOpenChange={setIsOpen}>
      <DialogContent onInteractOutside={e => e.preventDefault()} className="max-w-4xl">
        <DialogHeader>
          <DialogTitle>
            {ad ? `Редактировать баннер: ${ad.title}` : "Добавить рекламный баннер"}
          </DialogTitle>
        </DialogHeader>
        
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          <div className="space-y-4">
            <Form {...form}>
              <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-4">
                <FormField
                  control={form.control}
                  name="title"
                  render={({ field }) => (
                    <FormItem>
                      <FormLabel>Заголовок *</FormLabel>
                      <FormControl>
                        <Input placeholder="Заголовок баннера" {...field} />
                      </FormControl>
                      <FormMessage />
                    </FormItem>
                  )}
                />
                
                <FormField
                  control={form.control}
                  name="description"
                  render={({ field }) => (
                    <FormItem>
                      <FormLabel>Описание *</FormLabel>
                      <FormControl>
                        <Textarea 
                          placeholder="Подробное описание баннера" 
                          className="min-h-[80px]" 
                          {...field} 
                        />
                      </FormControl>
                      <FormMessage />
                    </FormItem>
                  )}
                />
                
                <FormField
                  control={form.control}
                  name="logoUrl"
                  render={({ field }) => (
                    <FormItem>
                      <FormLabel>URL логотипа</FormLabel>
                      <div className="flex gap-2">
                        <FormControl>
                          <Input placeholder="https://example.com/logo.png" {...field} />
                        </FormControl>
                        <Button 
                          type="button"
                          variant="outline"
                          onClick={() => handlePreviewImage("logoUrl")}
                          disabled={!form.getValues("logoUrl")}
                        >
                          Просмотр
                        </Button>
                      </div>
                      <FormMessage />
                    </FormItem>
                  )}
                />
                
                <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                  <FormField
                    control={form.control}
                    name="bgImage"
                    render={({ field }) => (
                      <FormItem>
                        <FormLabel>URL фонового изображения</FormLabel>
                        <div className="flex gap-2">
                          <FormControl>
                            <Input placeholder="https://example.com/bg.jpg" {...field} />
                          </FormControl>
                          <Button 
                            type="button"
                            variant="outline"
                            onClick={() => handlePreviewImage("bgImage")}
                            disabled={!form.getValues("bgImage")}
                          >
                            Просмотр
                          </Button>
                        </div>
                        <FormMessage />
                      </FormItem>
                    )}
                  />
                  
                  <FormField
                    control={form.control}
                    name="bgColor"
                    render={({ field }) => (
                      <FormItem className={hasBgImage ? "opacity-50" : ""}>
                        <FormLabel>Цвет фона</FormLabel>
                        <Select
                          disabled={hasBgImage}
                          onValueChange={field.onChange}
                          defaultValue={field.value}
                        >
                          <FormControl>
                            <SelectTrigger>
                              <SelectValue placeholder="Выберите цвет фона" />
                            </SelectTrigger>
                          </FormControl>
                          <SelectContent>
                            {backgroundGradients.map((gradient) => (
                              <SelectItem key={gradient.value} value={gradient.value}>
                                {gradient.label}
                              </SelectItem>
                            ))}
                          </SelectContent>
                        </Select>
                        <FormMessage />
                        {hasBgImage && (
                          <p className="text-xs text-gray-500 mt-1">
                            Цвет фона не используется при наличии фонового изображения
                          </p>
                        )}
                      </FormItem>
                    )}
                  />
                </div>
                
                <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                  <FormField
                    control={form.control}
                    name="buttonText"
                    render={({ field }) => (
                      <FormItem>
                        <FormLabel>Текст кнопки</FormLabel>
                        <FormControl>
                          <Input placeholder="Подробнее" {...field} />
                        </FormControl>
                        <FormMessage />
                      </FormItem>
                    )}
                  />
                  
                  <FormField
                    control={form.control}
                    name="buttonLink"
                    render={({ field }) => (
                      <FormItem>
                        <FormLabel>Ссылка кнопки</FormLabel>
                        <FormControl>
                          <Input placeholder="https://example.com/page" {...field} />
                        </FormControl>
                        <FormMessage />
                      </FormItem>
                    )}
                  />
                </div>
                
                <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                  <FormField
                    control={form.control}
                    name="order"
                    render={({ field }) => (
                      <FormItem>
                        <FormLabel>Порядок отображения</FormLabel>
                        <FormControl>
                          <Input type="number" min="0" {...field} />
                        </FormControl>
                        <FormMessage />
                      </FormItem>
                    )}
                  />
                  
                  <FormField
                    control={form.control}
                    name="active"
                    render={({ field }) => (
                      <FormItem className="flex flex-row items-start space-x-3 space-y-0 pt-6">
                        <FormControl>
                          <Checkbox
                            checked={field.value}
                            onCheckedChange={field.onChange}
                          />
                        </FormControl>
                        <div className="space-y-1 leading-none">
                          <FormLabel>Активен</FormLabel>
                          <p className="text-xs text-gray-500">
                            Неактивные баннеры не будут отображаться на сайте
                          </p>
                        </div>
                      </FormItem>
                    )}
                  />
                </div>
                
                <div className="flex justify-end space-x-4 pt-4">
                  <Button type="button" variant="outline" onClick={handleClose}>
                    Отмена
                  </Button>
                  <Button type="submit" disabled={mutation.isPending}>
                    {mutation.isPending ? (
                      <>
                        <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                        Сохранение...
                      </>
                    ) : (
                      ad ? "Сохранить" : "Добавить"
                    )}
                  </Button>
                </div>
              </form>
            </Form>
          </div>
          
          {/* Предпросмотр баннера */}
          <div className="space-y-2">
            <h3 className="text-sm font-medium text-gray-500">Предпросмотр баннера</h3>
            <div 
              className={`bg-gradient-to-r ${previewData.bgColor} rounded-xl shadow-md overflow-hidden h-[200px]`}
              style={previewData.bgImage ? {
                backgroundImage: `url(${previewData.bgImage})`,
                backgroundSize: 'cover',
                backgroundPosition: 'center'
              } : {}}
            >
              <div className="px-6 py-6 h-full flex flex-col justify-between">
                <div>
                  <h3 className="text-xl font-bold text-white">
                    {previewData.title || "Заголовок баннера"}
                  </h3>
                  <p className="mt-2 text-white text-sm leading-relaxed line-clamp-3">
                    {previewData.description || "Описание баннера будет отображаться здесь..."}
                  </p>
                </div>
                
                <div className="flex items-end justify-between">
                  <div>
                    <Button
                      variant="outline"
                      className="border-white text-white hover:bg-white/20"
                    >
                      {previewData.buttonText || "Подробнее"}
                    </Button>
                  </div>
                  
                  {previewData.logoUrl && (
                    <div className="flex-shrink-0">
                      <img 
                        src={previewData.logoUrl}
                        alt="Логотип" 
                        className="h-16 w-16 object-contain rounded border-2 border-white"
                      />
                    </div>
                  )}
                </div>
              </div>
            </div>
            <p className="text-xs text-gray-500 text-center mt-2">
              Это предварительный просмотр. Реальный баннер может выглядеть немного иначе.
            </p>
          </div>
        </div>
      </DialogContent>
    </Dialog>
  );
}