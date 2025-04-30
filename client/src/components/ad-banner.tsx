import { ExternalLink } from "lucide-react";

export default function AdBanner() {
  return (
    <div className="bg-gradient-to-r from-blue-600 to-indigo-700 rounded-xl shadow-md overflow-hidden">
      <div className="px-6 py-8 sm:p-10 sm:flex sm:items-center">
        <div className="sm:flex-1">
          <h3 className="text-xl font-extrabold text-white sm:text-2xl">
            Турнир ATOM﮳GAME 2025
          </h3>
          <p className="mt-2 text-white text-sm sm:text-base leading-relaxed">
            Не пропустите грандиозный турнир по киберспорту среди молодежи атомных городов России!
            Соревнования в дисциплинах Dota 2, CS2, и FIFA с участием команд из разных регионов.
          </p>
          <div className="mt-4">
            <a
              href="#" 
              className="inline-flex items-center px-4 py-2 border border-white text-sm font-medium rounded-md text-white hover:bg-white hover:bg-opacity-10 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-offset-blue-600 focus:ring-white transition"
            >
              Подробнее <ExternalLink className="ml-2 h-4 w-4" />
            </a>
          </div>
        </div>
        <div className="mt-6 sm:mt-0 sm:ml-10 sm:flex-shrink-0">
          <img 
            src="https://via.placeholder.com/120x120?text=ATOM" 
            alt="ATOM﮳GAME Logo" 
            className="h-24 w-24 object-cover object-center rounded-md border-2 border-white"
          />
        </div>
      </div>
    </div>
  );
}