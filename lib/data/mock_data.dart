import '../models/building.dart';


//Временные тестовые данные новостей и корпусов омгту
class MockData {

  // // static final List<News> news = [
  // //   const News(
  // //     id: '1',
  // //     title: 'Учёные ОмГТУ открыли новый материал для квантовых компьютеров',
  // //     date: '12.02',
  // //     preview: 'Команда исследователей из лаборатории квантовой физики совершила прорыв...',
  // //   ),
  // //   const News(
  // //     id: '2',
  // //     title: 'Студенты ОмГТУ заняли первое место на хакатоне',
  // //     date: '10.02',
  // //     preview: 'Команда "Code Warriors" из группы ИУ5-31б победила в региональном...',
  // //   ),
  // ];
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
