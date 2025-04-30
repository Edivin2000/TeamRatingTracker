import { useState } from "react";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { z } from "zod";
import { useMutation } from "@tanstack/react-query";
import { Team, insertTeamSchema } from "@shared/schema";
import { apiRequest, queryClient } from "@/lib/queryClient";
import { useToast } from "@/hooks/use-toast";
import { X, Upload, Loader2 } from "lucide-react";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";

interface TeamFormProps {
  team: Team | null;
  onClose: () => void;
}

export default function TeamForm({ team, onClose }: TeamFormProps) {
  const { toast } = useToast();
  const [logoPreview, setLogoPreview] = useState<string | null>(team?.logoUrl || null);
  
  const formSchema = insertTeamSchema.extend({
    logoFile: z.instanceof(FileList).optional().transform(val => val && val.length > 0 ? val[0] : undefined),
  });

  type FormData = z.infer<typeof formSchema>;

  const {
    register,
    handleSubmit,
    formState: { errors },
  } = useForm<FormData>({
    resolver: zodResolver(formSchema),
    defaultValues: {
      name: team?.name || "",
      score: team?.score || 0,
      logoUrl: team?.logoUrl || "",
    },
  });

  const createTeamMutation = useMutation({
    mutationFn: async (data: FormData) => {
      // Handle logo file upload if present
      let logoUrl = team?.logoUrl || "";
      
      if (data.logoFile) {
        // Convert to base64 for in-memory storage
        const reader = new FileReader();
        
        // Create a promise to wait for FileReader
        const base64Promise = new Promise<string>((resolve) => {
          reader.onloadend = () => {
            resolve(reader.result as string);
          };
        });
        
        reader.readAsDataURL(data.logoFile);
        logoUrl = await base64Promise;
      }
      
      const teamData = {
        name: data.name,
        score: data.score,
        logoUrl,
      };
      
      if (team) {
        // Update existing team
        const res = await apiRequest("PUT", `/api/teams/${team.id}`, teamData);
        return res.json();
      } else {
        // Create new team
        const res = await apiRequest("POST", "/api/teams", teamData);
        return res.json();
      }
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["/api/teams"] });
      toast({
        title: team ? "Team updated" : "Team created",
        description: team
          ? "The team has been updated successfully."
          : "The team has been created successfully.",
      });
      onClose();
    },
    onError: (error) => {
      toast({
        title: team ? "Failed to update team" : "Failed to create team",
        description: error.message,
        variant: "destructive",
      });
    },
  });

  const onSubmit = (data: FormData) => {
    createTeamMutation.mutate(data);
  };

  const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (file) {
      const reader = new FileReader();
      reader.onloadend = () => {
        setLogoPreview(reader.result as string);
      };
      reader.readAsDataURL(file);
    }
  };

  return (
    <Dialog open={true} onOpenChange={onClose}>
      <DialogContent className="sm:max-w-md">
        <DialogHeader>
          <DialogTitle>{team ? "Edit Team" : "Add New Team"}</DialogTitle>
        </DialogHeader>
        
        <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
          <input type="hidden" {...register("logoUrl")} />
          
          <div className="space-y-2">
            <Label htmlFor="name">Team Name</Label>
            <Input 
              id="name" 
              type="text" 
              {...register("name")} 
              placeholder="Enter team name" 
            />
            {errors.name && (
              <p className="text-sm text-red-500">{errors.name.message}</p>
            )}
          </div>
          
          <div className="space-y-2">
            <Label htmlFor="score">Team Score</Label>
            <Input 
              id="score" 
              type="number" 
              {...register("score", { valueAsNumber: true })} 
              placeholder="Enter team score" 
            />
            {errors.score && (
              <p className="text-sm text-red-500">{errors.score.message}</p>
            )}
          </div>
          
          <div className="space-y-2">
            <Label>Team Logo</Label>
            <div className="flex items-center space-x-4">
              <div className="w-16 h-16 bg-gray-100 rounded-full flex items-center justify-center overflow-hidden">
                {logoPreview ? (
                  <img 
                    src={logoPreview} 
                    alt="Logo preview" 
                    className="w-full h-full object-cover" 
                  />
                ) : (
                  <div className="text-gray-300 text-xl">
                    {team?.name.substring(0, 2).toUpperCase() || ""}
                  </div>
                )}
              </div>
              <div>
                <Label 
                  htmlFor="logoFile" 
                  className="cursor-pointer inline-flex items-center px-4 py-2 bg-gray-200 hover:bg-gray-300 rounded-md text-sm font-medium transition"
                >
                  <Upload className="w-4 h-4 mr-2" />
                  Upload Logo
                </Label>
                <input
                  type="file"
                  id="logoFile"
                  className="hidden"
                  accept="image/*"
                  {...register("logoFile")}
                  onChange={handleFileChange}
                />
              </div>
            </div>
          </div>
          
          <div className="flex justify-end space-x-2 pt-4">
            <Button
              type="button"
              variant="outline"
              onClick={onClose}
            >
              Cancel
            </Button>
            <Button 
              type="submit"
              disabled={createTeamMutation.isPending}
            >
              {createTeamMutation.isPending && (
                <Loader2 className="w-4 h-4 mr-2 animate-spin" />
              )}
              {team ? "Update" : "Create"} Team
            </Button>
          </div>
        </form>
      </DialogContent>
    </Dialog>
  );
}
