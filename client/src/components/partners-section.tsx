import { Card, CardContent } from "@/components/ui/card";
import { useQuery } from "@tanstack/react-query";
import { Partner } from "@shared/schema";
import { Skeleton } from "./ui/skeleton";

export default function PartnersSection() {
  const { data: partners, isLoading, error } = useQuery<Partner[]>({
    queryKey: ["/api/partners"],
    staleTime: 1000 * 60 * 5, // 5 minutes
  });
  
  if (isLoading) {
    return <PartnersSkeleton />;
  }
  
  if (error || !partners || partners.length === 0) {
    return (
      <div className="bg-white rounded-xl shadow-md p-6">
        <div className="mt-6 text-center text-sm text-gray-500">
          <p>Проект поддерживается <span className="font-medium">Фондом «АТР АЭС» и АО «Концерн Росэнергоатом»</span></p>
          <p className="mt-2">Разработчик: <span className="font-medium">ATOM﮳GAME Team</span></p>
        </div>
      </div>
    );
  }
  
  return (
    <div className="bg-white rounded-xl shadow-md p-6">
      <div className="grid grid-cols-2 md:grid-cols-4 gap-6">
        {partners.map((partner) => (
          <a 
            key={partner.id} 
            href={partner.website || "#"} 
            target="_blank" 
            rel="noopener noreferrer"
            className="block"
          >
            <Card className="border-0 transition-all duration-200 hover:shadow-md">
              <CardContent className="flex items-center justify-center p-4 h-24">
                <img 
                  src={partner.logoUrl || "https://placehold.co/160x80/gray/white?text=Partner"}
                  alt={`${partner.name} logo`}
                  className="max-h-16 max-w-full"
                />
              </CardContent>
            </Card>
            <div className="mt-2 text-center text-sm text-gray-600">
              {partner.name}
            </div>
          </a>
        ))}
      </div>
      <div className="mt-6 text-center text-sm text-gray-500">
        <p>Проект поддерживается <span className="font-medium">Фондом «АТР АЭС» и АО «Концерн Росэнергоатом»</span></p>
        <p className="mt-2">Разработчик: <span className="font-medium">ATOM﮳GAME Team</span></p>
      </div>
    </div>
  );
}

function PartnersSkeleton() {
  return (
    <div className="bg-white rounded-xl shadow-md p-6">
      <div className="grid grid-cols-2 md:grid-cols-4 gap-6">
        {[1, 2, 3, 4].map((id) => (
          <div key={id} className="block">
            <Skeleton className="h-24 w-full bg-gray-100" />
            <Skeleton className="h-5 w-2/3 mx-auto mt-2 bg-gray-100" />
          </div>
        ))}
      </div>
      <div className="mt-6 text-center text-sm text-gray-500">
        <p>Проект поддерживается <span className="font-medium">Фондом «АТР АЭС» и АО «Концерн Росэнергоатом»</span></p>
        <p className="mt-2">Разработчик: <span className="font-medium">ATOM﮳GAME Team</span></p>
      </div>
    </div>
  );
}