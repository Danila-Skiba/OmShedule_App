import { useState } from "react";
import { ChevronLeft, ChevronRight, Plus, MapPin, User, Clock, Search, X } from "lucide-react";
import { lessons } from "../data/mockData";
import { Sheet, SheetContent, SheetHeader, SheetTitle, SheetTrigger } from "../components/ui/sheet";
import { Dialog, DialogContent, DialogHeader, DialogTitle } from "../components/ui/dialog";
import { Input } from "../components/ui/input";
import { Label } from "../components/ui/label";
import { motion, AnimatePresence } from "motion/react";

const weekDays = ["ПН", "ВТ", "СР", "ЧТ", "ПТ", "СБ"];
const dateRange = "17 фев - 24 фев";

type TabType = "group" | "teacher" | "room";

export default function Schedule() {
  const [view, setView] = useState<"today" | "tomorrow" | "week">("today");
  const [selectedLesson, setSelectedLesson] = useState<any>(null);
  const [activeTab, setActiveTab] = useState<TabType>("group");
  const [searchQuery, setSearchQuery] = useState("");
  const [showSearch, setShowSearch] = useState(false);
  const [showAddEvent, setShowAddEvent] = useState(false);
  const [selectedDay, setSelectedDay] = useState(1);

  const today = new Date().getDay() || 7;
  const todayIndex = today === 7 ? 0 : today - 1;

  // Form state
  const [newEvent, setNewEvent] = useState({
    title: "",
    type: "personal",
    time: "",
    room: "",
    notes: "",
  });

  const getLessonTypeColor = (type: string) => {
    switch (type) {
      case "lecture":
        return "bg-[#3B82F6]/10 border-[#3B82F6]/30 text-[#1E3A8A]";
      case "lab":
        return "bg-[#F59E0B]/10 border-[#F59E0B]/30 text-[#92400E]";
      case "exam":
        return "bg-[#EF4444]/10 border-[#EF4444]/30 text-[#991B1B]";
      case "personal":
        return "bg-[#10B981]/10 border-[#10B981]/30 text-[#065F46]";
      default:
        return "bg-white border-[#E2E8F0] text-[#1E293B]";
    }
  };

  const getLessonTypeBadge = (type: string) => {
    switch (type) {
      case "lecture":
        return "Лекция";
      case "lab":
        return "Лабораторная";
      case "exam":
        return "Экзамен";
      case "personal":
        return "Личное";
      default:
        return "Занятие";
    }
  };

  const filteredLessons = lessons.filter((lesson) => {
    if (!searchQuery) return true;
    return (
      lesson.subject.toLowerCase().includes(searchQuery.toLowerCase()) ||
      lesson.teacher.toLowerCase().includes(searchQuery.toLowerCase()) ||
      lesson.room.toLowerCase().includes(searchQuery.toLowerCase())
    );
  });

  const handleAddEvent = () => {
    console.log("New event:", newEvent);
    setShowAddEvent(false);
    setNewEvent({ title: "", type: "personal", time: "", room: "", notes: "" });
  };

  return (
    <div className="min-h-screen bg-[#F8FAFC]">
      {/* Header */}
      <motion.header
        initial={{ y: -20, opacity: 0 }}
        animate={{ y: 0, opacity: 1 }}
        className="bg-[#1E3A8A] text-white p-4 shadow-md sticky top-0 z-10"
      >
        <div className="flex items-center justify-between">
          <h1 className="text-lg font-bold">Расписание</h1>
          <button
            onClick={() => setShowSearch(!showSearch)}
            className="p-2 hover:bg-white/10 rounded-lg transition-colors"
          >
            {showSearch ? <X className="w-5 h-5" /> : <Search className="w-5 h-5" />}
          </button>
        </div>

        <AnimatePresence>
          {showSearch && (
            <motion.div
              initial={{ height: 0, opacity: 0 }}
              animate={{ height: "auto", opacity: 1 }}
              exit={{ height: 0, opacity: 0 }}
              transition={{ duration: 0.2 }}
              className="overflow-hidden"
            >
              <div className="mt-3">
                <Input
                  type="text"
                  placeholder="Поиск по предмету, преподавателю, аудитории..."
                  value={searchQuery}
                  onChange={(e) => setSearchQuery(e.target.value)}
                  className="bg-white/10 border-white/20 text-white placeholder:text-white/60"
                />
              </div>
            </motion.div>
          )}
        </AnimatePresence>
      </motion.header>

      {/* Tabs with smooth transition */}
      <div className="bg-white border-b border-[#E2E8F0] sticky top-14 z-10">
        <div className="flex relative">
          {(["group", "teacher", "room"] as TabType[]).map((tab) => (
            <button
              key={tab}
              onClick={() => setActiveTab(tab)}
              className={`flex-1 py-3 text-sm font-semibold transition-colors relative ${
                activeTab === tab ? "text-[#1E3A8A]" : "text-[#64748B]"
              }`}
            >
              {tab === "group" && "Группа"}
              {tab === "teacher" && "Преподаватель"}
              {tab === "room" && "Аудитория"}
            </button>
          ))}
          <motion.div
            className="absolute bottom-0 h-0.5 bg-[#3B82F6]"
            initial={false}
            animate={{
              left: activeTab === "group" ? "0%" : activeTab === "teacher" ? "33.33%" : "66.66%",
              width: "33.33%",
            }}
            transition={{ type: "spring", stiffness: 300, damping: 30 }}
          />
        </div>
      </div>

      {/* Segmented Control */}
      <motion.div
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        className="bg-white p-4 border-b border-[#E2E8F0]"
      >
        <div className="inline-flex bg-[#F1F5F9] rounded-xl p-1 w-full relative">
          <motion.div
            className="absolute inset-y-1 bg-white rounded-lg shadow-sm"
            initial={false}
            animate={{
              left: view === "today" ? "4px" : view === "tomorrow" ? "33.33%" : "66.66%",
              width: "calc(33.33% - 8px)",
            }}
            transition={{ type: "spring", stiffness: 300, damping: 30 }}
          />
          {(["today", "tomorrow", "week"] as const).map((v) => (
            <button
              key={v}
              onClick={() => setView(v)}
              className={`flex-1 px-4 py-2 rounded-lg text-sm font-semibold transition-colors relative z-10 ${
                view === v ? "text-[#1E3A8A]" : "text-[#64748B]"
              }`}
            >
              {v === "today" && "Сегодня"}
              {v === "tomorrow" && "Завтра"}
              {v === "week" && "Неделя"}
            </button>
          ))}
        </div>
      </motion.div>

      {/* Calendar Swipe */}
      <div className="bg-white p-4 border-b border-[#E2E8F0]">
        <div className="flex items-center justify-between mb-3">
          <button className="p-2 hover:bg-[#F1F5F9] rounded-lg transition-colors">
            <ChevronLeft className="w-5 h-5 text-[#64748B]" />
          </button>
          <span className="text-sm font-semibold text-[#1E293B]">{dateRange}</span>
          <button className="p-2 hover:bg-[#F1F5F9] rounded-lg transition-colors">
            <ChevronRight className="w-5 h-5 text-[#64748B]" />
          </button>
        </div>

        <div className="grid grid-cols-6 gap-2">
          {weekDays.map((day, index) => (
            <motion.button
              key={day}
              onClick={() => setSelectedDay(index + 1)}
              whileTap={{ scale: 0.95 }}
              className={`text-center py-2 rounded-lg transition-all ${
                selectedDay === index + 1
                  ? "bg-[#3B82F6] text-white font-bold shadow-md"
                  : index === todayIndex
                  ? "bg-[#3B82F6]/20 text-[#1E3A8A] font-semibold"
                  : "bg-[#F8FAFC] text-[#64748B]"
              }`}
            >
              <span className="text-xs">{day}</span>
            </motion.button>
          ))}
        </div>
      </div>

      {/* Schedule Content */}
      <div className="p-4 space-y-3">
        <AnimatePresence mode="wait">
          {view === "week" ? (
            // Week view
            <motion.div
              key="week"
              initial={{ opacity: 0, x: 20 }}
              animate={{ opacity: 1, x: 0 }}
              exit={{ opacity: 0, x: -20 }}
              transition={{ duration: 0.3 }}
              className="space-y-4"
            >
              {weekDays.map((day, dayIndex) => {
                const dayLessons = filteredLessons.filter((l) => l.dayOfWeek === dayIndex + 1);
                return (
                  <div key={day}>
                    <h3 className="text-sm font-bold text-[#64748B] mb-2">{day}</h3>
                    <div className="space-y-2">
                      {dayLessons.length > 0 ? (
                        dayLessons.map((lesson, index) => (
                          <motion.div
                            key={lesson.id}
                            initial={{ opacity: 0, y: 10 }}
                            animate={{ opacity: 1, y: 0 }}
                            transition={{ delay: index * 0.05 }}
                          >
                            <Sheet>
                              <SheetTrigger asChild>
                                <motion.button
                                  whileHover={{ scale: 1.02 }}
                                  whileTap={{ scale: 0.98 }}
                                  onClick={() => setSelectedLesson(lesson)}
                                  className={`w-full text-left p-4 rounded-2xl border-2 shadow-sm transition-all ${getLessonTypeColor(
                                    lesson.type
                                  )}`}
                                >
                                  <div className="flex items-start justify-between gap-3">
                                    <div className="flex-1">
                                      <div className="flex items-center gap-2 mb-1">
                                        <span className="text-sm font-bold">
                                          {lesson.timeStart} - {lesson.timeEnd}
                                        </span>
                                        <span className="text-xs px-2 py-0.5 bg-white/50 rounded-full">
                                          {getLessonTypeBadge(lesson.type)}
                                        </span>
                                      </div>
                                      <p className="font-semibold text-sm mb-1">{lesson.subject}</p>
                                      <p className="text-xs opacity-75">
                                        {lesson.teacher} • {lesson.room}
                                      </p>
                                    </div>
                                  </div>
                                </motion.button>
                              </SheetTrigger>
                              <LessonDetails lesson={selectedLesson} />
                            </Sheet>
                          </motion.div>
                        ))
                      ) : (
                        <div className="text-center py-6 text-sm text-[#64748B]">Занятий нет</div>
                      )}
                    </div>
                  </div>
                );
              })}
            </motion.div>
          ) : (
            // Today/Tomorrow view
            <motion.div
              key={view}
              initial={{ opacity: 0, x: 20 }}
              animate={{ opacity: 1, x: 0 }}
              exit={{ opacity: 0, x: -20 }}
              transition={{ duration: 0.3 }}
              className="space-y-3"
            >
              {filteredLessons
                .filter((l) => l.dayOfWeek === (view === "today" ? today : today + 1))
                .map((lesson, index) => (
                  <motion.div
                    key={lesson.id}
                    initial={{ opacity: 0, y: 10 }}
                    animate={{ opacity: 1, y: 0 }}
                    transition={{ delay: index * 0.05 }}
                  >
                    <Sheet>
                      <SheetTrigger asChild>
                        <motion.button
                          whileHover={{ scale: 1.02 }}
                          whileTap={{ scale: 0.98 }}
                          onClick={() => setSelectedLesson(lesson)}
                          className={`w-full text-left p-4 rounded-2xl border-2 shadow-sm transition-all ${getLessonTypeColor(
                            lesson.type
                          )}`}
                        >
                          <div className="flex items-start justify-between gap-3">
                            <div className="flex-1">
                              <div className="flex items-center gap-2 mb-1">
                                <span className="text-sm font-bold">
                                  {lesson.timeStart} - {lesson.timeEnd}
                                </span>
                                <span className="text-xs px-2 py-0.5 bg-white/50 rounded-full">
                                  {getLessonTypeBadge(lesson.type)}
                                </span>
                              </div>
                              <p className="font-semibold text-sm mb-1">{lesson.subject}</p>
                              <p className="text-xs opacity-75">
                                {lesson.teacher} • {lesson.room}
                              </p>
                            </div>
                          </div>
                        </motion.button>
                      </SheetTrigger>
                      <LessonDetails lesson={selectedLesson} />
                    </Sheet>
                  </motion.div>
                ))}
            </motion.div>
          )}
        </AnimatePresence>
      </div>

      {/* FAB - Add Event */}
      <motion.button
        whileHover={{ scale: 1.1 }}
        whileTap={{ scale: 0.9 }}
        onClick={() => setShowAddEvent(true)}
        className="fixed bottom-20 right-4 w-14 h-14 bg-[#3B82F6] text-white rounded-full shadow-lg flex items-center justify-center"
      >
        <Plus className="w-6 h-6" />
      </motion.button>

      {/* Add Event Dialog */}
      <Dialog open={showAddEvent} onOpenChange={setShowAddEvent}>
        <DialogContent className="max-w-md">
          <DialogHeader>
            <DialogTitle className="text-xl font-bold text-[#1E3A8A]">
              Добавить событие
            </DialogTitle>
          </DialogHeader>

          <div className="space-y-4">
            <div>
              <Label htmlFor="title" className="text-sm font-semibold text-[#1E3A8A]">
                Название
              </Label>
              <Input
                id="title"
                value={newEvent.title}
                onChange={(e) => setNewEvent({ ...newEvent, title: e.target.value })}
                placeholder="Встреча, задача, экзамен..."
                className="mt-1"
              />
            </div>

            <div>
              <Label className="text-sm font-semibold text-[#1E3A8A]">Тип</Label>
              <div className="grid grid-cols-2 gap-2 mt-2">
                {[
                  { id: "personal", label: "Личное", color: "#10B981" },
                  { id: "meeting", label: "Встреча", color: "#3B82F6" },
                  { id: "exam", label: "Экзамен", color: "#EF4444" },
                  { id: "other", label: "Другое", color: "#F59E0B" },
                ].map((type) => (
                  <button
                    key={type.id}
                    onClick={() => setNewEvent({ ...newEvent, type: type.id })}
                    className={`p-3 rounded-xl border-2 transition-all ${
                      newEvent.type === type.id
                        ? "border-[#3B82F6] bg-[#3B82F6]/10"
                        : "border-[#E2E8F0]"
                    }`}
                  >
                    <div className="flex items-center gap-2">
                      <div
                        className="w-4 h-4 rounded-full"
                        style={{ backgroundColor: type.color }}
                      ></div>
                      <span className="text-sm font-medium">{type.label}</span>
                    </div>
                  </button>
                ))}
              </div>
            </div>

            <div className="grid grid-cols-2 gap-3">
              <div>
                <Label htmlFor="time" className="text-sm font-semibold text-[#1E3A8A]">
                  Время
                </Label>
                <Input
                  id="time"
                  type="time"
                  value={newEvent.time}
                  onChange={(e) => setNewEvent({ ...newEvent, time: e.target.value })}
                  className="mt-1"
                />
              </div>

              <div>
                <Label htmlFor="room" className="text-sm font-semibold text-[#1E3A8A]">
                  Аудитория
                </Label>
                <Input
                  id="room"
                  value={newEvent.room}
                  onChange={(e) => setNewEvent({ ...newEvent, room: e.target.value })}
                  placeholder="312"
                  className="mt-1"
                />
              </div>
            </div>

            <div>
              <Label htmlFor="notes" className="text-sm font-semibold text-[#1E3A8A]">
                Заметки
              </Label>
              <textarea
                id="notes"
                value={newEvent.notes}
                onChange={(e) => setNewEvent({ ...newEvent, notes: e.target.value })}
                placeholder="Дополнительная информация..."
                className="w-full mt-1 p-3 rounded-xl border border-[#E2E8F0] text-sm resize-none"
                rows={3}
              />
            </div>

            <div className="flex gap-2 pt-2">
              <button
                onClick={() => setShowAddEvent(false)}
                className="flex-1 py-3 rounded-xl font-semibold text-[#1E3A8A] bg-[#F1F5F9] hover:bg-[#E2E8F0] transition-colors"
              >
                Отмена
              </button>
              <button
                onClick={handleAddEvent}
                className="flex-1 py-3 rounded-xl font-semibold text-white bg-[#3B82F6] hover:bg-[#1E3A8A] transition-colors"
              >
                Добавить
              </button>
            </div>
          </div>
        </DialogContent>
      </Dialog>
    </div>
  );
}

