import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:omstu_schedule/core/services/schedule_cache_service.dart';
import 'package:omstu_schedule/core/utils/week_service.dart';
import 'package:omstu_schedule/widgets/base_container.dart';
import 'package:omstu_schedule/data/schedule_data.dart';
import '../constants/app_colors.dart';
import '../core/services/settings_service.dart';
import '../core/services/task_service.dart';
import '../core/state/filter_controller.dart';
import '../core/state/schedule_week_controller.dart';
import '../core/utils/platform_utils.dart';
import '../data/building_data.dart';
import '../models/lesson.dart';
import '../models/personal_task.dart';
import '../models/schedule_type.dart';
import '../widgets/personal_task_card.dart';
import '../ui/adaptive/adaptive_exports.dart';
import '../widgets/app_dialog.dart';
import 'add_task_screen.dart';

// ---------------------------------------------------------------------------
// Бесконечный PageView: 7001 страниц, середина = 3500
// ---------------------------------------------------------------------------
const int _kMidPage = 3500;
const int _kTotalDayPages = 7001;

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

/// Хранит сессионное состояние расписания (сохраняется при переходах между вкладками).
class _SessionState {
  static String view = 'today';
  static DateTime? selectedDate;
  static int? selectedDayIndex;
  static bool filterBarVisible = false;
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  String _view = _SessionState.view;

  late FilterController _filterController;
  late ScheduleWeekController _weekController;
  List<PersonalTask> _tasks = [];

  /// Опорный день (нормализованный до 00:00) — page kMidPage соответствует этому дню.
  late DateTime _refDay;

  late PageController _dayPageController;
  bool _isPageAnimating = false;
  int _weekSwipeKey = 0; // ключ для AnimatedSwitcher при смене недели

  /// Куда «уехала» полоска дней в последний раз: 1 — вперёд, -1 — назад.
  /// От этого зависит, с какой стороны въезжает новая неделя.
  int _stripDirection = 1;

  /// Страница-«мостик» на время перехода между неделями и дата, которую она
  /// показывает вместо своей. Подробности — в [_shiftWeekKeepingWeekday].
  int? _bridgePage;
  DateTime? _bridgeDate;

  // Текущие значения фильтра (дублируем для передачи в cache/week queries)
  String? _filterGroupIds;
  String? _filterTeacherNames;
  String? _filterRoomIds;

  // Показ/скрытие панели фильтров по кнопке
  bool _filterBarVisible = _SessionState.filterBarVisible;

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  ScheduleType get currentScheduleType {
    final ft = _filterController.currentFilterType.value;
    if (ft == FilterType.group) return ScheduleType.group;
    if (ft == FilterType.teacher) return ScheduleType.teacher;
    if (ft == FilterType.audience) return ScheduleType.audience;
    return ScheduleType.group;
  }

  DateTime _dateForPage(int page) {
    final offset = page - _kMidPage;
    return _refDay.add(Duration(days: offset));
  }

  int _pageForDate(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    return _kMidPage + d.difference(_refDay).inDays;
  }

  /// Дата, которую страница показывает на самом деле.
  ///
  /// Отличается от [_dateForPage] только у страницы-«мостика», пока идёт
  /// переход между неделями.
  DateTime _visibleDateForPage(int page) {
    final bridgeDate = _bridgeDate;
    if (bridgeDate != null && page == _bridgePage) return bridgeDate;
    return _dateForPage(page);
  }

  int get _currentDayPage => _pageForDate(_weekController.selectedDate);

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();
    _refDay = DateTime(now.year, now.month, now.day);

    _filterController = FilterController();
    _applyDefaultsFromProfile();
    _filterController.addListener(_onFilterChanged);

    // Восстанавливаем сессионную дату, если есть
    final restoreDate = _SessionState.selectedDate;

    // Создаём контроллер с уже известными фильтрами — одна загрузка.
    _weekController = ScheduleWeekController(
      initialDate: restoreDate,
      initialGroupIds: _filterGroupIds,
      initialTeacherNames: _filterTeacherNames,
      initialRoomIds: _filterRoomIds,
    );

    // Если текущий режим — «Личное», сразу ставим personalMode
    if (_filterController.isPersonal) {
      _weekController.setPersonalMode(true);
    }

    // Восстанавливаем выбранный день
    if (_SessionState.selectedDayIndex != null) {
      _weekController.selectDay(_SessionState.selectedDayIndex!);
    }

    _weekController.addListener(_onWeekControllerChanged);
    TaskService.instance.addListener(_onTasksChanged);
    _loadTasks();

