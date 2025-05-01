import React, { useState, useEffect } from 'react';
import { Card, CardContent } from '@/components/ui/card';
import { useQuery } from '@tanstack/react-query';

type TimeLeft = {
  days: number;
  hours: number;
  minutes: number;
  seconds: number;
};

const calculateTimeLeft = (endDate: string): TimeLeft => {
  const difference = new Date(endDate).getTime() - new Date().getTime();
  let timeLeft: TimeLeft = {
    days: 0,
    hours: 0,
    minutes: 0,
    seconds: 0
  };

  if (difference > 0) {
    timeLeft = {
      days: Math.floor(difference / (1000 * 60 * 60 * 24)),
      hours: Math.floor((difference / (1000 * 60 * 60)) % 24),
      minutes: Math.floor((difference / 1000 / 60) % 60),
      seconds: Math.floor((difference / 1000) % 60)
    };
  }

  return timeLeft;
};

export default function CountdownTimer() {
  const [timeLeft, setTimeLeft] = useState<TimeLeft>({
    days: 0,
    hours: 0,
    minutes: 0,
    seconds: 0
  });

  const { data: timers, isLoading } = useQuery({
    queryKey: ['/api/timers'],
    refetchInterval: 60000, // Refetch every minute
  });

  const activeTimer = timers && timers.length > 0 ? timers[0] : null;
  
  useEffect(() => {
    if (!activeTimer) return;
    
    // Начальный расчет
    setTimeLeft(calculateTimeLeft(activeTimer.endDate));
    
    // Обновление каждую секунду
    const timer = setInterval(() => {
      setTimeLeft(calculateTimeLeft(activeTimer.endDate));
    }, 1000);

    return () => clearInterval(timer);
  }, [activeTimer]);

  if (isLoading) {
    return null; // or loading spinner
  }

  if (!activeTimer) {
    return null; // no active timer
  }

  const { days, hours, minutes, seconds } = timeLeft;
  const isExpired = days <= 0 && hours <= 0 && minutes <= 0 && seconds <= 0;

  if (isExpired) {
    return null; // timer expired
  }

  return (
    <Card className="w-full max-w-md mx-auto mb-8">
      <CardContent className="p-4">
        <div className="flex flex-col">
          <h3 className="text-xl font-bold mb-4">{activeTimer.displayName || 'Обратный отсчет'}</h3>
          
          <div className={`grid grid-cols-4 gap-2 text-center bg-gradient-to-r ${activeTimer.color}`}>
            <div className="flex flex-col items-center justify-center p-3 text-white">
              <div className="text-2xl font-bold">{days}</div>
              <div className="text-xs">дней</div>
            </div>
            <div className="flex flex-col items-center justify-center p-3 text-white">
              <div className="text-2xl font-bold">{hours}</div>
              <div className="text-xs">часов</div>
            </div>
            <div className="flex flex-col items-center justify-center p-3 text-white">
              <div className="text-2xl font-bold">{minutes}</div>
              <div className="text-xs">минут</div>
            </div>
            <div className="flex flex-col items-center justify-center p-3 text-white">
              <div className="text-2xl font-bold">{seconds}</div>
              <div className="text-xs">секунд</div>
            </div>
          </div>
        </div>
      </CardContent>
    </Card>
  );
}