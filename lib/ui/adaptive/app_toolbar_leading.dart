import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../core/utils/platform_utils.dart';

/// Кнопка слева в верхней панели: «назад» или «закрыть».
///
/// На iOS 26 — нативная кнопка пакета со стеклом (`AdaptiveButton.sfSymbol`,
/// стиль по умолчанию `glass`): ровно та же, которую каркас ставит сам, когда
/// `leading` не задан. Раньше экраны рисовали здесь обычный `IconButton`, и на
/// стеклянном тулбаре он выглядел чужеродно — плоская иконка без подложки
/// рядом с нативными действиями справа.
///
/// На iOS ≤ 18 и Android — привычный `IconButton`: там у панели нет стекла, и
/// нативная кнопка пакета была бы такой же плоской, только другого размера.
///
/// Размер 38×38 совпадает с тем, что пакет использует для своей автоматической
/// кнопки возврата, — чтобы шапки экранов не отличались друг от друга.
class AppToolbarLeading extends StatelessWidget {
  /// Стрелка «назад».
  const AppToolbarLeading.back({super.key, this.onPressed})
      : _symbol = 'chevron.left',
        _isBack = true;

  /// Крестик «закрыть» — для экранов, которые открываются поверх как лист.
  const AppToolbarLeading.close({super.key, this.onPressed})
      : _symbol = 'xmark',
        _isBack = false;

  /// По умолчанию — закрыть текущий экран.
  final VoidCallback? onPressed;

  final String _symbol;
  final bool _isBack;

  IconData get _icon {
    if (_isBack) {
      return isIOS ? CupertinoIcons.back : Icons.arrow_back_rounded;
    }
    return isIOS ? CupertinoIcons.xmark : Icons.close_rounded;
  }

  @override
  Widget build(BuildContext context) {
    void handlePressed() {
      final callback = onPressed;
      if (callback != null) {
        callback();
        return;
      }
      Navigator.of(context).maybePop();
    }

    if (PlatformInfo.isIOS26OrHigher()) {
      return SizedBox(
        height: 38,
        width: 38,
        child: AdaptiveButton.sfSymbol(
          onPressed: handlePressed,
          sfSymbol: SFSymbol(_symbol, size: 20),
        ),
      );
    }

    return IconButton(
      icon: Icon(_icon),
      onPressed: handlePressed,
    );
  }
}
