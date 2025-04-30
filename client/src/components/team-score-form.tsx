import { useState } from "react";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { z } from "zod";
import { useMutation } from "@tanstack/react-query";
import { Team, ScoreUpdate } from "@shared/schema";
import { apiRequest, queryClient } from "@/lib/queryClient";
import { useToast } from "@/hooks/use-toast";
import { 
  Dialog, 
  DialogContent, 
  DialogHeader, 
  DialogTitle, 
  DialogDescription 
} from "@/components/ui/dialog";
import { Form, FormControl, FormField, FormItem, FormLabel, FormMessage } from "@/components/ui/form";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Loader2, PlusCircle, MinusCircle, PenLine } from "lucide-react";
import { RadioGroup, RadioGroupItem } from "@/components/ui/radio-group";
import { Label } from "@/components/ui/label";

interface TeamScoreFormProps {
  team: Team;
  onClose: () => void;
}

// Схема для валидации формы
const formSchema = z.object({
  operation: z.enum(["add", "subtract", "set"], {
    required_error: "Необходимо выбрать операцию",
  }),
  value: z.coerce.number().int().min(0, "Значение должно быть положительным числом"),
});

type FormData = z.infer<typeof formSchema>;

export default function TeamScoreForm({ team, onClose }: TeamScoreFormProps) {
  const { toast } = useToast();
  const [isOpen, setIsOpen] = useState(true);

  const form = useForm<FormData>({
    resolver: zodResolver(formSchema),
    defaultValues: {
      operation: "add",
      value: 0,
    },
  });

  const mutation = useMutation({
    mutationFn: async (data: FormData) => {
      const res = await apiRequest("POST", `/api/teams/${team.id}/score`, data);
      return await res.json();
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["/api/teams"] });
      toast({
        title: "Очки обновлены",
        description: "Очки команды успешно обновлены",
      });
      handleClose();
    },
    onError: (error) => {
      toast({
        title: "Ошибка",
        description: `Не удалось обновить очки команды: ${error.message}`,
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

  // Предварительный подсчет результата
  const operation = form.watch("operation");
  const value = form.watch("value") || 0;
  let resultScore = team.score;

  if (operation === "add") {
    resultScore = team.score + value;
  } else if (operation === "subtract") {
    resultScore = Math.max(0, team.score - value);
  } else if (operation === "set") {
    resultScore = value;
  }

  return (
    <Dialog open={isOpen} onOpenChange={setIsOpen}>
      <DialogContent onInteractOutside={e => e.preventDefault()} className="max-w-md">
        <DialogHeader>
          <DialogTitle>
            Изменить очки команды: {team.name}
          </DialogTitle>
          <DialogDescription>
            Текущее количество очков: <strong>{team.score}</strong>
          </DialogDescription>
        </DialogHeader>
        
        <Form {...form}>
          <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-4">
            <FormField
              control={form.control}
              name="operation"
              render={({ field }) => (
                <FormItem className="space-y-3">
                  <FormLabel>Операция с очками</FormLabel>
                  <FormControl>
                    <RadioGroup
                      onValueChange={field.onChange}
                      defaultValue={field.value}
                      className="flex flex-col space-y-1"
                    >
                      <div className="flex items-center space-x-2">
                        <RadioGroupItem value="add" id="add" />
                        <Label htmlFor="add" className="flex items-center cursor-pointer">
                          <PlusCircle className="w-4 h-4 mr-2 text-green-600" />
                          Добавить очки
                        </Label>
                      </div>
                      <div className="flex items-center space-x-2">
                        <RadioGroupItem value="subtract" id="subtract" />
                        <Label htmlFor="subtract" className="flex items-center cursor-pointer">
                          <MinusCircle className="w-4 h-4 mr-2 text-red-600" />
                          Вычесть очки
                        </Label>
                      </div>
                      <div className="flex items-center space-x-2">
                        <RadioGroupItem value="set" id="set" />
                        <Label htmlFor="set" className="flex items-center cursor-pointer">
                          <PenLine className="w-4 h-4 mr-2 text-blue-600" />
                          Установить значение
                        </Label>
                      </div>
                    </RadioGroup>
                  </FormControl>
                  <FormMessage />
                </FormItem>
              )}
            />
            
            <FormField
              control={form.control}
              name="value"
              render={({ field }) => (
                <FormItem>
                  <FormLabel>Значение</FormLabel>
                  <FormControl>
                    <Input type="number" min="0" {...field} />
                  </FormControl>
                  <FormMessage />
                </FormItem>
              )}
            />
            
            <div className="mt-6 p-3 bg-gray-50 rounded-md">
              <div className="text-sm text-gray-500">Результат:</div>
              <div className="text-xl font-bold mt-1 flex items-baseline">
                <span>{team.score}</span>
                <span className="mx-2">
                  {operation === "add" && <span className="text-green-600">→</span>}
                  {operation === "subtract" && <span className="text-red-600">→</span>}
                  {operation === "set" && <span className="text-blue-600">→</span>}
                </span>
                <span>{resultScore}</span>
                <span className="ml-2 text-xs text-gray-500">
                  {operation === "add" && value > 0 && `(+${value})`}
                  {operation === "subtract" && value > 0 && `(-${value})`}
                  {operation === "set" && 
                    (value > team.score ? `(+${value - team.score})` : 
                     value < team.score ? `(-${team.score - value})` : "")}
                </span>
              </div>
            </div>
            
            <div className="flex justify-end space-x-4 pt-4">
              <Button type="button" variant="outline" onClick={handleClose}>
                Отмена
              </Button>
              <Button 
                type="submit" 
                disabled={mutation.isPending || value === 0}
                className={
                  operation === "add" ? "bg-green-600 hover:bg-green-700" :
                  operation === "subtract" ? "bg-red-600 hover:bg-red-700" :
                  undefined
                }
              >
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