function LessonDetails({ lesson }: { lesson: any }) {
  if (!lesson) return null;

  return (
    <SheetContent side="bottom" className="rounded-t-3xl">
      <SheetHeader>
        <SheetTitle className="text-xl font-bold text-[#1E3A8A]">{lesson.subject}</SheetTitle>
      </SheetHeader>
      <div className="space-y-4 mt-6">
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 bg-[#3B82F6]/10 rounded-full flex items-center justify-center">
            <Clock className="w-5 h-5 text-[#3B82F6]" />
          </div>
          <div>
            <p className="text-sm text-[#64748B]">Время</p>
            <p className="font-semibold text-[#1E293B]">
              {lesson.timeStart} - {lesson.timeEnd}
            </p>
          </div>
        </div>

        <div className="flex items-center gap-3">
          <div className="w-10 h-10 bg-[#10B981]/10 rounded-full flex items-center justify-center">
            <User className="w-5 h-5 text-[#10B981]" />
          </div>
          <div>
            <p className="text-sm text-[#64748B]">Преподаватель</p>
            <p className="font-semibold text-[#1E293B]">{lesson.teacher}</p>
            <div className="flex items-center gap-1 mt-1">
              <span className="text-xs text-[#F59E0B]">★ 4.2</span>
              <span className="text-xs text-[#64748B]">(127 отзывов)</span>
            </div>
          </div>
        </div>

        <div className="flex items-center gap-3">
          <div className="w-10 h-10 bg-[#EF4444]/10 rounded-full flex items-center justify-center">
            <MapPin className="w-5 h-5 text-[#EF4444]" />
          </div>
          <div>
            <p className="text-sm text-[#64748B]">Аудитория</p>
            <p className="font-semibold text-[#1E293B]">
              {lesson.room}, {lesson.building}
            </p>
            <p className="text-xs text-[#64748B] mt-1">350м • 5 мин пешком</p>
          </div>
        </div>

        <div className="flex gap-2 pt-4">
          <button className="flex-1 bg-[#3B82F6] text-white py-3 rounded-xl font-semibold hover:bg-[#1E3A8A] transition-colors">
            Построить маршрут
          </button>
          <button className="flex-1 bg-[#F1F5F9] text-[#1E3A8A] py-3 rounded-xl font-semibold hover:bg-[#E2E8F0] transition-colors">
            Отметить посещение
          </button>
        </div>
      </div>
    </SheetContent>
  );
}
