#!/bin/bash

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

echo -e "${BOLD}${GREEN}====================================================${NC}"
echo -e "${BOLD}${GREEN}       Исправление сохранения изображений           ${NC}"
echo -e "${BOLD}${GREEN}====================================================${NC}"

# 1. Исправление partner-form.tsx
echo -e "\n${BLUE}[1/5] Исправление компонента partner-form.tsx...${NC}"
cat > client/src/components/partner-form.tsx << 'EOF'
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
        logoUrl: logoPreview || "",
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

  const handleFileChange = async (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0];
    if (file) {
      try {
        const optimizedImage = await optimizeImage(file);
        setLogoPreview(optimizedImage);
      } catch (error) {
        console.error("Ошибка оптимизации изображения:", error);
        toast({
          title: "Ошибка изображения",
          description: "Не удалось обработать изображение. Попробуйте другой файл.",
          variant: "destructive",
        });
      }
    }
  };

  // Оптимизирует и конвертирует изображение в base64
  const optimizeImage = async (file: File, maxWidth = 200, maxHeight = 100): Promise<string> => {
    if (!file) return "";
    
    return new Promise((resolve, reject) => {
      const reader = new FileReader();
      reader.onload = (e) => {
        const img = new Image();
        img.onload = () => {
          // Расчёт размеров с сохранением пропорций
          let width = img.width;
          let height = img.height;
          
          if (width > maxWidth) {
            height = (height * maxWidth) / width;
            width = maxWidth;
          }
          
          if (height > maxHeight) {
            width = (width * maxHeight) / height;
            height = maxHeight;
          }
          
          // Создаём canvas для ресайза
          const canvas = document.createElement('canvas');
          canvas.width = width;
          canvas.height = height;
          
          // Рисуем и сжимаем изображение
          const ctx = canvas.getContext('2d');
          if (!ctx) {
            reject(new Error('Не удалось создать контекст canvas'));
            return;
          }
          
          ctx.drawImage(img, 0, 0, width, height);
          
          // Конвертируем в строку base64 с настройкой качества
          const dataUrl = canvas.toDataURL('image/jpeg', 0.92);
          resolve(dataUrl);
        };
        
        img.onerror = () => {
          reject(new Error('Не удалось загрузить изображение'));
        };
        
        img.src = e.target?.result as string;
      };
      
      reader.onerror = () => {
        reject(new Error('Не удалось прочитать файл'));
      };
      
      reader.readAsDataURL(file);
    });
  };

  return (
    <Dialog open={isOpen} onOpenChange={(open) => {
      if (!open) handleClose();
    }}>
      <DialogContent className="max-w-lg">
        <DialogHeader>
          <DialogTitle>
            {partner ? "Редактировать партнера" : "Добавить нового партнера"}
          </DialogTitle>
        </DialogHeader>
        
        <Form {...form}>
          <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-6">
            <FormField
              control={form.control}
              name="name"
              render={({ field }) => (
                <FormItem>
                  <FormLabel>Название организации</FormLabel>
                  <FormControl>
                    <Input placeholder="Название партнера" {...field} />
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
                  <label 
                    htmlFor="logoFile" 
                    className="cursor-pointer inline-flex items-center px-4 py-2 bg-gray-200 hover:bg-gray-300 rounded-md text-sm font-medium transition-smooth"
                  >
                    <Upload className="w-4 h-4 mr-2" />
                    Загрузить логотип
                  </label>
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
                        onChange={(e) => {
                          field.onChange(e);
                          if (e.target.value) {
                            setLogoPreview(e.target.value);
                          }
                        }}
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
                  "Сохранить"
                )}
              </Button>
            </div>
          </form>
        </Form>
      </DialogContent>
    </Dialog>
  );
}

function Label({ className, ...props }: React.LabelHTMLAttributes<HTMLLabelElement> & { className?: string }) {
  return (
    <label className={`text-sm font-medium leading-none peer-disabled:cursor-not-allowed peer-disabled:opacity-70 ${className || ""}`} {...props} />
  );
}
EOF

