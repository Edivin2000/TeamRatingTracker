import { useState, useEffect } from "react";
import { useLocation } from "wouter";
import { 
  Card, 
  CardContent, 
  CardDescription, 
  CardHeader, 
  CardTitle 
} from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { useAuth } from "@/hooks/use-auth";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { z } from "zod";
import { Loader2, Trophy } from "lucide-react";
import { loginSchema } from "@shared/schema";

export default function AuthPage() {
  const [location, navigate] = useLocation();
  const { user, loginMutation, registerMutation } = useAuth();
  const [tab, setTab] = useState<string>("login");
  
  // Create separate schemas
  const loginFormSchema = loginSchema;
  const registerFormSchema = loginSchema.extend({
    confirmPassword: z.string().min(1, "Please confirm your password"),
  }).refine((data) => data.password === data.confirmPassword, {
    message: "Passwords don't match",
    path: ["confirmPassword"],
  });

  type LoginFormData = z.infer<typeof loginFormSchema>;
  type RegisterFormData = z.infer<typeof registerFormSchema>;
  
  // Setup login form
  const loginForm = useForm<LoginFormData>({
    resolver: zodResolver(loginFormSchema),
    defaultValues: {
      username: "",
      password: "",
    },
  });

  // Setup register form  
  const registerForm = useForm<RegisterFormData>({
    resolver: zodResolver(registerFormSchema),
    defaultValues: {
      username: "",
      password: "",
      confirmPassword: "",
    },
  });

  // Handle login form submission
  const onLoginSubmit = (data: LoginFormData) => {
    loginMutation.mutate(data);
  };

  // Handle register form submission
  const onRegisterSubmit = (data: RegisterFormData) => {
    const { confirmPassword, ...userData } = data;
    registerMutation.mutate({
      ...userData,
      isAdmin: 1, // Set as admin
    });
  };

  // Redirect if already logged in
  useEffect(() => {
    if (user) {
      navigate(user.isAdmin ? "/admin" : "/");
    }
  }, [user, navigate]);

  return (
    <div className="min-h-screen flex flex-col md:flex-row">
      {/* Left side: Auth form */}
      <div className="w-full md:w-1/2 p-8 flex items-center justify-center bg-white">
        <div className="w-full max-w-md">
          <div className="text-center mb-8">
            <h1 className="text-3xl font-bold mb-2">Team Rankings</h1>
            <p className="text-gray-500">Admin authentication required</p>
          </div>
          
          <Tabs value={tab} onValueChange={setTab} defaultValue="login" className="w-full">
            <TabsList className="grid w-full grid-cols-2 mb-8">
              <TabsTrigger value="login">Login</TabsTrigger>
              <TabsTrigger value="register">Register</TabsTrigger>
            </TabsList>
            
            <TabsContent value="login">
              <Card>
                <CardHeader>
                  <CardTitle>Login</CardTitle>
                  <CardDescription>
                    Enter your credentials to access the admin dashboard.
                  </CardDescription>
                </CardHeader>
                <CardContent>
                  <form onSubmit={loginForm.handleSubmit(onLoginSubmit)} className="space-y-4">
                    <div className="space-y-2">
                      <Label htmlFor="loginUsername">Username</Label>
                      <Input 
                        id="loginUsername" 
                        {...loginForm.register("username")} 
                        placeholder="Enter your username"
                      />
                      {loginForm.formState.errors.username && (
                        <p className="text-sm text-red-500">{loginForm.formState.errors.username.message}</p>
                      )}
                    </div>
                    
                    <div className="space-y-2">
                      <Label htmlFor="loginPassword">Password</Label>
                      <Input 
                        id="loginPassword" 
                        type="password" 
                        {...loginForm.register("password")} 
                        placeholder="Enter your password"
                      />
                      {loginForm.formState.errors.password && (
                        <p className="text-sm text-red-500">{loginForm.formState.errors.password.message}</p>
                      )}
                    </div>
                    
                    <Button type="submit" className="w-full" disabled={loginMutation.isPending}>
                      {loginMutation.isPending ? (
                        <Loader2 className="h-4 w-4 mr-2 animate-spin" />
                      ) : null}
                      Login
                    </Button>
                  </form>
                </CardContent>
              </Card>
            </TabsContent>
            
            <TabsContent value="register">
              <Card>
                <CardHeader>
                  <CardTitle>Create an Account</CardTitle>
                  <CardDescription>
                    Register a new admin account to manage teams.
                  </CardDescription>
                </CardHeader>
                <CardContent>
                  <form onSubmit={registerForm.handleSubmit(onRegisterSubmit)} className="space-y-4">
                    <div className="space-y-2">
                      <Label htmlFor="registerUsername">Username</Label>
                      <Input 
                        id="registerUsername" 
                        {...registerForm.register("username")} 
                        placeholder="Choose a username"
                      />
                      {registerForm.formState.errors.username && (
                        <p className="text-sm text-red-500">{registerForm.formState.errors.username.message}</p>
                      )}
                    </div>
                    
                    <div className="space-y-2">
                      <Label htmlFor="registerPassword">Password</Label>
                      <Input 
                        id="registerPassword" 
                        type="password" 
                        {...registerForm.register("password")} 
                        placeholder="Choose a password"
                      />
                      {registerForm.formState.errors.password && (
                        <p className="text-sm text-red-500">{registerForm.formState.errors.password.message}</p>
                      )}
                    </div>
                    
                    <div className="space-y-2">
                      <Label htmlFor="confirmPassword">Confirm Password</Label>
                      <Input 
                        id="confirmPassword" 
                        type="password" 
                        {...registerForm.register("confirmPassword")} 
                        placeholder="Confirm your password"
                      />
                      {registerForm.formState.errors.confirmPassword && (
                        <p className="text-sm text-red-500">{registerForm.formState.errors.confirmPassword.message}</p>
                      )}
                    </div>
                    
                    <Button type="submit" className="w-full" disabled={registerMutation.isPending}>
                      {registerMutation.isPending ? (
                        <Loader2 className="h-4 w-4 mr-2 animate-spin" />
                      ) : null}
                      Register
                    </Button>
                  </form>
                </CardContent>
              </Card>
            </TabsContent>
          </Tabs>
        </div>
      </div>
      
      {/* Right side: Hero banner */}
      <div className="w-full md:w-1/2 bg-gradient-to-br from-primary to-blue-700 p-8 text-white flex items-center">
        <div className="max-w-lg mx-auto space-y-8">
          <div className="text-center">
            <Trophy className="h-16 w-16 mx-auto mb-4" />
            <h2 className="text-4xl font-bold mb-4">Team Rankings System</h2>
            <p className="text-xl opacity-90">
              Manage team scores and keep track of rankings with this powerful admin dashboard.
            </p>
          </div>
          
          <div className="bg-white/10 backdrop-blur-sm rounded-lg p-6 space-y-4">
            <h3 className="text-xl font-semibold">Key Features:</h3>
            <ul className="space-y-2">
              <li className="flex items-center space-x-2">
                <span className="h-5 w-5 bg-white/20 rounded-full flex items-center justify-center text-sm">✓</span>
                <span>Add and manage teams</span>
              </li>
              <li className="flex items-center space-x-2">
                <span className="h-5 w-5 bg-white/20 rounded-full flex items-center justify-center text-sm">✓</span>
                <span>Update team scores</span>
              </li>
              <li className="flex items-center space-x-2">
                <span className="h-5 w-5 bg-white/20 rounded-full flex items-center justify-center text-sm">✓</span>
                <span>Upload team logos</span>
              </li>
              <li className="flex items-center space-x-2">
                <span className="h-5 w-5 bg-white/20 rounded-full flex items-center justify-center text-sm">✓</span>
                <span>View beautiful leaderboard with top teams highlighted</span>
              </li>
            </ul>
          </div>
        </div>
      </div>
    </div>
  );
}
