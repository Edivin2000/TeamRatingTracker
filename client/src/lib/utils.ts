import { clsx, type ClassValue } from "clsx"
import { twMerge } from "tailwind-merge"

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs))
}

/**
 * Функция очистки истории рейтингов команд
 * Полностью удаляет сохраненные данные о предыдущих позициях команд
 * После вызова этой функции все индикаторы изменения позиций будут показывать "0"
 */
export function clearRankingsHistory() {
  localStorage.removeItem('teamRankingsData');
  console.log('%c История рейтингов успешно очищена ', 'background: #f44336; color: white; padding: 3px; border-radius: 3px;');
  
  // Вызываем обновление страницы, чтобы изменения вступили в силу немедленно
  window.location.reload();
}

/**
 * Функция логирования изменений в рейтинге команд с красивым форматированием
 */
export function logRankingChange(teamName: string, previousRank: number, currentRank: number) {
  const diff = previousRank - currentRank;
  
  if (diff > 0) {
    console.log(
      `%c↑ ${teamName} %c поднялась с ${previousRank} на ${currentRank} место (+${diff}) `, 
      'color: #4caf50; font-weight: bold;', 
      'color: #4caf50;'
    );
  } else if (diff < 0) {
    console.log(
      `%c↓ ${teamName} %c опустилась с ${previousRank} на ${currentRank} место (${diff}) `, 
      'color: #f44336; font-weight: bold;', 
      'color: #f44336;'
    );
  } else {
    console.log(
      `%c• ${teamName} %c позиция не изменилась (${currentRank} место) `, 
      'color: #9e9e9e; font-weight: bold;', 
      'color: #9e9e9e;'
    );
  }
}
