import 'package:flutter/material.dart';

/// Элемент сегментированного контрола.
class SegmentItem<T> {
  final T value;
  final String label;
  final IconData? icon;

  const SegmentItem({
    required this.value,
    required this.label,
    this.icon,
  });
}

/// Сегментированный контрол с плавной анимацией перемещающегося индикатора.
/// Выбранный сегмент подсвечивается перемещающимся контейнером.
class AnimatedSegmentedControl<T> extends StatefulWidget {
  final List<SegmentItem<T>> items;
  final T selectedValue;
  final ValueChanged<T> onSelected;
  final EdgeInsetsGeometry? padding;
  final double height;
  final BorderRadius? borderRadius;

  const AnimatedSegmentedControl({
    super.key,
    required this.items,
    required this.selectedValue,
    required this.onSelected,
    this.padding,
    this.height = 48,
    this.borderRadius,
  });

  @override
  State<AnimatedSegmentedControl<T>> createState() =>
      _AnimatedSegmentedControlState<T>();
}

class _AnimatedSegmentedControlState<T> extends State<AnimatedSegmentedControl<T>> {
  final List<GlobalKey> _itemKeys = [];
  Rect? _selectedItemRect;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _initializeKeys();
    _selectedIndex = _getSelectedIndex();
  }

  @override
  void didUpdateWidget(AnimatedSegmentedControl<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items.length != widget.items.length) {
      _initializeKeys();
    }
    final newIndex = _getSelectedIndex();
    if (newIndex != _selectedIndex) {
      setState(() {
        _selectedIndex = newIndex;
      });
      _updateSelectedItemRect();
    }
  }

  void _initializeKeys() {
    _itemKeys.clear();
    for (var i = 0; i < widget.items.length; i++) {
      _itemKeys.add(GlobalKey());
    }
  }

  int _getSelectedIndex() {
    return widget.items.indexWhere((item) => item.value == widget.selectedValue);
  }

  void _updateSelectedItemRect() {
    if (_selectedIndex >= 0 && _selectedIndex < _itemKeys.length) {
      final context = _itemKeys[_selectedIndex].currentContext;
      if (context != null) {
        final renderBox = context.findRenderObject() as RenderBox;
        final offset = renderBox.localToGlobal(Offset.zero);
        setState(() {
          _selectedItemRect = Rect.fromLTWH(
            offset.dx,
            offset.dy,
            renderBox.size.width,
            renderBox.size.height,
          );
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final borderRadius = widget.borderRadius ?? BorderRadius.circular(16);

    // Обновляем позицию индикатора после рендеринга
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateSelectedItemRect();
    });

    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          height: widget.height,
          padding: widget.padding ?? const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(
              alpha: isDark ? 0.4 : 0.6,
            ),
            borderRadius: borderRadius,
          ),
          child: Stack(
            children: [
              // Анимированный индикатор выбранного сегмента
              if (_selectedItemRect != null)
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOutCubic,
                  left: _getIndicatorLeft(constraints),
                  width: _getIndicatorWidth(constraints),
                  top: 4,
                  bottom: 4,
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark 
                          ? theme.colorScheme.primary.withValues(alpha: 0.3)
                          : theme.colorScheme.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.primary.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
              
              // Сегменты
              Row(
                children: widget.items.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  final isSelected = item.value == widget.selectedValue;
                  
                  return Expanded(
                    key: _itemKeys[index],
                    child: GestureDetector(
                      onTap: () {
                        if (!isSelected) {
                          widget.onSelected(item.value);
                        }
                      },
                      child: Container(
                        height: widget.height - 8,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (item.icon != null) ...[
                              Icon(
                                item.icon,
                                size: 18,
                                color: isSelected
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                              const SizedBox(width: 6),
                            ],
                            Flexible(
                              child: Text(
                                item.label,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: theme.textTheme.labelLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: isSelected
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.onSurface.withValues(alpha: 0.7),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  double _getIndicatorLeft(BoxConstraints constraints) {
    if (_selectedItemRect == null) return 0;
    
    final totalWidth = constraints.maxWidth;
    final segmentWidth = totalWidth / widget.items.length;
    return _selectedIndex * segmentWidth + 4; // +4 для учета padding
  }

  double _getIndicatorWidth(BoxConstraints constraints) {
    if (_selectedItemRect == null) return 0;
    
    final totalWidth = constraints.maxWidth;
    return totalWidth / widget.items.length - 8; // -8 для учета margin между сегментами
  }
}