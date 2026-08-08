import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:flutter/material.dart';

/// Нативный таб-бар iOS 26 с работающим одиночным нажатием.
///
/// Пакет отдаёт `UITabBar` через `UiKitView` и объявляет ему
/// `gestureRecognizers: {TapGestureRecognizer}`. Из-за этого одиночный тап
/// забирает арена жестов Flutter и до нативного вида он не доходит —
/// вкладка переключается только протягиванием пальца вдоль панели
/// (протягивание как жест не заявлено, поэтому уходит в нативный вид напрямую).
/// Публичной настройки для этого у пакета нет.
///
/// Обход: поверх нативной панели лежит прозрачный слой, который ловит
/// **только** тапы и сам сообщает выбранный индекс. Всё остальное —
/// отрисовка Liquid Glass, «ползунок» выделения, протягивание — остаётся
/// нативным: слой прозрачен для любых жестов, кроме одиночного нажатия.
class AppNativeTabBar extends StatelessWidget {
  const AppNativeTabBar({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onTap,
    this.selectedItemColor,
    this.unselectedItemColor,
  });

  final List<AdaptiveNavigationDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onTap;
  final Color? selectedItemColor;
  final Color? unselectedItemColor;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        IOS26NativeTabBar(
          destinations: destinations,
          selectedIndex: selectedIndex,
          onTap: onTap,
          tint: selectedItemColor,
          unselectedItemTint: unselectedItemColor,
          // never — панель не должна ужиматься при скролле: пакет анимирует её
          // через Transform/Opacity поверх platform view, и попадания по
          // нативному виду начинают приходиться мимо.
          minimizeBehavior: TabBarMinimizeBehavior.never,
        ),
        Positioned.fill(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final itemWidth = constraints.maxWidth / destinations.length;

              return GestureDetector(
                // translucent, а не opaque: слой не должен забирать у нативной
                // панели остальные касания, только участвовать в разборе тапа.
                behavior: HitTestBehavior.translucent,
                // Только onTapUp — жесты протягивания слой не заявляет,
                // поэтому арена отдаёт их нативному виду, как и раньше.
                onTapUp: (details) {
                  if (itemWidth <= 0) return;
                  final index = (details.localPosition.dx / itemWidth)
                      .floor()
                      .clamp(0, destinations.length - 1);
                  if (index == selectedIndex) return;
                  onTap(index);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
