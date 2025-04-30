import { useState } from "react";
import { useQuery, useMutation } from "@tanstack/react-query";
import { Team } from "@shared/schema";
import { useAuth } from "@/hooks/use-auth";
import { apiRequest, queryClient } from "@/lib/queryClient";
import { Button } from "@/components/ui/button";
import { PlusCircle, Trophy } from "lucide-react";
import TeamForm from "@/components/team-form";
import AdminTeamTable from "@/components/admin-team-table";
import { useToast } from "@/hooks/use-toast";
import { Skeleton } from "@/components/ui/skeleton";

export default function AdminPage() {
  const { user, logoutMutation } = useAuth();
  const { toast } = useToast();
  const [isFormOpen, setIsFormOpen] = useState(false);
  const [editingTeam, setEditingTeam] = useState<Team | null>(null);

  const { data: teams, isLoading } = useQuery<Team[]>({
    queryKey: ["/api/teams"],
  });

  const deleteTeamMutation = useMutation({
    mutationFn: async (teamId: number) => {
      await apiRequest("DELETE", `/api/teams/${teamId}`);
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["/api/teams"] });
      toast({
        title: "Team deleted",
        description: "The team has been deleted successfully.",
      });
    },
    onError: (error) => {
      toast({
        title: "Failed to delete team",
        description: error.message,
        variant: "destructive",
      });
    },
  });

  const handleEditTeam = (team: Team) => {
    setEditingTeam(team);
    setIsFormOpen(true);
  };

  const handleDeleteTeam = (teamId: number) => {
    if (window.confirm("Are you sure you want to delete this team?")) {
      deleteTeamMutation.mutate(teamId);
    }
  };

  const handleLogout = () => {
    logoutMutation.mutate();
  };

  return (
    <div className="min-h-screen bg-gray-100">
      {/* Admin Header */}
      <div className="bg-primary text-white p-4 shadow-md">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 flex justify-between items-center">
          <div className="flex items-center">
            <Trophy className="h-6 w-6 mr-2" />
            <h1 className="font-heading font-bold text-xl">Admin Dashboard</h1>
          </div>
          <div className="flex items-center space-x-4">
            <span className="text-sm hidden md:inline-block">
              Welcome, {user?.username}
            </span>
            <Button
              variant="outline"
              className="bg-white text-primary hover:bg-gray-100"
              onClick={handleLogout}
              disabled={logoutMutation.isPending}
            >
              Logout
            </Button>
          </div>
        </div>
      </div>

      {/* Main Content */}
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <div className="bg-white rounded-lg shadow-md overflow-hidden">
          <div className="p-6">
            <div className="flex justify-between items-center mb-6">
              <h2 className="font-heading font-bold text-xl text-dark">Team Management</h2>
              <Button
                onClick={() => {
                  setEditingTeam(null);
                  setIsFormOpen(true);
                }}
                className="bg-green-500 hover:bg-green-600"
              >
                <PlusCircle className="mr-2 h-4 w-4" /> Add New Team
              </Button>
            </div>

            {isLoading ? (
              <Skeleton className="h-64 w-full" />
            ) : (
              <AdminTeamTable
                teams={teams || []}
                onEdit={handleEditTeam}
                onDelete={handleDeleteTeam}
              />
            )}
          </div>
        </div>
      </div>

      {/* Team Form Modal */}
      {isFormOpen && (
        <TeamForm
          team={editingTeam}
          onClose={() => {
            setIsFormOpen(false);
            setEditingTeam(null);
          }}
        />
      )}
    </div>
  );
}
