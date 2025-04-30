import { useState } from "react";
import { useQuery } from "@tanstack/react-query";
import { Team } from "@shared/schema";
import Navbar from "@/components/layout/navbar";
import Footer from "@/components/layout/footer";
import TeamPodium from "@/components/team-podium";
import TeamTable from "@/components/team-table";
import { Skeleton } from "@/components/ui/skeleton";

export default function HomePage() {
  const { data: teams, isLoading } = useQuery<Team[]>({
    queryKey: ["/api/teams"],
  });

  const sortedTeams = teams?.sort((a, b) => b.score - a.score) || [];
  const topThreeTeams = sortedTeams.slice(0, 3);

  return (
    <div className="flex flex-col min-h-screen">
      <Navbar />
      
      <main className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8 flex-grow">
        {/* Page Title */}
        <div className="text-center mb-10">
          <h2 className="font-heading font-bold text-3xl sm:text-4xl text-dark mb-2">Team Leaderboard</h2>
          <p className="text-gray-600 max-w-2xl mx-auto">Current rankings of all teams based on their accumulated scores</p>
        </div>

        {/* Podium Section */}
        <div className="mb-12">
          <h3 className="font-heading font-semibold text-xl text-dark mb-6">Top Teams</h3>
          
          {isLoading ? (
            <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
              {[...Array(3)].map((_, i) => (
                <div key={i} className="flex flex-col items-center space-y-4">
                  <Skeleton className="h-40 w-full rounded-lg" />
                </div>
              ))}
            </div>
          ) : (
            <TeamPodium teams={topThreeTeams} />
          )}
        </div>

        {/* Rankings Table */}
        <div>
          <h3 className="font-heading font-semibold text-xl text-dark mb-6">Complete Rankings</h3>
          
          {isLoading ? (
            <Skeleton className="h-64 w-full rounded-xl" />
          ) : (
            <TeamTable teams={sortedTeams} />
          )}
        </div>
      </main>
      
      <Footer />
    </div>
  );
}
