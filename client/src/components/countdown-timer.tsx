import { useState, useEffect } from "react";
import { useQuery } from "@tanstack/react-query";
import { Timer } from "@shared/schema";
import { format } from "date-fns";
import { ru } from "date-fns/locale";
import { Skeleton } from "@/components/ui/skeleton";

type TimeLeft = {
  days: number;
  hours: number;
  minutes: number;
  seconds: number;
};

const calculateTimeLeft = (endDate: string): TimeLeft => {
  const difference = new Date(endDate).getTime() - new Date().getTime();
  
  if (difference <= 0) {
    // Время вышло
    return {
      days: 0,
      hours: 0,
      minutes: 0,
      seconds: 0
    };
  }
  
  return {
    days: Math.floor(difference / (1000 * 60 * 60 * 24)),
    hours: Math.floor((difference / (1000 * 60 * 60)) % 24),
    minutes: Math.floor((difference / 1000 / 60) % 60),
    seconds: Math.floor((difference / 1000) % 60)
  };
};

export default function CountdownTimer() {
  const { data: timers, isLoading } = useQuery<Timer[]>({
    queryKey: ["/api/timers"],
    staleTime: 60000, // 1 минута кеширования
  });

  const [timeLeft, setTimeLeft] = useState<TimeLeft>({
    days: 0,
    hours: 0,
    minutes: 0,
    seconds: 0
  });

  // Находим активный таймер с самой ранней датой окончания
  const activeTimer = timers && timers.length > 0
    ? [...timers]
        .filter(timer => timer.active)
        .sort((a, b) => new Date(a.endDate).getTime() - new Date(b.endDate).getTime())[0]
    : null;

  useEffect(() => {
    if (!activeTimer) return;

    // Сразу устанавливаем текущее оставшееся время
    setTimeLeft(calculateTimeLeft(activeTimer.endDate));

    // Обновляем каждую секунду
    const interval = setInterval(() => {
      const newTimeLeft = calculateTimeLeft(activeTimer.endDate);
      setTimeLeft(newTimeLeft);
      
      // Если таймер закончился, очищаем интервал
      if (newTimeLeft.days === 0 && 
          newTimeLeft.hours === 0 && 
          newTimeLeft.minutes === 0 && 
          newTimeLeft.seconds === 0) {
        clearInterval(interval);
      }
    }, 1000);

    return () => clearInterval(interval);
  }, [activeTimer]);

  // Если нет активных таймеров или идет загрузка
  if (isLoading) {
    return (
      <div className="bg-primary/5 rounded-lg p-6 mb-6">
        <Skeleton className="h-7 w-48 mb-4" />
        <div className="grid grid-cols-4 gap-2">
          <Skeleton className="h-20 rounded-md" />
          <Skeleton className="h-20 rounded-md" />
          <Skeleton className="h-20 rounded-md" />
          <Skeleton className="h-20 rounded-md" />
        </div>
      </div>
    );
  }

  if (!activeTimer) {
    return null; // Не показываем таймер если нет активных
  }

  // Форматируем дату для отображения
  const formattedEndDate = format(
    new Date(activeTimer.endDate),
    "d MMMM yyyy, HH:mm",
    { locale: ru }
  );

  // Формируем CSS класс для градиента, используя цвет таймера или стандартный градиент
  let gradientClass = "bg-gradient-to-r ";
  
  // Если в таймере указан цвет, используем его, иначе - стандартный градиент
  if (activeTimer.color) {
    gradientClass += activeTimer.color;
  } else {
    gradientClass += "from-blue-600 to-indigo-700";
  }
  const isTimeExpired = 
    timeLeft.days === 0 && 
    timeLeft.hours === 0 && 
    timeLeft.minutes === 0 && 
    timeLeft.seconds === 0;

  return (
    <div className={`rounded-lg p-6 mb-6 shadow-lg border border-gray-100`}>
      <div className="text-center mb-6">
        <h3 className={`text-xl md:text-2xl font-bold bg-clip-text text-transparent ${gradientClass}`}>
          {activeTimer.displayName || activeTimer.name}
        </h3>
        <p className="text-sm text-gray-500 mt-2">
          {isTimeExpired 
            ? "Регистрация открыта! Создавайте свои команды прямо сейчас!" 
            : `До ${formattedEndDate}`}
        </p>
      </div>

      {!isTimeExpired && (
        <div className="grid grid-cols-4 gap-3">
          <div className="flex flex-col items-center">
            <div className={`${gradientClass} text-white text-2xl md:text-4xl font-bold rounded-md flex items-center justify-center w-full h-16 md:h-20 shadow-md`}>
              {String(timeLeft.days).padStart(2, '0')}
            </div>
            <span className="text-xs mt-2 font-medium">ДНЕЙ</span>
          </div>
          
          <div className="flex flex-col items-center">
            <div className={`${gradientClass} text-white text-2xl md:text-4xl font-bold rounded-md flex items-center justify-center w-full h-16 md:h-20 shadow-md`}>
              {String(timeLeft.hours).padStart(2, '0')}
            </div>
            <span className="text-xs mt-2 font-medium">ЧАСОВ</span>
          </div>
          
          <div className="flex flex-col items-center">
            <div className={`${gradientClass} text-white text-2xl md:text-4xl font-bold rounded-md flex items-center justify-center w-full h-16 md:h-20 shadow-md`}>
              {String(timeLeft.minutes).padStart(2, '0')}
            </div>
            <span className="text-xs mt-2 font-medium">МИНУТ</span>
          </div>
          
          <div className="flex flex-col items-center">
            <div className={`${gradientClass} text-white text-2xl md:text-4xl font-bold rounded-md flex items-center justify-center w-full h-16 md:h-20 shadow-md animate-pulse`}>
              {String(timeLeft.seconds).padStart(2, '0')}
            </div>
            <span className="text-xs mt-2 font-medium">СЕКУНД</span>
          </div>
        </div>
      )}

      {isTimeExpired && (
        <div className="text-center mt-4">
          <button className={`px-6 py-3 rounded-md shadow-md text-white font-bold ${gradientClass} hover:opacity-90 transition-opacity`}>
            Зарегистрировать команду
          </button>
        </div>
      )}
    </div>
  );
}