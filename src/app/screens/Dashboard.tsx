import { useNavigate } from "react-router";
import { Clock, Users, MapPin, Newspaper, Bell, Menu, ChevronRight } from "lucide-react";
import { lessons, tasks, news } from "../data/mockData";
import { Progress } from "../components/ui/progress";
import { motion } from "motion/react";

export default function Dashboard() {
  const navigate = useNavigate();
  const today = new Date().getDay();
  const todayLessons = lessons.filter((l) => l.dayOfWeek === today);
  const completedTasks = tasks.filter((t) => t.completed).length;
  const totalTasks = tasks.length;

  // Симуляция текущего времени и следующей пары
  const nextLesson = todayLessons[0];
  const minutesToNext = 14;

  return (
    <div className="min-h-screen bg-[#F8FAFC] pb-4">
      {/* App Bar */}
      <header className="bg-[#1E3A8A] text-white p-4 shadow-md">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-3">
            <button className="p-2 hover:bg-white/10 rounded-lg transition-colors">
              <Menu className="w-6 h-6" />
            </button>
            <h1 className="text-lg font-bold">Расписание ОмГТУ</h1>
          </div>
          <button className="p-2 hover:bg-white/10 rounded-lg transition-colors relative">
            <Bell className="w-6 h-6" />
            <span className="absolute top-1 right-1 w-2 h-2 bg-[#EF4444] rounded-full"></span>
          </button>
        </div>
      </header>

      <div className="p-4 space-y-4">
        {/* Quick Actions */}
        <motion.div 
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.3 }}
          className="grid grid-cols-4 gap-2"
        >
          <motion.button
            whileHover={{ scale: 1.05 }}
            whileTap={{ scale: 0.95 }}
            onClick={() => navigate("/schedule")}
            className="bg-white rounded-2xl p-3 shadow-sm border border-[#E2E8F0] hover:shadow-md transition-shadow flex flex-col items-center gap-2"
          >
            <div className="w-12 h-12 bg-[#3B82F6]/10 rounded-full flex items-center justify-center">
              <Clock className="w-6 h-6 text-[#3B82F6]" />
            </div>
            <div className="text-center">
              <p className="text-xs font-semibold text-[#1E293B]">Сегодня</p>
              <p className="text-[10px] text-[#64748B]">{nextLesson?.timeStart || "08:30"}</p>
            </div>
          </motion.button>

          <motion.button
            whileHover={{ scale: 1.05 }}
            whileTap={{ scale: 0.95 }}
            onClick={() => navigate("/schedule")}
            className="bg-white rounded-2xl p-3 shadow-sm border border-[#E2E8F0] hover:shadow-md transition-shadow flex flex-col items-center gap-2"
          >
            <div className="w-12 h-12 bg-[#10B981]/10 rounded-full flex items-center justify-center">
              <Users className="w-6 h-6 text-[#10B981]" />
            </div>
            <div className="text-center">
              <p className="text-xs font-semibold text-[#1E293B]">Группа</p>
              <p className="text-[10px] text-[#64748B]">ИУ5-31б</p>
            </div>
          </motion.button>

          <motion.button
            whileHover={{ scale: 1.05 }}
            whileTap={{ scale: 0.95 }}
            onClick={() => navigate("/schedule")}
            className="bg-white rounded-2xl p-3 shadow-sm border border-[#E2E8F0] hover:shadow-md transition-shadow flex flex-col items-center gap-2"
          >
            <div className="w-12 h-12 bg-[#F59E0B]/10 rounded-full flex items-center justify-center">
              <Users className="w-6 h-6 text-[#F59E0B]" />
            </div>
            <div className="text-center">
              <p className="text-xs font-semibold text-[#1E293B]">Препод.</p>
              <p className="text-[10px] text-[#64748B]">Петров В.В.</p>
            </div>
          </motion.button>

          <motion.button
            whileHover={{ scale: 1.05 }}
            whileTap={{ scale: 0.95 }}
            onClick={() => navigate("/maps")}
            className="bg-white rounded-2xl p-3 shadow-sm border border-[#E2E8F0] hover:shadow-md transition-shadow flex flex-col items-center gap-2"
          >
            <div className="w-12 h-12 bg-[#EF4444]/10 rounded-full flex items-center justify-center">
              <MapPin className="w-6 h-6 text-[#EF4444]" />
            </div>
            <div className="text-center">
              <p className="text-xs font-semibold text-[#1E293B]">Карты</p>
              <p className="text-[10px] text-[#64748B]">🗺️</p>
            </div>
          </motion.button>
        </motion.div>

        {/* Stats Row */}
        <div className="grid grid-cols-3 gap-3">
          <div className="bg-white rounded-2xl p-4 shadow-sm border border-[#E2E8F0]">
            <p className="text-xs text-[#64748B] mb-1">Посещено пар</p>
            <p className="text-xl font-bold text-[#1E3A8A]">14/18</p>
            <Progress value={77.8} className="mt-2 h-1" />
          </div>

          <div className="bg-white rounded-2xl p-4 shadow-sm border border-[#E2E8F0]">
            <p className="text-xs text-[#64748B] mb-1">Задачи</p>
            <p className="text-xl font-bold text-[#10B981]">
              {completedTasks}/{totalTasks}
            </p>
            <Progress value={(completedTasks / totalTasks) * 100} className="mt-2 h-1" />
          </div>

          <div className="bg-white rounded-2xl p-4 shadow-sm border border-[#E2E8F0]">
            <p className="text-xs text-[#64748B] mb-1">До следующей</p>
            <p className="text-xl font-bold text-[#F59E0B]">{minutesToNext}м</p>
            <div className="mt-2 h-1 bg-[#F59E0B]/20 rounded-full overflow-hidden">
              <div className="h-full bg-[#F59E0B] w-1/2 animate-pulse"></div>
            </div>
          </div>
        </div>

        {/* Quick Schedule Timeline */}
        <div className="bg-white rounded-2xl p-4 shadow-sm border border-[#E2E8F0]">
          <h3 className="text-sm font-bold text-[#1E293B] mb-3">Расписание на сегодня</h3>
          <div className="space-y-3">
            {todayLessons.slice(0, 3).map((lesson, index) => (
              <div key={lesson.id} className="flex items-center gap-3">
                <div className="flex flex-col items-center">
                  <span className="text-sm font-bold text-[#1E3A8A]">{lesson.timeStart}</span>
                  <div
                    className={`w-3 h-3 rounded-full ${
                      index === 0
                        ? "bg-[#EF4444] animate-pulse"
                        : index === 1
                        ? "bg-[#F59E0B]"
                        : "bg-[#10B981]"
                    }`}
                  ></div>
                  <span className="text-xs text-[#64748B]">{lesson.timeEnd}</span>
                </div>
                <div className="flex-1 h-px bg-[#E2E8F0]"></div>
                <div className="flex-1">
                  <p className="text-sm font-semibold text-[#1E293B]">{lesson.subject}</p>
                  <p className="text-xs text-[#64748B]">
                    {lesson.teacher} • {lesson.room}
                  </p>
                </div>
              </div>
            ))}
          </div>
          <button
            onClick={() => navigate("/schedule")}
            className="w-full mt-4 text-[#3B82F6] text-sm font-semibold flex items-center justify-center gap-1 hover:text-[#1E3A8A] transition-colors"
          >
            Показать всё расписание
            <ChevronRight className="w-4 h-4" />
          </button>
        </div>

        {/* News Feed */}
        <div className="space-y-3">
          <h3 className="text-sm font-bold text-[#1E293B] px-1">Новости ОмГТУ</h3>
          {news.map((item) => (
            <div
              key={item.id}
              className="bg-white rounded-2xl p-4 shadow-sm border border-[#E2E8F0] hover:shadow-md transition-shadow cursor-pointer"
            >
              <div className="flex items-start gap-3">
                <div className="w-12 h-12 bg-gradient-to-br from-[#3B82F6] to-[#1E3A8A] rounded-xl flex items-center justify-center flex-shrink-0">
                  <Newspaper className="w-6 h-6 text-white" />
                </div>
                <div className="flex-1">
                  <div className="flex items-center gap-2 mb-1">
                    <span className="text-xs text-[#64748B]">{item.date}</span>
                  </div>
                  <h4 className="text-sm font-semibold text-[#1E293B] mb-1">{item.title}</h4>
                  <p className="text-xs text-[#64748B] line-clamp-2">{item.preview}</p>
                  <button className="text-xs text-[#3B82F6] font-semibold mt-2 flex items-center gap-1">
                    Читать дальше
                    <ChevronRight className="w-3 h-3" />
                  </button>
                </div>
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}