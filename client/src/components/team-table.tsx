import { Team } from "@shared/schema";

export default function TeamTable({ teams }: { teams: Team[] }) {
  return (
    <div className="bg-white rounded-xl shadow-md overflow-hidden">
      <div className="overflow-x-auto">
        <table className="min-w-full divide-y divide-gray-200">
          <thead className="bg-gray-100">
            <tr>
              <th scope="col" className="px-6 py-4 text-left text-xs font-medium text-gray-500 uppercase tracking-wider w-16">
                Rank
              </th>
              <th scope="col" className="px-6 py-4 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Team
              </th>
              <th scope="col" className="px-6 py-4 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">
                Score
              </th>
            </tr>
          </thead>
          <tbody className="bg-white divide-y divide-gray-200">
            {teams.length > 0 ? (
              teams.map((team, index) => (
                <tr key={team.id} className="hover:bg-gray-50">
                  <td className="px-6 py-4 whitespace-nowrap">
                    <div className="flex items-center">
                      <div 
                        className={`flex-shrink-0 h-8 w-8 rounded-full 
                          ${index < 3 
                            ? 'bg-primary text-white' 
                            : 'bg-gray-300 text-gray-700'
                          } 
                          flex items-center justify-center font-bold`}
                      >
                        {index + 1}
                      </div>
                    </div>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <div className="flex items-center">
                      <div className="flex-shrink-0 h-10 w-10 bg-gray-100 rounded-full flex items-center justify-center overflow-hidden">
                        {team.logoUrl ? (
                          <img 
                            src={team.logoUrl} 
                            alt={`${team.name} logo`} 
                            className="h-full w-full object-cover rounded-full" 
                          />
                        ) : (
                          <div className="text-gray-300 text-lg font-semibold">
                            {team.name.substring(0, 2).toUpperCase()}
                          </div>
                        )}
                      </div>
                      <div className="ml-4">
                        <div className="text-sm font-medium text-gray-900">
                          {team.name}
                        </div>
                      </div>
                    </div>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-right text-sm">
                    <span className="font-bold text-dark px-4 py-1 rounded-full bg-blue-50">
                      {team.score}
                    </span>
                  </td>
                </tr>
              ))
            ) : (
              <tr>
                <td colSpan={3} className="px-6 py-10 text-center text-gray-500">
                  No teams available. Add teams to see them here.
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}
