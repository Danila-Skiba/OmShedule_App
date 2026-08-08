/// Единая точка входа в адаптивный UI-слой приложения.
///
/// Экраны импортируют **только** этот файл и никогда — `adaptive_platform_ui`
/// напрямую. Пакет находится в версии 0.1.x, ломающие изменения приходят даже
/// в патч-релизах; слой обёрток — единственная страховка на этот случай и на
/// случай появления официального `cupertino_ui`.
///
/// ```dart
/// import 'package:omstu_schedule/ui/adaptive/adaptive_exports.dart';
/// ```
library;

export 'app_alert_dialog.dart';
export 'app_button.dart';
export 'app_icons.dart';
export 'app_list_tile.dart';
export 'app_scaffold.dart';
export 'app_segmented_control.dart';
export 'app_snack_bar.dart';
export 'app_switch.dart';
export 'app_tab_bar.dart';
export 'app_text_field.dart';
export 'app_toolbar_leading.dart';

/// Определение платформы и версии iOS (`PlatformInfo.isIOS26OrHigher()`).
export 'package:adaptive_platform_ui/adaptive_platform_ui.dart'
    show PlatformInfo;
