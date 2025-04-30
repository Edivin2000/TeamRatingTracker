import { ExternalLink } from "lucide-react";
import { useEffect, useState } from "react";
import { useQuery } from "@tanstack/react-query";
import { Ad } from "@shared/schema";
import { Skeleton } from "./ui/skeleton";

export default function AdBanner() {
  const [currentAdIndex, setCurrentAdIndex] = useState(0);
  const { data: ads, isLoading, error } = useQuery<Ad[]>({
    queryKey: ["/api/ads"],
    staleTime: 1000 * 60 * 5, // 5 minutes
  });

  useEffect(() => {
    if (!ads || ads.length <= 1) return;
    
    const interval = setInterval(() => {
      setCurrentAdIndex((prevIndex) => (prevIndex + 1) % ads.length);
    }, 5000); // Каждые 5 секунд
    
    return () => clearInterval(interval);
  }, [ads]);
  
  if (isLoading) {
    return <BannerSkeleton />;
  }
  
  if (error || !ads || ads.length === 0) {
    return null; // Не показываем баннер при ошибке или отсутствии баннеров
  }
  
  const currentAd = ads[currentAdIndex];
  const bgStyle = currentAd.bgImage 
    ? { backgroundImage: `url(${currentAd.bgImage})`, backgroundSize: 'cover', backgroundPosition: 'center' }
    : {};
  
  return (
    <div 
      className={`bg-gradient-to-r ${currentAd.bgColor} rounded-xl shadow-md overflow-hidden relative`}
      style={bgStyle}
    >
      {/* Индикаторы для нескольких баннеров */}
      {ads.length > 1 && (
        <div className="absolute top-2 right-2 flex gap-1">
          {ads.map((_, index) => (
            <span 
              key={index} 
              className={`h-2 w-2 rounded-full ${
                index === currentAdIndex ? "bg-white" : "bg-white/40"
              }`}
            />
          ))}
        </div>
      )}
      
      <div className="px-6 py-8 sm:p-10 sm:flex sm:items-center">
        <div className="sm:flex-1">
          <h3 className="text-xl font-extrabold text-white sm:text-2xl">
            {currentAd.title}
          </h3>
          <p className="mt-2 text-white text-sm sm:text-base leading-relaxed">
            {currentAd.description}
          </p>
          <div className="mt-4">
            <a
              href={currentAd.buttonLink} 
              target="_blank"
              rel="noopener noreferrer"
              className="inline-flex items-center px-4 py-2 border border-white text-sm font-medium rounded-md text-white hover:bg-white hover:bg-opacity-10 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-offset-blue-600 focus:ring-white transition"
            >
              {currentAd.buttonText} <ExternalLink className="ml-2 h-4 w-4" />
            </a>
          </div>
        </div>
        {currentAd.logoUrl && (
          <div className="mt-6 sm:mt-0 sm:ml-10 sm:flex-shrink-0">
            <img 
              src={currentAd.logoUrl} 
              alt={`${currentAd.title} Logo`} 
              className="h-24 w-24 object-cover object-center rounded-md border-2 border-white"
            />
          </div>
        )}
      </div>
    </div>
  );
}

function BannerSkeleton() {
  return (
    <div className="bg-gradient-to-r from-blue-600/40 to-indigo-700/40 rounded-xl shadow-md overflow-hidden animate-pulse">
      <div className="px-6 py-8 sm:p-10 sm:flex sm:items-center">
        <div className="sm:flex-1">
          <Skeleton className="h-8 w-3/4 bg-white/20 mb-4" />
          <Skeleton className="h-4 w-full bg-white/20 mb-2" />
          <Skeleton className="h-4 w-5/6 bg-white/20 mb-2" />
          <Skeleton className="h-4 w-4/6 bg-white/20 mb-5" />
          <Skeleton className="h-10 w-32 bg-white/20" />
        </div>
        <div className="mt-6 sm:mt-0 sm:ml-10 sm:flex-shrink-0">
          <Skeleton className="h-24 w-24 rounded-md bg-white/20" />
        </div>
      </div>
    </div>
  );
}