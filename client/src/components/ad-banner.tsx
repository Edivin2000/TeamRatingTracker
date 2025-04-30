import { ExternalLink } from "lucide-react";
import { useEffect, useState } from "react";
import { useQuery } from "@tanstack/react-query";
import { Ad } from "@shared/schema";
import { Skeleton } from "./ui/skeleton";

// Константа фиксированной высоты для всех состояний баннера
const BANNER_HEIGHT = 220;

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
  
  // Фильтруем только активные баннеры (или пустой массив, если данных нет)
  const activeAds = ads?.filter(ad => ad.active) || [];
  
  // Убедимся, что индекс не выходит за пределы массива баннеров
  const safeIndex = activeAds.length ? (currentAdIndex % activeAds.length) : 0;
  
  // Текущий баннер или null, если нет активных баннеров
  const currentAd = activeAds.length ? activeAds[safeIndex] : null;
  
  // Определяем стиль фона для активного баннера
  const bgStyle = currentAd?.bgImage 
    ? { backgroundImage: `url(${currentAd.bgImage})`, backgroundSize: 'cover', backgroundPosition: 'center' }
    : {};
  
  // Обрабатываем ссылку кнопки
  const buttonLink = currentAd?.buttonLink || "#";
  
  // CSS класс для плавного перехода между баннерами
  const transitionClass = "transition-all duration-500 ease-in-out";
  
  // CSS класс для цвета фона (градиент или специфичный для баннера)
  const bgColorClass = currentAd?.bgColor || "from-blue-600 to-indigo-700";
  
  return (
    // Внешний контейнер с фиксированной высотой
    <div style={{ height: `${BANNER_HEIGHT}px` }} className="w-full relative">
      {/* Общий контейнер баннера с тенью и скругленными углами */}
      <div className={`absolute inset-0 rounded-xl shadow-md overflow-hidden bg-gradient-to-r ${bgColorClass} ${transitionClass}`}
           style={bgStyle}>
        
        {/* Индикаторы для нескольких баннеров */}
        {activeAds.length > 1 && (
          <div className="absolute top-2 right-2 flex gap-1 z-10">
            {activeAds.map((_, index) => (
              <button 
                key={index} 
                onClick={() => setCurrentAdIndex(index)}
                className={`h-2 w-2 rounded-full ${
                  index === safeIndex ? "bg-white" : "bg-white/40"
                } ${transitionClass}`}
                aria-label={`Перейти к баннеру ${index + 1}`}
              />
            ))}
          </div>
        )}
        
        {/* Содержимое баннера */}
        <div className="absolute inset-0 p-6 sm:p-10 flex items-center">
          <div className="flex-1">
            {/* Состояние загрузки */}
            {isLoading ? (
              <div className="animate-pulse">
                <Skeleton className="h-8 w-3/4 bg-white/20 mb-4" />
                <Skeleton className="h-4 w-full bg-white/20 mb-2" />
                <Skeleton className="h-4 w-5/6 bg-white/20 mb-2" />
                <Skeleton className="h-4 w-4/6 bg-white/20 mb-5" />
                <Skeleton className="h-10 w-32 bg-white/20" />
              </div>
            ) : 
            // Нет активных баннеров или произошла ошибка
            (!currentAd || error) ? (
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
            ) : (
              // Активный баннер
              <>
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
              </>
            )}
          </div>
          
          {/* Логотип баннера (только для активного баннера) */}
          {!isLoading && currentAd && currentAd.logoUrl && (
            <div className="hidden sm:block ml-10 flex-shrink-0">
              <img 
                src={currentAd.logoUrl} 
                alt={`${currentAd.title} Logo`} 
                className="h-24 w-24 object-cover object-center rounded-md border-2 border-white"
                loading="lazy"
              />
            </div>
          )}
          
          {/* Скелетон для логотипа при загрузке */}
          {isLoading && (
            <div className="hidden sm:block ml-10 flex-shrink-0">
              <Skeleton className="h-24 w-24 rounded-md bg-white/20" />
            </div>
          )}
        </div>
      </div>
    </div>
  );
}