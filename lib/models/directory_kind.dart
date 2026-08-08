/// Справочник расписания, который приложение умеет обновлять само.
///
/// Лежит в моделях, а не рядом с сервисом обновления: на него ссылаются и
/// хранилище ([DirectoryUpdatesStore]), и справочники ([ScheduleData]), и сам
/// сервис — иначе получился бы круговой импорт.
enum DirectoryKind { groups, persons, auditoriums }

extension DirectoryKindX on DirectoryKind {
  /// Значение параметра `type` в поисковом API вуза.
  String get apiType => switch (this) {
        DirectoryKind.groups => 'group',
        DirectoryKind.persons => 'person',
        DirectoryKind.auditoriums => 'auditorium',
      };

  /// Ключ справочника в файле добавок и в настройках.
  /// Совпадает с именами JSON-ассетов.
  String get storageKey => switch (this) {
        DirectoryKind.groups => 'groups',
        DirectoryKind.persons => 'persons',
        DirectoryKind.auditoriums => 'auditories',
      };

  /// Название для сообщений пользователю.
  String get title => switch (this) {
        DirectoryKind.groups => 'группы',
        DirectoryKind.persons => 'преподаватели',
        DirectoryKind.auditoriums => 'аудитории',
      };
}
