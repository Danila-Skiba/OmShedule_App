import { useState } from "react";
import { User, CheckCircle2, Circle, Settings, Trophy, TrendingUp, Calendar } from "lucide-react";
import { useNavigate } from "react-router";
import { tasks } from "../data/mockData";
import { Progress } from "../components/ui/progress";
import { motion } from "motion/react";

export default function Profile() {
  const navigate = useNavigate();
  const [role, setRole] = useState<"student" | "teacher">("student");
  const [taskList, setTaskList] = useState(tasks);

  const toggleTask = (id: string) => {
    setTaskList((prev) =>
      prev.map((task) => (task.id === id ? { ...task, completed: !task.completed } : task))
    );
  };

  const completedTasks = taskList.filter((t) => t.completed).length;
  const totalTasks = taskList.length;
  const completionRate = Math.round((completedTasks / totalTasks) * 100);

  return (
    <div className="min-h-screen bg-[#F8FAFC] pb-4">
      {/* Header */}
      <header className="bg-gradient-to-br from-[#1E3A8A] to-[#3B82F6] text-white p-6 shadow-md">
        <div className="flex items-center justify-between mb-4">
          <h1 className="text-lg font-bold">Профиль</h1>
          <button 
            onClick={() => navigate("/settings")}
            className="p-2 hover:bg-white/10 rounded-lg transition-colors"
          >
            <Settings className="w-5 h-5" />
          </button>
        </div>

        <div className="flex items-center gap-4">
          <div className="w-20 h-20 bg-white/20 rounded-full flex items-center justify-center backdrop-blur-sm border-2 border-white/30">
            <User className="w-10 h-10 text-white" />
          </div>
          <div className="flex-1">
            <h2 className="text-xl font-bold">Иван Петров</h2>
            <p className="text-sm opacity-90">ИУ5-31б</p>
            <div className="flex items-center gap-2 mt-2">
              <Trophy className="w-4 h-4 text-[#F59E0B]" />
              <span className="text-xs font-semibold">Активный студент</span>
            </div>
          </div>
        </div>
      </header>

      <div className="p-4 space-y-4">
        {/* Role Switcher */}
        <div className="bg-white rounded-2xl p-4 shadow-sm border border-[#E2E8F0]">
          <p className="text-sm font-semibold text-[#64748B] mb-3">Роль</p>
          <div className="space-y-2">
            <button
              onClick={() => setRole("student")}
              className={`w-full text-left p-3 rounded-xl flex items-center gap-3 transition-all ${
                role === "student"
                  ? "bg-[#3B82F6]/10 border-2 border-[#3B82F6]"
                  : "bg-[#F8FAFC] border-2 border-transparent"
              }`}
            >
              <div
                className={`w-5 h-5 rounded-full border-2 flex items-center justify-center ${
                  role === "student"
                    ? "border-[#3B82F6] bg-[#3B82F6]"
                    : "border-[#CBD5E1]"
                }`}
              >
                {role === "student" && <div className="w-2 h-2 bg-white rounded-full"></div>}
              </div>
              <div>
                <p className="text-sm font-semibold text-[#1E3A8A]">Студент</p>
                <p className="text-xs text-[#64748B]">ИУ5-31б</p>
              </div>
            </button>

            <button
              onClick={() => setRole("teacher")}
              className={`w-full text-left p-3 rounded-xl flex items-center gap-3 transition-all ${
                role === "teacher"
                  ? "bg-[#3B82F6]/10 border-2 border-[#3B82F6]"
                  : "bg-[#F8FAFC] border-2 border-transparent"
              }`}
            >
              <div
                className={`w-5 h-5 rounded-full border-2 flex items-center justify-center ${
                  role === "teacher"
                    ? "border-[#3B82F6] bg-[#3B82F6]"
                    : "border-[#CBD5E1]"
                }`}
              >
                {role === "teacher" && <div className="w-2 h-2 bg-white rounded-full"></div>}
              </div>
              <div>
                <p className="text-sm font-semibold text-[#1E3A8A]">Преподаватель</p>
                <p className="text-xs text-[#64748B]">Кафедра ИВТ</p>
              </div>
            </button>
          </div>
        </div>

        {/* Statistics */}
        <div className="grid grid-cols-2 gap-3">
          <div className="bg-white rounded-2xl p-4 shadow-sm border border-[#E2E8F0]">
            <div className="flex items-center justify-between mb-2">
              <p className="text-sm text-[#64748B]">Посещаемость</p>
              <TrendingUp className="w-4 h-4 text-[#10B981]" />
            </div>
            <p className="text-2xl font-bold text-[#1E3A8A] mb-2">78%</p>
            <Progress value={78} className="h-2" />
            <p className="text-xs text-[#64748B] mt-2">За неделю</p>
          </div>

          <div className="bg-white rounded-2xl p-4 shadow-sm border border-[#E2E8F0]">
            <div className="flex items-center justify-between mb-2">
              <p className="text-sm text-[#64748B]">Активность</p>
              <Calendar className="w-4 h-4 text-[#3B82F6]" />
            </div>
            <p className="text-2xl font-bold text-[#1E3A8A] mb-2">4.2</p>
            <div className="flex gap-1">
              {[...Array(5)].map((_, i) => (
                <div
                  key={i}
                  className={`h-2 flex-1 rounded-full ${
                    i < 4 ? "bg-[#3B82F6]" : "bg-[#E2E8F0]"
                  }`}
                ></div>
              ))}
            </div>
            <p className="text-xs text-[#64748B] mt-2">За месяц</p>
          </div>
        </div>

        {/* Tasks Section */}
        <div className="bg-white rounded-2xl p-4 shadow-sm border border-[#E2E8F0]">
          <div className="flex items-center justify-between mb-4">
            <h3 className="text-sm font-bold text-[#1E3A8A]">Мои задачи</h3>
            <div className="px-3 py-1 bg-[#3B82F6]/10 rounded-full">
              <span className="text-xs font-semibold text-[#3B82F6]">
                {completedTasks}/{totalTasks}
              </span>
            </div>
          </div>

          <div className="mb-4">
            <Progress value={completionRate} className="h-2" />
            <p className="text-xs text-[#64748B] mt-2">{completionRate}% выполнено</p>
          </div>

          <div className="space-y-2">
            {taskList.map((task) => (
              <button
                key={task.id}
                onClick={() => toggleTask(task.id)}
                className={`w-full text-left p-3 rounded-xl transition-all flex items-start gap-3 ${
                  task.completed
                    ? "bg-[#10B981]/5 border border-[#10B981]/20"
                    : "bg-[#F8FAFC] hover:bg-[#F1F5F9] border border-[#E2E8F0]"
                }`}
              >
                <div className="mt-0.5">
                  {task.completed ? (
                    <CheckCircle2 className="w-5 h-5 text-[#10B981]" />
                  ) : (
                    <Circle className="w-5 h-5 text-[#CBD5E1]" />
                  )}
                </div>
                <div className="flex-1">
                  <p
                    className={`text-sm font-semibold ${
                      task.completed ? "text-[#64748B] line-through" : "text-[#1E3A8A]"
                    }`}
                  >
                    {task.title}
                  </p>
                  <p
                    className={`text-xs mt-1 ${
                      task.deadline === "сегодня" || task.deadline === "завтра"
                        ? "text-[#EF4444] font-semibold"
                        : "text-[#64748B]"
                    }`}
                  >
                    {task.deadline}
                  </p>
                </div>
              </button>
            ))}
          </div>
        </div>

        {/* Academic Performance */}
        <div className="bg-white rounded-2xl p-4 shadow-sm border border-[#E2E8F0]">
          <h3 className="text-sm font-bold text-[#1E3A8A] mb-4">Успеваемоть</h3>
          <div className="space-y-3">
            <div>
              <div className="flex items-center justify-between mb-2">
                <span className="text-sm text-[#64748B]">Математический анализ</span>
                <span className="text-sm font-bold text-[#10B981]">4.5</span>
              </div>
              <Progress value={90} className="h-2" />
            </div>

            <div>
              <div className="flex items-center justify-between mb-2">
                <span className="text-sm text-[#64748B]">Программирование</span>
                <span className="text-sm font-bold text-[#10B981]">5.0</span>
              </div>
              <Progress value={100} className="h-2" />
            </div>

            <div>
              <div className="flex items-center justify-between mb-2">
                <span className="text-sm text-[#64748B]">Физика</span>
                <span className="text-sm font-bold text-[#F59E0B]">4.0</span>
              </div>
              <Progress value={80} className="h-2" />
            </div>

            <div>
              <div className="flex items-center justify-between mb-2">
                <span className="text-sm text-[#64748B]">Английский язык</span>
                <span className="text-sm font-bold text-[#10B981]">4.8</span>
              </div>
              <Progress value={96} className="h-2" />
            </div>
          </div>

          <div className="mt-4 pt-4 border-t border-[#E2E8F0]">
            <div className="flex items-center justify-between">
              <span className="text-sm font-semibold text-[#64748B]">Средний балл</span>
              <span className="text-xl font-bold text-[#1E3A8A]">4.6</span>
            </div>
          </div>
        </div>

        {/* Achievements */}
        <div className="bg-gradient-to-br from-[#F59E0B]/10 to-[#EF4444]/10 rounded-2xl p-4 border border-[#F59E0B]/20">
          <div className="flex items-center gap-2 mb-3">
            <Trophy className="w-5 h-5 text-[#F59E0B]" />
            <h3 className="text-sm font-bold text-[#92400E]">Достижения</h3>
          </div>
          <div className="grid grid-cols-4 gap-2">
            {[
              { icon: "🎯", name: "Отличник" },
              { icon: "⚡", name: "Скорость" },
              { icon: "🔥", name: "Серия" },
              { icon: "🏆", name: "Чемпион" },
            ].map((achievement) => (
              <div
                key={achievement.name}
                className="bg-white rounded-xl p-3 text-center shadow-sm"
              >
                <div className="text-2xl mb-1">{achievement.icon}</div>
                <p className="text-xs text-[#64748B]">{achievement.name}</p>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}