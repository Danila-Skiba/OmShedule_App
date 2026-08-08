import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/services/task_service.dart';
import '../core/utils/platform_utils.dart';
import '../models/personal_task.dart';
import '../ui/adaptive/adaptive_exports.dart';
import 'calendar_picker_screen.dart';

/// Полноценная страница добавления / редактирования личной задачи.
/// Поля: Название, Время (CupertinoPicker), Описание.
class AddTaskScreen extends StatefulWidget {
  final DateTime forDate;
  final VoidCallback onSaved;

  /// Если передана — режим редактирования.
  final PersonalTask? existingTask;

  const AddTaskScreen({
    super.key,
    required this.forDate,
    required this.onSaved,
    this.existingTask,
  });

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  final _titleFocus = FocusNode();
  final _descriptionFocus = FocusNode();

  /// Ключи полей — по ним экран подкручивается к тому, что получило фокус.
  final _titleKey = GlobalKey();
  final _descriptionKey = GlobalKey();

  int _selectedHour = 8;
  int _selectedMinute = 0;
  bool _saving = false;

  /// Хоть одно поле в фокусе — значит открыта клавиатура и нужна панель
  /// «Готово». Считаем по фокусу, а не по `viewInsets`: инсет обнуляется лишь
  /// в конце анимации закрытия, и панель заметно «догоняла» уезжающую
  /// клавиатуру, а потом пропадала рывком.
  bool get _editing => _titleFocus.hasFocus || _descriptionFocus.hasFocus;

  /// Дата задачи. Приходит с экрана, но её можно поменять прямо здесь.
  late DateTime _selectedDate;

  bool get _isEditing => widget.existingTask != null;

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  static String _formatDate(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  static const _monthNames = [
    'января', 'февраля', 'марта', 'апреля', 'мая', 'июня',
    'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря',
  ];

  String get _formattedDateLabel {
    final d = _selectedDate;
    return '${d.day} ${_monthNames[d.month - 1]} ${d.year}';
  }

  String get _formattedTime =>
      '${_selectedHour.toString().padLeft(2, '0')}:${_selectedMinute.toString().padLeft(2, '0')}';

  @override
  void initState() {
    super.initState();
    _selectedDate = _dateOnly(widget.forDate);
    final t = widget.existingTask;
    if (t != null) {
      // У задачи в редактировании своя дата — она главнее переданной экраном.
      final parsed = DateTime.tryParse(t.date);
      if (parsed != null) _selectedDate = _dateOnly(parsed);
      _titleController.text = t.title;
      _descriptionController.text = t.audience ?? '';
      final parts = t.time.split(':');
      if (parts.length == 2) {
        _selectedHour = int.tryParse(parts[0]) ?? 8;
        _selectedMinute = int.tryParse(parts[1]) ?? 0;
      }
    }

    // Панель «Готово» появляется и исчезает вместе с фокусом.
    _titleFocus.addListener(_onFocusChanged);
    _descriptionFocus.addListener(_onFocusChanged);
  }

  void _onFocusChanged() {
    if (!mounted) return;
    setState(() {});

    // Описание — последнее поле формы, и на невысоком экране клавиатура его
    // полностью накрывала: приходилось скроллить вслепую. Подкручиваем экран
    // к тому полю, что получило фокус, когда клавиатура уже поднялась и
    // каркас ужал содержимое.
    final key = _titleFocus.hasFocus
        ? _titleKey
        : _descriptionFocus.hasFocus
            ? _descriptionKey
            : null;
    if (key == null) return;

    // Две попытки: клавиатура поднимается не мгновенно, и первая прокрутка
    // считается по ещё не ужатому вьюпорту. Вторая доводит поле до конца.
    for (final delay in const [Duration(milliseconds: 300), Duration(milliseconds: 650)]) {
      Future<void>.delayed(delay, () {
        if (!mounted) return;
        final fieldContext = key.currentContext;
        if (fieldContext == null || !fieldContext.mounted) return;
        Scrollable.ensureVisible(
          fieldContext,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          // Прокручиваем ровно настолько, чтобы поле целиком оказалось над
          // клавиатурой, — и ни строкой больше.
          alignment: 1,
          alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
        );
      });
    }
  }

  /// Выбор даты тем же календарём, что и на экране расписания.
  ///
  /// Раньше здесь были системные пикеры (колесо на iOS, `showDatePicker` на
  /// Android) — два разных вида выбора даты в одном приложении. Диапазон дат
  /// задаёт сам [CalendarPickerScreen], поэтому он совпадает с расписанием.
  Future<void> _pickDate() async {
    FocusScope.of(context).unfocus();

    final picked = await Navigator.of(context).push<DateTime>(
      buildRoute<DateTime>(CalendarPickerScreen(initialDate: _selectedDate)),
    );

    if (picked == null || !mounted) return;
    setState(() => _selectedDate = _dateOnly(picked));
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      AppSnackBar.show(context, message: 'Введите название задачи');
      return;
    }

    setState(() => _saving = true);

    final task = PersonalTask(
      id: widget.existingTask?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      time: _formattedTime,
      audience: _descriptionController.text.trim().isNotEmpty
          ? _descriptionController.text.trim()
          : null,
      date: _formatDate(_selectedDate),
      createdAt:
          widget.existingTask?.createdAt ?? DateTime.now().toIso8601String(),
      completed: widget.existingTask?.completed ?? false,
    );

    try {
      await TaskService.instance.saveTask(task);
      if (mounted) {
        widget.onSaved();
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        AppSnackBar.error(context, 'Ошибка сохранения: $e');
      }
    }
  }

