import { MapPin, Navigation, Coffee, Car, Star, Phone, Clock } from "lucide-react";
import { buildings } from "../data/mockData";

export default function Maps() {
  const currentBuilding = buildings[2]; // Корпус 3

  return (
    <div className="min-h-screen bg-[#F8FAFC]">
      {/* Header */}
      <header className="bg-[#1E3A8A] text-white p-4 shadow-md">
        <div className="flex items-center gap-2">
          <MapPin className="w-5 h-5" />
          <div>
            <h1 className="text-lg font-bold">{currentBuilding.name}</h1>
            <p className="text-xs opacity-90">{currentBuilding.address}</p>
          </div>
        </div>
      </header>

      {/* Map Preview - Static mockup */}
      <div className="relative h-64 bg-gradient-to-br from-[#E0E7FF] to-[#DBEAFE] border-b-4 border-[#3B82F6]">
        {/* Map Mockup - simplified visualization */}
        <div className="absolute inset-0 p-6">
          <div className="w-full h-full bg-[#F1F5F9] rounded-2xl shadow-lg overflow-hidden relative">
            {/* Grid pattern */}
            <div className="absolute inset-0 opacity-20">
              <div className="grid grid-cols-8 grid-rows-6 h-full">
                {Array.from({ length: 48 }).map((_, i) => (
                  <div key={i} className="border border-[#64748B]"></div>
                ))}
              </div>
            </div>

            {/* Roads */}
            <div className="absolute top-1/2 left-0 right-0 h-8 bg-[#94A3B8] -translate-y-1/2"></div>
            <div className="absolute left-1/3 top-0 bottom-0 w-6 bg-[#94A3B8]"></div>

            {/* Buildings */}
            <div className="absolute top-1/4 left-1/2 w-16 h-16 bg-[#3B82F6] rounded-lg shadow-md flex items-center justify-center transform -translate-x-1/2">
              <MapPin className="w-8 h-8 text-white animate-bounce" />
            </div>
            <div className="absolute bottom-1/4 left-1/4 w-12 h-12 bg-[#64748B] rounded-lg"></div>
            <div className="absolute top-1/3 right-1/4 w-10 h-10 bg-[#64748B] rounded-lg"></div>
          </div>
        </div>

        {/* Distance Badge */}
        <div className="absolute top-8 right-8 bg-white rounded-full px-4 py-2 shadow-lg">
          <div className="flex items-center gap-2">
            <Navigation className="w-4 h-4 text-[#3B82F6]" />
            <div>
              <p className="text-xs font-bold text-[#1E3A8A]">{currentBuilding.distance}</p>
              <p className="text-[10px] text-[#64748B]">{currentBuilding.walkTime}</p>
            </div>
          </div>
        </div>
      </div>

      {/* Quick Actions */}
      <div className="p-4 grid grid-cols-3 gap-3">
        <button className="bg-[#3B82F6] text-white p-4 rounded-2xl shadow-md hover:bg-[#1E3A8A] transition-colors flex flex-col items-center gap-2">
          <Navigation className="w-6 h-6" />
          <span className="text-xs font-semibold">Маршрут</span>
        </button>
        <button className="bg-white text-[#1E3A8A] p-4 rounded-2xl shadow-md border border-[#E2E8F0] hover:shadow-lg transition-shadow flex flex-col items-center gap-2">
          <Coffee className="w-6 h-6" />
          <span className="text-xs font-semibold">Кафе</span>
        </button>
        <button className="bg-white text-[#1E3A8A] p-4 rounded-2xl shadow-md border border-[#E2E8F0] hover:shadow-lg transition-shadow flex flex-col items-center gap-2">
          <Car className="w-6 h-6" />
          <span className="text-xs font-semibold">Парковки</span>
        </button>
      </div>

      {/* Building Details */}
      <div className="p-4 space-y-3">
        <div className="bg-white rounded-2xl p-4 shadow-sm border border-[#E2E8F0]">
          <h3 className="text-sm font-bold text-[#1E293B] mb-3 flex items-center gap-2">
            <MapPin className="w-4 h-4 text-[#3B82F6]" />
            Информация о корпусе
          </h3>

          <div className="space-y-3">
            <div className="flex items-center justify-between">
              <span className="text-sm text-[#64748B]">Адрес</span>
              <span className="text-sm font-semibold text-[#1E3A8A]">
                {currentBuilding.address}
              </span>
            </div>
            <div className="flex items-center justify-between">
              <span className="text-sm text-[#64748B]">Расстояние</span>
              <span className="text-sm font-semibold text-[#1E3A8A]">
                {currentBuilding.distance} • {currentBuilding.walkTime}
              </span>
            </div>
            <div className="flex items-center justify-between">
              <span className="text-sm text-[#64748B]">Кафе в корпусе</span>
              <span className="text-sm font-semibold text-[#10B981]">
                {currentBuilding.hasCafe ? "Да" : "Нет"}
              </span>
            </div>
          </div>
        </div>

        {/* Current Lesson in this building */}
        <div className="bg-gradient-to-br from-[#3B82F6] to-[#1E3A8A] rounded-2xl p-4 shadow-lg text-white">
          <div className="flex items-center gap-2 mb-3">
            <Clock className="w-4 h-4" />
            <h3 className="text-sm font-bold">Ближайшая пара в этом корпусе</h3>
          </div>
          <div className="space-y-2">
            <div className="flex items-center justify-between">
              <span className="text-sm opacity-90">Аудитория</span>
              <span className="text-sm font-bold">312 (3 этаж)</span>
            </div>
            <div className="flex items-center justify-between">
              <span className="text-sm opacity-90">Время</span>
              <span className="text-sm font-bold">08:30 - 10:15</span>
            </div>
            <div className="flex items-center justify-between">
              <span className="text-sm opacity-90">Преподаватель</span>
              <span className="text-sm font-bold">Петров В.В.</span>
            </div>
            <div className="flex items-center gap-1 mt-2">
              <Star className="w-4 h-4 fill-[#F59E0B] text-[#F59E0B]" />
              <span className="text-sm font-semibold">4.2</span>
              <span className="text-sm opacity-75">(127 отзывов)</span>
            </div>
          </div>
        </div>

        {/* All Buildings List */}
        <div className="bg-white rounded-2xl p-4 shadow-sm border border-[#E2E8F0]">
          <h3 className="text-sm font-bold text-[#1E293B] mb-3">Все корпуса</h3>
          <div className="space-y-3">
            {buildings.map((building) => (
              <button
                key={building.id}
                className="w-full text-left p-3 rounded-xl bg-[#F8FAFC] hover:bg-[#F1F5F9] transition-colors"
              >
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-3">
                    <div className="w-10 h-10 bg-[#3B82F6]/10 rounded-full flex items-center justify-center">
                      <MapPin className="w-5 h-5 text-[#3B82F6]" />
                    </div>
                    <div>
                      <p className="text-sm font-semibold text-[#1E3A8A]">{building.name}</p>
                      <p className="text-xs text-[#64748B]">{building.address}</p>
                    </div>
                  </div>
                  <div className="text-right">
                    <p className="text-xs font-semibold text-[#1E3A8A]">{building.distance}</p>
                    <p className="text-xs text-[#64748B]">{building.walkTime}</p>
                  </div>
                </div>
              </button>
            ))}
          </div>
        </div>

        {/* Nearby Places */}
        <div className="bg-white rounded-2xl p-4 shadow-sm border border-[#E2E8F0]">
          <h3 className="text-sm font-bold text-[#1E293B] mb-3 flex items-center gap-2">
            <Coffee className="w-4 h-4 text-[#F59E0B]" />
            Рядом с корпусом
          </h3>
          <div className="space-y-3">
            <div className="flex items-start gap-3">
              <div className="w-10 h-10 bg-[#F59E0B]/10 rounded-full flex items-center justify-center flex-shrink-0">
                <Coffee className="w-5 h-5 text-[#F59E0B]" />
              </div>
              <div className="flex-1">
                <p className="text-sm font-semibold text-[#1E3A8A]">Столовая ОмГТУ</p>
                <p className="text-xs text-[#64748B]">50м • 1 мин</p>
                <div className="flex items-center gap-1 mt-1">
                  <Star className="w-3 h-3 fill-[#F59E0B] text-[#F59E0B]" />
                  <span className="text-xs text-[#64748B]">4.5 (234)</span>
                </div>
              </div>
              <button className="p-2 bg-[#F1F5F9] rounded-lg">
                <Phone className="w-4 h-4 text-[#3B82F6]" />
              </button>
            </div>

            <div className="flex items-start gap-3">
              <div className="w-10 h-10 bg-[#10B981]/10 rounded-full flex items-center justify-center flex-shrink-0">
                <Coffee className="w-5 h-5 text-[#10B981]" />
              </div>
              <div className="flex-1">
                <p className="text-sm font-semibold text-[#1E3A8A]">Кофейня "Энергия"</p>
                <p className="text-xs text-[#64748B]">120м • 2 мин</p>
                <div className="flex items-center gap-1 mt-1">
                  <Star className="w-3 h-3 fill-[#F59E0B] text-[#F59E0B]" />
                  <span className="text-xs text-[#64748B]">4.8 (89)</span>
                </div>
              </div>
              <button className="p-2 bg-[#F1F5F9] rounded-lg">
                <Phone className="w-4 h-4 text-[#3B82F6]" />
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
