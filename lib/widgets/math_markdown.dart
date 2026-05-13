import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:url_launcher/url_launcher.dart';

/// Виджет Markdown с поддержкой LaTeX формул.
///
/// Поддерживает:
/// - Инлайн формулы: `$E = mc^2$`
/// - Блочные формулы: `$$\int_a^b f(x)dx$$`
/// - Многострочные блочные формулы
class MathMarkdownViewer extends StatelessWidget {
  final String content;
  final bool selectable;
  final EdgeInsets? padding;

  const MathMarkdownViewer({
    super.key,
    required this.content,
    this.selectable = true,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;
    final onSurface = theme.colorScheme.onSurface;

    // Разбиваем контент на текстовые и math-блоки
    final segments = _parseContent(content);

    return ListView.builder(
      padding: padding ?? EdgeInsets.fromLTRB(20, 8, 20, MediaQuery.of(context).padding.bottom + 100),
      itemCount: segments.length,
      itemBuilder: (context, index) {
        final seg = segments[index];
        if (seg.isMath) {
          return _buildMathBlock(seg.text, seg.isBlock, theme, isDark, primary, onSurface);
        } else {
          return MarkdownBody(
            data: seg.text,
            selectable: selectable,
            onTapLink: (text, href, title) {
              if (href != null) {
                launchUrl(Uri.parse(href), mode: LaunchMode.externalApplication);
              }
            },
            extensionSet: md.ExtensionSet.gitHubWeb,
            styleSheet: _buildStyleSheet(theme, isDark, primary, onSurface),
          );
        }
      },
    );
  }

  Widget _buildMathBlock(
    String tex,
    bool isBlock,
    ThemeData theme,
    bool isDark,
    Color primary,
    Color onSurface,
  ) {
    if (isBlock) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
            child: Math.tex(
              tex.trim(),
              textStyle: TextStyle(
                fontSize: 18,
                color: onSurface,
              ),
              mathStyle: MathStyle.display,
              onErrorFallback: (err) => Text(
                tex.trim(),
                style: TextStyle(
                  fontSize: 14,
                  fontFamily: 'monospace',
                  color: onSurface.withValues(alpha: 0.7),
                ),
              ),
            ),
          ),
        ),
      );
    } else {
      // Инлайн — не рендерим отдельно, он встроен в текст
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Math.tex(
            tex.trim(),
            textStyle: TextStyle(
              fontSize: 15,
              color: onSurface,
            ),
            mathStyle: MathStyle.text,
            onErrorFallback: (err) => Text(
              tex.trim(),
              style: TextStyle(
                fontSize: 14,
                fontFamily: 'monospace',
                color: onSurface.withValues(alpha: 0.7),
              ),
            ),
          ),
        ),
      );
    }
  }

  MarkdownStyleSheet _buildStyleSheet(
    ThemeData theme,
    bool isDark,
    Color primary,
    Color onSurface,
  ) {
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
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(8),
          bottomRight: Radius.circular(8),
        ),
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
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.white.withValues(alpha: 0.1) : onSurface.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
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

// =============================================================================
// Парсер: разделяет текст на обычный Markdown и LaTeX
// =============================================================================

class _ContentSegment {
  final String text;
  final bool isMath;
  final bool isBlock;

  const _ContentSegment(this.text, {this.isMath = false, this.isBlock = false});
}

/// Компактный виджет для рендера math-markdown внутри чата (не скроллится).
class MathMarkdownBody extends StatelessWidget {
  final String content;
  final Color? textColor;

  const MathMarkdownBody({super.key, required this.content, this.textColor});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final onSurface = textColor ?? theme.colorScheme.onSurface;
    final segments = _parseContent(content);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: segments.map((seg) {
        if (seg.isMath) {
          if (seg.isBlock) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Math.tex(
                  seg.text.trim(),
                  textStyle: TextStyle(fontSize: 16, color: onSurface),
                  mathStyle: MathStyle.display,
                  onErrorFallback: (err) => Text(
                    seg.text.trim(),
                    style: TextStyle(fontSize: 13, fontFamily: 'monospace', color: onSurface.withValues(alpha: 0.7)),
                  ),
                ),
              ),
            );
          } else {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Math.tex(
                seg.text.trim(),
                textStyle: TextStyle(fontSize: 14, color: onSurface),
                mathStyle: MathStyle.text,
                onErrorFallback: (err) => Text(
                  seg.text.trim(),
                  style: TextStyle(fontSize: 13, fontFamily: 'monospace', color: onSurface.withValues(alpha: 0.7)),
                ),
              ),
            );
          }
        } else {
          return MarkdownBody(
            data: seg.text,
            selectable: false,
            shrinkWrap: true,
            styleSheet: MarkdownStyleSheet(
              p: TextStyle(fontSize: 14, color: onSurface, height: 1.4),
              strong: TextStyle(fontWeight: FontWeight.w700, color: onSurface),
              em: TextStyle(fontStyle: FontStyle.italic, color: onSurface.withValues(alpha: 0.85)),
              code: TextStyle(
                fontSize: 12,
                fontFamily: 'monospace',
                color: isDark ? const Color(0xFFE8B44C) : const Color(0xFFC9962E),
              ),
              h1: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: onSurface),
              h2: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: onSurface),
              h3: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: onSurface),
              listBullet: TextStyle(fontSize: 14, color: onSurface),
            ),
          );
        }
      }).toList(),
    );
  }
}

/// Парсит контент на сегменты Markdown и LaTeX.
List<_ContentSegment> _parseContent(String input) {
  final segments = <_ContentSegment>[];
  // Регулярка: $$...$$  или $...$  (не экранированные)
  final regex = RegExp(r'(\$\$[\s\S]*?\$\$|\$[^\$\n]+?\$)');
  int lastEnd = 0;

  for (final match in regex.allMatches(input)) {
    // Текст до формулы
    if (match.start > lastEnd) {
      final before = input.substring(lastEnd, match.start).trim();
      if (before.isNotEmpty) {
        segments.add(_ContentSegment(before));
      }
    }

    final raw = match.group(0)!;
    if (raw.startsWith(r'$$') && raw.endsWith(r'$$')) {
      // Блочная формула
      final tex = raw.substring(2, raw.length - 2);
      segments.add(_ContentSegment(tex, isMath: true, isBlock: true));
    } else {
      // Инлайн формула
      final tex = raw.substring(1, raw.length - 1);
      segments.add(_ContentSegment(tex, isMath: true, isBlock: false));
    }
    lastEnd = match.end;
  }

  // Остаток текста
  if (lastEnd < input.length) {
    final rest = input.substring(lastEnd).trim();
    if (rest.isNotEmpty) {
      segments.add(_ContentSegment(rest));
    }
  }

  return segments.isEmpty ? [_ContentSegment(input)] : segments;
}
