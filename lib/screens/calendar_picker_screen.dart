import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';

import '../constants/app_constants.dart';
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

  @override
  void initState() {
    super.initState();
    final init = widget.initialDate ?? DateTime.now();
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
      appBar: AppBar(
        title: const Text('Выбор даты'),
        leading: IconButton(
          icon: const Icon(Icons.close),
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

              
              firstDay: DateTime(DateTime.now().year, DateTime.now().month - 2, 1),
              lastDay: DateTime(DateTime.now().year, DateTime.now().month + 3, 31),
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
              child: TextButton(
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
              )
          ],
        ),
      ),
    );
  }
}
