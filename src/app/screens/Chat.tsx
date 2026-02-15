import { useState } from "react";
import { Send, Mic, Bot, User } from "lucide-react";

interface Message {
  id: string;
  text: string;
  sender: "user" | "bot";
  timestamp: string;
}

export default function Chat() {
  const [messages, setMessages] = useState<Message[]>([
    {
      id: "1",
      text: "Привет! Я помощник ОмГТУ на базе Gigachat. Чем могу помочь?",
      sender: "bot",
      timestamp: new Date().toLocaleTimeString("ru-RU", {
        hour: "2-digit",
        minute: "2-digit",
      }),
    },
  ]);
  const [input, setInput] = useState("");

  const quickPrompts = [
    "Составь план на неделю",
    "Что задали по матану?",
    "Расскажи про Петрова",
    "Где ближайшее кафе?",
  ];

  const handleSend = () => {
    if (!input.trim()) return;

    const userMessage: Message = {
      id: Date.now().toString(),
      text: input,
      sender: "user",
      timestamp: new Date().toLocaleTimeString("ru-RU", {
        hour: "2-digit",
        minute: "2-digit",
      }),
    };

    setMessages((prev) => [...prev, userMessage]);
    setInput("");

    // Simulate bot response
    setTimeout(() => {
      const botMessage: Message = {
        id: (Date.now() + 1).toString(),
        text: getBotResponse(input),
        sender: "bot",
        timestamp: new Date().toLocaleTimeString("ru-RU", {
          hour: "2-digit",
          minute: "2-digit",
        }),
      };
      setMessages((prev) => [...prev, botMessage]);
    }, 1000);
  };

  const handleQuickPrompt = (prompt: string) => {
    setInput(prompt);
  };

  const getBotResponse = (userInput: string): string => {
    const lower = userInput.toLowerCase();
    if (lower.includes("план") || lower.includes("неделю")) {
      return "📅 Вот твой план на неделю:\n\n• ПН: Математический анализ (08:30), Физика (11:00)\n• ВТ: Английский язык (08:30), Базы данных (11:00)\n• СР: Дискретная математика (08:30)\n\nНе забудь сдать лабу по матану до завтра!";
    }
    if (lower.includes("матан") || lower.includes("математик")) {
      return "📚 По математическому анализу:\n• Лабораторная работа №3 - сдать завтра\n• Подготовиться к семинару по теме \"Интегралы\"\n• Решить задачи №12-18 из учебника";
    }
    if (lower.includes("петров")) {
      return "👨‍🏫 Петров Владимир Владимирович:\n• Рейтинг: 4.2/5.0 (127 отзывов)\n• Предмет: Математический анализ\n• Кабинет: 312, Корпус 3\n• Студенты отмечают: строгий, но справедливый преподаватель";
    }
    if (lower.includes("кафе") || lower.includes("столовая")) {
      return "☕ Ближайшие места:\n\n1. Столовая ОмГТУ - 50м, 1 мин\n   ⭐ 4.5 (234 отзыва)\n\n2. Кофейня \"Энергия\" - 120м, 2 мин\n   ⭐ 4.8 (89 отзывов)\n\nОбе работают с 08:00 до 18:00";
    }
    return "Понял твой запрос! Я помогу с расписанием, задачами, информацией о преподавателях и навигацией по университету. Задай более конкретный вопрос 😊";
  };

  return (
    <div className="h-screen bg-[#F8FAFC] flex flex-col">
      {/* Header */}
      <header className="bg-gradient-to-r from-[#1E3A8A] to-[#3B82F6] text-white p-4 shadow-md flex-shrink-0">
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 bg-white/20 rounded-full flex items-center justify-center backdrop-blur-sm">
            <Bot className="w-6 h-6" />
          </div>
          <div>
            <h1 className="text-lg font-bold">Помощник Gigachat</h1>
            <div className="flex items-center gap-2">
              <div className="w-2 h-2 bg-[#10B981] rounded-full animate-pulse"></div>
              <p className="text-xs opacity-90">Онлайн</p>
            </div>
          </div>
        </div>
      </header>

      {/* Messages */}
      <div className="flex-1 overflow-y-auto p-4 space-y-4">
        {messages.map((message) => (
          <div
            key={message.id}
            className={`flex gap-3 ${message.sender === "user" ? "flex-row-reverse" : ""}`}
          >
            <div
              className={`w-8 h-8 rounded-full flex items-center justify-center flex-shrink-0 ${
                message.sender === "bot"
                  ? "bg-gradient-to-br from-[#3B82F6] to-[#1E3A8A]"
                  : "bg-gradient-to-br from-[#10B981] to-[#059669]"
              }`}
            >
              {message.sender === "bot" ? (
                <Bot className="w-5 h-5 text-white" />
              ) : (
                <User className="w-5 h-5 text-white" />
              )}
            </div>

            <div
              className={`flex-1 max-w-[75%] ${
                message.sender === "user" ? "flex flex-col items-end" : ""
              }`}
            >
              <div
                className={`rounded-2xl p-4 shadow-sm ${
                  message.sender === "bot"
                    ? "bg-white border border-[#E2E8F0] rounded-tl-sm"
                    : "bg-[#3B82F6] text-white rounded-tr-sm"
                }`}
              >
                <p
                  className={`text-sm whitespace-pre-line ${
                    message.sender === "bot" ? "text-[#1E293B]" : "text-white"
                  }`}
                >
                  {message.text}
                </p>
              </div>
              <span className="text-xs text-[#64748B] mt-1 px-2">{message.timestamp}</span>
            </div>
          </div>
        ))}
      </div>

      {/* Quick Prompts */}
      {messages.length <= 1 && (
        <div className="px-4 pb-3">
          <p className="text-xs text-[#64748B] mb-2 px-1">Быстрые команды:</p>
          <div className="flex flex-wrap gap-2">
            {quickPrompts.map((prompt) => (
              <button
                key={prompt}
                onClick={() => handleQuickPrompt(prompt)}
                className="px-4 py-2 bg-white text-[#1E3A8A] text-sm font-medium rounded-full border border-[#E2E8F0] hover:bg-[#F8FAFC] hover:border-[#3B82F6] transition-all shadow-sm"
              >
                {prompt}
              </button>
            ))}
          </div>
        </div>
      )}

      {/* Input */}
      <div className="bg-white border-t border-[#E2E8F0] p-4 flex-shrink-0">
        <div className="flex items-center gap-2">
          <div className="flex-1 flex items-center gap-2 bg-[#F8FAFC] rounded-2xl px-4 py-3 border border-[#E2E8F0] focus-within:border-[#3B82F6] transition-colors">
            <input
              type="text"
              value={input}
              onChange={(e) => setInput(e.target.value)}
              onKeyPress={(e) => e.key === "Enter" && handleSend()}
              placeholder="Напиши сообщение..."
              className="flex-1 bg-transparent outline-none text-sm text-[#1E293B] placeholder:text-[#94A3B8]"
            />
            <button className="p-2 hover:bg-[#E2E8F0] rounded-full transition-colors">
              <Mic className="w-5 h-5 text-[#64748B]" />
            </button>
          </div>
          <button
            onClick={handleSend}
            disabled={!input.trim()}
            className={`w-12 h-12 rounded-full flex items-center justify-center transition-all shadow-md ${
              input.trim()
                ? "bg-[#3B82F6] hover:bg-[#1E3A8A] active:scale-90"
                : "bg-[#CBD5E1] cursor-not-allowed"
            }`}
          >
            <Send className="w-5 h-5 text-white" />
          </button>
        </div>
      </div>
    </div>
  );
}
