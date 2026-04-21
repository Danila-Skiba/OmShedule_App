/// Данные о корпусах ОмГТУ: названия и адреса.
class BuildingInfo {
  final String name;
  final String address;

  const BuildingInfo({
    required this.name,
    required this.address,
  });
}

/// Карта корпусов ОмГТУ.
/// Ключ — префикс аудитории (первый символ или «ВК»).
class BuildingData {
  BuildingData._();

  static const Map<String, BuildingInfo> buildings = {
    'Г': BuildingInfo(name: 'Главный корпус', address: 'Проспект Мира, 11'),
    '1': BuildingInfo(name: 'УЛК-1', address: 'Проспект Мира, 11 к1'),
    '2': BuildingInfo(name: 'УЛК-2', address: 'Проспект Мира, 11 к2'),
    '3': BuildingInfo(name: 'УЛК-3', address: 'Долгирева, 79'),
    '4': BuildingInfo(name: 'УЛК-4', address: 'Долгирева, 79'),
    '5': BuildingInfo(name: 'УЛК-5', address: 'Проспект Мира, 32а'),
    '6': BuildingInfo(name: 'УЛК-6', address: 'Проспект Мира, 11 к6'),
    '7': BuildingInfo(name: 'УЛК-7', address: 'Проспект Мира, 30а'),
    '8': BuildingInfo(name: 'УЛК-8', address: 'Проспект Мира, 11 к8'),
    '9': BuildingInfo(name: 'УЛК-9', address: 'Нефтезаводская улица, 33Б'),
    '10': BuildingInfo(name: 'УЛК-10', address: 'Улица Химиков, 13'),
    '11': BuildingInfo(name: 'УЛК-11', address: 'Улица Химиков, 15'),
    '12': BuildingInfo(name: 'УЛК-12', address: 'Улица Звездная, 2Б'),
    '13': BuildingInfo(name: 'УЛК-13', address: 'Улица Певцова, 13'),
    '14': BuildingInfo(name: 'УЛК-14', address: 'Улица Красногвардейская, 9'),
    'ВК': BuildingInfo(name: 'Военно-учебный корпус', address: 'Долгирева, 79'),
  };

  /// Определяет корпус по названию аудитории.
  static BuildingInfo? findByAuditorium(String? auditorium) {
    if (auditorium == null || auditorium.isEmpty) return null;
    final trimmed = auditorium.trim();

    if (trimmed.toUpperCase().startsWith('ВК')) return buildings['ВК'];

    final multiDigit = RegExp(r'^(\d{2})').firstMatch(trimmed);
    if (multiDigit != null) {
      final key = multiDigit.group(1)!;
      if (buildings.containsKey(key)) return buildings[key];
    }

    final firstChar = trimmed[0].toUpperCase();
    if (buildings.containsKey(firstChar)) return buildings[firstChar];

    return null;
  }
}
