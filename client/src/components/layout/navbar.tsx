import { useState } from "react";
import { Link, useLocation } from "wouter";
import { Trophy } from "lucide-react";
import { Button } from "@/components/ui/button";
import { useAuth } from "@/hooks/use-auth";

export default function Navbar() {
  const [location] = useLocation();
  const { user } = useAuth();
  
  return (
    <nav className="bg-white shadow-md">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex justify-between h-16">
          <div className="flex items-center">
            <Link href="/">
              <div className="flex-shrink-0 flex items-center cursor-pointer">
                <Trophy className="text-primary h-6 w-6 mr-2" />
                <h1 className="font-heading font-bold text-xl text-dark">Рейтинг Команд</h1>
              </div>
            </Link>
          </div>
          <div className="flex items-center">
            {user ? (
              <Link href="/admin">
                <Button variant="default" className="bg-primary hover:bg-blue-600 text-white">
                  Панель Администратора
                </Button>
              </Link>
            ) : (
              <Link href="/auth">
                <Button variant="default" className="bg-primary hover:bg-blue-600 text-white">
                  Вход для Администратора
                </Button>
              </Link>
            )}
          </div>
        </div>
      </div>
    </nav>
  );
}
