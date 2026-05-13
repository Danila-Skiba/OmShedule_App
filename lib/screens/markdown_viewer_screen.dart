import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:url_launcher/url_launcher.dart';

/// Экран просмотра Markdown-конспекта с поддержкой LaTeX-формул.
class MarkdownViewerScreen extends StatelessWidget {
  final String title;
  final String subtitle;
  final String markdownContent;

  const MarkdownViewerScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.markdownContent,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;
    final onSurface = theme.colorScheme.onSurface;
    final onSurfaceVar = theme.colorScheme.onSurfaceVariant;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: onSurfaceVar,
              ),
            ),
          ],
        ),
      ),
      body: _MathMarkdownView(
        data: markdownContent,
        isDark: isDark,
        primary: primary,
        onSurface: onSurface,
      ),
    );
  }
}

/// Виджет для отображения Markdown с математическими формулами.
class _MathMarkdownView extends StatelessWidget {
  final String data;
  final bool isDark;
  final Color primary;
  final Color onSurface;

  const _MathMarkdownView({
    required this.data,
    required this.isDark,
    required this.primary,
    required this.onSurface,
  });

  @override
  Widget build(BuildContext context) {
    // Разбиваем контент на блоки: обычный md и блочные формулы $$...$$
    // Инлайн-формулы $...$ конвертируем в backtick-code внутри md
    final blocks = _parseBlockMathOnly(data);

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(20, 8, 20, MediaQuery.of(context).padding.bottom + 100),
      itemCount: blocks.length,
      itemBuilder: (context, index) {
        final block = blocks[index];
        if (block.isMath && block.isBlock) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: _buildMathBlock(context, block.content, true),
          );
        }
        // Заменяем инлайн $...$ на `...` чтобы _InlineMathBuilder обработал
        final processed = _convertInlineMathToCode(block.content);
        return MarkdownBody(
          data: processed,
          selectable: true,
          onTapLink: (text, href, title) {
            if (href != null) {
              launchUrl(Uri.parse(href), mode: LaunchMode.externalApplication);
            }
          },
          builders: {
            'code': _InlineMathBuilder(isDark: isDark, onSurface: onSurface),
          },
          styleSheet: _buildStyleSheet(context),
        );
      },
    );
  }

  /// Конвертирует инлайн-формулы $...$ в backtick-code `...` для обработки _InlineMathBuilder.
  static String _convertInlineMathToCode(String input) {
    // Заменяем $...$ (не $$) на `...`
    return input.replaceAllMapped(
      RegExp(r'(?<!\$)\$(?!\$)(.+?)(?<!\$)\$(?!\$)'),
      (m) => '`${m.group(1)}`',
    );
  }

  Widget _buildMathBlock(BuildContext context, String latex, bool isBlock) {
    final mathColor = onSurface;

    try {
      final mathWidget = Math.tex(
        latex.trim(),
        textStyle: TextStyle(fontSize: isBlock ? 18 : 15, color: mathColor),
        mathStyle: isBlock ? MathStyle.display : MathStyle.text,
      );

      if (isBlock) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.04)
                : primary.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : primary.withValues(alpha: 0.1),
            ),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: mathWidget,
          ),
        );
      }
      return mathWidget;
    } catch (_) {
      // Если LaTeX невалидный — показываем как текст
      return Text(
        latex,
        style: TextStyle(
          fontSize: 14,
          fontFamily: 'monospace',
          color: onSurface.withValues(alpha: 0.7),
        ),
      );
    }
  }

  MarkdownStyleSheet _buildStyleSheet(BuildContext context) {
    return MarkdownStyleSheet(
      h1: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: onSurface, height: 1.3),
      h1Padding: const EdgeInsets.only(top: 20, bottom: 8),
      h2: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: onSurface, height: 1.3),
      h2Padding: const EdgeInsets.only(top: 18, bottom: 6),
      h3: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: onSurface, height: 1.3),
      h3Padding: const EdgeInsets.only(top: 14, bottom: 4),
      h4: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: onSurface, height: 1.3),
      p: TextStyle(fontSize: 15, color: onSurface.withValues(alpha: 0.88), height: 1.6),
      pPadding: const EdgeInsets.only(bottom: 10),
      strong: TextStyle(fontWeight: FontWeight.w700, color: onSurface),
      em: TextStyle(fontStyle: FontStyle.italic, color: onSurface.withValues(alpha: 0.85)),
      listBullet: TextStyle(fontSize: 15, color: primary, fontWeight: FontWeight.w600),
      listBulletPadding: const EdgeInsets.only(right: 8),
      listIndent: 20,
      blockquote: TextStyle(fontSize: 14, color: onSurface.withValues(alpha: 0.7), fontStyle: FontStyle.italic, height: 1.5),
      blockquoteDecoration: BoxDecoration(
        color: isDark ? primary.withValues(alpha: 0.06) : primary.withValues(alpha: 0.04),
        border: Border(left: BorderSide(color: primary.withValues(alpha: 0.4), width: 3)),
        borderRadius: const BorderRadius.only(topRight: Radius.circular(8), bottomRight: Radius.circular(8)),
      ),
      blockquotePadding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      code: TextStyle(
        fontSize: 13,
        fontFamily: 'monospace',
        color: isDark ? const Color(0xFFE8B44C) : const Color(0xFFC9962E),
        backgroundColor: isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFF5F0E8),
      ),
      codeblockDecoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF7F4EF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2DDD5)),
      ),
      codeblockPadding: const EdgeInsets.all(14),
      horizontalRuleDecoration: BoxDecoration(
        border: Border(top: BorderSide(color: isDark ? Colors.white.withValues(alpha: 0.1) : onSurface.withValues(alpha: 0.1), width: 1)),
      ),
      a: TextStyle(color: primary, decoration: TextDecoration.underline, decorationColor: primary.withValues(alpha: 0.4)),
      tableHead: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: onSurface),
      tableBody: TextStyle(fontSize: 13, color: onSurface.withValues(alpha: 0.85)),
      tableBorder: TableBorder.all(
        color: isDark ? Colors.white.withValues(alpha: 0.1) : onSurface.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      tableHeadAlign: TextAlign.left,
      tableCellsPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      tableColumnWidth: const IntrinsicColumnWidth(),
    );
  }
}

