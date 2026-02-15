import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'app_router.dart';
import 'core/services/settings_service.dart';
import 'core/theme/theme_notifier.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SettingsService.init();
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
    return ChangeNotifierProvider(
      create: (_) => ThemeNotifier(),
      child: Consumer<ThemeNotifier>(
        builder: (context, themeNotifier, _) {
          return MaterialApp.router(
            title: 'Расписание ОмГТУ',
            debugShowCheckedModeBanner: false,
            theme: themeNotifier.lightTheme(),
            darkTheme: themeNotifier.darkTheme(),
            themeMode: themeNotifier.themeMode == ThemeMode.dark ? ThemeMode.dark : ThemeMode.light,
            routerConfig: appRouter,
          );
        },
      ),
    );
  }
}
