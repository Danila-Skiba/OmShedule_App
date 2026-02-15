import { Outlet, useNavigate, useLocation } from "react-router";
import { Home, Calendar, Map, User, MessageSquare } from "lucide-react";

export default function MobileLayout() {
  const navigate = useNavigate();
  const location = useLocation();

  const navItems = [
    { path: "/", icon: Home, label: "Главная" },
    { path: "/schedule", icon: Calendar, label: "Расписание" },
    { path: "/maps", icon: Map, label: "Карты" },
    { path: "/profile", icon: User, label: "Профиль" },
    { path: "/chat", icon: MessageSquare, label: "Помощник" },
  ];

  const isActive = (path: string) => {
    if (path === "/") {
      return location.pathname === "/";
    }
    return location.pathname.startsWith(path);
  };

  return (
    <div className="flex flex-col h-screen bg-[#F8FAFC] max-w-md mx-auto">
      {/* Main Content */}
      <div className="flex-1 overflow-y-auto pb-20">
        <Outlet />
      </div>

      {/* Bottom Navigation Bar */}
      <nav className="fixed bottom-0 left-0 right-0 max-w-md mx-auto bg-white border-t border-[#E2E8F0] shadow-lg">
        <div className="flex justify-around items-center h-16">
          {navItems.map((item) => {
            const Icon = item.icon;
            const active = isActive(item.path);
            return (
              <button
                key={item.path}
                onClick={() => navigate(item.path)}
                className={`flex flex-col items-center justify-center gap-1 px-3 py-2 transition-colors ${
                  active ? "text-[#1E3A8A]" : "text-[#64748B]"
                }`}
              >
                <Icon className={`w-6 h-6 ${active ? "fill-[#3B82F6]/20" : ""}`} />
                <span className="text-xs font-medium">{item.label}</span>
              </button>
            );
          })}
        </div>
      </nav>
    </div>
  );
}
