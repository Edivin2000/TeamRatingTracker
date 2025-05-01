import { useState } from "react";
import { useQuery, useMutation } from "@tanstack/react-query";
import { Team, Partner, Ad, Timer } from "@shared/schema";
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
  Clock
} from "lucide-react";
import TeamForm from "@/components/team-form";
import TeamScoreForm from "@/components/team-score-form";
import PartnerForm from "@/components/partner-form";
import AdBannerForm from "@/components/ad-banner-form";
import TimerForm from "@/components/timer-form";
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
          <TabsList className="mb-6 grid grid-cols-4 h-auto">
            <TabsTrigger value="teams" className="py-3 data-[state=active]:bg-primary data-[state=active]:text-white">
              <Users className="w-4 h-4 mr-2" /> Команды
            </TabsTrigger>
            <TabsTrigger value="partners" className="py-3 data-[state=active]:bg-primary data-[state=active]:text-white">
              <BriefcaseBusiness className="w-4 h-4 mr-2" /> Партнеры
            </TabsTrigger>
            <TabsTrigger value="ads" className="py-3 data-[state=active]:bg-primary data-[state=active]:text-white">
              <Image className="w-4 h-4 mr-2" /> Рекламные баннеры
            </TabsTrigger>
            <TabsTrigger value="settings" className="py-3 data-[state=active]:bg-primary data-[state=active]:text-white">
              <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className="w-4 h-4 mr-2"><path d="M12.22 2h-.44a2 2 0 0 0-2 2v.18a2 2 0 0 1-1 1.73l-.43.25a2 2 0 0 1-2 0l-.15-.08a2 2 0 0 0-2.73.73l-.22.38a2 2 0 0 0 .73 2.73l.15.1a2 2 0 0 1 1 1.72v.51a2 2 0 0 1-1 1.74l-.15.09a2 2 0 0 0-.73 2.73l.22.38a2 2 0 0 0 2.73.73l.15-.08a2 2 0 0 1 2 0l.43.25a2 2 0 0 1 1 1.73V20a2 2 0 0 0 2 2h.44a2 2 0 0 0 2-2v-.18a2 2 0 0 1 1-1.73l.43-.25a2 2 0 0 1 2 0l.15.08a2 2 0 0 0 2.73-.73l.22-.39a2 2 0 0 0-.73-2.73l-.15-.08a2 2 0 0 1-1-1.74v-.5a2 2 0 0 1 1-1.74l.15-.09a2 2 0 0 0 .73-2.73l-.22-.38a2 2 0 0 0-2.73-.73l-.15.08a2 2 0 0 1-2 0l-.43-.25a2 2 0 0 1-1-1.73V4a2 2 0 0 0-2-2z"></path><circle cx="12" cy="12" r="3"></circle></svg>
              Настройки
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
          
          {/* Вкладка Настройки */}
          <TabsContent value="settings">
            <Card>
              <CardHeader>
                <div className="flex justify-between items-center">
                  <div>
                    <CardTitle>Настройки системы</CardTitle>
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
    </div>
  );
}