/// Парсинг markdown на блоки: текст и блочные формулы ($$...$$).
/// Инлайн-формулы ($...$) обрабатываются отдельно в _convertInlineMathToCode.
class _ContentBlock {
  final String content;
  final bool isMath;
  final bool isBlock;

  const _ContentBlock(this.content, {this.isMath = false, this.isBlock = false});
}

List<_ContentBlock> _parseBlockMathOnly(String input) {
  final blocks = <_ContentBlock>[];
  final blockMathRegex = RegExp(r'\$\$([\s\S]*?)\$\$');
  int lastEnd = 0;

  for (final match in blockMathRegex.allMatches(input)) {
    if (match.start > lastEnd) {
      final textBefore = input.substring(lastEnd, match.start).trim();
      if (textBefore.isNotEmpty) {
        blocks.add(_ContentBlock(textBefore));
      }
    }
    blocks.add(_ContentBlock(match.group(1)!, isMath: true, isBlock: true));
    lastEnd = match.end;
  }

  if (lastEnd < input.length) {
    final remaining = input.substring(lastEnd).trim();
    if (remaining.isNotEmpty) {
      blocks.add(_ContentBlock(remaining));
    }
  }

  if (blocks.isEmpty) {
    blocks.add(_ContentBlock(input));
  }

  return blocks;
}

/// Builder для инлайн-кода, проверяет, не является ли код LaTeX-формулой.
class _InlineMathBuilder extends MarkdownElementBuilder {
  final bool isDark;
  final Color onSurface;

  _InlineMathBuilder({required this.isDark, required this.onSurface});

  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    final code = element.textContent;
    // Если код выглядит как LaTeX (содержит \, ^, _, {), рендерим как формулу
    if (_looksLikeLaTeX(code)) {
      try {
        return Math.tex(
          code,
          textStyle: TextStyle(fontSize: 14, color: onSurface),
          mathStyle: MathStyle.text,
        );
      } catch (_) {
        return null; // fallback к обычному коду
      }
    }
    return null; // обычный код
  }

  bool _looksLikeLaTeX(String s) {
    return s.contains('\\') ||
        s.contains('^') ||
        s.contains('_') ||
        s.contains('{') ||
        s.contains('\\frac') ||
        s.contains('\\sum') ||
        s.contains('\\int');
  }
}
