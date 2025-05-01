import { useState } from "react";
import { useQuery, useMutation } from "@tanstack/react-query";
import { Team, Partner, Ad, Timer, SiteSettings } from "@shared/schema";
import { useAuth } from "@/hooks/use-auth";
import { apiRequest, queryClient } from "@/lib/queryClient";
import { clearRankingsHistory } from "@/lib/utils";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { 
  PlusCircle, 
  Trophy, 
  Users, 
  Image, 
  Edit,
  Trash2,
  BarChart, 
  BriefcaseBusiness,
  Clock,
  Palette
} from "lucide-react";
import TeamForm from "@/components/team-form";
import TeamScoreForm from "@/components/team-score-form";
import PartnerForm from "@/components/partner-form";
import AdBannerForm from "@/components/ad-banner-form";
import TimerForm from "@/components/timer-form";
import SiteSettingsForm from "@/components/site-settings-form";
import AdminTeamTable from "@/components/admin-team-table";
import AdminTimerTable from "@/components/admin-timer-table";
import { useToast } from "@/hooks/use-toast";
import { Skeleton } from "@/components/ui/skeleton";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";

export default function AdminPage() {
  const { user, logoutMutation } = useAuth();
  const { toast } = useToast();
  
  // Состояния для форм
  const [isTeamFormOpen, setIsTeamFormOpen] = useState(false);
  const [isScoreFormOpen, setIsScoreFormOpen] = useState(false);
  const [isPartnerFormOpen, setIsPartnerFormOpen] = useState(false);
  const [isAdFormOpen, setIsAdFormOpen] = useState(false);
  const [isTimerFormOpen, setIsTimerFormOpen] = useState(false);
  const [isSiteSettingsFormOpen, setIsSiteSettingsFormOpen] = useState(false);
  
  // Состояния для редактирования
  const [editingTeam, setEditingTeam] = useState<Team | null>(null);
  const [editingScoreTeam, setEditingScoreTeam] = useState<Team | null>(null);
  const [editingPartner, setEditingPartner] = useState<Partner | null>(null);
  const [editingAd, setEditingAd] = useState<Ad | null>(null);
  const [editingTimer, setEditingTimer] = useState<Timer | null>(null);

  // Запросы данных
  const { data: teams, isLoading: isTeamsLoading } = useQuery<Team[]>({
    queryKey: ["/api/teams"],
  });

  const { data: partners, isLoading: isPartnersLoading } = useQuery<Partner[]>({
    queryKey: ["/api/partners"],
  });

  const { data: ads, isLoading: isAdsLoading } = useQuery<Ad[]>({
    queryKey: ["/api/ads"],
  });
  
  const { data: timers, isLoading: isTimersLoading } = useQuery<Timer[]>({
    queryKey: ["/api/admin/timers"],
  });
  
  const { data: siteSettings, isLoading: isSettingsLoading } = useQuery<SiteSettings>({
    queryKey: ["/api/site-settings"],
  });

  // Мутации для удаления
  const deleteTeamMutation = useMutation({
    mutationFn: async (teamId: number) => {
      await apiRequest("DELETE", `/api/teams/${teamId}`);
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["/api/teams"] });
      toast({
        title: "Команда удалена",
        description: "Команда была успешно удалена.",
      });
    },
    onError: (error) => {
      toast({
        title: "Не удалось удалить команду",
        description: error.message,
        variant: "destructive",
      });
    },
  });

  const deletePartnerMutation = useMutation({
    mutationFn: async (partnerId: number) => {
      await apiRequest("DELETE", `/api/partners/${partnerId}`);
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["/api/partners"] });
      toast({
        title: "Партнер удален",
        description: "Партнер был успешно удален.",
      });
    },
    onError: (error) => {
      toast({
        title: "Не удалось удалить партнера",
        description: error.message,
        variant: "destructive",
      });
    },
  });

  const deleteAdMutation = useMutation({
    mutationFn: async (adId: number) => {
      await apiRequest("DELETE", `/api/ads/${adId}`);
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["/api/ads"] });
      toast({
        title: "Баннер удален",
        description: "Рекламный баннер был успешно удален.",
      });
    },
    onError: (error) => {
      toast({
        title: "Не удалось удалить баннер",
        description: error.message,
        variant: "destructive",
      });
    },
  });
  
  const deleteTimerMutation = useMutation({
    mutationFn: async (timerId: number) => {
      await apiRequest("DELETE", `/api/timers/${timerId}`);
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["/api/admin/timers"] });
      queryClient.invalidateQueries({ queryKey: ["/api/timers"] });
      toast({
        title: "Таймер удален",
        description: "Таймер был успешно удален.",
      });
    },
    onError: (error) => {
      toast({
        title: "Не удалось удалить таймер",
        description: error.message,
        variant: "destructive",
      });
    },
  });

  // Обработчики
  const handleEditTeam = (team: Team) => {
    setEditingTeam(team);
    setIsTeamFormOpen(true);
  };

  const handleEditTeamScore = (team: Team) => {
    setEditingScoreTeam(team);
    setIsScoreFormOpen(true);
  };

  const handleEditPartner = (partner: Partner) => {
    setEditingPartner(partner);
    setIsPartnerFormOpen(true);
  };

  const handleEditAd = (ad: Ad) => {
    setEditingAd(ad);
    setIsAdFormOpen(true);
  };
  
  const handleEditTimer = (timer: Timer) => {
    setEditingTimer(timer);
    setIsTimerFormOpen(true);
  };

  const handleDeleteTeam = (teamId: number) => {
    if (window.confirm("Вы уверены, что хотите удалить эту команду?")) {
      deleteTeamMutation.mutate(teamId);
    }
  };

  const handleDeletePartner = (partnerId: number) => {
    if (window.confirm("Вы уверены, что хотите удалить этого партнера?")) {
      deletePartnerMutation.mutate(partnerId);
    }
  };

  const handleDeleteAd = (adId: number) => {
    if (window.confirm("Вы уверены, что хотите удалить этот рекламный баннер?")) {
      deleteAdMutation.mutate(adId);
    }
  };
  
  const handleDeleteTimer = (timerId: number) => {
    if (window.confirm("Вы уверены, что хотите удалить этот таймер?")) {
      deleteTimerMutation.mutate(timerId);
    }
  };

  const handleLogout = () => {
    logoutMutation.mutate();
  };

  return (
    <div className="min-h-screen bg-gray-100">
      {/* Заголовок админа */}
      <div className="bg-primary text-white p-4 shadow-md">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 flex justify-between items-center">
          <div className="flex items-center">
            <Trophy className="h-6 w-6 mr-2" />
            <h1 className="font-heading font-bold text-xl">Панель Администратора</h1>
          </div>
          <div className="flex items-center space-x-4">
            <span className="text-sm hidden md:inline-block">
              Добро пожаловать, {user?.username}
            </span>
            <Button
              variant="outline"
              className="bg-white text-primary hover:bg-gray-100"
              onClick={handleLogout}
              disabled={logoutMutation.isPending}
            >
              Выйти
            </Button>
          </div>
        </div>
      </div>

      {/* Основное содержимое */}
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <Tabs defaultValue="teams" className="w-full">
          <TabsList className="mb-6 grid grid-cols-5 h-auto">
            <TabsTrigger value="teams" className="py-3 data-[state=active]:bg-primary data-[state=active]:text-white">
              <Users className="w-4 h-4 mr-2" /> Команды
            </TabsTrigger>
            <TabsTrigger value="partners" className="py-3 data-[state=active]:bg-primary data-[state=active]:text-white">
              <BriefcaseBusiness className="w-4 h-4 mr-2" /> Партнеры
            </TabsTrigger>
            <TabsTrigger value="ads" className="py-3 data-[state=active]:bg-primary data-[state=active]:text-white">
              <Image className="w-4 h-4 mr-2" /> Рекламные баннеры
            </TabsTrigger>
            <TabsTrigger value="timers" className="py-3 data-[state=active]:bg-primary data-[state=active]:text-white">
              <Clock className="w-4 h-4 mr-2" /> Таймеры
            </TabsTrigger>
            <TabsTrigger value="settings" className="py-3 data-[state=active]:bg-primary data-[state=active]:text-white">
              <Palette className="w-4 h-4 mr-2" /> Дизайн сайта
            </TabsTrigger>
          </TabsList>
          
          {/* Вкладка Команды */}
          <TabsContent value="teams">
            <Card>
              <CardHeader>
                <div className="flex justify-between items-center">
                  <div>
                    <CardTitle>Управление Командами</CardTitle>
                    <CardDescription>
                      Создавайте, редактируйте и управляйте командами и их очками
                    </CardDescription>
                  </div>
                  <Button
                    onClick={() => {
                      setEditingTeam(null);
                      setIsTeamFormOpen(true);
                    }}
                    className="bg-green-500 hover:bg-green-600"
                  >
                    <PlusCircle className="mr-2 h-4 w-4" /> Добавить команду
                  </Button>
                </div>
              </CardHeader>
              <CardContent>
                {isTeamsLoading ? (
                  <Skeleton className="h-64 w-full" />
                ) : (
                  <AdminTeamTable
                    teams={teams || []}
                    onEdit={handleEditTeam}
                    onDelete={handleDeleteTeam}
                    onScoreEdit={handleEditTeamScore}
                  />
                )}
              </CardContent>
            </Card>
          </TabsContent>
          
          {/* Вкладка Партнеры */}
          <TabsContent value="partners">
            <Card>
              <CardHeader>
                <div className="flex justify-between items-center">
                  <div>
                    <CardTitle>Управление Партнерами</CardTitle>
                    <CardDescription>
                      Добавляйте и управляйте логотипами и ссылками партнеров
                    </CardDescription>
                  </div>
                  <Button
                    onClick={() => {
                      setEditingPartner(null);
                      setIsPartnerFormOpen(true);
                    }}
                    className="bg-green-500 hover:bg-green-600"
                  >
                    <PlusCircle className="mr-2 h-4 w-4" /> Добавить партнера
                  </Button>
                </div>
              </CardHeader>
              <CardContent>
                {isPartnersLoading ? (
                  <Skeleton className="h-64 w-full" />
                ) : (
                  <div className="overflow-x-auto">
                    <table className="min-w-full divide-y divide-gray-200">
                      <thead className="bg-gray-100">
                        <tr>
                          <th scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                            Партнер
                          </th>
                          <th scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                            Порядок
                          </th>
                          <th scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                            Сайт
                          </th>
                          <th scope="col" className="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">
                            Действия
                          </th>
                        </tr>
                      </thead>
                      <tbody className="bg-white divide-y divide-gray-200">
                        {partners && partners.length > 0 ? (
                          [...partners]
                            .sort((a, b) => (a.order || 0) - (b.order || 0))
                            .map((partner) => (
                              <tr key={partner.id} className="hover:bg-gray-50">
                                <td className="px-6 py-4 whitespace-nowrap">
                                  <div className="flex items-center">
                                    <div className="flex-shrink-0 h-10 w-10 bg-gray-100 rounded flex items-center justify-center overflow-hidden">
                                      {partner.logoUrl ? (
                                        <img 
                                          src={partner.logoUrl} 
                                          alt={`${partner.name} logo`} 
                                          className="h-full w-full object-contain" 
                                        />
                                      ) : (
                                        <div className="text-gray-300 text-lg font-semibold">
                                          {partner.name.substring(0, 2).toUpperCase()}
                                        </div>
                                      )}
                                    </div>
                                    <div className="ml-4">
                                      <div className="text-sm font-medium text-gray-900">
                                        {partner.name}
                                      </div>
                                    </div>
                                  </div>
                                </td>
                                <td className="px-6 py-4 whitespace-nowrap">
                                  <span className="font-medium text-dark">
                                    {partner.order || 0}
                                  </span>
                                </td>
                                <td className="px-6 py-4 whitespace-nowrap">
                                  {partner.website ? (
                                    <a 
                                      href={partner.website} 
                                      target="_blank" 
                                      rel="noopener noreferrer"
                                      className="text-blue-600 hover:text-blue-800 hover:underline"
                                    >
                                      {partner.website.replace(/^https?:\/\//, '')}
                                    </a>
                                  ) : (
                                    <span className="text-gray-400">Не указан</span>
                                  )}
                                </td>
                                <td className="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                                  <Button 
                                    variant="ghost" 
                                    size="sm" 
                                    className="text-indigo-600 hover:text-indigo-900 mr-2"
                                    onClick={() => handleEditPartner(partner)}
                                  >
                                    <Edit className="w-4 h-4 mr-1" /> Изменить
                                  </Button>
                                  <Button 
                                    variant="ghost" 
                                    size="sm" 
                                    className="text-red-600 hover:text-red-900"
                                    onClick={() => handleDeletePartner(partner.id)}
                                  >
                                    <Trash2 className="w-4 h-4 mr-1" /> Удалить
                                  </Button>
                                </td>
                              </tr>
                            ))
                        ) : (
                          <tr>
                            <td colSpan={4} className="px-6 py-10 text-center text-gray-500">
                              Нет доступных партнеров. Добавьте партнера, чтобы начать.
                            </td>
                          </tr>
                        )}
                      </tbody>
                    </table>
                  </div>
                )}
              </CardContent>
            </Card>
          </TabsContent>
          
          {/* Вкладка Рекламные баннеры */}
          <TabsContent value="ads">
            <Card>
              <CardHeader>
                <div className="flex justify-between items-center">
                  <div>
                    <CardTitle>Управление Рекламными Баннерами</CardTitle>
                    <CardDescription>
                      Создавайте и редактируйте рекламные баннеры для главной страницы
                    </CardDescription>
                  </div>
                  <Button
                    onClick={() => {
                      setEditingAd(null);
                      setIsAdFormOpen(true);
                    }}
                    className="bg-green-500 hover:bg-green-600"
                  >
                    <PlusCircle className="mr-2 h-4 w-4" /> Добавить баннер
                  </Button>
                </div>
              </CardHeader>
              <CardContent>
                {isAdsLoading ? (
                  <Skeleton className="h-64 w-full" />
                ) : (
                  <div className="overflow-x-auto">
                    <table className="min-w-full divide-y divide-gray-200">
                      <thead className="bg-gray-100">
                        <tr>
                          <th scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                            Баннер
                          </th>
                          <th scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                            Порядок
                          </th>
                          <th scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                            Статус
                          </th>
                          <th scope="col" className="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">
                            Действия
                          </th>
                        </tr>
                      </thead>
                      <tbody className="bg-white divide-y divide-gray-200">
                        {ads && ads.length > 0 ? (
                          [...ads]
                            .sort((a, b) => (a.order || 0) - (b.order || 0))
                            .map((ad) => (
                              <tr key={ad.id} className={`hover:bg-gray-50 ${!ad.active ? 'bg-gray-50 opacity-70' : ''}`}>
                                <td className="px-6 py-4 whitespace-nowrap">
                                  <div className="flex items-center">
                                    <div className="flex-shrink-0 h-10 w-24 bg-gradient-to-r from-blue-600 to-indigo-700 rounded flex items-center justify-center overflow-hidden">
                                      {ad.logoUrl ? (
                                        <img 
                                          src={ad.logoUrl} 
                                          alt="Логотип" 
                                          className="h-8 w-auto object-contain" 
                                        />
                                      ) : (
                                        <div className="text-white text-xs font-semibold px-2 text-center">
                                          {ad.title.substring(0, 10)}...
                                        </div>
                                      )}
                                    </div>
                                    <div className="ml-4">
                                      <div className="text-sm font-medium text-gray-900">
                                        {ad.title}
                                      </div>
                                      <div className="text-xs text-gray-500 mt-1">
                                        {ad.description.length > 50 
                                          ? `${ad.description.substring(0, 50)}...` 
                                          : ad.description}
                                      </div>
                                    </div>
                                  </div>
                                </td>
                                <td className="px-6 py-4 whitespace-nowrap">
                                  <span className="font-medium text-dark">
                                    {ad.order || 0}
                                  </span>
                                </td>
                                <td className="px-6 py-4 whitespace-nowrap">
                                  {ad.active ? (
                                    <Badge className="bg-green-100 text-green-800 border-green-200">
                                      Активен
                                    </Badge>
                                  ) : (
                                    <Badge variant="outline" className="text-gray-500 border-gray-300">
                                      Неактивен
                                    </Badge>
                                  )}
                                </td>
                                <td className="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                                  <Button 
                                    variant="ghost" 
                                    size="sm" 
                                    className="text-indigo-600 hover:text-indigo-900 mr-2"
                                    onClick={() => handleEditAd(ad)}
                                  >
                                    <Edit className="w-4 h-4 mr-1" /> Изменить
                                  </Button>
                                  <Button 
                                    variant="ghost" 
                                    size="sm" 
                                    className="text-red-600 hover:text-red-900"
                                    onClick={() => handleDeleteAd(ad.id)}
                                  >
                                    <Trash2 className="w-4 h-4 mr-1" /> Удалить
                                  </Button>
                                </td>
                              </tr>
                            ))
                        ) : (
                          <tr>
                            <td colSpan={4} className="px-6 py-10 text-center text-gray-500">
                              Нет доступных баннеров. Добавьте баннер, чтобы начать.
                            </td>
                          </tr>
                        )}
                      </tbody>
                    </table>
                  </div>
                )}
              </CardContent>
            </Card>
          </TabsContent>
          
          {/* Вкладка Таймеры */}
          <TabsContent value="timers">
            <Card>
              <CardHeader>
                <div className="flex justify-between items-center">
                  <div>
                    <CardTitle>Таймеры обратного отсчета</CardTitle>
                    <CardDescription>
                      Добавьте таймеры для отображения на главной странице
                    </CardDescription>
                  </div>
                  <Button
                    onClick={() => {
                      setEditingTimer(null);
                      setIsTimerFormOpen(true);
                    }}
                    className="bg-green-500 hover:bg-green-600"
                  >
                    <PlusCircle className="mr-2 h-4 w-4" /> Добавить таймер
                  </Button>
                </div>
              </CardHeader>
              <CardContent>
                {isTimersLoading ? (
                  <Skeleton className="h-64 w-full" />
                ) : (
                  <AdminTimerTable
                    timers={timers || []}
                    onEdit={handleEditTimer}
                    onDelete={handleDeleteTimer}
                  />
                )}
              </CardContent>
            </Card>
          </TabsContent>
          
          {/* Вкладка Настройки дизайна */}
          <TabsContent value="settings">
            <Card>
              <CardHeader>
                <div className="flex justify-between items-center">
                  <div>
                    <CardTitle>Настройки дизайна сайта</CardTitle>
                    <CardDescription>
                      Изменение цветовой схемы, шрифтов и других элементов дизайна сайта
                    </CardDescription>
                  </div>
                  <Button
                    onClick={() => setIsSiteSettingsFormOpen(true)}
                    className="bg-indigo-500 hover:bg-indigo-600"
                  >
                    <Palette className="mr-2 h-4 w-4" /> Редактировать дизайн
                  </Button>
                </div>
              </CardHeader>
              <CardContent>
                {isSettingsLoading ? (
                  <Skeleton className="h-64 w-full" />
                ) : (
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                    <div className="space-y-4">
                      <h3 className="text-lg font-medium">Текущие настройки дизайна</h3>
                      
                      <div className="grid grid-cols-2 gap-4">
                        <div className="rounded-md p-4 border border-gray-200">
                          <h4 className="text-sm font-medium text-gray-500 mb-1">Основной цвет</h4>
                          <div className="flex items-center gap-2">
                            <div 
                              className="h-6 w-6 rounded-full border border-gray-300" 
                              style={{ backgroundColor: siteSettings?.primaryColor || '#0f172a' }}
                            />
                            <span className="text-sm">{siteSettings?.primaryColor || '#0f172a'}</span>
                          </div>
                        </div>
                        
                        <div className="rounded-md p-4 border border-gray-200">
                          <h4 className="text-sm font-medium text-gray-500 mb-1">Второстепенный цвет</h4>
                          <div className="flex items-center gap-2">
                            <div 
                              className="h-6 w-6 rounded-full border border-gray-300" 
                              style={{ backgroundColor: siteSettings?.secondaryColor || '#1e293b' }}
                            />
                            <span className="text-sm">{siteSettings?.secondaryColor || '#1e293b'}</span>
                          </div>
                        </div>
                        
                        <div className="rounded-md p-4 border border-gray-200">
                          <h4 className="text-sm font-medium text-gray-500 mb-1">Акцентный цвет</h4>
                          <div className="flex items-center gap-2">
                            <div 
                              className="h-6 w-6 rounded-full border border-gray-300" 
                              style={{ backgroundColor: siteSettings?.accentColor || '#3b82f6' }}
                            />
                            <span className="text-sm">{siteSettings?.accentColor || '#3b82f6'}</span>
                          </div>
                        </div>
                        
                        <div className="rounded-md p-4 border border-gray-200">
                          <h4 className="text-sm font-medium text-gray-500 mb-1">Цвет заголовка</h4>
                          <div className="flex items-center gap-2">
                            <div 
                              className="h-6 w-6 rounded-full border border-gray-300" 
                              style={{ backgroundColor: siteSettings?.headerBgColor || '#0f172a' }}
                            />
                            <span className="text-sm">{siteSettings?.headerBgColor || '#0f172a'}</span>
                          </div>
                        </div>
                      </div>
                      
                      <div className="grid grid-cols-2 gap-4">
                        <div className="rounded-md p-4 border border-gray-200">
                          <h4 className="text-sm font-medium text-gray-500 mb-1">Основной шрифт</h4>
                          <div className="flex items-center">
                            <span className="text-sm font-medium" style={{ fontFamily: siteSettings?.fontPrimary || 'Inter' }}>
                              {siteSettings?.fontPrimary || 'Inter'}
                            </span>
                          </div>
                        </div>
                        
                        <div className="rounded-md p-4 border border-gray-200">
                          <h4 className="text-sm font-medium text-gray-500 mb-1">Радиус скругления</h4>
                          <div className="flex items-center">
                            <span className="text-sm">
                              {siteSettings?.borderRadius || '0.5rem'}
                            </span>
                          </div>
                        </div>
                        
                        <div className="rounded-md p-4 border border-gray-200">
                          <h4 className="text-sm font-medium text-gray-500 mb-1">Стиль кнопок</h4>
                          <div className="flex items-center">
                            <span className="text-sm capitalize">
                              {siteSettings?.buttonStyle || 'default'}
                            </span>
                          </div>
                        </div>
                        
                        <div className="rounded-md p-4 border border-gray-200">
                          <h4 className="text-sm font-medium text-gray-500 mb-1">Позиция логотипа</h4>
                          <div className="flex items-center">
                            <span className="text-sm capitalize">
                              {siteSettings?.logoPosition === 'center' ? 'По центру' : 
                               siteSettings?.logoPosition === 'left' ? 'Слева' : 
                               siteSettings?.logoPosition === 'right' ? 'Справа' : 'По центру'}
                            </span>
                          </div>
                        </div>
                      </div>
                    </div>
                    
                    <div 
                      className="rounded-lg overflow-hidden shadow-md" 
                      style={{ backgroundColor: siteSettings?.primaryColor || '#0f172a' }}
                    >
                      <div 
                        className="h-16 px-4 flex items-center justify-center" 
                        style={{ 
                          backgroundColor: siteSettings?.headerBgColor || '#0f172a',
                          justifyContent: siteSettings?.logoPosition === 'center' ? 'center' : 
                                         siteSettings?.logoPosition === 'left' ? 'flex-start' : 
                                         siteSettings?.logoPosition === 'right' ? 'flex-end' : 'center'
                        }}
                      >
                        <div className="text-white font-bold text-xl">ATOM﮳GAME</div>
                      </div>
                      
                      <div className="p-6 space-y-4">
                        <div 
                          className="rounded-lg p-4 text-white" 
                          style={{ 
                            backgroundColor: siteSettings?.secondaryColor || '#1e293b',
                            borderRadius: siteSettings?.borderRadius || '0.5rem'
                          }}
                        >
                          <h3 className="font-bold mb-2">Пример карточки</h3>
                          <p className="text-sm opacity-75">Это пример карточки с выбранными настройками дизайна</p>
                          <button 
                            style={{ 
                              backgroundColor: siteSettings?.accentColor || '#3b82f6',
                              borderRadius: siteSettings?.borderRadius || '0.5rem',
                              padding: '0.5rem 1rem',
                              marginTop: '1rem',
                              fontWeight: 'bold',
                              border: 'none' 
                            }}
                          >
                            Кнопка
                          </button>
                        </div>
                        
                        <div 
                          className="rounded-lg p-4 text-white" 
                          style={{ 
                            backgroundColor: siteSettings?.tableBgColor || '#1e293b',
                            borderRadius: siteSettings?.borderRadius || '0.5rem'
                          }}
                        >
                          <h3 className="font-bold mb-2">Пример таблицы</h3>
                          <div className="w-full border-collapse">
                            <div className="flex justify-between border-b border-gray-700 pb-2 mb-2">
                              <div className="font-medium">Команда</div>
                              <div className="font-medium">Очки</div>
                            </div>
                            <div className="flex justify-between py-1">
                              <div>Команда A</div>
                              <div>100</div>
                            </div>
                            <div className="flex justify-between py-1">
                              <div>Команда B</div>
                              <div>85</div>
                            </div>
                          </div>
                        </div>
                      </div>
                    </div>
                  </div>
                )}
              </CardContent>
            </Card>
            
            <Card className="mt-8">
              <CardHeader>
                <div className="flex justify-between items-center">
                  <div>
                    <CardTitle>Системные настройки</CardTitle>
                    <CardDescription>
                      Управление глобальными настройками и функциями приложения
                    </CardDescription>
                  </div>
                </div>
              </CardHeader>
              <CardContent>
                <div className="space-y-8">
                  <div className="bg-gray-50 p-4 rounded-lg border border-gray-200">
                    <div className="flex justify-between items-start">
                      <div>
                        <h3 className="text-lg font-medium mb-2 text-primary">Рейтинги команд</h3>
                        <p className="text-sm text-gray-600 mb-3">
                          Управление историей изменения позиций команд в рейтинге. При сбросе истории все индикаторы позиций будут показывать "0" до следующего изменения очков.
                        </p>
                        <div className="text-xs text-gray-500 mb-4 flex items-center">
                          <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className="w-4 h-4 mr-1"><circle cx="12" cy="12" r="10"></circle><path d="M12 16v-4"></path><path d="M12 8h.01"></path></svg>
                          Эта операция не может быть отменена
                        </div>
                      </div>
                      <Button 
                        variant="destructive" 
                        className="mt-2 transition-all hover:scale-105"
                        onClick={() => {
                          if (window.confirm("Вы уверены, что хотите сбросить всю историю рейтингов? Эта операция не может быть отменена.")) {
                            clearRankingsHistory();
                            toast({
                              title: "История рейтингов сброшена",
                              description: "Индикаторы изменения позиций будут обновлены после следующего изменения очков",
                            });
                          }
                        }}
                      >
                        <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className="w-4 h-4 mr-2"><path d="M3 6h18"></path><path d="M19 6v14c0 1-1 2-2 2H7c-1 0-2-1-2-2V6"></path><path d="M8 6V4c0-1 1-2 2-2h4c1 0 2 1 2 2v2"></path><line x1="10" y1="11" x2="10" y2="17"></line><line x1="14" y1="11" x2="14" y2="17"></line></svg>
                        Сбросить историю рейтингов
                      </Button>
                    </div>
                  </div>
                  
                  <div className="bg-blue-50 p-4 rounded-lg border border-blue-200">
                    <div className="flex items-center">
                      <div className="mr-4 bg-blue-100 p-2 rounded-full">
                        <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className="text-blue-700"><circle cx="12" cy="12" r="10"></circle><path d="M12 16v-4"></path><path d="M12 8h.01"></path></svg>
                      </div>
                      <div>
                        <h3 className="text-md font-medium text-blue-700">Информация о системе</h3>
                        <p className="text-sm text-blue-600 mt-1">
                          Текущая версия: 1.0.0 | Система рейтинга команд проекта ATOM﮳GAME
                        </p>
                      </div>
                    </div>
                  </div>
                </div>
              </CardContent>
            </Card>
          </TabsContent>
        </Tabs>
      </div>

      {/* Модальные формы */}
      {isTeamFormOpen && (
        <TeamForm
          team={editingTeam}
          onClose={() => {
            setIsTeamFormOpen(false);
            setEditingTeam(null);
          }}
        />
      )}
      
      {isScoreFormOpen && editingScoreTeam && (
        <TeamScoreForm
          team={editingScoreTeam}
          onClose={() => {
            setIsScoreFormOpen(false);
            setEditingScoreTeam(null);
          }}
        />
      )}
      
      {isPartnerFormOpen && (
        <PartnerForm
          partner={editingPartner}
          onClose={() => {
            setIsPartnerFormOpen(false);
            setEditingPartner(null);
          }}
        />
      )}
      
      {isAdFormOpen && (
        <AdBannerForm
          ad={editingAd}
          onClose={() => {
            setIsAdFormOpen(false);
            setEditingAd(null);
          }}
        />
      )}
      
      {isTimerFormOpen && (
        <TimerForm
          timer={editingTimer}
          onClose={() => {
            setIsTimerFormOpen(false);
            setEditingTimer(null);
          }}
        />
      )}
      
      {isSiteSettingsFormOpen && (
        <SiteSettingsForm
          settings={siteSettings || null}
          onClose={() => {
            setIsSiteSettingsFormOpen(false);
          }}
        />
      )}
    </div>
  );
}
