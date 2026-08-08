import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:flutter/material.dart';

/// Конфигурация верхней панели. На iOS 26+ — нативный `UIToolbar` со стеклом.
typedef AppAppBar = AdaptiveAppBar;

/// Действие в верхней панели (`iosSymbol` — SF Symbol для iOS 26+,
/// `icon` — фолбэк для iOS ≤ 18 и Android).
typedef AppAppBarAction = AdaptiveAppBarAction;

/// Конфигурация нижней навигации. На iOS 26+ — нативный `UITabBar`.
typedef AppBottomNavigationBar = AdaptiveBottomNavigationBar;

/// Пункт нижней навигации.
typedef AppNavigationDestination = AdaptiveNavigationDestination;

/// Каркас экрана.
///
/// iOS 26+ — нативные toolbar/tab bar с Liquid Glass, iOS ≤ 18 —
/// `CupertinoPageScaffold`, Android — `Scaffold`.
class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    this.appBar,
    this.bottomNavigationBar,
    this.body,
    this.floatingActionButton,
    this.resizeToAvoidBottomInset,
    this.extendBodyBehindAppBar = false,
    this.enableBlur = true,
    this.applyTopSafeArea = true,
  });

  final AdaptiveAppBar? appBar;
  final AdaptiveBottomNavigationBar? bottomNavigationBar;
  final Widget? body;
  final Widget? floatingActionButton;
  final bool? resizeToAvoidBottomInset;
  final bool extendBodyBehindAppBar;
  final bool enableBlur;

  /// Обернуть [body] в `SafeArea` сверху.
  ///
  /// На iOS 26 стеклянный тулбар рисуется оверлеем поверх контента и, в отличие
  /// от Material `Scaffold` с непрозрачным `AppBar`, тело не сдвигает. Пакет
  /// вместо этого увеличивает `MediaQuery.padding.top` на высоту тулбара и
  /// рассчитывает, что страница разберётся сама через `SafeArea` — иначе
  /// контент уезжает под тулбар и строку состояния.
  ///
  /// Отключайте, только если экран сам обрабатывает верхний отступ.
  final bool applyTopSafeArea;

  @override
  Widget build(BuildContext context) {
    // Сдвигаем тело лишь при наличии своей панели: у каркаса без appBar
    // (оболочка с нижней навигацией) SafeArea съела бы отступ, который нужен
    // вложенному экрану под его собственный тулбар.
    final effectiveBody = body != null && appBar != null && applyTopSafeArea
        ? SafeArea(bottom: false, child: body!)
        : body;

    return AdaptiveScaffold(
      appBar: appBar,
      bottomNavigationBar: bottomNavigationBar,
      body: effectiveBody,
      floatingActionButton: floatingActionButton,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      enableBlur: enableBlur,
    );
  }
}
