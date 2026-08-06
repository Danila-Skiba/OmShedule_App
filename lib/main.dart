import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'app_router.dart';
import 'core/services/settings_service.dart';
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
          return GestureDetector(
            onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
            behavior: HitTestBehavior.translucent,
            child: MaterialApp.router(
              title: 'Расписание ОмГТУ',
              debugShowCheckedModeBanner: false,
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: const [
                Locale('ru'),
                Locale('en'),
              ],
              theme: themeNotifier.lightTheme(),
              darkTheme: themeNotifier.darkTheme(),
              themeMode: themeNotifier.themeMode == ThemeMode.dark ? ThemeMode.dark : ThemeMode.light,
              routerConfig: appRouter,
            ),
          );
        },
      ),
    );
  }
}
