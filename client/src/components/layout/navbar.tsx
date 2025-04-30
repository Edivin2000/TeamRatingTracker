import { useState } from "react";
import { Link, useLocation } from "wouter";
import { Trophy, Settings, User } from "lucide-react";
import { Button } from "@/components/ui/button";
import { useAuth } from "@/hooks/use-auth";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import atomGameLogo from "../../assets/atom-game-logo-blue.png";

export default function Navbar() {
  const [location] = useLocation();
  const { user, logoutMutation } = useAuth();
  
  const handleLogout = () => {
    logoutMutation.mutate();
  };
  
  // Секретный счетчик кликов для доступа к админпанели
  const [secretKeyCounter, setSecretKeyCounter] = useState(0);
  const [showSecretAuth, setShowSecretAuth] = useState(false);
  
  // Сбрасываем счетчик через 3 секунды после последнего нажатия
  const resetSecretTimer = () => {
    setTimeout(() => {
      setSecretKeyCounter(0);
    }, 3000);
  };
  
  // Проверяем количество кликов для разблокировки секретной авторизации
  const checkSecretAuth = (newCount: number) => {
    if (newCount >= 5) {
      setShowSecretAuth(true);
      setTimeout(() => {
        setShowSecretAuth(false);
        setSecretKeyCounter(0);
      }, 5000); // Скрываем ссылку через 5 секунд
    }
  };
  
  return (
    <nav className="bg-white shadow-md">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex h-20 relative">
          {/* Создаем невидимую зону для клика в правом углу для администраторов */}
          {!user && (
            <>
              <span 
                className="absolute top-0 right-0 h-10 w-10 cursor-default z-10" 
                title=""
                onClick={() => {
                  setSecretKeyCounter(prev => {
                    const newCount = prev + 1;
                    resetSecretTimer();
                    checkSecretAuth(newCount);
                    return newCount;
                  });
                }}
              />
              
              {/* Показываем секретную ссылку только после определенного количества кликов */}
              {showSecretAuth && (
                <div className="absolute top-2 right-2 animate-pulse z-20">
                  <Link href="/auth">
                    <span className="text-xs text-blue-500 opacity-70 hover:opacity-100 transition-opacity cursor-pointer">
                      Войти
                    </span>
                  </Link>
                </div>
              )}
            </>
          )}
          
          {/* Центрированный логотип */}
          <div className="flex items-center justify-center w-full">
            <Link href="/">
              <div className="flex-shrink-0 flex items-center cursor-pointer">
                <img 
                  src={atomGameLogo} 
                  alt="ATOM.GAME" 
                  className="h-14 md:h-16"
                />
              </div>
            </Link>
          </div>
          
          {/* Панель администратора в правом углу (видна только при авторизации) */}
          {user && (
            <div className="absolute right-0 top-1/2 transform -translate-y-1/2 flex items-center">
              <DropdownMenu>
                <DropdownMenuTrigger asChild>
                  <Button variant="ghost" className="relative h-8 w-8 rounded-full text-gray-700 hover:bg-gray-100">
                    <User className="h-4 w-4" />
                  </Button>
                </DropdownMenuTrigger>
                <DropdownMenuContent align="end">
                  <DropdownMenuItem className="cursor-pointer">
                    <Link href="/admin">
                      <div className="flex items-center">
                        <Settings className="mr-2 h-4 w-4" />
                        <span>Панель администратора</span>
                      </div>
                    </Link>
                  </DropdownMenuItem>
                  <DropdownMenuItem 
                    className="cursor-pointer"
                    onClick={handleLogout}
                  >
                    Выйти
                  </DropdownMenuItem>
                </DropdownMenuContent>
              </DropdownMenu>
            </div>
          )}
        </div>
      </div>
    </nav>
  );
}
