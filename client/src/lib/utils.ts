import { clsx, type ClassValue } from "clsx"
import { twMerge } from "tailwind-merge"

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs))
}

// Функция очистки истории рейтингов
export function clearRankingsHistory() {
  localStorage.removeItem('teamRankingsData');
  console.log('История рейтингов очищена');
}
