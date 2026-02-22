import 'package:flutter/foundation.dart';

/// Тип фильтра расписания.
enum FilterType {
  group,
  teacher,
  audience,
  personal,
}

/// Контроллер фильтров экрана расписания.
/// Централизует состояние выбранного типа и значений.
class FilterController extends ChangeNotifier {
  final ValueNotifier<FilterType> currentFilterType =
      ValueNotifier(FilterType.group);
  final ValueNotifier<String?> selectedGroup = ValueNotifier<String?>(null);
  final ValueNotifier<String?> selectedTeacher = ValueNotifier<String?>(null);
  final ValueNotifier<String?> selectedAudience = ValueNotifier<String?>(null);

  void setFilterType(FilterType type) {
    if (currentFilterType.value == type) return;
    currentFilterType.value = type;
    currentFilterType.notifyListeners();
    notifyListeners();
  }

  void updateGroup(String? value) {
    selectedGroup.value = value;
    selectedGroup.notifyListeners();
    notifyListeners();
  }

  void updateTeacher(String? value) {
    selectedTeacher.value = value;
    selectedTeacher.notifyListeners();
    notifyListeners();
  }

  void updateAudience(String? value) {
    selectedAudience.value = value;
    selectedAudience.notifyListeners();
    notifyListeners();
  }

  void updateSelection(FilterType type, String? value) {
    switch (type) {
      case FilterType.group:
        updateGroup(value);
        break;
      case FilterType.teacher:
        updateTeacher(value);
        break;
      case FilterType.audience:
        updateAudience(value);
        break;
      case FilterType.personal:
        break;
    }
  }

  void clearSelection() {
    selectedGroup.value = null;
    selectedTeacher.value = null;
    selectedAudience.value = null;
    selectedGroup.notifyListeners();
    selectedTeacher.notifyListeners();
    selectedAudience.notifyListeners();
    notifyListeners();
  }

  String? get selectedValue {
    switch (currentFilterType.value) {
      case FilterType.group:
        return selectedGroup.value;
      case FilterType.teacher:
        return selectedTeacher.value;
      case FilterType.audience:
        return selectedAudience.value;
      case FilterType.personal:
        return null;
    }
  }

  bool get isPersonal => currentFilterType.value == FilterType.personal;
}
