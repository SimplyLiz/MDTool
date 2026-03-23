import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/github.dart' as gh_theme;
import 'package:flutter_highlight/themes/vs2015.dart' as vs_dark_theme;
import '../themes/app_theme.dart';

class FencedCodeBlockBuilder extends MarkdownElementBuilder {
  final BuildContext context;

  FencedCodeBlockBuilder({required this.context});

  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    // We handle <code> elements (both with and without language classes)
    if (element.tag != 'code') return null;

    final classAttr = element.attributes['class'] ?? '';
    // Handle both language-specific and plain code blocks
    final hasLanguage = classAttr.startsWith('language-');

    // We can assume this is a fenced code block if we reach here
    // (inline code is handled differently by flutter_markdown)

    // Safety check for empty or invalid content
    final rawCode = element.textContent;
    if (rawCode.trim().isEmpty) return null;

    // language comes from the "class" attribute: e.g. "language-dart"
    final lang = hasLanguage ? classAttr.substring('language-'.length) : ''; // empty -> no syntax highlighting

    final normalizedLang = _normalizeLanguage(lang);

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDarkTheme = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(color: colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Language label and copy button
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isDarkTheme ? colorScheme.surfaceContainerHigh : colorScheme.surfaceContainer,
              borderRadius: normalizedLang.isNotEmpty ? const BorderRadius.only(topLeft: Radius.circular(8), topRight: Radius.circular(8)) : BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                if (normalizedLang.isNotEmpty) ...[
                  Text(
                    normalizedLang,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: colorScheme.onSurface, fontFamily: 'Monaco'),
                  ),
                ],
                const Spacer(),
                // Copy button
                _CopyButton(code: rawCode, context: context),
              ],
            ),
          ),
          // Code content
          Padding(
            padding: const EdgeInsets.all(12),
            child: SizedBox(
              width: double.infinity,
              child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: _buildHighlightedCode(rawCode, normalizedLang, isDarkTheme)),
            ),
          ),
        ],
      ),
    );
    // Returning a Widget replaces the default rendering for this element.
  }

  String _normalizeLanguage(String language) {
    // Normalize common language aliases
    switch (language.toLowerCase()) {
      case 'js':
        return 'javascript';
      case 'ts':
        return 'typescript';
      case 'sh':
      case 'shell':
        return 'bash';
      case 'yml':
        return 'yaml';
      case 'md':
        return 'markdown';
      default:
        return language;
    }
  }

  Widget _buildHighlightedCode(String code, String language, bool isDarkTheme) {
    // Use async highlighting for large code blocks (>1000 characters or >50 lines)
    final isLargeCodeBlock = code.length > 1000 || code.split('\n').length > 50;

    if (isLargeCodeBlock) {
      return FutureBuilder<Widget>(
        future: _computeHighlighting(code, language, isDarkTheme),
        builder: (context, snapshot) {
          final loadingColorScheme = Theme.of(context).colorScheme;
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: loadingColorScheme.onSurface.withValues(alpha: 0.7))),
                  const SizedBox(width: 8),
                  Text(
                    'Highlighting code...',
                    style: TextStyle(fontFamily: 'Monaco', fontSize: 13, color: loadingColorScheme.onSurface.withValues(alpha: 0.7)),
                  ),
                ],
              ),
            );
          }

          if (snapshot.hasError) {
            return _buildFallbackText(code);
          }

          return snapshot.data ?? _buildFallbackText(code);
        },
      );
    } else {
      // Use synchronous highlighting for smaller code blocks
      if (language.isEmpty) {
        // For plain code blocks, use Text widget without syntax highlighting
        return Text(
          code,
          style: TextStyle(fontFamily: 'Monaco', fontSize: 13, color: Theme.of(context).colorScheme.onSurface),
        );
      } else {
        return HighlightView(
          code,
          language: language,
          theme: isDarkTheme ? _getTransparentVs2015Theme() : _getTransparentGitHubTheme(),
          tabSize: 2,
          padding: EdgeInsets.zero,
          textStyle: const TextStyle(fontFamily: 'Monaco', fontSize: 13),
        );
      }
    }
  }

  Future<Widget> _computeHighlighting(String code, String language, bool isDarkTheme) async {
    return await compute(_highlightInBackground, {'code': code, 'language': language, 'isDarkTheme': isDarkTheme});
  }

  Widget _buildFallbackText(String code) {
    final colorScheme = Theme.of(context).colorScheme;
    return Text(
      code,
      style: TextStyle(fontFamily: 'Monaco', fontSize: 13, color: colorScheme.onSurface),
    );
  }

  Map<String, TextStyle> _getTransparentVs2015Theme() {
    // Copy vs2015 theme but set transparent background for root
    final theme = Map<String, TextStyle>.from(vs_dark_theme.vs2015Theme);
    theme['root'] = const TextStyle(color: Color(0xffDCDCDC), backgroundColor: Colors.transparent);
    return theme;
  }

  Map<String, TextStyle> _getTransparentGitHubTheme() {
    // Copy GitHub theme but remove all background colors
    final theme = <String, TextStyle>{};
    gh_theme.githubTheme.forEach((key, style) {
      // Create new TextStyle without backgroundColor
      theme[key] = TextStyle(
        color: style.color,
        fontWeight: style.fontWeight,
        fontStyle: style.fontStyle,
        decoration: style.decoration,
        backgroundColor: Colors.transparent,
        // Explicitly set transparent background
      );
    });
    // Ensure root has transparent background
    theme['root'] = TextStyle(
      color: theme['root']?.color ?? const Color(0xFF000000),
      backgroundColor: Colors.transparent,
    );
    return theme;
  }
}

