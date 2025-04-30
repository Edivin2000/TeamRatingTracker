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
              <a className="flex-shrink-0 flex items-center">
                <Trophy className="text-primary h-6 w-6 mr-2" />
                <h1 className="font-heading font-bold text-xl text-dark">Team Rankings</h1>
              </a>
            </Link>
          </div>
          <div className="flex items-center">
            {user ? (
              <Link href="/admin">
                <a>
                  <Button variant="default" className="bg-primary hover:bg-blue-600 text-white">
                    Admin Dashboard
                  </Button>
                </a>
              </Link>
            ) : (
              <Link href="/auth">
                <a>
                  <Button variant="default" className="bg-primary hover:bg-blue-600 text-white">
                    Admin Login
                  </Button>
                </a>
              </Link>
            )}
          </div>
        </div>
      </div>
    </nav>
  );
}
