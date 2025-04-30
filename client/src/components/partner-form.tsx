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
import { Loader2 } from "lucide-react";

interface PartnerFormProps {
  partner: Partner | null;
  onClose: () => void;
}

// Расширяем схему для валидации формы
const formSchema = insertPartnerSchema.extend({
  logoUrl: z.string().url("Должен быть валидный URL").or(z.literal("")),
  website: z.string().url("Должен быть валидный URL").or(z.literal("")),
  order: z.coerce.number().int().min(0, "Порядок должен быть положительным числом"),
});

type FormData = z.infer<typeof formSchema>;

export default function PartnerForm({ partner, onClose }: PartnerFormProps) {
  const { toast } = useToast();
  const [isOpen, setIsOpen] = useState(true);

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
      if (partner) {
        const res = await apiRequest("PUT", `/api/partners/${partner.id}`, data);
        return await res.json();
      } else {
        const res = await apiRequest("POST", "/api/partners", data);
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

  const handlePreviewImage = () => {
    const url = form.getValues("logoUrl");
    if (url) {
      window.open(url, "_blank");
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
                      onClick={handlePreviewImage}
                      disabled={!form.getValues("logoUrl")}
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