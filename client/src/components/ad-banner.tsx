import { ExternalLink } from "lucide-react";
import { useEffect, useState } from "react";
import { useQuery } from "@tanstack/react-query";
import { Ad } from "@shared/schema";
import { Skeleton } from "./ui/skeleton";

export default function AdBanner() {
  const [currentAdIndex, setCurrentAdIndex] = useState(0);
  
  const { data: ads, isLoading, error } = useQuery<Ad[]>({
    queryKey: ["/api/ads"],
    staleTime: 1000 * 60 * 5, // 5 минут
  });

  // Эффект для ротации баннеров
  useEffect(() => {
    if (!ads || ads.length <= 1) return;
    
    const interval = setInterval(() => {
      setCurrentAdIndex((prevIndex) => (prevIndex + 1) % ads.length);
    }, 5000); // Каждые 5 секунд
    
    return () => clearInterval(interval);
  }, [ads]);
  
  // Содержимое баннера по умолчанию (для ошибок/пустых данных)
  const fallbackBannerContent = (
    <>
      <h3 className="text-xl font-extrabold text-white sm:text-2xl">
        Турнир ATOM﮳GAME 2025
      </h3>
      <p className="mt-2 text-white text-sm sm:text-base leading-relaxed">
        Не пропустите грандиозный турнир по киберспорту среди молодежи атомных городов России!
      </p>
      <div className="mt-4">
        <a
          href="#"
          className="inline-flex items-center px-4 py-2 border border-white text-sm font-medium rounded-md text-white hover:bg-white hover:bg-opacity-10 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-offset-blue-600 focus:ring-white transition"
        >
          Подробнее <ExternalLink className="ml-2 h-4 w-4" />
        </a>
      </div>
    </>
  );
  
  // Состояние загрузки
  if (isLoading) {
    return (
      <div className="relative w-full h-64">
        <div className="absolute inset-0 bg-gradient-to-r from-blue-600/40 to-indigo-700/40 rounded-xl shadow-md overflow-hidden">
          <div className="absolute inset-0 p-6 sm:p-10 flex flex-col justify-center">
            <BannerSkeleton />
          </div>
        </div>
      </div>
    );
  }
  
  // Обработка ошибок и пустых данных
  if (error || !ads || ads.length === 0) {
    return (
      <div className="relative w-full h-64">
        <div className="absolute inset-0 bg-gradient-to-r from-blue-600 to-indigo-700 rounded-xl shadow-md overflow-hidden">
          <div className="absolute inset-0 p-6 sm:p-10 flex flex-col justify-center">
            <div className="sm:flex-1">
              {fallbackBannerContent}
            </div>
          </div>
        </div>
      </div>
    );
  }
  
  // Фильтруем только активные баннеры
  const activeAds = ads.filter(ad => ad.active);
  
  // Если после фильтрации не осталось активных баннеров, показываем запасной баннер
  if (activeAds.length === 0) {
    return (
      <div className="relative w-full h-64">
        <div className="absolute inset-0 bg-gradient-to-r from-blue-600 to-indigo-700 rounded-xl shadow-md overflow-hidden">
          <div className="absolute inset-0 p-6 sm:p-10 flex flex-col justify-center">
            <div className="sm:flex-1">
              {fallbackBannerContent}
            </div>
          </div>
        </div>
      </div>
    );
  }
  
  // Убедимся, что индекс не выходит за пределы массива баннеров
  const safeIndex = currentAdIndex % activeAds.length;
  const currentAd = activeAds[safeIndex];
  
  // Определяем стиль фона
  const bgStyle = currentAd.bgImage 
    ? { backgroundImage: `url(${currentAd.bgImage})`, backgroundSize: 'cover', backgroundPosition: 'center' }
    : {};
  
  // Обрабатываем ссылку кнопки
  const buttonLink = currentAd.buttonLink || "#";
  
  return (
    <div className="relative w-full h-64">
      <div 
        className={`absolute inset-0 bg-gradient-to-r ${currentAd.bgColor || "from-blue-600 to-indigo-700"} rounded-xl shadow-md overflow-hidden`}
        style={bgStyle}
      >
        {/* Индикаторы для нескольких баннеров */}
        {activeAds.length > 1 && (
          <div className="absolute top-2 right-2 flex gap-1 z-10">
            {activeAds.map((_, index) => (
              <button 
                key={index} 
                onClick={() => setCurrentAdIndex(index)}
                className={`h-2 w-2 rounded-full ${
                  index === safeIndex ? "bg-white" : "bg-white/40"
                } transition-colors`}
                aria-label={`Перейти к баннеру ${index + 1}`}
              />
            ))}
          </div>
        )}
        
        <div className="absolute inset-0 p-6 sm:p-10 flex items-center">
          <div className="flex-1">
            <h3 className="text-xl font-extrabold text-white sm:text-2xl">
              {currentAd.title}
            </h3>
            <p className="mt-2 text-white text-sm sm:text-base leading-relaxed">
              {currentAd.description}
            </p>
            <div className="mt-4">
              <a
                href={buttonLink} 
                target="_blank"
                rel="noopener noreferrer"
                className="inline-flex items-center px-4 py-2 border border-white text-sm font-medium rounded-md text-white hover:bg-white hover:bg-opacity-10 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-offset-blue-600 focus:ring-white transition"
              >
                {currentAd.buttonText || "Подробнее"} <ExternalLink className="ml-2 h-4 w-4" />
              </a>
            </div>
          </div>
          
          {currentAd.logoUrl && (
            <div className="hidden sm:block ml-10 flex-shrink-0">
              <img 
                src={currentAd.logoUrl} 
                alt={`${currentAd.title} Logo`} 
                className="h-24 w-24 object-cover object-center rounded-md border-2 border-white"
                loading="lazy"
              />
            </div>
          )}
        </div>
      </div>
    </div>
  );
}

function BannerSkeleton() {
  return (
    <div className="w-full animate-pulse">
      <div className="sm:flex sm:items-center">
        <div className="sm:flex-1">
          <Skeleton className="h-8 w-3/4 bg-white/20 mb-4" />
          <Skeleton className="h-4 w-full bg-white/20 mb-2" />
          <Skeleton className="h-4 w-5/6 bg-white/20 mb-2" />
          <Skeleton className="h-4 w-4/6 bg-white/20 mb-5" />
          <Skeleton className="h-10 w-32 bg-white/20" />
        </div>
        <div className="hidden sm:block sm:ml-10 sm:flex-shrink-0">
          <Skeleton className="h-24 w-24 rounded-md bg-white/20" />
        </div>
      </div>
    </div>
  );
}