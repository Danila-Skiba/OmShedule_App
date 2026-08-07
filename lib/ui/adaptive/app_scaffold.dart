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
  });

  final AdaptiveAppBar? appBar;
  final AdaptiveBottomNavigationBar? bottomNavigationBar;
  final Widget? body;
  final Widget? floatingActionButton;
  final bool? resizeToAvoidBottomInset;
  final bool extendBodyBehindAppBar;
  final bool enableBlur;

  @override
  Widget build(BuildContext context) {
    return AdaptiveScaffold(
      appBar: appBar,
      bottomNavigationBar: bottomNavigationBar,
      body: body,
      floatingActionButton: floatingActionButton,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      enableBlur: enableBlur,
    );
  }
}
