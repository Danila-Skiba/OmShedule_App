import 'dart:io' show Platform;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

// ─── Platform Detection ───────────────────────────────────────────────── // iOS
final bool isIOS = Platform.isIOS;

// ─── Loading Indicator ────────────────────────────────────────────────── // iOS
/// CupertinoActivityIndicator на iOS, CircularProgressIndicator на Android.
Widget buildLoader({double? radius, double? strokeWidth, Color? color}) {
  if (isIOS) {
    return CupertinoActivityIndicator(radius: radius ?? 14, color: color);
  }
  return CircularProgressIndicator(
    strokeWidth: strokeWidth ?? 4.0,
    color: color,
  );
}

/// Маленький лоадер (для кнопок и т.п.).
Widget buildSmallLoader({Color? color}) {
  if (isIOS) {
    return CupertinoActivityIndicator(radius: 10, color: color);
  }
  return SizedBox(
    width: 22,
    height: 22,
    child: CircularProgressIndicator(strokeWidth: 2.5, color: color),
  );
}

// ─── Внешние ссылки ─────────────────────────────────────────────────────
/// Открывает ссылку во внешнем приложении (браузер, карты).
///
/// Все адреса в приложении — обычные https, так что открыть их на iOS всегда
/// есть чем. Но `launchUrl` возвращает Future и умеет бросать
/// `PlatformException`: вызовы без обработки превращались бы в необработанное
/// асинхронное исключение, а пользователь всё равно ничего бы не заметил.
Future<void> openExternalUrl(String url) async {
  try {
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  } catch (e) {
    debugPrint('Не удалось открыть ссылку $url: $e');
  }
}

// ─── Scroll ───────────────────────────────────────────────────────────── // iOS
/// Поведение скролла для всего приложения.
///
/// На iOS списки «оттягиваются» у краёв независимо от того, помещается ли
/// содержимое на экран: короткая лента новостей или пустая панель «Сегодня»
/// раньше стояли колом, тогда как в системных приложениях тянется любой экран.
/// Даёт это [AlwaysScrollableScrollPhysics] в родителях — сама
/// `BouncingScrollPhysics` при коротком содержимом скролл не разрешает.
///
/// На Android поведение остаётся материальным: там оттяг у краёв чужероден.
class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    if (!isIOS) return super.getScrollPhysics(context);
    return const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());
  }
}

// ─── Navigation Transitions ──────────────────────────────────────────── // iOS
/// CupertinoPageRoute на iOS, MaterialPageRoute на Android.
Route<T> buildRoute<T>(Widget page) {
  if (isIOS) {
    return CupertinoPageRoute<T>(builder: (_) => page);
  }
  return MaterialPageRoute<T>(builder: (_) => page);
}

// ─── AppBar ───────────────────────────────────────────────────────────── // iOS
/// CupertinoNavigationBar на iOS, AppBar на Android.
PreferredSizeWidget buildAppBar({
  required BuildContext context,
  String? title,
  Widget? titleWidget,
  List<Widget>? actions,
  Widget? leading,
  bool automaticallyImplyLeading = true,
  Color? backgroundColor,
}) {
  if (isIOS) {
    final theme = Theme.of(context);
    return CupertinoNavigationBar(
      middle: titleWidget ??
          (title != null
              ? Text(title, style: TextStyle(color: theme.colorScheme.onSurface))
              : null),
      leading: leading,
      trailing: actions != null && actions.isNotEmpty
          ? Row(mainAxisSize: MainAxisSize.min, children: actions)
          : null,
      backgroundColor:
          backgroundColor ?? theme.scaffoldBackgroundColor.withValues(alpha: 0.85),
      border: Border(
        bottom: BorderSide(
          color: theme.dividerColor.withValues(alpha: 0.2),
          width: 0.5,
        ),
      ),
      automaticallyImplyLeading: automaticallyImplyLeading,
    );
  }
  return AppBar(
    title: titleWidget ?? (title != null ? Text(title) : null),
    actions: actions,
    leading: leading,
    automaticallyImplyLeading: automaticallyImplyLeading,
    backgroundColor: backgroundColor,
  );
}