# 2. Исправление team-form.tsx
echo -e "\n${BLUE}[2/5] Исправление компонента team-form.tsx...${NC}"
cat > client/src/components/team-form.tsx << 'EOF'
import { useState } from "react";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { z } from "zod";
import { useMutation } from "@tanstack/react-query";
import { Team, insertTeamSchema } from "@shared/schema";
import { apiRequest, queryClient } from "@/lib/queryClient";
import { useToast } from "@/hooks/use-toast";
import { Dialog, DialogContent, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { Form, FormControl, FormField, FormItem, FormLabel, FormMessage } from "@/components/ui/form";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Checkbox } from "@/components/ui/checkbox";
import { Loader2, Upload, Image as ImageIcon } from "lucide-react";

interface TeamFormProps {
  team: Team | null;
  onClose: () => void;
}

export default function TeamForm({ team, onClose }: TeamFormProps) {
  const { toast } = useToast();
  const [isOpen, setIsOpen] = useState(true);
  const [logoPreview, setLogoPreview] = useState<string | null>(team?.logoUrl || null);

  // Расширяем схему для валидации формы
  const formSchema = insertTeamSchema.extend({
    name: z.string().min(2, "Название должно содержать не менее 2 символов"),
    logoUrl: z.string().nullable().optional(),
    score: z.coerce.number().min(0, "Счет должен быть положительным числом").default(0),
    excluded: z.boolean().default(false),
    logoFile: z.instanceof(FileList).optional().transform(val => val && val.length > 0 ? val[0] : undefined),
  });
  
  type FormData = z.infer<typeof formSchema>;

  const form = useForm<FormData>({
    resolver: zodResolver(formSchema),
    defaultValues: team 
      ? {
          name: team.name,
          logoUrl: team.logoUrl || "",
          score: team.score || 0,
          excluded: team.excluded || false,
        }
      : {
          name: "",
          logoUrl: "",
          score: 0,
          excluded: false,
        },
  });

  const mutation = useMutation({
    mutationFn: async (data: FormData) => {
      // Используем logoPreview, который уже содержит изображение
      const teamData = {
        name: data.name,
        logoUrl: logoPreview || "",
        score: data.score,
        excluded: data.excluded,
      };
      
      if (team) {
        const res = await apiRequest("PUT", `/api/teams/${team.id}`, teamData);
        return await res.json();
      } else {
        const res = await apiRequest("POST", "/api/teams", teamData);
        return await res.json();
      }
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["/api/teams"] });
      queryClient.invalidateQueries({ queryKey: ["/api/admin/teams"] });
      toast({
        title: team ? "Команда обновлена" : "Команда добавлена",
        description: team 
          ? "Данные команды успешно обновлены" 
          : "Новая команда успешно добавлена",
      });
      handleClose();
    },
    onError: (error) => {
      toast({
        title: "Ошибка",
        description: `Не удалось ${team ? 'обновить' : 'добавить'} команду: ${error.message}`,
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

  const handleFileChange = async (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0];
    if (file) {
      try {
        const optimizedImage = await optimizeImage(file);
        setLogoPreview(optimizedImage);
      } catch (error) {
        console.error("Ошибка оптимизации изображения:", error);
        toast({
          title: "Ошибка изображения",
          description: "Не удалось обработать изображение. Попробуйте другой файл.",
          variant: "destructive",
        });
      }
    }
  };

  // Оптимизирует и конвертирует изображение в base64
  const optimizeImage = async (file: File, maxWidth = 300, maxHeight = 300): Promise<string> => {
    if (!file) return "";
    
    return new Promise((resolve, reject) => {
      const reader = new FileReader();
      reader.onload = (e) => {
        const img = new Image();
        img.onload = () => {
          // Расчёт размеров с сохранением пропорций
          let width = img.width;
          let height = img.height;
          
          if (width > maxWidth) {
            height = (height * maxWidth) / width;
            width = maxWidth;
          }
          
          if (height > maxHeight) {
            width = (width * maxHeight) / height;
            height = maxHeight;
          }
          
          // Создаём canvas для ресайза
          const canvas = document.createElement('canvas');
          canvas.width = width;
          canvas.height = height;
          
          // Рисуем и сжимаем изображение
          const ctx = canvas.getContext('2d');
          if (!ctx) {
            reject(new Error('Не удалось создать контекст canvas'));
            return;
          }
          
          ctx.drawImage(img, 0, 0, width, height);
          
          // Конвертируем в строку base64 с настройкой качества
          const dataUrl = canvas.toDataURL('image/jpeg', 0.92);
          resolve(dataUrl);
        };
        
        img.onerror = () => {
          reject(new Error('Не удалось загрузить изображение'));
        };
        
        img.src = e.target?.result as string;
      };
      
      reader.onerror = () => {
        reject(new Error('Не удалось прочитать файл'));
      };
      
      reader.readAsDataURL(file);
    });
  };

  return (
    <Dialog open={isOpen} onOpenChange={(open) => {
      if (!open) handleClose();
    }}>
      <DialogContent className="max-w-lg">
        <DialogHeader>
          <DialogTitle>
            {team ? "Редактировать команду" : "Добавить новую команду"}
          </DialogTitle>
        </DialogHeader>
        
        <Form {...form}>
          <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-6">
            <FormField
              control={form.control}
              name="name"
              render={({ field }) => (
                <FormItem>
                  <FormLabel>Название команды</FormLabel>
                  <FormControl>
                    <Input placeholder="Название команды" {...field} />
                  </FormControl>
                  <FormMessage />
                </FormItem>
              )}
            />
            
            <div className="space-y-2">
              <FormLabel>Логотип команды</FormLabel>
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
                  <label 
                    htmlFor="logoFile" 
                    className="cursor-pointer inline-flex items-center px-4 py-2 bg-gray-200 hover:bg-gray-300 rounded-md text-sm font-medium transition-smooth"
                  >
                    <Upload className="w-4 h-4 mr-2" />
                    Загрузить логотип
                  </label>
                  <input
                    type="file"
                    id="logoFile"
                    className="hidden"
                    accept="image/*"
                    {...form.register("logoFile")}
                    onChange={handleFileChange}
                  />
                  <div className="text-xs text-gray-500">
                    Рекомендуемый размер: 300x300px, JPG или PNG
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
                        onChange={(e) => {
                          field.onChange(e);
                          if (e.target.value) {
                            setLogoPreview(e.target.value);
                          }
                        }}
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
              name="score"
              render={({ field }) => (
                <FormItem>
                  <FormLabel>Очки</FormLabel>
                  <FormControl>
                    <Input type="number" min="0" {...field} />
                  </FormControl>
                  <FormMessage />
                </FormItem>
              )}
            />
            
            <FormField
              control={form.control}
              name="excluded"
              render={({ field }) => (
                <FormItem className="flex flex-row items-start space-x-3 space-y-0 py-4">
                  <FormControl>
                    <Checkbox
                      checked={field.value}
                      onCheckedChange={field.onChange}
                    />
                  </FormControl>
                  <div className="space-y-1 leading-none">
                    <FormLabel>
                      Исключить из таблицы лидеров
                    </FormLabel>
                    <p className="text-sm text-gray-500">
                      Если отмечено, команда не будет отображаться в общей таблице рейтинга
                    </p>
                  </div>
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
                  "Сохранить"
                )}
              </Button>
            </div>
          </form>
        </Form>
      </DialogContent>
    </Dialog>
  );
}
EOF

# 3. Исправление ad-banner-form.tsx
echo -e "\n${BLUE}[3/5] Исправление компонента ad-banner-form.tsx...${NC}"
cat > client/src/components/ad-banner-form.tsx << 'EOF'
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
import { Loader2, Upload, Image as ImageIcon } from "lucide-react";

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
  logoFile: z.instanceof(FileList).optional().transform(val => val && val.length > 0 ? val[0] : undefined),
  bgImageFile: z.instanceof(FileList).optional().transform(val => val && val.length > 0 ? val[0] : undefined),
});

