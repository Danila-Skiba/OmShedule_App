import { useState } from "react";
import { ArrowLeft, Moon, Sun, Bell, Globe, Palette, User, Lock, HelpCircle } from "lucide-react";
import { useNavigate } from "react-router";
import { Switch } from "../components/ui/switch";
import { motion } from "motion/react";

export default function Settings() {
  const navigate = useNavigate();
  const [darkMode, setDarkMode] = useState(false);
  const [notifications, setNotifications] = useState(true);
  const [language, setLanguage] = useState("ru");
  const [theme, setTheme] = useState("blue");

  const themes = [
    { id: "blue", name: "Синий (ОмГТУ)", color: "#1E3A8A" },
    { id: "green", name: "Зелёный", color: "#10B981" },
    { id: "purple", name: "Фиолетовый", color: "#8B5CF6" },
    { id: "red", name: "Красный", color: "#EF4444" },
  ];

  return (
    <div className="min-h-screen bg-[#F8FAFC]">
      {/* Header */}
      <header className="bg-[#1E3A8A] text-white p-4 shadow-md sticky top-0 z-10">
        <div className="flex items-center gap-3">
          <button
            onClick={() => navigate("/profile")}
            className="p-2 hover:bg-white/10 rounded-lg transition-colors"
          >
            <ArrowLeft className="w-5 h-5" />
          </button>
          <h1 className="text-lg font-bold">Настройки</h1>
        </div>
      </header>

      <div className="p-4 space-y-4">
        {/* Appearance Section */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.3 }}
          className="bg-white rounded-2xl shadow-sm border border-[#E2E8F0] overflow-hidden"
        >
          <div className="p-4 border-b border-[#E2E8F0]">
            <h3 className="text-sm font-bold text-[#1E3A8A] flex items-center gap-2">
              <Palette className="w-4 h-4" />
              Внешний вид
            </h3>
          </div>

          <div className="p-4 space-y-4">
            {/* Dark Mode */}
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-3">
                {darkMode ? (
                  <Moon className="w-5 h-5 text-[#64748B]" />
                ) : (
                  <Sun className="w-5 h-5 text-[#F59E0B]" />
                )}
                <div>
                  <p className="text-sm font-semibold text-[#1E3A8A]">Тёмная тема</p>
                  <p className="text-xs text-[#64748B]">Снизить яркость экрана</p>
                </div>
              </div>
              <Switch checked={darkMode} onCheckedChange={setDarkMode} />
            </div>

            {/* Theme Color */}
            <div>
              <p className="text-sm font-semibold text-[#1E3A8A] mb-3">Цветовая схема</p>
              <div className="grid grid-cols-2 gap-2">
                {themes.map((t) => (
                  <button
                    key={t.id}
                    onClick={() => setTheme(t.id)}
                    className={`p-3 rounded-xl border-2 transition-all ${
                      theme === t.id
                        ? "border-[#3B82F6] bg-[#3B82F6]/5"
                        : "border-[#E2E8F0] bg-white"
                    }`}
                  >
                    <div className="flex items-center gap-2">
                      <div
                        className="w-6 h-6 rounded-full"
                        style={{ backgroundColor: t.color }}
                      ></div>
                      <span className="text-sm font-medium text-[#1E3A8A]">{t.name}</span>
                    </div>
                  </button>
                ))}
              </div>
            </div>
          </div>
        </motion.div>

        {/* Notifications Section */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.3, delay: 0.1 }}
          className="bg-white rounded-2xl shadow-sm border border-[#E2E8F0] overflow-hidden"
        >
          <div className="p-4 border-b border-[#E2E8F0]">
            <h3 className="text-sm font-bold text-[#1E3A8A] flex items-center gap-2">
              <Bell className="w-4 h-4" />
              Уведомления
            </h3>
          </div>

          <div className="p-4 space-y-4">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm font-semibold text-[#1E3A8A]">Push-уведомления</p>
                <p className="text-xs text-[#64748B]">О парах и событиях</p>
              </div>
              <Switch checked={notifications} onCheckedChange={setNotifications} />
            </div>

            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm font-semibold text-[#1E3A8A]">Напоминания</p>
                <p className="text-xs text-[#64748B]">За 15 минут до пары</p>
              </div>
              <Switch checked={true} />
            </div>

            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm font-semibold text-[#1E3A8A]">Новости ОмГТУ</p>
                <p className="text-xs text-[#64748B]">Важные объявления</p>
              </div>
              <Switch checked={false} />
            </div>
          </div>
        </motion.div>

        {/* Language & Region */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.3, delay: 0.2 }}
          className="bg-white rounded-2xl shadow-sm border border-[#E2E8F0] overflow-hidden"
        >
          <div className="p-4 border-b border-[#E2E8F0]">
            <h3 className="text-sm font-bold text-[#1E3A8A] flex items-center gap-2">
              <Globe className="w-4 h-4" />
              Язык и регион
            </h3>
          </div>

          <div className="p-4 space-y-3">
            {[
              { id: "ru", name: "Русский", flag: "🇷🇺" },
              { id: "en", name: "English", flag: "🇬🇧" },
            ].map((lang) => (
              <button
                key={lang.id}
                onClick={() => setLanguage(lang.id)}
                className={`w-full p-3 rounded-xl flex items-center gap-3 transition-all ${
                  language === lang.id
                    ? "bg-[#3B82F6]/10 border-2 border-[#3B82F6]"
                    : "bg-[#F8FAFC] border-2 border-transparent"
                }`}
              >
                <span className="text-2xl">{lang.flag}</span>
                <span className="text-sm font-semibold text-[#1E3A8A]">{lang.name}</span>
                {language === lang.id && (
                  <div className="ml-auto w-5 h-5 rounded-full bg-[#3B82F6] flex items-center justify-center">
                    <div className="w-2 h-2 bg-white rounded-full"></div>
                  </div>
                )}
              </button>
            ))}
          </div>
        </motion.div>

        {/* Account & Privacy */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.3, delay: 0.3 }}
          className="bg-white rounded-2xl shadow-sm border border-[#E2E8F0]"
        >
          <button className="w-full p-4 flex items-center gap-3 hover:bg-[#F8FAFC] transition-colors">
            <div className="w-10 h-10 bg-[#3B82F6]/10 rounded-full flex items-center justify-center">
              <User className="w-5 h-5 text-[#3B82F6]" />
            </div>
            <div className="flex-1 text-left">
              <p className="text-sm font-semibold text-[#1E3A8A]">Аккаунт</p>
              <p className="text-xs text-[#64748B]">Управление профилем</p>
            </div>
          </button>

          <div className="border-t border-[#E2E8F0]"></div>

          <button className="w-full p-4 flex items-center gap-3 hover:bg-[#F8FAFC] transition-colors">
            <div className="w-10 h-10 bg-[#10B981]/10 rounded-full flex items-center justify-center">
              <Lock className="w-5 h-5 text-[#10B981]" />
            </div>
            <div className="flex-1 text-left">
              <p className="text-sm font-semibold text-[#1E3A8A]">Конфиденциальность</p>
              <p className="text-xs text-[#64748B]">Безопасность данных</p>
            </div>
          </button>

          <div className="border-t border-[#E2E8F0]"></div>

          <button className="w-full p-4 flex items-center gap-3 hover:bg-[#F8FAFC] transition-colors">
            <div className="w-10 h-10 bg-[#F59E0B]/10 rounded-full flex items-center justify-center">
              <HelpCircle className="w-5 h-5 text-[#F59E0B]" />
            </div>
            <div className="flex-1 text-left">
              <p className="text-sm font-semibold text-[#1E3A8A]">Помощь и поддержка</p>
              <p className="text-xs text-[#64748B]">FAQ и обратная связь</p>
            </div>
          </button>
        </motion.div>

        {/* App Info */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.3, delay: 0.4 }}
          className="text-center py-4"
        >
          <p className="text-xs text-[#64748B]">Расписание ОмГТУ</p>
          <p className="text-xs text-[#64748B]">Версия 1.0.0</p>
        </motion.div>
      </div>
    </div>
  );
}