    final initialPage = restoreDate != null
        ? _pageForDate(restoreDate)
        : _kMidPage;
    _dayPageController = PageController(initialPage: initialPage);
  }

  @override
  void dispose() {
    // Сохраняем сессионное состояние
    _SessionState.view = _view;
    _SessionState.selectedDate = _weekController.selectedDate;
    _SessionState.selectedDayIndex = _weekController.selectedDayIndex;

    TaskService.instance.removeListener(_onTasksChanged);
    _filterController.removeListener(_onFilterChanged);
    _filterController.dispose();
    _weekController.removeListener(_onWeekControllerChanged);
    _weekController.dispose();
    _dayPageController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Event handlers
  // ---------------------------------------------------------------------------

  void _onFilterChanged() => setState(() {});

  void _onTasksChanged() {
    if (_filterController.isPersonal && mounted) _loadTasks();
  }

  void _onWeekControllerChanged() {
    if (!mounted) return;
    setState(() {});
    _loadTasks();
    // Синхронизируем PageController с выбранным днём (только если не свайп)
    if (_dayPageController.hasClients && !_isPageAnimating) {
      final target = _currentDayPage;
      if ((_dayPageController.page?.round() ?? -1) != target) {
        _dayPageController.jumpToPage(target);
      }
    }
  }

  Future<void> _loadTasks() async {
    if (!mounted) return;
    final week = _weekController.currentWeek;
    final tasks = await TaskService.instance.getTasksForPeriod(
      week.startDate,
      week.endDate,
    );
    if (mounted) setState(() => _tasks = tasks);
  }

  // ---------------------------------------------------------------------------
  // Фильтры
  // ---------------------------------------------------------------------------

  /// Возвращает название, только если оно есть в актуальном справочнике.
  static String? _validGroup(String? name) =>
      ScheduleData.hasGroup(name) ? name : null;

  static String? _validTeacher(String? name) =>
      ScheduleData.hasPerson(name) ? name : null;

  static String? _validAudience(String? name) =>
      ScheduleData.hasAuditorium(name) ? name : null;

  void _applyDefaultsFromProfile() {
    // Восстанавливаем все сохранённые значения фильтров.
    // Справочники обновляются, поэтому сохранённые названия проверяем:
    // отсутствующие в справочнике считаем несохранёнными.
    final savedType = SettingsService.getLastFilterType();
    final savedGroup = _validGroup(SettingsService.getLastGroupId());
    final savedTeacher = _validTeacher(SettingsService.getLastTeacherId());
    final savedAudience = _validAudience(SettingsService.getLastAudienceId());

    final role = SettingsService.getProfileRole();

    // Всегда восстанавливаем ВСЕ фильтры из памяти
    final group = savedGroup ??
        (role == 'student'
            ? ScheduleData.firstGroupName
            : _validGroup(SettingsService.getDefaultGroupId()));
    _filterController.updateGroup(group);

    final teacher = savedTeacher ??
        _validTeacher(SettingsService.getDefaultTeacherId()) ??
        ScheduleData.firstPersonName;
    _filterController.updateTeacher(teacher);

    if (savedAudience != null) {
      _filterController.updateAudience(savedAudience);
    }

    // Определяем активный тип фильтра
    FilterType ft;
    switch (savedType) {
      case 'teacher':
        ft = FilterType.teacher;
        break;
      case 'audience':
        ft = FilterType.audience;
        break;
      case 'personal':
        ft = FilterType.personal;
        break;
      default:
        ft = FilterType.group;
    }

    // Если вообще ничего не сохранено — дефолт по роли
    if (savedGroup == null && savedTeacher == null && savedAudience == null) {
      ft = role == 'student' ? FilterType.group : FilterType.teacher;
    }

    _filterController.setFilterType(ft);

    // Устанавливаем активные фильтры для загрузки расписания
    switch (ft) {
      case FilterType.group:
        _filterGroupIds = _filterController.selectedGroup.value;
        break;
      case FilterType.teacher:
        _filterTeacherNames = _filterController.selectedTeacher.value;
        break;
      case FilterType.audience:
        _filterRoomIds = _filterController.selectedAudience.value;
        break;
      case FilterType.personal:
        break;
    }
  }

  void _syncFiltersToController() {
    final ft = _filterController.currentFilterType.value;
    final isPersonal = ft == FilterType.personal;
    _weekController.setPersonalMode(isPersonal);

    if (isPersonal) {
      _filterGroupIds = null;
      _filterTeacherNames = null;
      _filterRoomIds = null;
      return;
    }

    String? groupIds;
    String? teacherNames;
    String? roomIds;

    switch (ft) {
      case FilterType.group:
        groupIds = _filterController.selectedGroup.value;
        break;
      case FilterType.teacher:
        teacherNames = _filterController.selectedTeacher.value;
        break;
      case FilterType.audience:
        roomIds = _filterController.selectedAudience.value;
        break;
      case FilterType.personal:
        break;
    }

    _filterGroupIds = groupIds;
    _filterTeacherNames = teacherNames;
    _filterRoomIds = roomIds;

    _weekController.setFilters(
      groupIds: groupIds,
      teacherNames: teacherNames,
      roomIds: roomIds,
    );
  }

  void _saveCurrentFilter() {
    final ft = _filterController.currentFilterType.value;
    // Сохраняем активный тип
    switch (ft) {
      case FilterType.group:
        SettingsService.setLastFilterType('group');
        break;
      case FilterType.teacher:
        SettingsService.setLastFilterType('teacher');
        break;
      case FilterType.audience:
        SettingsService.setLastFilterType('audience');
        break;
      case FilterType.personal:
        SettingsService.setLastFilterType('personal');
        break;
    }
    // Всегда сохраняем ВСЕ значения фильтров
    SettingsService.setLastGroupId(_filterController.selectedGroup.value);
    SettingsService.setLastTeacherId(_filterController.selectedTeacher.value);
    SettingsService.setLastAudienceId(_filterController.selectedAudience.value);
  }

  String get _filterIndicator {
    final v = _filterController.selectedValue;
    if (v != null) return v;
    if (_filterController.isPersonal) return 'Личное';
    switch (_filterController.currentFilterType.value) {
      case FilterType.group:
        return 'Выберите группу';
      case FilterType.teacher:
        return 'Выберите преподавателя';
      case FilterType.audience:
        return 'Выберите аудиторию';
      case FilterType.personal:
        return 'Личное';
    }
  }

  // ---------------------------------------------------------------------------
  // Данные по дням
  // ---------------------------------------------------------------------------

  static String _dateStr(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  List<PersonalTask> _tasksForDate(DateTime date) {
    final s = _dateStr(date);
    return _tasks.where((t) => t.date == s).toList()
      ..sort((a, b) => a.time.compareTo(b.time));
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: _buildHeader(),
      body: Stack(
        children: [
          _view == 'today' ? _buildDaySwipeView() : _buildWeekSwipeView(),
          // Пелена загрузки раньше появлялась и пропадала в один кадр —
          // при листании недель это читалось как мигание. Теперь она
          // проявляется, а касания сквозь неё блокируются только пока
          // загрузка действительно идёт.
          Builder(builder: (context) {
            final isLoading =
                _weekController.loadState == ScheduleLoadState.loading;
            return IgnorePointer(
              ignoring: !isLoading,
              child: AnimatedOpacity(
                opacity: isLoading ? 1 : 0,
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                child: Container(
                  color: Theme.of(context)
                      .scaffoldBackgroundColor
                      .withValues(alpha: 0.65),
                  // Сам индикатор держим в дереве только во время загрузки:
                  // он крутится бесконечно и при нулевой прозрачности продолжал
                  // бы гнать кадры впустую.
                  child: isLoading
                      ? Center(child: buildLoader()) // iOS
                      : const SizedBox.expand(),
                ),
              ),
            );
          }),
          if (_filterController.isPersonal)
            Positioned(
              right: 16,
              bottom: 160,
              child: _buildFAB(),
            ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // AppBar
  // ---------------------------------------------------------------------------

  AppAppBar _buildHeader() {
    // Нативный тулбар iOS 26 не умеет анимировать смену иконки, поэтому
    // вместо AnimatedSwitcher — два разных SF Symbol на два состояния.
    final filterIcon =
        _filterBarVisible ? AppIcons.filterOff : AppIcons.filter;

    return AppAppBar(
      title: 'Расписание',
      useNativeToolbar: true,
      // Без явного tintColor нативный тулбар красит кнопки системным синим
      // (в том числе подсветкой при нажатии). Задаём цвет сами, чтобы иконки
      // выглядели одинаково и в покое, и во время нажатия.
      tintColor: Theme.of(context).colorScheme.onSurface,
      actions: [
        AppAppBarAction(
          iosSymbol: filterIcon.symbol,
          icon: filterIcon.icon,
          onPressed: () => setState(() {
            _filterBarVisible = !_filterBarVisible;
            _SessionState.filterBarVisible = _filterBarVisible;
          }),
        ),
        AppAppBarAction(
          iosSymbol: AppIcons.calendarPick.symbol,
          icon: AppIcons.calendarPick.icon,
          onPressed: _openCalendar,
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Day view — бесконечный PageView (свайп меняет день, в т.ч. через неделю)
  // ---------------------------------------------------------------------------

  Widget _buildDaySwipeView() {
    return Column(
      children: [
        _buildCollapsibleFilterHeader(),
        _buildSegmentedControl(),
        _buildCalendarStrip(),
        if (_weekController.loadState == ScheduleLoadState.error)
          Expanded(child: _buildErrorState())
        else
          Expanded(
            child: PageView.builder(
              // Ключ — опора для тестов: на экране несколько PageView
              // (ещё один внутри карточек пар), и различать их по внутренним
              // признакам делегата хрупко.
              key: const ValueKey('schedule-day-pages'),
              controller: _dayPageController,
              physics: const BouncingScrollPhysics(),
              itemCount: _kTotalDayPages,
              onPageChanged: _onDayPageChanged,
              itemBuilder: (context, page) {
                return _buildSingleDayPage(_visibleDateForPage(page));
              },
            ),
          ),
      ],
    );
  }

  /// Анимированная обёртка для filter bar + indicator (toggle по кнопке)
  Widget _buildCollapsibleFilterHeader() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOut,
      height: _filterBarVisible
          ? (_filterController.isPersonal ? 66 : 106)
          : 8,
      clipBehavior: Clip.hardEdge,
      decoration: const BoxDecoration(),
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildFilterBar(),
            _buildFilterIndicator(),
          ],
        ),
      ),
    );
  }

  /// Переход на соседнюю неделю с сохранением дня недели: со среды 12-го
  /// свайп вперёд ведёт на среду 19-го, а не на понедельник.
  ///
  /// Этим свайп по полоске дней отличается от стрелок «‹ ›» рядом с датой
  /// периода: те переводят на начало недели ([ScheduleWeekController.goToNextWeek]).
  ///
  /// Анимация всегда на **одну** страницу, а не на семь. `animateToPage` через
  /// неделю прокручивал бы `PageView` по всем промежуточным дням: они успевали
  /// отрисоваться и мелькали, а `onPageChanged` срабатывал на каждом. Поэтому
  /// соседней странице временно назначается целевая дата ([_bridgeDate]) — до
  /// неё и идёт обычный однокадровый переход, как при свайпе между днями.
  ///
  /// Когда анимация закончилась, подмена снимается, а опорный день [_refDay]
  /// сдвигается на шесть суток: вместе с самой перелистнутой страницей это
  /// ровно неделя, поэтому та же страница означает ту же дату и содержимое не
  /// дёргается. Соседние страницы после этого снова идут подряд по дням.
  void _shiftWeekKeepingWeekday(int direction) {
    // Переход уже идёт — второй свайп подряд игнорируем, иначе «мостик»
    // перезапишется и страницы разъедутся с датами.
    if (_bridgePage != null) return;

    final target =
        _weekController.selectedDate.add(Duration(days: 7 * direction));
    if (!WeekService.isValidDate(target)) return;

    HapticFeedback.selectionClick();

    if (!_dayPageController.hasClients) {
      setState(() => _stripDirection = direction);
      _weekController.goToWeekContaining(target);
      return;
    }

    final bridgePage =
        (_dayPageController.page?.round() ?? _currentDayPage) + direction;

    setState(() {
      _stripDirection = direction;
      _bridgePage = bridgePage;
      _bridgeDate = target;
    });

    // Флаг ставим до обращения к контроллеру: его слушатель при изменении
    // даты дёргает `jumpToPage`, и день сменился бы рывком вместо анимации.
    _isPageAnimating = true;
    _weekController.goToWeekContaining(target);

    _dayPageController
        .animateToPage(
          bridgePage,
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeInOut,
        )
        .whenComplete(() {
      if (!mounted) return;
      setState(() {
        _refDay = _refDay.add(Duration(days: 6 * direction));
        _bridgePage = null;
        _bridgeDate = null;
      });
      _isPageAnimating = false;
    });
  }

  void _onDayPageChanged(int page) {
    _isPageAnimating = true;
    final date = _visibleDateForPage(page);

    // Если дата вышла за пределы текущей недели — переходим на нужную неделю
    if (!_weekController.currentWeek.contains(date)) {
      _weekController.goToWeekContaining(date);
    } else {
      final dayIdx = _weekController.currentWeek.dayIndexFor(date);
      if (dayIdx != null) _weekController.selectDay(dayIdx);
    }

    Future.delayed(const Duration(milliseconds: 350), () {
      if (mounted) _isPageAnimating = false;
    });
  }

  Widget _buildSingleDayPage(DateTime date) {
    final dayOfWeek = date.weekday; // 1=Mon..7=Sun (совпадает с API)
    final isPersonal = _filterController.isPersonal;

    List<Lesson> dayLessons;
    if (isPersonal) {
      dayLessons = [];
    } else if (_weekController.currentWeek.contains(date)) {
      dayLessons = _weekController.lessons
          .where((l) => l.dayOfWeek == dayOfWeek)
          .toList();
    } else {
      final week = WeekService.getWeekForDate(date);
      final cached = ScheduleCacheService.instance.getCachedLessons(
        week,
        groupIds: _filterGroupIds,
        teacherNames: _filterTeacherNames,
        roomIds: _filterRoomIds,
      );
      dayLessons = cached?.where((l) => l.dayOfWeek == dayOfWeek).toList() ?? [];
    }

    final dayTasks = _tasksForDate(date);
    final lessonNumbers = _assignLessonNumbers(dayLessons);
    final now = DateTime.now();
    final isToday = date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;

    // Группируем пары по временному слоту
    final Map<String, List<Lesson>> lessonsByTime = {};
    for (final l in dayLessons) {
      lessonsByTime.putIfAbsent(l.timeStart, () => []).add(l);
    }

    // Строим единый список: {время, уроки или задача}
    final allSlots = <({String time, bool isLesson, List<Lesson>? lessons, PersonalTask? task})>[];
    for (final time in lessonsByTime.keys) {
      allSlots.add((time: time, isLesson: true, lessons: lessonsByTime[time], task: null));
    }
    if (isPersonal) {
      for (final t in dayTasks) {
        allSlots.add((time: t.time, isLesson: false, lessons: null, task: t));
      }
    }
    allSlots.sort((a, b) => a.time.compareTo(b.time));

    if (allSlots.isEmpty) {
      return Center(
        child: Text(
          isPersonal ? 'Задач нет' : 'Занятий нет',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.5),
              ),
        ),
      );
    }

    final displayItems = <Widget>[];
    for (final slot in allSlots) {
      if (!slot.isLesson) {
        final t = slot.task!;
        displayItems.add(Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: PersonalTaskCard(
            task: t,
            onTap: () => _editTask(t),
            onDelete: () => _confirmDeleteTask(t),
          ),
        ));
      } else {
        final lessons = slot.lessons!;
        final num = lessonNumbers[slot.time] ?? 1;
        if (lessons.length == 1) {
          final lesson = lessons.first;
          final isCurrent = isToday && _isLessonCurrently(lesson, now);
          displayItems.add(Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _LessonCard(
              lesson: lesson,
              onTap: () => _showLessonDetails(lesson),
              type: currentScheduleType,
              pairNumber: num,
              isCurrent: isCurrent,
            ),
          ));
        } else {
          // Несколько пар на один слот — горизонтальный скролл
          displayItems.add(Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _LessonGroupPageView(
              lessons: lessons,
              onTap: _showLessonDetails,
              type: currentScheduleType,
              pairNumber: num,
              isCurrentCheck: isToday
                  ? (l) => _isLessonCurrently(l, now)
                  : (_) => false,
            ),
          ));
        }
      }
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
      children: displayItems,
    );
  }

  /// Присваивает номера парам: использует поле duration из API, если есть;
  /// иначе вычисляет по уникальному timeStart.
  Map<String, int> _assignLessonNumbers(List<Lesson> lessons) {
    final sorted = List<Lesson>.from(lessons)
      ..sort((a, b) => a.timeStart.compareTo(b.timeStart));
    final map = <String, int>{};
    var num = 0;
    for (final l in sorted) {
      if (!map.containsKey(l.timeStart)) {
        num++;
        // duration — это lessonNumberStart из API; при отсутствии поля там 0,
        // и тогда номер пары считаем сами по порядку уникальных timeStart.
        map[l.timeStart] = l.duration > 0 ? l.duration : num;
      }
    }
    return map;
  }

  /// Проверяет, идёт ли пара прямо сейчас.
  bool _isLessonCurrently(Lesson lesson, DateTime now) {
    try {
      final startParts = lesson.timeStart.split(':');
      final endParts = lesson.timeEnd.split(':');
      final startMinutes =
          int.parse(startParts[0]) * 60 + int.parse(startParts[1]);
      final endMinutes =
          int.parse(endParts[0]) * 60 + int.parse(endParts[1]);
      final nowMinutes = now.hour * 60 + now.minute;
      return nowMinutes >= startMinutes && nowMinutes < endMinutes;
    } catch (_) {
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Week view — свайп через GestureDetector + AnimatedSwitcher
  // ---------------------------------------------------------------------------

  Widget _buildWeekSwipeView() {
    return Column(
      children: [
        _buildCollapsibleFilterHeader(),
        _buildSegmentedControl(),
        _buildCalendarStrip(),
        if (_weekController.loadState == ScheduleLoadState.error)
          Expanded(child: _buildErrorState())
        else
          Expanded(
            child: GestureDetector(
              onHorizontalDragEnd: (details) {
                final v = details.primaryVelocity ?? 0;
                if (v < -400) {
                  _weekController.goToNextWeek();
                  setState(() => _weekSwipeKey++);
                }
                if (v > 400) {
                  _weekController.goToPreviousWeek();
                  setState(() => _weekSwipeKey++);
                }
              },
              behavior: HitTestBehavior.translucent,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: CustomScrollView(
                  key: ValueKey(_weekSwipeKey),
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                      sliver: _buildWeekSliver(),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Filter bar
  // ---------------------------------------------------------------------------

  Widget _buildFilterBar() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final items = [
      (FilterType.group, 'Группа', Icons.groups_rounded),
      (FilterType.teacher, 'Преподаватель', Icons.person_rounded),
      (FilterType.audience, 'Аудитория', Icons.meeting_room_rounded),
      (FilterType.personal, 'Личное', Icons.person_pin_rounded),
    ];

    return ValueListenableBuilder<FilterType>(
      valueListenable: _filterController.currentFilterType,
      builder: (context, selectedType, _) {
        return SizedBox(
          height: 66,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final item = items[i];
              final isSelected = selectedType == item.$1;

              // Цвета для светлой / тёмной темы
              final selectedBg = isDark
                  ? Colors.white.withValues(alpha: 0.14)
                  : Colors.white;
              final unselectedBg = isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.white.withValues(alpha: 0.5);

              final textColor = isDark
                  ? (isSelected
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.5))
                  : (isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface.withValues(alpha: 0.55));

              final iconColor = isDark
                  ? (isSelected
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.45))
                  : (isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface.withValues(alpha: 0.5));

              return GestureDetector(
                onTap: () {
                  _filterController.setFilterType(item.$1);
                  _syncFiltersToController();
                  _saveCurrentFilter();
                },
                child: BaseContainer(
                  shadow: isSelected && !isDark,
                  backgroundColor: isSelected ? selectedBg : unselectedBg,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(item.$3, size: 17, color: iconColor),
                      const SizedBox(width: 6),
                      Text(
                        item.$2,
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Filter indicator
  // ---------------------------------------------------------------------------

  Widget _buildFilterIndicator() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final color = isDark ? Colors.white.withValues(alpha: 0.85) : theme.colorScheme.primary;

    if (_filterController.isPersonal) return const SizedBox(height: 4);

    return TextButton.icon(
      style: TextButton.styleFrom(
        minimumSize: const Size(48, 40),
        tapTargetSize: MaterialTapTargetSize.padded,
      ),
      onPressed: _openSelectForCurrentFilter,
      icon: Icon(Icons.arrow_forward_ios_rounded, size: 13, color: color),
      label: Text(
        _filterIndicator,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Segmented control (День / Неделя)
  // ---------------------------------------------------------------------------

  Widget _buildSegmentedControl() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: AppSegmentedControl(
        labels: const ['День', 'Неделя'],
        selectedIndex: _view == 'today' ? 0 : 1,
        color: theme.colorScheme.primary,
        selectedTextColor: Colors.white,
        textColor: isDark
            ? Colors.white.withValues(alpha: 0.45)
            : theme.colorScheme.onSurface.withValues(alpha: 0.5),
        onValueChanged: (index) =>
            _onViewChanged(index == 0 ? 'today' : 'week'),
      ),
    );
  }

  void _onViewChanged(String value) {
    if (value == _view) return;
    setState(() {
      _view = value;
      _SessionState.view = value;
    });
    if (value == 'today') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_dayPageController.hasClients) {
          _dayPageController.jumpToPage(_currentDayPage);
        }
      });
    }
  }

  // ---------------------------------------------------------------------------
  // Calendar strip
  // ---------------------------------------------------------------------------

  Widget _buildCalendarStrip() {
    final week = _weekController.currentWeek;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isLoading =
        _weekController.loadState == ScheduleLoadState.loading;
    final iconColor = isDark
        ? Colors.white.withValues(alpha: isLoading ? 0.25 : 0.7)
        : theme.colorScheme.onSurface.withValues(alpha: isLoading ? 0.25 : 0.7);

    if (_view == 'week') {
      return Container(
        color: theme.cardColor,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _navIconBtn(Icons.chevron_left_rounded, iconColor,
                isLoading ? null : () {
                  _weekController.goToPreviousWeek();
                  setState(() => _weekSwipeKey++);
                }),
            _periodLabel(week.formattedPeriod, theme),
            _navIconBtn(Icons.chevron_right_rounded, iconColor,
                isLoading ? null : () {
                  _weekController.goToNextWeek();
                  setState(() => _weekSwipeKey++);
                }),
          ],
        ),
      );
    }

    // Дневной режим — полоска с 7 ячейками
    return Container(
      color: theme.cardColor,
      padding: const EdgeInsets.only(left: 8, right: 8, top: 10, bottom: 14),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _navIconBtn(Icons.chevron_left_rounded, iconColor,
                  isLoading ? null : () => _weekController.goToPreviousWeek()),
              _periodLabel(week.formattedPeriod, theme),
              _navIconBtn(Icons.chevron_right_rounded, iconColor,
                  isLoading ? null : () => _weekController.goToNextWeek()),
            ],
          ),
          const SizedBox(height: 10),
          // Свайп по ячейкам дней листает недели, оставаясь на том же дне
          // недели. Жест висит только на этой строке: ниже свой `PageView` со
          // свайпом между днями, и объединять их нельзя — иначе один из двух
          // забирал бы жест целиком.
          //
          // `onHorizontalDragEnd` вместо вложенного `PageView`: полоска
          // перестраивается под неделю контроллера, и держать её собственную
          // прокрутку в согласии с ним пришлось бы вручную.
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragEnd: isLoading
                ? null
                : (details) {
                    final velocity = details.primaryVelocity ?? 0;
                    // Короткие дрожащие движения пальцем не считаем свайпом.
                    if (velocity.abs() < 120) return;
                    // Палец влево (отрицательная скорость) — вперёд по времени.
                    _shiftWeekKeepingWeekday(velocity < 0 ? 1 : -1);
                  },
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 260),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (child, animation) {
                final isIncoming =
                    child.key == ValueKey<DateTime>(week.startDate);
                final dx = isIncoming
                    ? _stripDirection * 0.25
                    : -_stripDirection * 0.25;
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: Offset(dx, 0),
                    end: Offset.zero,
                  ).animate(animation),
                  child: FadeTransition(opacity: animation, child: child),
                );
              },
              child: Row(
                key: ValueKey<DateTime>(week.startDate),
                children: List.generate(7, (i) {
              final label = WeekService.weekDayLabels[i];
              final date = week.dates[i];
              final isSelected = _weekController.selectedDayIndex == i;
              final today = DateTime.now();
              final isToday = date.year == today.year &&
                  date.month == today.month &&
                  date.day == today.day;

              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    _weekController.selectDay(i);
                    if (_dayPageController.hasClients) {
                      _dayPageController.animateToPage(
                        _pageForDate(date),
                        duration: const Duration(milliseconds: 280),
                        curve: Curves.easeInOut,
                      );
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : isToday
                                ? theme.colorScheme.primary.withValues(alpha: isDark ? 0.25 : 0.18)
                                : theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 7),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Ячейка узкая — седьмая часть экрана. Подпись
                          // ужимается, а не переносится по буквам: при крупном
                          // системном шрифте «ПН» вставало в три строки и
                          // полоска разъезжалась.
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              label,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? Colors.white
                                    : isToday
                                        ? theme.colorScheme.primary
                                        : theme.colorScheme.onSurface
                                            .withValues(alpha: 0.55),
                              ),
                            ),
                          ),
                          const SizedBox(height: 2),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              '${date.day}',
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: isSelected
                                    ? Colors.white
                                    : isToday
                                        ? theme.colorScheme.primary
                                        : theme.colorScheme.onSurface
                                            .withValues(alpha: 0.7),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Период недели между стрелками «‹ ›».
  ///
  /// Занимает всё, что осталось от стрелок, и ужимается вместо того, чтобы на
  /// них наезжать: «28 сен 2026 - 4 октября 2026» — уже длинная строка, а с
  /// увеличенным системным шрифтом она перестаёт помещаться и на широком экране.
  Widget _periodLabel(String text, ThemeData theme) {
    return Expanded(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          text,
          maxLines: 1,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _navIconBtn(
      IconData icon, Color color, VoidCallback? onPressed) {
    return SizedBox(
      width: 40,
      height: 40,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onPressed,
          child: Center(child: Icon(icon, color: color, size: 26)),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Week sliver
  // ---------------------------------------------------------------------------

  Widget _buildWeekSliver() {
    final theme = Theme.of(context);
    final items = <Widget>[];
    final week = _weekController.currentWeek;
    final isPersonal = _filterController.isPersonal;

    for (var di = 0; di < 7; di++) {
      final dayOfWeek = di + 1;
      final date = week.dates[di];
      final label = WeekService.weekDayLabels[di];
      final dayLessons = isPersonal
          ? <Lesson>[]
          : _weekController.lessons
              .where((l) => l.dayOfWeek == dayOfWeek)
              .toList();
      final dayTasks = _tasksForDate(date);

      final today = DateTime.now();
      final isToday = date.year == today.year &&
          date.month == today.month &&
          date.day == today.day;

      items.add(Padding(
        padding: const EdgeInsets.only(top: 14, bottom: 6),
        child: Row(
          children: [
            Text(
              '$label, ${date.day}',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: isToday
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface.withValues(alpha: 0.55),
              ),
            ),
            if (isToday) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Сегодня',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ));

      final lessonNums = _assignLessonNumbers(dayLessons);
      final now = DateTime.now();

      // Группируем пары по временному слоту
      final Map<String, List<Lesson>> wkLessonsByTime = {};
      for (final l in dayLessons) {
        wkLessonsByTime.putIfAbsent(l.timeStart, () => []).add(l);
      }

      final wkSlots = <({String time, bool isLesson, List<Lesson>? lessons, PersonalTask? task})>[];
      for (final time in wkLessonsByTime.keys) {
        wkSlots.add((time: time, isLesson: true, lessons: wkLessonsByTime[time], task: null));
      }
      if (isPersonal) {
        for (final t in dayTasks) {
          wkSlots.add((time: t.time, isLesson: false, lessons: null, task: t));
        }
      }
      wkSlots.sort((a, b) => a.time.compareTo(b.time));

      for (final slot in wkSlots) {
        if (!slot.isLesson) {
          final t = slot.task!;
          items.add(Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: PersonalTaskCard(
              task: t,
              onTap: () => _editTask(t),
              onDelete: () => _confirmDeleteTask(t),
            ),
          ));
        } else {
          final lessons = slot.lessons!;
          final num = lessonNums[slot.time] ?? 1;
          if (lessons.length == 1) {
            final lesson = lessons.first;
            final isCurrent = isToday && _isLessonCurrently(lesson, now);
            items.add(Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _LessonCard(
                lesson: lesson,
                onTap: () => _showLessonDetails(lesson),
                type: currentScheduleType,
                pairNumber: num,
                isCurrent: isCurrent,
              ),
            ));
          } else {
            items.add(Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _LessonGroupPageView(
                lessons: lessons,
                onTap: _showLessonDetails,
                type: currentScheduleType,
                pairNumber: num,
                isCurrentCheck: isToday
                    ? (l) => _isLessonCurrently(l, now)
                    : (_) => false,
              ),
            ));
          }
        }
      }

      if (wkSlots.isEmpty) {
        items.add(Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            isPersonal ? 'Задач нет' : 'Занятий нет',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.38),
            ),
          ),
        ));
      }
    }

    return SliverList(delegate: SliverChildListDelegate(items));
  }

  // ---------------------------------------------------------------------------
  // Error state
  // ---------------------------------------------------------------------------

  Widget _buildErrorState() {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded, size: 52, color: theme.colorScheme.onSurface.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text(
              'Не удалось загрузить расписание',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () => _weekController.retryLoad(),
              icon: const Icon(Icons.refresh_rounded, size: 20),
              label: const Text('Повторить'),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Navigation helpers
  // ---------------------------------------------------------------------------

  void _openSelectForCurrentFilter() {
    switch (_filterController.currentFilterType.value) {
      case FilterType.group:
        _openSelect('group');
        break;
      case FilterType.teacher:
        _openSelect('teacher');
        break;
      case FilterType.audience:
        _openSelect('room');
        break;
      case FilterType.personal:
        break;
    }
  }

  Future<void> _openSelect(String type) async {
    String? result;
    if (type == 'group') {
      result = await context.push<String?>(
        '/schedule/select-group',
        extra: {'selected': _filterController.selectedGroup.value},
      );
      if (result != null && mounted) {
        _filterController.updateGroup(result);
        _syncFiltersToController();
        _saveCurrentFilter();
      }
    } else if (type == 'teacher') {
      result = await context.push<String?>(
        '/schedule/select-teacher',
        extra: {'selected': _filterController.selectedTeacher.value},
      );
      if (result != null && mounted) {
        _filterController.updateTeacher(result);
        _syncFiltersToController();
        _saveCurrentFilter();
      }
    } else if (type == 'room') {
      result = await context.push<String?>(
        '/schedule/select-room',
        extra: {'selected': _filterController.selectedAudience.value},
      );
      if (result != null && mounted) {
        _filterController.updateAudience(result);
        _syncFiltersToController();
        _saveCurrentFilter();
      }
    }
  }

  Future<void> _openCalendar() async {
    final selected = await context.push<DateTime?>(
      '/schedule/calendar',
      extra: {'initialDate': _weekController.selectedDate},
    );
    if (selected != null && mounted) {
      _weekController.goToWeekContaining(selected);
      if (_view == 'today' && _dayPageController.hasClients) {
        _dayPageController.jumpToPage(_pageForDate(selected));
      }
    }
  }

  void _showLessonDetails(Lesson l) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      enableDrag: true, // свайп вниз для закрытия
      backgroundColor: Colors.transparent,
      builder: (_) => _LessonDetailsSheet(lesson: l),
    );
  }

  // ---------------------------------------------------------------------------
  // FAB + task dialog
  // ---------------------------------------------------------------------------

  Widget _buildFAB() {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.primary,
      borderRadius: BorderRadius.circular(999),
      elevation: 6,
      shadowColor: theme.colorScheme.primary.withValues(alpha: 0.4),
      child: InkWell(
        onTap: _showAddTaskDialog,
        borderRadius: BorderRadius.circular(999),
        child: SizedBox(
          width: 56,
          height: 56,
          child: Icon(Icons.add_rounded,
              color: theme.colorScheme.onPrimary, size: 28),
        ),
      ),
    );
  }

  void _editTask(PersonalTask task) {
    final dateParts = task.date.split('-');
    final forDate = DateTime(
      int.parse(dateParts[0]),
      int.parse(dateParts[1]),
      int.parse(dateParts[2]),
    );
    Navigator.of(context).push(
      buildRoute(AddTaskScreen( // iOS
        forDate: forDate,
        onSaved: _loadTasks,
        existingTask: task,
      )),
    );
  }

  void _showAddTaskDialog() {
    final forDate = _view == 'week'
        ? _weekController.currentWeek.startDate
        : _weekController.currentWeek
            .dates[_weekController.selectedDayIndex];
    Navigator.of(context).push(
      buildRoute(AddTaskScreen(forDate: forDate, onSaved: _loadTasks)), // iOS
    );
  }

  Future<void> _confirmDeleteTask(PersonalTask task) async {
    final confirmed = await AppDialog.show(
      context: context,
      icon: Icons.delete_outline_rounded,
      title: 'Удалить задачу?',
      message: '«${task.title}» будет удалена.',
      confirmText: 'Удалить',
      isDanger: true,
    );
    if (confirmed == true && mounted) {
      try {
        await TaskService.instance.deleteTask(task.id);
        await _loadTasks();
        if (mounted) {
          AppSnackBar.success(context, 'Задача удалена');
        }
      } catch (e) {
        if (mounted) {
          AppSnackBar.error(context, 'Ошибка удаления: $e');
        }
      }
    }
  }
}

// =============================================================================
// Карточка занятия
// =============================================================================

/// Акцентный цвет для чипа типа занятия (единственный разноцветный элемент).
Color _lessonTypeChipColor(LessonType type, bool isDark) {
  switch (type) {
    case LessonType.lecture:
      return isDark ? const Color(0xFF6AADFF) : const Color(0xFF4A8FD9);
    case LessonType.lab:
      return isDark ? const Color(0xFFE8B44C) : const Color(0xFFC9962E);
    case LessonType.retake:
      return isDark ? const Color(0xFFE07676) : const Color(0xFFCC5555);
    case LessonType.practice:
      return isDark ? const Color(0xFF4ED9A0) : const Color(0xFF3EA87C);
    case LessonType.personal:
      return isDark ? const Color(0xFFA98BFA) : const Color(0xFF8B6FD4);
    case LessonType.exam:
      return isDark ? const Color(0xFFFF7A7A) : const Color(0xFFD94444);
    case LessonType.examPrep:
      return isDark ? const Color(0xFFFFB86A) : const Color(0xFFD9882E);
  }
}

/// Переключатель для нескольких пар на одно время (разные подгруппы).
/// Свайп между карточками + минималистичные точки снизу.
class _LessonGroupPageView extends StatefulWidget {
  final List<Lesson> lessons;
  final void Function(Lesson) onTap;
  final ScheduleType type;
  final int? pairNumber;
  final bool Function(Lesson) isCurrentCheck;

  const _LessonGroupPageView({
    required this.lessons,
    required this.onTap,
    required this.type,
    this.pairNumber,
    required this.isCurrentCheck,
  });

  @override
  State<_LessonGroupPageView> createState() => _LessonGroupPageViewState();
}

class _LessonGroupPageViewState extends State<_LessonGroupPageView> {
  int _currentIndex = 0;
  late final PageController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = PageController();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;
    final onSurface = theme.colorScheme.onSurface;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Карточки — свайп через PageView
        SizedBox(
          height: 120,
          child: PageView.builder(
            controller: _ctrl,
            itemCount: widget.lessons.length,
            physics: const BouncingScrollPhysics(),
            onPageChanged: (p) => setState(() => _currentIndex = p),
            itemBuilder: (context, i) {
              final lesson = widget.lessons[i];
              return _LessonCard(
                lesson: lesson,
                onTap: () => widget.onTap(lesson),
                type: widget.type,
                pairNumber: widget.pairNumber,
                isCurrent: widget.isCurrentCheck(lesson),
              );
            },
          ),
        ),
        // Точки-переключатели
        if (widget.lessons.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(widget.lessons.length, (i) {
                final isActive = i == _currentIndex;
                return GestureDetector(
                  onTap: () {
                    _ctrl.animateToPage(i,
                        duration: const Duration(milliseconds: 280),
                        curve: Curves.easeInOut);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: isActive ? 18 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: isActive
                          ? primary
                          : (isDark
                              ? onSurface.withValues(alpha: 0.2)
                              : primary.withValues(alpha: 0.2)),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                );
              }),
            ),
          ),
      ],
    );
  }
}

