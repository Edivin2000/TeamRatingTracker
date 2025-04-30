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
import atomGameLogo from "../../assets/atom-game-logo.png";

export default function Navbar() {
  const [location] = useLocation();
  const { user, logoutMutation } = useAuth();
  
  const handleLogout = () => {
    logoutMutation.mutate();
  };
  
  return (
    <nav className="bg-black shadow-md">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex justify-between h-16">
          <div className="flex items-center">
            <Link href="/">
              <div className="flex-shrink-0 flex items-center cursor-pointer">
                <img 
                  src={atomGameLogo} 
                  alt="ATOM﮳GAME" 
                  className="h-10 md:h-12"
                />
              </div>
            </Link>
          </div>
          <div className="flex items-center">
            {user ? (
              <DropdownMenu>
                <DropdownMenuTrigger asChild>
                  <Button variant="ghost" className="relative h-8 w-8 rounded-full text-white hover:bg-gray-800">
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
            ) : (
              <span className="text-xs text-gray-400">
                <Link href="/auth">
                  <span className="hover:text-white cursor-pointer transition">Администрация</span>
                </Link>
              </span>
            )}
          </div>
        </div>
      </div>
    </nav>
  );
}
