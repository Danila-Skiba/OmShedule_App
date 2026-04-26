import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';

/// Экран просмотра Markdown-конспекта.
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
      body: Markdown(
        data: markdownContent,
        selectable: true,
        padding: EdgeInsets.fromLTRB(20, 8, 20, MediaQuery.of(context).padding.bottom + 100),
        onTapLink: (text, href, title) {
          if (href != null) {
            launchUrl(Uri.parse(href), mode: LaunchMode.externalApplication);
          }
        },
        styleSheet: MarkdownStyleSheet(
          // ── Заголовки ──
          h1: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: onSurface,
            height: 1.3,
          ),
          h1Padding: const EdgeInsets.only(top: 20, bottom: 8),
          h2: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: onSurface,
            height: 1.3,
          ),
          h2Padding: const EdgeInsets.only(top: 18, bottom: 6),
          h3: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: onSurface,
            height: 1.3,
          ),
          h3Padding: const EdgeInsets.only(top: 14, bottom: 4),
          h4: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: onSurface,
            height: 1.3,
          ),

          // ── Текст ──
          p: TextStyle(
            fontSize: 15,
            color: onSurface.withOpacity(0.88),
            height: 1.6,
          ),
          pPadding: const EdgeInsets.only(bottom: 10),

          // ── Жирный / курсив ──
          strong: TextStyle(
            fontWeight: FontWeight.w700,
            color: onSurface,
          ),
          em: TextStyle(
            fontStyle: FontStyle.italic,
            color: onSurface.withOpacity(0.85),
          ),

          // ── Списки ──
          listBullet: TextStyle(
            fontSize: 15,
            color: primary,
            fontWeight: FontWeight.w600,
          ),
          listBulletPadding: const EdgeInsets.only(right: 8),
          listIndent: 20,

          // ── Цитаты ──
          blockquote: TextStyle(
            fontSize: 14,
            color: onSurface.withOpacity(0.7),
            fontStyle: FontStyle.italic,
            height: 1.5,
          ),
          blockquoteDecoration: BoxDecoration(
            color: isDark
                ? primary.withOpacity(0.06)
                : primary.withOpacity(0.04),
            border: Border(
              left: BorderSide(
                color: primary.withOpacity(0.4),
                width: 3,
              ),
            ),
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(8),
              bottomRight: Radius.circular(8),
            ),
          ),
          blockquotePadding: const EdgeInsets.fromLTRB(14, 10, 14, 10),

          // ── Код инлайн ──
          code: TextStyle(
            fontSize: 13,
            fontFamily: 'monospace',
            color: isDark ? const Color(0xFFE8B44C) : const Color(0xFFC9962E),
            backgroundColor: isDark
                ? Colors.white.withOpacity(0.06)
                : const Color(0xFFF5F0E8),
          ),

          // ── Блок кода ──
          codeblockDecoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.05)
                : const Color(0xFFF7F4EF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.08)
                  : const Color(0xFFE2DDD5),
            ),
          ),
          codeblockPadding: const EdgeInsets.all(14),

          // ── Горизонтальная линия ──
          horizontalRuleDecoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: isDark
                    ? Colors.white.withOpacity(0.1)
                    : onSurface.withOpacity(0.1),
                width: 1,
              ),
            ),
          ),

          // ── Ссылки ──
          a: TextStyle(
            color: primary,
            decoration: TextDecoration.underline,
            decorationColor: primary.withOpacity(0.4),
          ),

          // ── Таблицы ──
          tableHead: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: onSurface,
          ),
          tableBody: TextStyle(
            fontSize: 13,
            color: onSurface.withOpacity(0.85),
          ),
          tableBorder: TableBorder.all(
            color: isDark
                ? Colors.white.withOpacity(0.1)
                : onSurface.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          tableHeadAlign: TextAlign.left,
          tableCellsPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          tableColumnWidth: const IntrinsicColumnWidth(),
        ),
      ),
    );
  }
}
