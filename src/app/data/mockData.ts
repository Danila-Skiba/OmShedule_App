// Mock данные для приложения "Расписание ОмГТУ"

export interface Lesson {
  id: string;
  subject: string;
  type: 'lecture' | 'lab' | 'exam' | 'personal';
  teacher: string;
  room: string;
  building: string;
  timeStart: string;
  timeEnd: string;
  dayOfWeek: number; // 0-6
  date?: string;
  status?: 'active' | 'completed' | 'cancelled' | 'rescheduled';
}

export interface Task {
  id: string;
  title: string;
  deadline: string;
  completed: boolean;
}

export interface News {
  id: string;
  title: string;
  date: string;
  preview: string;
}

export interface Teacher {
  id: string;
  name: string;
  rating: number;
  reviewCount: number;
}

export const lessons: Lesson[] = [
  {
    id: '1',
    subject: 'Математический анализ',
    type: 'lecture',
    teacher: 'Петров В.В.',
    room: '312',
    building: 'Корпус 3',
    timeStart: '08:30',
    timeEnd: '10:15',
    dayOfWeek: 1,
    status: 'active',
  },
  {
    id: '2',
    subject: 'Физика',
    type: 'lecture',
    teacher: 'Сидоров И.П.',
    room: '105',
    building: 'Корпус 1',
    timeStart: '11:00',
    timeEnd: '12:45',
    dayOfWeek: 1,
    status: 'active',
  },
  {
    id: '3',
    subject: 'Программирование',
    type: 'lab',
    teacher: 'Иванова А.С.',
    room: '204',
    building: 'Корпус 2',
    timeStart: '14:00',
    timeEnd: '15:45',
    dayOfWeek: 1,
    status: 'active',
  },
  {
    id: '4',
    subject: 'Английский язык',
    type: 'lecture',
    teacher: 'Смирнова О.Л.',
    room: '401',
    building: 'Корпус 4',
    timeStart: '08:30',
    timeEnd: '10:15',
    dayOfWeek: 2,
    status: 'active',
  },
  {
    id: '5',
    subject: 'Базы данных',
    type: 'lab',
    teacher: 'Козлов Д.А.',
    room: '215',
    building: 'Корпус 2',
    timeStart: '11:00',
    timeEnd: '12:45',
    dayOfWeek: 2,
    status: 'active',
  },
  {
    id: '6',
    subject: 'Дискретная математика',
    type: 'lecture',
    teacher: 'Новиков С.М.',
    room: '308',
    building: 'Корпус 3',
    timeStart: '08:30',
    timeEnd: '10:15',
    dayOfWeek: 3,
    status: 'active',
  },
];

export const tasks: Task[] = [
  { id: '1', title: 'Сдать лабу по матану', deadline: 'завтра', completed: false },
  { id: '2', title: 'Подготовить доклад', deadline: '21 фев', completed: false },
  { id: '3', title: 'Купить конспект', deadline: 'сегодня', completed: false },
  { id: '4', title: 'Сдать отчет по физике', deadline: '18 фев', completed: true },
  { id: '5', title: 'Решить задачи №12-18', deadline: '20 фев', completed: false },
  { id: '6', title: 'Подготовиться к экзамену', deadline: '25 фев', completed: false },
  { id: '7', title: 'Написать реферат', deadline: '22 фев', completed: true },
];

export const news: News[] = [
  {
    id: '1',
    title: 'Учёные ОмГТУ открыли новый материал для квантовых компьютеров',
    date: '12.02',
    preview: 'Команда исследователей из лаборатории квантовой физики совершила прорыв...',
  },
  {
    id: '2',
    title: 'Студенты ОмГТУ заняли первое место на хакатоне',
    date: '10.02',
    preview: 'Команда "Code Warriors" из группы ИУ5-31б победила в региональном...',
  },
];

export const teachers: Teacher[] = [
  { id: '1', name: 'Петров В.В.', rating: 4.2, reviewCount: 127 },
  { id: '2', name: 'Сидоров И.П.', rating: 4.5, reviewCount: 89 },
  { id: '3', name: 'Иванова А.С.', rating: 4.8, reviewCount: 156 },
];

export const buildings = [
  {
    id: '1',
    name: 'Корпус 1',
    address: 'пр. Мира, 11',
    distance: '200м',
    walkTime: '3 мин',
    hasCafe: true,
  },
  {
    id: '2',
    name: 'Корпус 2',
    address: 'ул. Нефтезаводская, 54',
    distance: '450м',
    walkTime: '6 мин',
    hasCafe: false,
  },
  {
    id: '3',
    name: 'Корпус 3',
    address: 'ул. 5-я Линия, 1',
    distance: '350м',
    walkTime: '5 мин',
    hasCafe: true,
  },
  {
    id: '4',
    name: 'Корпус 4',
    address: 'пр. Карла Маркса, 35',
    distance: '600м',
    walkTime: '8 мин',
    hasCafe: true,
  },
];