class _LessonCard extends StatelessWidget {
  final Lesson lesson;
  final VoidCallback onTap;
  final ScheduleType type;
  final int? pairNumber;
  final bool isCurrent;

  const _LessonCard({
    required this.lesson,
    required this.onTap,
    required this.type,
    this.pairNumber,
    this.isCurrent = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final chipColor = _lessonTypeChipColor(lesson.type, isDark);
    final hasSubgroup =
        lesson.subgroup != null && lesson.subgroup!.isNotEmpty;

    // Единый фон карточки для всех типов
    final cardBg = isDark
        ? const Color(0xFF1E1E22)
        : Colors.white;
    final borderClr = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : const Color(0xFFE4E8EF);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderClr, width: 1),
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Левая полоска — цвет типа
            Container(
              width: 4,
              height: 52,
              margin: const EdgeInsets.only(right: 12, top: 2),
              decoration: BoxDecoration(
                color: chipColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Основной контент
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Время + тип занятия справа
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          '${lesson.timeStart} – ${lesson.timeEnd}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.55),
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (hasSubgroup) ...[
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.people_outline_rounded,
                              size: 13,
                              color: chipColor.withValues(alpha: 0.7),
                            ),
                            const SizedBox(width: 3),
                            _SubgroupBadge(
                              label: lesson.subgroup![lesson.subgroup!.length - 1],
                              color: chipColor,
                              isDark: isDark,
                            ),
                          ],
                        ),
                        const SizedBox(width: 8),
                      ],
                      // Тип занятия — справа. Чип занимает столько, сколько
                      // нужно подписи: «ПОДГОТОВКА» и «КОНСУЛЬТАЦИЯ» должны
                      // читаться целиком. Место под него при нехватке ширины
                      // освобождает время слева — оно ужимается с многоточием.
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: chipColor.withValues(alpha: isDark ? 0.18 : 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          lesson.typeLabel,
                          maxLines: 1,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: chipColor,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                      if (pairNumber != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: isCurrent
                                ? theme.colorScheme.primary.withValues(alpha: 0.15)
                                : (isDark
                                    ? Colors.white.withValues(alpha: 0.06)
                                    : const Color(0xFFF0F2F5)),
                            shape: BoxShape.circle,
                            border: isCurrent
                                ? Border.all(
                                    color: theme.colorScheme.primary.withValues(alpha: 0.5),
                                    width: 1.5,
                                  )
                                : null,
                          ),
                          child: Center(
                            child: Text(
                              '$pairNumber',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: isCurrent
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.onSurface.withValues(alpha: 0.4),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    lesson.subject,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  _LessonMeta(lesson: lesson, type: type, theme: theme),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LessonMeta extends StatelessWidget {
  final Lesson lesson;
  final ScheduleType type;
  final ThemeData theme;

  const _LessonMeta(
      {required this.lesson, required this.type, required this.theme});

  @override
  Widget build(BuildContext context) {
    final color = theme.colorScheme.onSurface.withValues(alpha: 0.6);
    final items = <Widget>[];

    if (type != ScheduleType.teacher &&
        lesson.teacher?.isNotEmpty == true) {
      items.add(_MetaItem(
          icon: Icons.person_outline_rounded,
          text: lesson.teacher!,
          color: color,
          theme: theme));
    }
    if (type != ScheduleType.group) {
      if (lesson.group != null && lesson.group!.isNotEmpty) {
        items.add(_MetaItem(
            icon: Icons.group_outlined,
            text: lesson.subgroup != null && lesson.subgroup!.isNotEmpty
                ? '${lesson.group}/${lesson.subgroup![lesson.subgroup!.length - 1]}'
                : lesson.group!,
            color: color,
            theme: theme));
      } else if (lesson.subgroup != null && lesson.subgroup!.isNotEmpty) {
        items.add(_MetaItem(
            icon: Icons.group_outlined,
            text: lesson.subgroup!,
            color: color,
            theme: theme));
      } else if (lesson.stream != null && lesson.stream!.isNotEmpty) {
        items.add(_MetaItem(
            icon: Icons.group_outlined,
            text: lesson.stream!,
            color: color,
            theme: theme));
      }
    }
    if (type != ScheduleType.audience &&
        lesson.room?.isNotEmpty == true) {
      items.add(_MetaItem(
          icon: Icons.location_on_outlined,
          text: lesson.room!,
          color: color,
          theme: theme));
    }

    if (items.isEmpty) return const SizedBox.shrink();

    // Строим строку мета-информации с разделителями
    return LayoutBuilder(
      builder: (context, constraints) {
        return Row(
          children: [
            for (int i = 0; i < items.length; i++) ...[
              if (i > 0)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text('•', style: TextStyle(fontSize: 10, color: color)),
                ),
              Flexible(child: items[i]),
            ],
          ],
        );
      },
    );
  }
}

class _MetaItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  final ThemeData theme;

  const _MetaItem(
      {required this.icon,
      required this.text,
      required this.color,
      required this.theme});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
    );
  }
}

