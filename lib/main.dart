import 'dart:async';

import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'app_router.dart';
import 'core/services/schedule_directory_service.dart';
import 'core/services/settings_service.dart';
import 'core/utils/platform_utils.dart';
import 'data/schedule_data.dart';
import 'core/theme/theme_notifier.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ru');
  await SettingsService.init();
  // Справочники групп/преподавателей/аудиторий из assets/data
  await ScheduleData.load();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const OmstuScheduleApp());

  // Справочники дотягиваются фоном и только когда наступил срок (свой у
  // каждого — см. ScheduleDirectoryService.isDue). Намеренно без await: запуск
  // приложения не должен ждать сеть, а добавленные записи попадут в списки
  // выбора при следующем их открытии.
  //
  // С задержкой, потому что первый запуск на устройстве — самый тяжёлый:
  // меток нет, поэтому обходятся все три справочника, а это десятки запросов
  // подряд. Отпускаем их после того, как первый экран успел загрузить своё
  // (расписание на сегодня и новости).
  unawaited(
    Future<void>.delayed(
      const Duration(seconds: 5),
      ScheduleDirectoryService.instance.refreshIfDue,
    ),
  );
}

class OmstuScheduleApp extends StatelessWidget {
  const OmstuScheduleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeNotifier()),
      ],
      child: Consumer<ThemeNotifier>(
        builder: (context, themeNotifier, _) {
          final lightTheme = themeNotifier.lightTheme();
          final darkTheme = themeNotifier.darkTheme();
          final isDark = themeNotifier.themeMode == ThemeMode.dark;

          return GestureDetector(
            onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
            behavior: HitTestBehavior.translucent,
            child: AdaptiveApp.router(
              title: 'Расписание ОмГТУ',
              themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
              materialLightTheme: lightTheme,
              materialDarkTheme: darkTheme,
              cupertinoLightTheme: CupertinoThemeData(
                brightness: Brightness.light,
                primaryColor: lightTheme.colorScheme.primary,
                scaffoldBackgroundColor: lightTheme.scaffoldBackgroundColor,
              ),
              cupertinoDarkTheme: CupertinoThemeData(
                brightness: Brightness.dark,
                primaryColor: darkTheme.colorScheme.primary,
                scaffoldBackgroundColor: darkTheme.scaffoldBackgroundColor,
              ),
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                // Без этого делегата date/time-пикеры и системные кнопки
                // остаются на английском независимо от языка системы.
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: const [
                Locale('ru'),
                Locale('en'),
              ],
              // На iOS AdaptiveApp строит CupertinoApp, где нет ни Material-темы,
              // ни ScaffoldMessenger. Приложение целиком построено на
              // Theme.of(context) (AppTheme: цвета, Inter, карточки, поля ввода),
              // поэтому оба возвращаем вручную — иначе Theme.of отдаёт
              // ThemeData.fallback() и тёмная тема с акцентным цветом ломаются.
              // ScrollConfiguration здесь, а не в конфигах AdaptiveApp:
              // `AdaptiveApp.router` берёт scrollBehavior только из
              // material/cupertino-конфигов, а из builder он накрывает
              // одинаково обе ветки.
              builder: (context, child) => Theme(
                data: isDark ? darkTheme : lightTheme,
                child: ScrollConfiguration(
                  behavior: const AppScrollBehavior(),
                  // Системный шрифт масштабируется, но в пределах разумного.
                  //
                  // На «Крупном тексте» и тем более на размерах из раздела
                  // «Универсальный доступ» (до ×3,1) плотные места ломались:
                  // в полоске дней расписания «ПН» переносилось по буквам, а
                  // подписи в календаре обрезались. Полностью игнорировать
                  // настройку нельзя — это доступность, поэтому ограничиваем
                  // диапазон: ×1,3 крупнее системного всё ещё заметно, но
                  // сетки и полоски держат форму.
                  child: MediaQuery.withClampedTextScaling(
                    minScaleFactor: 0.9,
                    maxScaleFactor: 1.3,
                    child: ScaffoldMessenger(child: child!),
                  ),
                ),
              ),
              routerConfig: appRouter,
            ),
          );
        },
      ),
    );
  }
}
