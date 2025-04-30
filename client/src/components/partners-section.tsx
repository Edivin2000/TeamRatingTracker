import { Card, CardContent } from "@/components/ui/card";
import { useQuery } from "@tanstack/react-query";
import { Partner } from "@shared/schema";
import { Skeleton } from "./ui/skeleton";
import { ExternalLink } from "lucide-react";

export default function PartnersSection() {
  const { data: partners, isLoading, error } = useQuery<Partner[]>({
    queryKey: ["/api/partners"],
    staleTime: 1000 * 60 * 5, // 5 minutes
  });
  
  if (isLoading) {
    return <PartnersSkeleton />;
  }
  
  // Сортируем партнеров по полю order, если оно есть
  const sortedPartners = [...(partners || [])].sort((a, b) => {
    const orderA = a.order !== null ? a.order : 999;
    const orderB = b.order !== null ? b.order : 999;
    return orderA - orderB;
  });
  
  return (
    <div className="bg-gradient-to-br from-slate-50 to-white rounded-xl shadow-md p-6">
      <div className="relative mb-10">
        <div className="absolute inset-0 flex items-center">
          <div className="w-full border-t border-gray-200"></div>
        </div>
        <div className="relative flex justify-center">
          <h2 className="px-4 text-2xl font-bold text-center bg-gradient-to-br from-slate-50 to-white">
            <span className="bg-clip-text text-transparent bg-gradient-to-r from-blue-600 to-indigo-600">Наши Партнеры</span>
          </h2>
        </div>
      </div>
      
      {error || !partners || partners.length === 0 ? (
        <div className="text-center p-8">
          <p className="text-gray-500">Информация о партнерах временно недоступна</p>
        </div>
      ) : (
        <div>
          <div className="grid grid-cols-2 md:grid-cols-4 gap-6">
            {sortedPartners.map((partner) => (
              <a 
                key={partner.id} 
                href={partner.website || "#"} 
                target="_blank" 
                rel="noopener noreferrer"
                className={`group block ${partner.website ? 'cursor-pointer' : 'cursor-default'}`}
              >
                <Card className="border border-gray-100 overflow-hidden transition-all duration-300 
                              group-hover:shadow-lg group-hover:border-gray-200">
                  <CardContent className="flex items-center justify-center p-4 h-28 bg-white">
                    <img 
                      src={partner.logoUrl || "https://placehold.co/160x80/gray/white?text=Partner"}
                      alt={`${partner.name} logo`}
                      className="max-h-20 max-w-full transition-transform duration-300 group-hover:scale-105"
                    />
                  </CardContent>
                </Card>
                <div className="mt-3 text-center">
                  <div className="text-sm font-medium text-gray-800 flex items-center justify-center">
                    {partner.name}
                    {partner.website && (
                      <ExternalLink className="ml-1 w-3 h-3 text-gray-400 group-hover:text-blue-500 transition-colors" />
                    )}
                  </div>
                </div>
              </a>
            ))}
          </div>
          
          <div className="mt-10 pt-6 border-t border-gray-100 text-center">
            <p className="text-sm text-gray-600">
              Проект поддерживается <span className="font-semibold text-gray-800">Фондом «АТР АЭС» и АО «Концерн Росэнергоатом»</span>
            </p>
            <p className="mt-2 text-sm text-gray-600">
              Разработчик: <span className="font-semibold text-gray-800">ATOM﮳GAME Team</span>
            </p>
          </div>
        </div>
      )}
    </div>
  );
}

function PartnersSkeleton() {
  return (
    <div className="bg-gradient-to-br from-slate-50 to-white rounded-xl shadow-md p-6">
      <div className="relative mb-10">
        <div className="absolute inset-0 flex items-center">
          <div className="w-full border-t border-gray-200"></div>
        </div>
        <div className="relative flex justify-center">
          <h2 className="px-4 text-2xl font-bold text-center bg-gradient-to-br from-slate-50 to-white">
            <span className="bg-clip-text text-transparent bg-gradient-to-r from-blue-600 to-indigo-600">Наши Партнеры</span>
          </h2>
        </div>
      </div>
      
      <div className="grid grid-cols-2 md:grid-cols-4 gap-6">
        {[1, 2, 3, 4].map((id) => (
          <div key={id} className="block">
            <Card className="border border-gray-100 overflow-hidden">
              <CardContent className="p-0">
                <Skeleton className="h-28 w-full bg-gray-50" />
              </CardContent>
            </Card>
            <div className="mt-3 flex justify-center">
              <Skeleton className="h-5 w-24 bg-gray-50" />
            </div>
          </div>
        ))}
      </div>
      
      <div className="mt-10 pt-6 border-t border-gray-100 text-center">
        <p className="text-sm text-gray-600">
          Проект поддерживается <span className="font-semibold text-gray-800">Фондом «АТР АЭС» и АО «Концерн Росэнергоатом»</span>
        </p>
        <p className="mt-2 text-sm text-gray-600">
          Разработчик: <span className="font-semibold text-gray-800">ATOM﮳GAME Team</span>
        </p>
      </div>
    </div>
  );
}