type FormData = z.infer<typeof formSchema>;

export default function AdBannerForm({ ad, onClose }: AdBannerFormProps) {
  const { toast } = useToast();
  const [isOpen, setIsOpen] = useState(true);
  const [logoPreview, setLogoPreview] = useState<string | null>(ad?.logoUrl || null);
  const [bgImagePreview, setBgImagePreview] = useState<string | null>(ad?.bgImage || null);

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
          active: ad.active || false,
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
      const adData = {
        title: data.title,
        description: data.description,
        logoUrl: logoPreview || "",
        bgImage: bgImagePreview || "",
        bgColor: data.bgColor,
        buttonText: data.buttonText,
        buttonLink: data.buttonLink,
        active: data.active,
        order: data.order,
      };
      
      if (ad) {
        const res = await apiRequest("PUT", `/api/ads/${ad.id}`, adData);
        return await res.json();
      } else {
        const res = await apiRequest("POST", "/api/ads", adData);
        return await res.json();
      }
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["/api/ads"] });
      toast({
        title: ad ? "Баннер обновлен" : "Баннер добавлен",
        description: ad 
          ? "Данные баннера успешно обновлены" 
          : "Новый баннер успешно добавлен",
      });
      handleClose();
    },
    onError: (error) => {
      toast({
        title: "Ошибка",
        description: `Не удалось ${ad ? 'обновить' : 'добавить'} баннер: ${error.message}`,
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

  const handleLogoFileChange = async (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0];
    if (file) {
      try {
        const optimizedImage = await optimizeImage(file, 200, 100);
        setLogoPreview(optimizedImage);
      } catch (error) {
        console.error("Ошибка оптимизации изображения:", error);
        toast({
          title: "Ошибка изображения",
          description: "Не удалось обработать логотип. Попробуйте другой файл.",
          variant: "destructive",
        });
      }
    }
  };

  const handleBgImageFileChange = async (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0];
    if (file) {
      try {
        const optimizedImage = await optimizeImage(file, 1200, 600);
        setBgImagePreview(optimizedImage);
      } catch (error) {
        console.error("Ошибка оптимизации изображения:", error);
        toast({
          title: "Ошибка изображения",
          description: "Не удалось обработать фоновое изображение. Попробуйте другой файл.",
          variant: "destructive",
        });
      }
    }
  };

  // Оптимизирует и конвертирует изображение в base64
  const optimizeImage = async (file: File, maxWidth = 200, maxHeight = 100): Promise<string> => {
    if (!file) return "";
    
    return new Promise((resolve, reject) => {
      const reader = new FileReader();
      reader.onload = (e) => {
        const img = new Image();
        img.onload = () => {
          // Расчёт размеров с сохранением пропорций
          let width = img.width;
          let height = img.height;
          
          if (width > maxWidth) {
            height = (height * maxWidth) / width;
            width = maxWidth;
          }
          
          if (height > maxHeight) {
            width = (width * maxHeight) / height;
            height = maxHeight;
          }
          
          // Создаём canvas для ресайза
          const canvas = document.createElement('canvas');
          canvas.width = width;
          canvas.height = height;
          
          // Рисуем и сжимаем изображение
          const ctx = canvas.getContext('2d');
          if (!ctx) {
            reject(new Error('Не удалось создать контекст canvas'));
            return;
          }
          
          ctx.drawImage(img, 0, 0, width, height);
          
          // Конвертируем в строку base64 с настройкой качества
          const dataUrl = canvas.toDataURL('image/jpeg', 0.92);
          resolve(dataUrl);
        };
        
        img.onerror = () => {
          reject(new Error('Не удалось загрузить изображение'));
        };
        
        img.src = e.target?.result as string;
      };
      
      reader.onerror = () => {
        reject(new Error('Не удалось прочитать файл'));
      };
      
      reader.readAsDataURL(file);
    });
  };

  return (
    <Dialog open={isOpen} onOpenChange={(open) => {
      if (!open) handleClose();
    }}>
      <DialogContent className="max-w-lg">
        <DialogHeader>
          <DialogTitle>
            {ad ? "Редактировать рекламный баннер" : "Добавить новый баннер"}
          </DialogTitle>
        </DialogHeader>
        
        <Form {...form}>
          <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-4">
            <FormField
              control={form.control}
              name="title"
              render={({ field }) => (
                <FormItem>
                  <FormLabel>Заголовок</FormLabel>
                  <FormControl>
                    <Input placeholder="Введите заголовок баннера" {...field} />
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
                  <FormLabel>Описание</FormLabel>
                  <FormControl>
                    <Textarea 
                      placeholder="Введите описание баннера" 
                      className="resize-none" 
                      {...field} 
                    />
                  </FormControl>
                  <FormMessage />
                </FormItem>
              )}
            />
            
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div className="space-y-2">
                <FormLabel>Логотип</FormLabel>
                <div className="flex items-center space-x-4 mb-4">
                  <div className="w-20 h-20 bg-gray-100 rounded border flex items-center justify-center overflow-hidden">
                    {logoPreview ? (
                      <img 
                        src={logoPreview} 
                        alt="Предпросмотр логотипа" 
                        className="w-full h-full object-contain" 
                      />
                    ) : (
                      <ImageIcon className="w-8 h-8 text-gray-300" />
                    )}
                  </div>
                  <div className="flex flex-col space-y-2">
                    <label 
                      htmlFor="logoFile" 
                      className="cursor-pointer inline-flex items-center px-4 py-2 bg-gray-200 hover:bg-gray-300 rounded-md text-sm font-medium transition-smooth"
                    >
                      <Upload className="w-4 h-4 mr-2" />
                      Загрузить
                    </label>
                    <input
                      type="file"
                      id="logoFile"
                      className="hidden"
                      accept="image/*"
                      {...form.register("logoFile")}
                      onChange={handleLogoFileChange}
                    />
                  </div>
                </div>
                
                <FormField
                  control={form.control}
                  name="logoUrl"
                  render={({ field }) => (
                    <FormItem>
                      <FormLabel>Или URL логотипа</FormLabel>
                      <FormControl>
                        <Input 
                          placeholder="https://example.com/logo.png" 
                          value={field.value} 
                          onChange={(e) => {
                            field.onChange(e);
                            if (e.target.value) {
                              setLogoPreview(e.target.value);
                            }
                          }}
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
              
              <div className="space-y-2">
                <FormLabel>Фоновое изображение</FormLabel>
                <div className="flex items-center space-x-4 mb-4">
                  <div className="w-20 h-20 bg-gray-100 rounded border flex items-center justify-center overflow-hidden">
                    {bgImagePreview ? (
                      <img 
                        src={bgImagePreview} 
                        alt="Предпросмотр фона" 
                        className="w-full h-full object-cover" 
                      />
                    ) : (
                      <ImageIcon className="w-8 h-8 text-gray-300" />
                    )}
                  </div>
                  <div className="flex flex-col space-y-2">
                    <label 
                      htmlFor="bgImageFile" 
                      className="cursor-pointer inline-flex items-center px-4 py-2 bg-gray-200 hover:bg-gray-300 rounded-md text-sm font-medium transition-smooth"
                    >
                      <Upload className="w-4 h-4 mr-2" />
                      Загрузить
                    </label>
                    <input
                      type="file"
                      id="bgImageFile"
                      className="hidden"
                      accept="image/*"
                      {...form.register("bgImageFile")}
                      onChange={handleBgImageFileChange}
                    />
                  </div>
                </div>
                
                <FormField
                  control={form.control}
                  name="bgImage"
                  render={({ field }) => (
                    <FormItem>
                      <FormLabel>Или URL фона</FormLabel>
                      <FormControl>
                        <Input 
                          placeholder="https://example.com/bg.jpg" 
                          value={field.value} 
                          onChange={(e) => {
                            field.onChange(e);
                            if (e.target.value) {
                              setBgImagePreview(e.target.value);
                            }
                          }}
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
            </div>
            
            <FormField
              control={form.control}
              name="bgColor"
              render={({ field }) => (
                <FormItem>
                  <FormLabel>Цвет градиента фона</FormLabel>
                  <FormControl>
                    <select
                      className="flex h-10 w-full rounded-md border border-input bg-transparent px-3 py-2 text-sm ring-offset-background file:border-0 file:bg-transparent file:text-sm file:font-medium placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:cursor-not-allowed disabled:opacity-50"
                      value={field.value}
                      onChange={field.onChange}
                      onBlur={field.onBlur}
                      name={field.name}
                      ref={field.ref}
                    >
                      <option value="from-blue-600 to-indigo-700">Синий</option>
                      <option value="from-green-600 to-green-800">Зеленый</option>
                      <option value="from-red-600 to-red-800">Красный</option>
                      <option value="from-purple-600 to-purple-800">Фиолетовый</option>
                      <option value="from-orange-500 to-orange-700">Оранжевый</option>
                      <option value="from-gray-700 to-gray-900">Черный</option>
                    </select>
                  </FormControl>
                  <FormMessage />
                </FormItem>
              )}
            />
            
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
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
                      <Input placeholder="https://example.com" {...field} />
                    </FormControl>
                    <FormMessage />
                  </FormItem>
                )}
              />
            </div>
            
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <FormField
                control={form.control}
                name="active"
                render={({ field }) => (
                  <FormItem className="flex flex-row items-start space-x-3 space-y-0 py-4">
                    <FormControl>
                      <Checkbox
                        checked={field.value}
                        onCheckedChange={field.onChange}
                      />
                    </FormControl>
                    <div className="space-y-1 leading-none">
                      <FormLabel>
                        Активен
                      </FormLabel>
                      <p className="text-sm text-gray-500">
                        Отображать баннер на сайте
                      </p>
                    </div>
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
                  "Сохранить"
                )}
              </Button>
            </div>
          </form>
        </Form>
      </DialogContent>
    </Dialog>
  );
}
EOF

# 4. Исправление порта в server/index.ts
echo -e "\n${BLUE}[4/5] Исправление порта в server/index.ts...${NC}"
cat > server/index.ts << 'EOF'
import express, { type Request, Response, NextFunction } from "express";
import { registerRoutes } from "./routes";
import { setupVite, serveStatic, log } from "./vite";

const app = express();
// Увеличиваем лимит размера запроса до 10MB для загрузки изображений
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: false, limit: '10mb' }));