// Static function for compute() - must be top-level or static
Widget _highlightInBackground(Map<String, dynamic> params) {
  final String code = params['code'];
  final String language = params['language'];
  final bool isDarkTheme = params['isDarkTheme'];

  if (language.isEmpty) {
    // For plain code blocks, use Text widget without syntax highlighting
    return Text(
      code,
      style: TextStyle(fontFamily: 'Monaco', fontSize: 13, color: isDarkTheme ? const Color(0xFFD4D4D4) : const Color(0xFF000000)),
    );
  }

  // Create the theme with transparent background for both modes
  final theme = isDarkTheme ? _createTransparentVs2015Theme() : _createTransparentGitHubTheme();

  return HighlightView(
    code,
    language: language,
    theme: theme,
    tabSize: 2,
    padding: EdgeInsets.zero,
    textStyle: const TextStyle(fontFamily: 'Monaco', fontSize: 13),
  );
}

// Static function to create transparent vs2015 theme (for use in isolate)
Map<String, TextStyle> _createTransparentVs2015Theme() {
  final theme = Map<String, TextStyle>.from(vs_dark_theme.vs2015Theme);
  theme['root'] = const TextStyle(color: Color(0xffDCDCDC), backgroundColor: Colors.transparent);
  return theme;
}

// Static function to create transparent GitHub theme (for use in isolate)
Map<String, TextStyle> _createTransparentGitHubTheme() {
  // Copy GitHub theme but remove all background colors
  final theme = <String, TextStyle>{};
  gh_theme.githubTheme.forEach((key, style) {
    // Create new TextStyle without backgroundColor
    theme[key] = TextStyle(
      color: style.color,
      fontWeight: style.fontWeight,
      fontStyle: style.fontStyle,
      decoration: style.decoration,
      backgroundColor: Colors.transparent,
      // Explicitly set transparent background
    );
  });
  // Ensure root has transparent background
  theme['root'] = TextStyle(
    color: theme['root']?.color ?? const Color(0xFF000000),
    backgroundColor: Colors.transparent,
  );
  return theme;
}

class _CopyButton extends StatefulWidget {
  final String code;
  final BuildContext context;

  const _CopyButton({required this.code, required this.context});

  @override
  State<_CopyButton> createState() => _CopyButtonState();
}

class _CopyButtonState extends State<_CopyButton> {
  bool _isCopied = false;

  void _copyToClipboard() async {
    await Clipboard.setData(ClipboardData(text: widget.code));

    setState(() {
      _isCopied = true;
    });

    // Reset the copied state after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isCopied = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: _copyToClipboard,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(color: _isCopied ? (isDarkTheme ? AppTheme.darkSuccessBackground : AppTheme.lightSuccessBackground) : colorScheme.onSurface.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_isCopied ? Icons.check : Icons.copy, size: 14, color: _isCopied ? AppTheme.successGreen : colorScheme.onSurface.withValues(alpha: 0.7)),
            const SizedBox(width: 4),
            Text(
              _isCopied ? 'Copied!' : 'Copy',
              style: TextStyle(fontSize: 11, color: _isCopied ? AppTheme.successGreen : colorScheme.onSurface.withValues(alpha: 0.7), fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}