/// Компактный бейдж номера подгруппы.
class _SubgroupBadge extends StatelessWidget {
  final String label;  // обычно '1' или '2'
  final Color color;
  final bool isDark;

  const _SubgroupBadge(
      {required this.label, required this.color, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.18 : 0.12),
        shape: BoxShape.circle,
        border: Border.all(
            color: color.withValues(alpha: isDark ? 0.45 : 0.3), width: 1),
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Детали занятия (bottom sheet)
// =============================================================================

class _LessonDetailsSheet extends StatelessWidget {
  final Lesson lesson;

  const _LessonDetailsSheet({required this.lesson});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;
    final onSurface = theme.colorScheme.onSurface;
    final buildingInfo = BuildingData.findByAuditorium(lesson.room);
    final hasSubgroup = lesson.subgroup != null && lesson.subgroup!.isNotEmpty;

    Widget sheetContent = Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: BoxDecoration(
        color: isDark ? null : theme.cardColor,
        // В тёмной теме лист лежит поверх размытия и раньше был почти
        // прозрачным — содержимое под ним просвечивало и сливалось.
        // Блик сверху оставляем, но подмешиваем его к непрозрачному цвету
        // карточки, а не кладём голым белым с альфой.
        gradient: isDark
            ? LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color.alphaBlend(
                    Colors.white.withValues(alpha: 0.10),
                    theme.cardColor,
                  ),
                  Color.alphaBlend(
                    Colors.white.withValues(alpha: 0.05),
                    theme.cardColor,
                  ),
                ],
              )
            : null,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: isDark
            ? Border(
                top: BorderSide(
                  color: Colors.white.withValues(alpha: 0.15),
                  width: 0.5,
                ),
              )
            : Border(
                top: BorderSide(color: theme.dividerColor),
                left: BorderSide(color: theme.dividerColor),
                right: BorderSide(color: theme.dividerColor),
              ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, -4),
                ),
              ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: theme.dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Название предмета. Цвет — обычный текстовый, а не акцентный:
          // акцент пользователь выбирает сам, и на приглушённых оттенках
          // (пыльный зелёный, дымчато-голубой) заголовок терялся на фоне
          // шторки. Здесь он должен быть белым в тёмной теме и тёмным в
          // светлой — `onSurface` даёт ровно это.
          Text(
            lesson.subject,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: onSurface,
            ),
          ),
          const SizedBox(height: 20),

          // Время + Аудитория — две карточки рядом
          Row(
            children: [
              // Карточка времени
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        primary.withValues(alpha: isDark ? 0.1 : 0.06),
                        primary.withValues(alpha: isDark ? 0.05 : 0.02),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: primary.withValues(alpha: isDark ? 0.15 : 0.1),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.access_time_rounded, color: primary, size: 18),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${lesson.timeStart}–${lesson.timeEnd}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${_durationMinutes(lesson.timeStart, lesson.timeEnd)} мин',
                              style: TextStyle(
                                fontSize: 11,
                                color: onSurface.withValues(alpha: 0.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Карточка аудитории
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.error.withValues(alpha: isDark ? 0.1 : 0.06),
                        AppColors.error.withValues(alpha: isDark ? 0.04 : 0.02),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.error.withValues(alpha: isDark ? 0.15 : 0.1),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.location_on_rounded, color: AppColors.error, size: 18),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              lesson.room ?? '—',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (lesson.building != null && lesson.building!.isNotEmpty)
                              Text(
                                lesson.building!,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: onSurface.withValues(alpha: 0.5),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Детали
          _DetailRow(
              icon: Icons.person_rounded,
              iconColor: AppColors.success,
              label: 'Преподаватель',
              value: lesson.teacher ?? '—'),
          _DetailRow(
              icon: Icons.group_rounded,
              iconColor: primary,
              label: 'Группа',
              value: () {
                String groupStr = '';
                if (lesson.group != null && lesson.group!.isNotEmpty) {
                  groupStr = lesson.group!;
                  if (hasSubgroup) {
                    groupStr += '/${lesson.subgroup![lesson.subgroup!.length - 1]}';
                  }
                } else if (hasSubgroup) {
                  groupStr = lesson.subgroup!;
                }
                if (lesson.stream != null && lesson.stream!.isNotEmpty) {
                  groupStr = groupStr.isEmpty
                      ? lesson.stream!
                      : '$groupStr • ${lesson.stream!}';
                }
                return groupStr.isEmpty ? '—' : groupStr;
              }()),
          if (buildingInfo != null) ...[
            _DetailRow(
                icon: Icons.apartment_rounded,
                iconColor: primary,
                label: 'Корпус',
                value: '${buildingInfo.name} — ${buildingInfo.address}'),
            const SizedBox(height: 4),
            SizedBox( // iOS
              width: double.infinity,
              height: 48,
              child: isIOS
                  ? CupertinoButton(
                      onPressed: () => _openMapChooser(context, buildingInfo),
                      color: primary,
                      borderRadius: BorderRadius.circular(14),
                      padding: EdgeInsets.zero,
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.map_rounded, size: 20, color: CupertinoColors.white),
                          SizedBox(width: 8),
                          Text('Показать на карте', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: CupertinoColors.white)),
                        ],
                      ),
                    )
                  : ElevatedButton.icon(
                      onPressed: () => _openMapChooser(context, buildingInfo),
                      icon: const Icon(Icons.map_rounded, size: 20),
                      label: const Text('Показать на карте'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                        textStyle: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
            ),
          ],
        ],
      ),
    );

    if (isDark) {
      return ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: sheetContent,
        ),
      );
    }
    return sheetContent;
  }

  static int _durationMinutes(String start, String end) {
    try {
      final sp = start.split(':');
      final ep = end.split(':');
      final startMin = int.parse(sp[0]) * 60 + int.parse(sp[1]);
      final endMin = int.parse(ep[0]) * 60 + int.parse(ep[1]);
      return endMin - startMin;
    } catch (_) {
      return 90;
    }
  }

  void _openMapChooser(BuildContext context, BuildingInfo info) {
    // iOS — CupertinoActionSheet
    if (isIOS) {
      showCupertinoModalPopup(
        context: context,
        builder: (ctx) => CupertinoActionSheet(
          title: const Text('Показать на карте'),
          message: Text(info.address),
          actions: [
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.of(ctx).pop();
                _openIn2GIS(info);
              },
              child: const Text('2ГИС'),
            ),
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.of(ctx).pop();
                _openInYandexMaps(info);
              },
              child: const Text('Яндекс Карты'),
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Отмена'),
          ),
        ),
      );
      return;
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        Widget mapContent = Container(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          decoration: BoxDecoration(
            color: isDark ? null : theme.cardColor,
            gradient: isDark
                ? LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withValues(alpha: 0.1),
                      Colors.white.withValues(alpha: 0.05),
                    ],
                  )
                : null,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border: isDark
                ? Border(
                    top: BorderSide(
                      color: Colors.white.withValues(alpha: 0.15),
                      width: 0.5,
                    ),
                  )
                : Border(
                    top: BorderSide(color: theme.dividerColor),
                    left: BorderSide(color: theme.dividerColor),
                    right: BorderSide(color: theme.dividerColor),
                  ),
            boxShadow: isDark
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 20,
                      offset: const Offset(0, -4),
                    ),
                  ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: theme.dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                'Показать на карте',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                info.address,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),
              _RouteButton(
                icon: Icons.map_rounded,
                label: '2ГИС',
                color: const Color(0xFF34A853),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _openIn2GIS(info);
                },
              ),
              const SizedBox(height: 10),
              _RouteButton(
                icon: Icons.navigation_rounded,
                label: 'Яндекс Карты',
                color: const Color(0xFFFC3F1D),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _openInYandexMaps(info);
                },
              ),
            ],
          ),
        );

        if (isDark) {
          return ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: mapContent,
            ),
          );
        }
        return mapContent;
      },
    );
  }

  Future<void> _openIn2GIS(BuildingInfo info) {
    final query = Uri.encodeComponent('Омск, ${info.address}');
    return openExternalUrl('https://2gis.ru/omsk/search/$query');
  }

  Future<void> _openInYandexMaps(BuildingInfo info) {
    final query = Uri.encodeComponent('Омск, ${info.address}');
    return openExternalUrl('https://yandex.ru/maps/?text=$query');
  }
}

class _RouteButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _RouteButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Material(
      color: isDark
          ? color.withValues(alpha: 0.12)
          : color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: color.withValues(alpha: isDark ? 0.3 : 0.2),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 14),
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  const _DetailRow(
      {required this.icon,
      required this.iconColor,
      required this.label,
      required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant)),
                Text(value,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Обёртка: номер пары слева от карточки.
