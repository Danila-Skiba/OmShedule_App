import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';

import '../constants/app_constants.dart';
import '../core/utils/platform_utils.dart';
import '../core/utils/week_service.dart';

/// Экран выбора даты через календарь.
/// При выборе даты возвращает [DateTime] через Navigator.pop(context, selectedDate).
class CalendarPickerScreen extends StatefulWidget {
  /// Начальная дата для выделения в календаре.
  final DateTime? initialDate;

  const CalendarPickerScreen({super.key, this.initialDate});

  @override
  State<CalendarPickerScreen> createState() => _CalendarPickerScreenState();
}

class _CalendarPickerScreenState extends State<CalendarPickerScreen> {
  late DateTime _focusedDay;
  DateTime? _selectedDay;
  late final DateTime _firstDay;
  late final DateTime _lastDay;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final init = widget.initialDate ?? now;

    // Окно календаря должно включать и сегодня, и выбранную в расписании дату
    // (расписание можно листать сколь угодно далеко). Иначе focusedDay выйдет
    // за пределы [firstDay, lastDay] и TableCalendar упадёт на ассерте.
    final lower = init.isBefore(now) ? init : now;
    final upper = init.isAfter(now) ? init : now;
    _firstDay = DateTime(lower.year, lower.month - 2, 1);
    _lastDay = DateTime(upper.year, upper.month + 4, 0); // последний день (месяц + 3)

    _focusedDay = init;
    _selectedDay = init;
  }

  void _onDaySelected(DateTime selected, DateTime focused) {
    if (!WeekService.isValidDate(selected)) return;
    setState(() {
      _selectedDay = selected;
      _focusedDay = focused;
    });
  }

  void _onConfirm() {
    if (_selectedDay != null) {
      context.pop<DateTime>(_selectedDay);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: buildAppBar( // iOS
        context: context,
        title: 'Выбор даты',
        leading: IconButton(
          icon: Icon(isIOS ? CupertinoIcons.xmark : Icons.close), // iOS
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            TableCalendar<dynamic>(
              daysOfWeekStyle: DaysOfWeekStyle(
                weekdayStyle: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600
                ),
                weekendStyle: TextStyle(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w600
                ),
              ),

              
              firstDay: _firstDay,
              lastDay: _lastDay,
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) =>
                  _selectedDay != null &&
                  isSameDay(_selectedDay, day),
              onDaySelected: _onDaySelected,
              calendarFormat: CalendarFormat.month,
              startingDayOfWeek: StartingDayOfWeek.monday,
              locale: 'ru',
              headerStyle: HeaderStyle(
                titleTextStyle: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
                formatButtonVisible: false,
                titleCentered: true,
                leftChevronIcon: const Icon(Icons.chevron_left),
                rightChevronIcon: const Icon(Icons.chevron_right),
              ),
              calendarStyle: CalendarStyle(
                selectedDecoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                todayDecoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                weekendTextStyle: TextStyle(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppConstants.spacingLg),
              child: SizedBox( // iOS
                width: double.infinity,
                height: 48,
                child: isIOS
                    ? CupertinoButton(
                        onPressed: _onConfirm,
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(AppConstants.radiusMd),
                        padding: EdgeInsets.zero,
                        child: const Text('Выбрать дату', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: CupertinoColors.white)),
                      )
                    : TextButton(
                        onPressed: _onConfirm,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppConstants.radiusMd),
                          ),
                        ),
                        child: Text(
                          'Выбрать дату',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
