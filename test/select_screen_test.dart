import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omstu_schedule/models/schedule_entry.dart';
import 'package:omstu_schedule/screens/select_screen.dart';

const _items = [
  ScheduleEntry(
    id: '687',
    name: 'ФИТ-231',
    desc: 'Факультет информационных технологий и компьютерных систем | Дневная',
  ),
  ScheduleEntry(
    id: '483',
    name: 'МО-221',
    desc: 'Факультет информационных технологий и компьютерных систем | Дневная',
  ),
  ScheduleEntry(
    id: '999',
    name: 'РЭ-211',
    desc: 'Радиотехнический факультет | Заочная',
  ),
];

Widget _wrap(Widget child) => MaterialApp(home: child);

void main() {
  testWidgets('показывает название и описание записи', (tester) async {
    await tester.pumpWidget(_wrap(
      const SelectScreen(
        type: SelectType.group,
        title: 'Выберите группу',
        items: _items,
      ),
    ));

    expect(find.text('ФИТ-231'), findsOneWidget);
    expect(find.text('Радиотехнический факультет | Заочная'), findsOneWidget);
  });

  testWidgets('поиск работает и по названию, и по описанию', (tester) async {
    await tester.pumpWidget(_wrap(
      const SelectScreen(
        type: SelectType.group,
        title: 'Выберите группу',
        items: _items,
      ),
    ));

    await tester.enterText(find.byType(EditableText), 'радиотех');
    await tester.pumpAndSettle();

    expect(find.text('РЭ-211'), findsOneWidget);
    expect(find.text('ФИТ-231'), findsNothing);
    expect(find.text('Найдено: 1'), findsOneWidget);

    await tester.enterText(find.byType(EditableText), 'мо-2');
    await tester.pumpAndSettle();

    expect(find.text('МО-221'), findsOneWidget);
    expect(find.text('РЭ-211'), findsNothing);
  });

  testWidgets('возвращает название выбранной записи', (tester) async {
    String? result;
    await tester.pumpWidget(_wrap(
      Builder(
        builder: (context) => ElevatedButton(
          onPressed: () async {
            result = await Navigator.of(context).push<String?>(
              MaterialPageRoute(
                builder: (_) => const SelectScreen(
                  type: SelectType.group,
                  title: 'Выберите группу',
                  items: _items,
                ),
              ),
            );
          },
          child: const Text('open'),
        ),
      ),
    ));

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('МО-221'));
    await tester.pumpAndSettle();

    expect(result, 'МО-221');
  });
}
