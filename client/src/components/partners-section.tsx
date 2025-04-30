import { Card, CardContent } from "@/components/ui/card";

// Данные о партнерах
const partners = [
  {
    id: 1,
    name: "Фонд АТР АЭС",
    logo: "https://via.placeholder.com/160x80?text=ATR_AES",
    website: "#"
  },
  {
    id: 2,
    name: "АО 'Концерн Росэнергоатом'",
    logo: "https://via.placeholder.com/160x80?text=ROSATOM",
    website: "#"
  },
  {
    id: 3,
    name: "Патриотический клуб «Атом»",
    logo: "https://via.placeholder.com/160x80?text=ATOM",
    website: "#"
  },
  {
    id: 4,
    name: "Развитие",
    logo: "https://via.placeholder.com/160x80?text=SPONSOR",
    website: "#"
  }
];

export default function PartnersSection() {
  return (
    <div className="bg-white rounded-xl shadow-md p-6">
      <div className="grid grid-cols-2 md:grid-cols-4 gap-6">
        {partners.map((partner) => (
          <a 
            key={partner.id} 
            href={partner.website} 
            target="_blank" 
            rel="noopener noreferrer"
            className="block"
          >
            <Card className="border-0 transition-all duration-200 hover:shadow-md">
              <CardContent className="flex items-center justify-center p-4 h-24">
                <img 
                  src={partner.logo}
                  alt={`${partner.name} logo`}
                  className="max-h-16 max-w-full"
                />
              </CardContent>
            </Card>
            <div className="mt-2 text-center text-sm text-gray-600">
              {partner.name}
            </div>
          </a>
        ))}
      </div>
      <div className="mt-6 text-center text-sm text-gray-500">
        <p>Разработчик: <span className="font-medium">ATOM﮳GAME Team</span></p>
      </div>
    </div>
  );
}