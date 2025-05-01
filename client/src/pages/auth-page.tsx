import { useEffect } from "react";
import { useLocation } from "wouter";
import { 
  Card, 
  CardContent, 
  CardDescription, 
  CardHeader, 
  CardTitle 
} from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { useAuth } from "@/hooks/use-auth";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { z } from "zod";
import { Loader2, Trophy } from "lucide-react";
import { loginSchema } from "@shared/schema";

export default function AuthPage() {
  const [location, navigate] = useLocation();
  const { user, loginMutation } = useAuth();
  
  // Создаем схему для входа
  const loginFormSchema = loginSchema;
  type LoginFormData = z.infer<typeof loginFormSchema>;
  
  // Настраиваем форму входа
  const loginForm = useForm<LoginFormData>({
    resolver: zodResolver(loginFormSchema),
    defaultValues: {
      username: "",
      password: "",
    },
  });

  // Обработка отправки формы входа
  const onLoginSubmit = (data: LoginFormData) => {
    loginMutation.mutate(data);
  };

  // Перенаправление, если уже авторизован
  useEffect(() => {
    if (user) {
      navigate(user.isAdmin ? "/admin" : "/");
    }
  }, [user, navigate]);

  return (
    <div className="min-h-screen flex flex-col md:flex-row">
      {/* Левая сторона: Форма авторизации */}
      <div className="w-full md:w-1/2 p-8 flex items-center justify-center bg-white">
        <div className="w-full max-w-md">
          <div className="text-center mb-8">
            <h1 className="text-3xl font-bold mb-2">ATOM﮳GAME 2025</h1>
            <p className="text-gray-500">Требуется авторизация администратора</p>
          </div>
          
          <Card>
            <CardHeader>
              <CardTitle>Вход</CardTitle>
              <CardDescription>
                Введите учетные данные для доступа к панели администратора.
              </CardDescription>
            </CardHeader>
            <CardContent>
              <form onSubmit={loginForm.handleSubmit(onLoginSubmit)} className="space-y-4">
                <div className="space-y-2">
                  <Label htmlFor="loginUsername">Имя пользователя</Label>
                  <Input 
                    id="loginUsername" 
                    {...loginForm.register("username")} 
                    placeholder="Введите имя пользователя"
                  />
                  {loginForm.formState.errors.username && (
                    <p className="text-sm text-red-500">{loginForm.formState.errors.username.message}</p>
                  )}
                </div>
                
                <div className="space-y-2">
                  <Label htmlFor="loginPassword">Пароль</Label>
                  <Input 
                    id="loginPassword" 
                    type="password" 
                    {...loginForm.register("password")} 
                    placeholder="Введите пароль"
                  />
                  {loginForm.formState.errors.password && (
                    <p className="text-sm text-red-500">{loginForm.formState.errors.password.message}</p>
                  )}
                </div>
                
                <Button type="submit" className="w-full" disabled={loginMutation.isPending}>
                  {loginMutation.isPending ? (
                    <Loader2 className="h-4 w-4 mr-2 animate-spin" />
                  ) : null}
                  Войти
                </Button>
              </form>
            </CardContent>
          </Card>
        </div>
      </div>
      
      {/* Правая сторона: Информационный баннер */}
      <div className="w-full md:w-1/2 bg-gradient-to-br from-primary to-blue-700 p-8 text-white flex items-center">
        <div className="max-w-lg mx-auto space-y-8">
          <div className="text-center">
            <Trophy className="h-16 w-16 mx-auto mb-4" />
            <h2 className="text-4xl font-bold mb-4">ATOM﮳GAME БАЛАКОВО 2025</h2>
            <p className="text-xl opacity-90">
              Управляйте регистрацией, рейтингами команд и информацией о турнире с призовым фондом 150 000 рублей!
            </p>
          </div>
          
          <div className="bg-white/10 backdrop-blur-sm rounded-lg p-6 space-y-4">
            <h3 className="text-xl font-semibold">Возможности панели управления:</h3>
            <ul className="space-y-2">
              <li className="flex items-center space-x-2">
                <span className="h-5 w-5 bg-white/20 rounded-full flex items-center justify-center text-sm">✓</span>
                <span>Управление регистрацией на сезон 2025</span>
              </li>
              <li className="flex items-center space-x-2">
                <span className="h-5 w-5 bg-white/20 rounded-full flex items-center justify-center text-sm">✓</span>
                <span>Добавление и редактирование команд-участников</span>
              </li>
              <li className="flex items-center space-x-2">
                <span className="h-5 w-5 bg-white/20 rounded-full flex items-center justify-center text-sm">✓</span>
                <span>Управление отображением баннеров и таймеров</span>
              </li>
              <li className="flex items-center space-x-2">
                <span className="h-5 w-5 bg-white/20 rounded-full flex items-center justify-center text-sm">✓</span>
                <span>Добавление партнеров и спонсоров турнира</span>
              </li>
              <li className="flex items-center space-x-2">
                <span className="h-5 w-5 bg-white/20 rounded-full flex items-center justify-center text-sm">✓</span>
                <span>Контроль над рейтингом команд и турнирной таблицей</span>
              </li>
            </ul>
          </div>
        </div>
      </div>
    </div>
  );
}