app.use((req, res, next) => {
  const start = Date.now();
  const path = req.path;
  let capturedJsonResponse: Record<string, any> | undefined = undefined;

  const originalResJson = res.json;
  res.json = function (bodyJson, ...args) {
    capturedJsonResponse = bodyJson;
    return originalResJson.apply(res, [bodyJson, ...args]);
  };

  res.on("finish", () => {
    const duration = Date.now() - start;
    if (path.startsWith("/api")) {
      let logLine = `${req.method} ${path} ${res.statusCode} in ${duration}ms`;
      if (capturedJsonResponse) {
        logLine += ` :: ${JSON.stringify(capturedJsonResponse)}`;
      }

      if (logLine.length > 80) {
        logLine = logLine.slice(0, 79) + "…";
      }

      log(logLine);
    }
  });

  next();
});

(async () => {
  const server = await registerRoutes(app);

  app.use((err: any, _req: Request, res: Response, _next: NextFunction) => {
    const status = err.status || err.statusCode || 500;
    const message = err.message || "Internal Server Error";

    res.status(status).json({ message });
    throw err;
  });

  // importantly only setup vite in development and after
  // setting up all the other routes so the catch-all route
  // doesn't interfere with the other routes
  if (app.get("env") === "development") {
    await setupVite(app, server);
  } else {
    serveStatic(app);
  }

  // Явно устанавливаем порт 5001
  const port = 5001;
  const host = "0.0.0.0";
  const domain = process.env.DOMAIN || "localhost";
  
  server.listen({
    port,
    host,
    reusePort: true,
  }, () => {
    const baseUrl = process.env.NODE_ENV === "production" ? 
      `http://${domain}` : 
      `http://${host === '0.0.0.0' ? 'localhost' : host}:${port}`;
    
    log(`Server running at ${baseUrl} (port: ${port})`);
  });
})();
EOF

# 5. Создание скрипта запуска на порту 5001
echo -e "\n${BLUE}[5/5] Создание скрипта запуска с портом 5001...${NC}"
cat > start-server-5001.sh << 'EOF'
#!/bin/bash

# Цвета для вывода
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

echo -e "${GREEN}Запуск сервера на порту 5001...${NC}"

# Устанавливаем переменную окружения PORT=5001
export PORT=5001

# Перезапускаем workflow
npm run dev

echo -e "${YELLOW}Сервер запущен и доступен по адресу http://localhost:5001${NC}"
EOF

chmod +x start-server-5001.sh

echo -e "${GREEN}====================================================${NC}"
echo -e "${GREEN}Все исправления выполнены успешно!${NC}"
echo -e "${GREEN}====================================================${NC}"
echo -e "${YELLOW}Для запуска сервера на порту 5001 выполните:${NC}"
echo -e "${GREEN}./start-server-5001.sh${NC}"
echo -e "${YELLOW}Или перезапустите workflow 'Start application'${NC}"