import '../models/lesson.dart';
import '../models/task.dart';
import '../models/news.dart';
import '../models/teacher.dart';
import '../models/building.dart';

/// Mock-данные
class MockData {
  static final List<Lesson> lessons = [
    const Lesson(
      id: '1',
      subject: 'Математический анализ',
      type: LessonType.lecture,
      teacher: 'Петров В.В.',
      room: '312',
      building: 'Корпус 3',
      timeStart: '08:30',
      timeEnd: '10:15',
      dayOfWeek: 1,
      status: LessonStatus.active,
    ),
    const Lesson(
      id: '2',
      subject: 'Физика',
      type: LessonType.lecture,
      teacher: 'Сидоров И.П.',
      room: '105',
      building: 'Корпус 1',
      timeStart: '11:00',
      timeEnd: '12:45',
      dayOfWeek: 1,
      status: LessonStatus.active,
    ),
    const Lesson(
      id: '3',
      subject: 'Программирование',
      type: LessonType.lab,
      teacher: 'Иванова А.С.',
      room: '204',
      building: 'Корпус 2',
      timeStart: '14:00',
      timeEnd: '15:45',
      dayOfWeek: 1,
      status: LessonStatus.active,
    ),
    const Lesson(
      id: '4',
      subject: 'Английский язык',
      type: LessonType.lecture,
      teacher: 'Смирнова О.Л.',
      room: '401',
      building: 'Корпус 4',
      timeStart: '08:30',
      timeEnd: '10:15',
      dayOfWeek: 2,
      status: LessonStatus.active,
    ),
    const Lesson(
      id: '5',
      subject: 'Базы данных',
      type: LessonType.lab,
      teacher: 'Козлов Д.А.',
      room: '215',
      building: 'Корпус 2',
      timeStart: '11:00',
      timeEnd: '12:45',
      dayOfWeek: 2,
      status: LessonStatus.active,
    ),
    const Lesson(
      id: '6',
      subject: 'Дискретная математика',
      type: LessonType.lecture,
      teacher: 'Новиков С.М.',
      room: '308',
      building: 'Корпус 3',
      timeStart: '08:30',
      timeEnd: '10:15',
      dayOfWeek: 3,
      status: LessonStatus.active,
    ),
  ];

  static final List<Task> tasks = [
    const Task(id: '1', title: 'Сдать лабу по матану', deadline: 'завтра', completed: false),
    const Task(id: '2', title: 'Подготовить доклад', deadline: '21 фев', completed: false),
    const Task(id: '3', title: 'Купить конспект', deadline: 'сегодня', completed: false),
    const Task(id: '4', title: 'Сдать отчет по физике', deadline: '18 фев', completed: true),
    const Task(id: '5', title: 'Решить задачи №12-18', deadline: '20 фев', completed: false),
    const Task(id: '6', title: 'Подготовиться к экзамену', deadline: '25 фев', completed: false),
    const Task(id: '7', title: 'Написать реферат', deadline: '22 фев', completed: true),
  ];

  static final List<News> news = [
    const News(
      id: '1',
      title: 'Учёные ОмГТУ открыли новый материал для квантовых компьютеров',
      date: '12.02',
      preview: 'Команда исследователей из лаборатории квантовой физики совершила прорыв...',
    ),
    const News(
      id: '2',
      title: 'Студенты ОмГТУ заняли первое место на хакатоне',
      date: '10.02',
      preview: 'Команда "Code Warriors" из группы ИУ5-31б победила в региональном...',
    ),
  ];

  static final List<Teacher> teachers = [
    const Teacher(id: '1', name: 'Петров В.В.', rating: 4.2, reviewCount: 127),
    const Teacher(id: '2', name: 'Сидоров И.П.', rating: 4.5, reviewCount: 89),
    const Teacher(id: '3', name: 'Иванова А.С.', rating: 4.8, reviewCount: 156),
  ];

  static final List<Building> buildings = [
    const Building(
      id: '1',
      name: 'Корпус 1',
      address: 'пр. Мира, 11',
      distance: '200м',
      walkTime: '3 мин',
      hasCafe: true,
    ),
    const Building(
      id: '2',
      name: 'Корпус 2',
      address: 'ул. Нефтезаводская, 54',
      distance: '450м',
      walkTime: '6 мин',
      hasCafe: false,
    ),
    const Building(
      id: '3',
      name: 'Корпус 3',
      address: 'ул. 5-я Линия, 1',
      distance: '350м',
      walkTime: '5 мин',
      hasCafe: true,
    ),
    const Building(
      id: '4',
      name: 'Корпус 4',
      address: 'пр. Карла Маркса, 35',
      distance: '600м',
      walkTime: '8 мин',
      hasCafe: true,
    ),
  ];
}