  @override
  void dispose() {
    _titleFocus.removeListener(_onFocusChanged);
    _descriptionFocus.removeListener(_onFocusChanged);
    _titleFocus.dispose();
    _descriptionFocus.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AppScaffold(
      appBar: AppAppBar(
        title: _isEditing ? 'Редактировать' : 'Новая задача',
        useNativeToolbar: true,
        leading: const AppToolbarLeading.close(),
      ),
      // Отступ под клавиатуру делает сам каркас, а панель «Готово» — просто
      // последний элемент колонки. Так она едет ровно с клавиатурой: раньше
      // панель позиционировалась по `viewInsets` вручную и отставала.
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
            // Дата — нажимается, открывает выбор даты
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _pickDate,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : theme.colorScheme.primary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 18,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _formattedDateLabel,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.expand_more_rounded,
                      size: 20,
                      color: theme.colorScheme.primary
                          .withValues(alpha: 0.7),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Название
            Text(
              'Название',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 8),
            isIOS // iOS
                ? CupertinoTextField(
                    key: _titleKey,
                    controller: _titleController,
                    focusNode: _titleFocus,
                    textCapitalization: TextCapitalization.sentences,
                    // Название однострочное — «Готово» на клавиатуре само
                    // закрывает ввод, панель для него нужна лишь как запасной
                    // путь.
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => FocusScope.of(context).unfocus(),
                    placeholder: 'Встреча, задача, напоминание...',
                    style: theme.textTheme.bodyLarge,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.06)
                          : CupertinoColors.tertiarySystemBackground,
                      borderRadius: BorderRadius.circular(14),
                    ),
                  )
                : TextField(
                    key: _titleKey,
                    controller: _titleController,
                    focusNode: _titleFocus,
                    textCapitalization: TextCapitalization.sentences,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => FocusScope.of(context).unfocus(),
                    style: theme.textTheme.bodyLarge,
                    decoration: InputDecoration(
                      hintText: 'Встреча, задача, напоминание...',
                      filled: true,
                      fillColor: isDark
                          ? Colors.white.withValues(alpha: 0.06)
                          : Colors.grey.withValues(alpha: 0.06),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: theme.colorScheme.primary.withValues(alpha: 0.5),
                          width: 1.5,
                        ),
                      ),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),

            const SizedBox(height: 24),

            // Время
            Text(
              'Время',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 180,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.04)
                    : Colors.grey.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(16),
              ),
              child: CupertinoTimerPicker(
                mode: CupertinoTimerPickerMode.hm,
                initialTimerDuration: Duration(
                  hours: _selectedHour,
                  minutes: _selectedMinute,
                ),
                onTimerDurationChanged: (Duration duration) {
                  setState(() {
                    _selectedHour = duration.inHours;
                    _selectedMinute = duration.inMinutes % 60;
                  });
                },
              ),
            ),

            const SizedBox(height: 24),

            // Описание
            Text(
              'Описание',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 8),
            isIOS // iOS
                ? CupertinoTextField(
                    key: _descriptionKey,
                    controller: _descriptionController,
                    focusNode: _descriptionFocus,
                    textCapitalization: TextCapitalization.sentences,
                    maxLines: 4,
                    placeholder: 'Дополнительные детали...',
                    style: theme.textTheme.bodyLarge,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.06)
                          : CupertinoColors.tertiarySystemBackground,
                      borderRadius: BorderRadius.circular(14),
                    ),
                  )
                : TextField(
                    key: _descriptionKey,
                    controller: _descriptionController,
                    focusNode: _descriptionFocus,
                    textCapitalization: TextCapitalization.sentences,
                    maxLines: 4,
                    style: theme.textTheme.bodyLarge,
                    decoration: InputDecoration(
                      hintText: 'Дополнительные детали...',
                      filled: true,
                      fillColor: isDark
                          ? Colors.white.withValues(alpha: 0.06)
                          : Colors.grey.withValues(alpha: 0.06),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: theme.colorScheme.primary.withValues(alpha: 0.5),
                          width: 1.5,
                        ),
                      ),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),

            const SizedBox(height: 32),

            // Кнопка сохранения // iOS
            SizedBox(
              width: double.infinity,
              height: 50,
              child: isIOS
                  ? CupertinoButton(
                      onPressed: _saving ? null : _save,
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(14),
                      padding: EdgeInsets.zero,
                      child: _saving
                          ? buildSmallLoader(color: CupertinoColors.white)
                          : Text(
                              _isEditing ? 'Сохранить изменения' : 'Добавить задачу',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: CupertinoColors.white),
                            ),
                    )
                  : ElevatedButton(
                      onPressed: _saving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: _saving
                          ? buildSmallLoader(color: Colors.white)
                          : Text(
                              _isEditing ? 'Сохранить изменения' : 'Добавить задачу',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
            ),

            // Отступ для bottom navigation bar
            SizedBox(height: MediaQuery.of(context).padding.bottom + 100),
                ],
              ),
            ),
          ),

          // Панель «Готово» над клавиатурой.
          //
          // У описания несколько строк, и клавиатурная клавиша возврата там
          // переносит строку, а не закрывает ввод, — выйти из поля было
          // нечем. Панель решает это для обоих полей сразу и повторяет
          // привычный на iOS accessory bar над клавиатурой.
          if (_editing)
            _KeyboardDoneBar(
              onDone: () => FocusScope.of(context).unfocus(),
            ),
        ],
      ),
    );
  }
}

/// Высота панели «Готово».
const double _doneBarHeight = 44;

/// Панель над клавиатурой с единственной кнопкой «Готово».
class _KeyboardDoneBar extends StatelessWidget {
  const _KeyboardDoneBar({required this.onDone});

  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: _doneBarHeight,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7),
        border: Border(
          top: BorderSide(color: theme.dividerColor.withValues(alpha: 0.6)),
        ),
      ),
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: CupertinoButton(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        minimumSize: Size.zero,
        onPressed: () {
          HapticFeedback.lightImpact();
          onDone();
        },
        child: Text(
          'Готово',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.primary,
          ),
        ),
      ),
    );
  }
}
