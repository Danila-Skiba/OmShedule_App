import 'package:flutter_test/flutter_test.dart';
import 'package:omstu_schedule/data/schedule_data.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await ScheduleData.load();
  });

  test('справочники загружаются из ассетов', () {
    expect(ScheduleData.isLoaded, isTrue);
    expect(ScheduleData.groups, isNotEmpty);
    expect(ScheduleData.persons, isNotEmpty);
    expect(ScheduleData.auditoriums, isNotEmpty);
  });

  test('карты «название → id» совпадают со списками', () {
    expect(ScheduleData.getgroups.length, ScheduleData.groups.length);
    expect(ScheduleData.getpersons.length, ScheduleData.persons.length);
    expect(ScheduleData.getauditorium.length, ScheduleData.auditoriums.length);
  });

  test('известные записи находятся по названию', () {
    expect(ScheduleData.getgroups['ФИТ-231'], '687');
    expect(ScheduleData.getpersons['ЗЫКИНА А.В.'], '573');
    expect(ScheduleData.getauditorium['8-101'], '186');
  });

  test('списки отсортированы по названию', () {
    final names = ScheduleData.groups.map((e) => e.name.toLowerCase()).toList();
    final sorted = [...names]..sort();
    expect(names, sorted);
  });

  test('у записей заполнены id, название и описание', () {
    for (final entry in [
      ScheduleData.groups.first,
      ScheduleData.persons.first,
      ScheduleData.auditoriums.first,
    ]) {
      expect(entry.id, isNotEmpty);
      expect(entry.name, isNotEmpty);
      expect(entry.desc, isNotEmpty);
    }
  });

  test('проверка наличия названия в справочнике', () {
    expect(ScheduleData.hasGroup('ФИТ-231'), isTrue);
    expect(ScheduleData.hasGroup('НЕТ-ТАКОЙ'), isFalse);
    expect(ScheduleData.hasGroup(null), isFalse);
    expect(ScheduleData.hasAuditorium('8-100'), isFalse); // удалена из справочника
  });
}
