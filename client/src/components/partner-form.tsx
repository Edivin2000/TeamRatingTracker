import { useState } from "react";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { z } from "zod";
import { useMutation } from "@tanstack/react-query";
import { Partner, insertPartnerSchema } from "@shared/schema";
import { apiRequest, queryClient } from "@/lib/queryClient";
import { useToast } from "@/hooks/use-toast";
import { Dialog, DialogContent, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { Form, FormControl, FormField, FormItem, FormLabel, FormMessage } from "@/components/ui/form";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Loader2, Upload, Image as ImageIcon } from "lucide-react";

interface PartnerFormProps {
  partner: Partner | null;
  onClose: () => void;
}

// Расширяем схему для валидации формы
const formSchema = insertPartnerSchema.extend({
  logoUrl: z.string().nullable().optional(),
  website: z.string().url("Должен быть валидный URL").or(z.literal("")),
  order: z.coerce.number().int().min(0, "Порядок должен быть положительным числом"),
  logoFile: z.instanceof(FileList).optional().transform(val => val && val.length > 0 ? val[0] : undefined),
});

type FormData = z.infer<typeof formSchema>;

export default function PartnerForm({ partner, onClose }: PartnerFormProps) {
  const { toast } = useToast();
  const [isOpen, setIsOpen] = useState(true);
  const [logoPreview, setLogoPreview] = useState<string | null>(partner?.logoUrl || null);

  const form = useForm<FormData>({
    resolver: zodResolver(formSchema),
    defaultValues: partner 
      ? {
          name: partner.name,
          logoUrl: partner.logoUrl || "",
          website: partner.website || "#",
          order: partner.order || 0,
        }
      : {
          name: "",
          logoUrl: "",
          website: "#",
          order: 0,
        },
  });

  const mutation = useMutation({
    mutationFn: async (data: FormData) => {
      // Используем logoPreview, который уже содержит изображение,
      // если оно было загружено или URL, если было указано вручную
      const partnerData = {
        name: data.name,
        logoUrl: logoPreview || data.logoUrl || "",
        website: data.website,
        order: data.order,
      };
      
      // Логируем для отладки
      console.log("Отправляем данные партнера:", {
        name: partnerData.name,
        logoUrlLength: partnerData.logoUrl ? partnerData.logoUrl.length : 0,
        hasLogo: Boolean(partnerData.logoUrl),
        website: partnerData.website,
        order: partnerData.order
      });
      
      if (partner) {
        const res = await apiRequest("PUT", `/api/partners/${partner.id}`, partnerData);
        return await res.json();
      } else {
        const res = await apiRequest("POST", "/api/partners", partnerData);
        return await res.json();
      }
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["/api/partners"] });
      toast({
        title: partner ? "Партнер обновлен" : "Партнер добавлен",
        description: partner 
          ? "Данные партнера успешно обновлены" 
          : "Новый партнер успешно добавлен",
      });
      handleClose();
    },
    onError: (error) => {
      toast({
        title: "Ошибка",
        description: `Не удалось ${partner ? 'обновить' : 'добавить'} партнера: ${error.message}`,
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

  // Функция оптимизации изображения
  const optimizeImage = async (file: File, maxWidth = 200, maxHeight = 100): Promise<string> => {
    return new Promise((resolve, reject) => {
      const img = new Image();
      const reader = new FileReader();
      
      reader.onload = (e) => {
        img.src = e.target?.result as string;
        
        img.onload = () => {
          // Создаем canvas для изменения размера
          const canvas = document.createElement('canvas');
          let width = img.width;
          let height = img.height;
          
          // Вычисляем новые размеры с сохранением пропорций
          if (width > height) {
            if (width > maxWidth) {
              height = Math.round(height * maxWidth / width);
              width = maxWidth;
            }
          } else {
            if (height > maxHeight) {
              width = Math.round(width * maxHeight / height);
              height = maxHeight;
            }
          }
          
          // Устанавливаем размеры canvas
          canvas.width = width;
          canvas.height = height;
          
          // Отрисовываем изображение с новыми размерами
          const ctx = canvas.getContext('2d');
          ctx?.drawImage(img, 0, 0, width, height);
          
          // Преобразуем в base64 с указанным качеством
          const dataURL = canvas.toDataURL('image/jpeg', 0.7);
          resolve(dataURL);
        };
        
        img.onerror = () => {
          reject(new Error('Не удалось загрузить изображение'));
        };
      };
      
      reader.onerror = () => {
        reject(new Error('Не удалось прочитать файл'));
      };
      
      reader.readAsDataURL(file);
    });
  };

  const handleFileChange = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (file) {
      try {
        // Оптимизируем изображение перед отображением и перед загрузкой
        const optimizedImage = await optimizeImage(file);
        setLogoPreview(optimizedImage);
        
        // Обновляем значение logoUrl в форме, чтобы использовать оптимизированное изображение
        form.setValue("logoUrl", optimizedImage);
        
        // Выводим в консоль информацию о загруженном файле для отладки
        console.log("Оптимизированное изображение партнера готово к отправке");
      } catch (error) {
        console.error("Ошибка при оптимизации изображения:", error);
      }
    }
  };

  return (
    <Dialog open={isOpen} onOpenChange={setIsOpen}>
      <DialogContent onInteractOutside={e => e.preventDefault()} className="max-w-lg">
        <DialogHeader>
          <DialogTitle>
            {partner ? `Редактировать партнера: ${partner.name}` : "Добавить партнера"}
          </DialogTitle>
        </DialogHeader>
        
        <Form {...form}>
          <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-4">
            <FormField
              control={form.control}
              name="name"
              render={({ field }) => (
                <FormItem>
                  <FormLabel>Название *</FormLabel>
                  <FormControl>
                    <Input placeholder="Название организации" {...field} />
                  </FormControl>
                  <FormMessage />
                </FormItem>
              )}
            />
            
            <div className="space-y-2">
              <FormLabel>Логотип партнера</FormLabel>
              <div className="flex items-center space-x-4 mb-4">
                <div className="w-24 h-24 bg-gray-100 rounded border flex items-center justify-center overflow-hidden">
                  {logoPreview ? (
                    <img 
                      src={logoPreview} 
                      alt="Предпросмотр логотипа" 
                      className="w-full h-full object-contain" 
                    />
                  ) : (
                    <ImageIcon className="w-10 h-10 text-gray-300" />
                  )}
                </div>
                <div className="flex flex-col space-y-2">
                  <Label 
                    htmlFor="logoFile" 
                    className="cursor-pointer inline-flex items-center px-4 py-2 bg-gray-200 hover:bg-gray-300 rounded-md text-sm font-medium transition-smooth"
                  >
                    <Upload className="w-4 h-4 mr-2" />
                    Загрузить логотип
                  </Label>
                  <input
                    type="file"
                    id="logoFile"
                    className="hidden"
                    accept="image/*"
                    {...form.register("logoFile")}
                    onChange={handleFileChange}
                  />
                  <div className="text-xs text-gray-500">
                    Рекомендуемый размер: 200x100px, JPG или PNG
                  </div>
                </div>
              </div>
              
              <FormField
                control={form.control}
                name="logoUrl"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>Или укажите URL логотипа</FormLabel>
                    <FormControl>
                      <Input 
                        placeholder="https://example.com/logo.png" 
                        value={field.value || ""} 
                        onChange={field.onChange}
                        onBlur={field.onBlur}
                        name={field.name}
                        ref={field.ref}
                      />
                    </FormControl>
                    <FormMessage />
                  </FormItem>
                )}
              />
            </div>
            
            <FormField
              control={form.control}
              name="website"
              render={({ field }) => (
                <FormItem>
                  <FormLabel>URL сайта</FormLabel>
                  <FormControl>
                    <Input placeholder="https://example.com" {...field} />
                  </FormControl>
                  <FormMessage />
                </FormItem>
              )}
            />
            
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
                  partner ? "Сохранить" : "Добавить"
                )}
              </Button>
            </div>
          </form>
        </Form>
      </DialogContent>
    </Dialog>
  );
}

// Компонент Label для стилизации
function Label({ className, ...props }: React.LabelHTMLAttributes<HTMLLabelElement> & { className?: string }) {
  return (
    <label className={`text-sm font-medium ${className || ""}`} {...props} />
  );
}