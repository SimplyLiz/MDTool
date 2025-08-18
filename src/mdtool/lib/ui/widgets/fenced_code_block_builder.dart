import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/github.dart' as gh_theme;

class FencedCodeBlockBuilder extends MarkdownElementBuilder {
  final bool isDarkTheme;

  FencedCodeBlockBuilder({required this.isDarkTheme});

  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    // We only handle <code> elements that have a language class
    if (element.tag != 'code') return null;
    
    final classAttr = element.attributes['class'] ?? '';
    if (!classAttr.startsWith('language-')) return null;
    
    // Safety check for empty or invalid content
    final rawCode = element.textContent;
    if (rawCode.trim().isEmpty) return null;

    // language comes from the "class" attribute: e.g. "language-dart"
    final lang = classAttr.startsWith('language-')
        ? classAttr.substring('language-'.length)
        : ''; // empty -> auto

    final normalizedLang = _normalizeLanguage(lang);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: isDarkTheme ? const Color(0xFF1E1E1E) : const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Language label and copy button
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isDarkTheme ? const Color(0xFF2D2D2D) : const Color(0xFFE8E8E8),
              borderRadius: normalizedLang.isNotEmpty
                  ? const BorderRadius.only(
                      topLeft: Radius.circular(8),
                      topRight: Radius.circular(8),
                    )
                  : BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                if (normalizedLang.isNotEmpty) ...[
                  Text(
                    normalizedLang,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isDarkTheme ? Colors.white70 : Colors.black87,
                      fontFamily: 'Monaco',
                    ),
                  ),
                  const Spacer(),
                ],
                // Copy button
                _CopyButton(
                  code: rawCode,
                  isDarkTheme: isDarkTheme,
                ),
              ],
            ),
          ),
          // Code content
          Padding(
            padding: const EdgeInsets.all(12),
            child: SizedBox(
              width: double.infinity,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: _buildHighlightedCode(rawCode, normalizedLang),
              ),
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


  Widget _buildHighlightedCode(String code, String language) {
    // Use async highlighting for large code blocks (>1000 characters or >50 lines)
    final isLargeCodeBlock = code.length > 1000 || code.split('\n').length > 50;
    
    if (isLargeCodeBlock) {
      return FutureBuilder<Widget>(
        future: _computeHighlighting(code, language),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: isDarkTheme ? Colors.white70 : Colors.black54,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Highlighting code...',
                    style: TextStyle(
                      fontFamily: 'Monaco',
                      fontSize: 13,
                      color: isDarkTheme ? Colors.white70 : Colors.black54,
                    ),
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
      return HighlightView(
        code,
        language: language.isEmpty ? null : language,
        theme: isDarkTheme ? _customDarkTheme() : gh_theme.githubTheme,
        tabSize: 2,
        textStyle: const TextStyle(
          fontFamily: 'Monaco',
          fontSize: 13,
        ),
      );
    }
  }

  Future<Widget> _computeHighlighting(String code, String language) async {
    return await compute(_highlightInBackground, {
      'code': code,
      'language': language,
      'isDarkTheme': isDarkTheme,
    });
  }

  Widget _buildFallbackText(String code) {
    return Text(
      code,
      style: TextStyle(
        fontFamily: 'Monaco',
        fontSize: 13,
        color: isDarkTheme ? Colors.white : Colors.black,
      ),
    );
  }

  Map<String, TextStyle> _customDarkTheme() {
    // Custom dark theme optimized for better visibility and contrast
    return {
      'root': const TextStyle(
        backgroundColor: Color(0xFF1E1E1E),
        color: Color(0xFFD4D4D4), // Light gray for default text
      ),
      'keyword': const TextStyle(
        color: Color(0xFF569CD6), // Bright blue for keywords (void, class, etc.)
        fontWeight: FontWeight.bold,
      ),
      'built_in': const TextStyle(
        color: Color(0xFF4EC9B0), // Cyan for built-in types (String, int, List)
      ),
      'type': const TextStyle(
        color: Color(0xFF4EC9B0), // Cyan for types
      ),
      'string': const TextStyle(
        color: Color(0xFFCE9178), // Orange for strings
      ),
      'number': const TextStyle(
        color: Color(0xFFB5CEA8), // Light green for numbers
      ),
      'comment': const TextStyle(
        color: Color(0xFF6A9955), // Green for comments
        fontStyle: FontStyle.italic,
      ),
      'function': const TextStyle(
        color: Color(0xFFDCDCAA), // Yellow for function names
      ),
      'variable': const TextStyle(
        color: Color(0xFF9CDCFE), // Light blue for variables
      ),
      'property': const TextStyle(
        color: Color(0xFF9CDCFE), // Light blue for properties
      ),
      'attr': const TextStyle(
        color: Color(0xFF92C5F8), // Light blue for attributes
      ),
      'symbol': const TextStyle(
        color: Color(0xFFD4D4D4), // Default color for symbols
      ),
      'punctuation': const TextStyle(
        color: Color(0xFFD4D4D4), // Default color for punctuation
      ),
      'literal': const TextStyle(
        color: Color(0xFF569CD6), // Blue for literals (true, false, null)
      ),
      'tag': const TextStyle(
        color: Color(0xFF569CD6), // Blue for HTML/XML tags
      ),
      'name': const TextStyle(
        color: Color(0xFF4FC1FF), // Bright blue for names
      ),
      'class': const TextStyle(
        color: Color(0xFF4EC9B0), // Cyan for class names
        fontWeight: FontWeight.bold,
      ),
      'title': const TextStyle(
        color: Color(0xFFDCDCAA), // Yellow for titles/function definitions
        fontWeight: FontWeight.bold,
      ),
      'params': const TextStyle(
        color: Color(0xFF9CDCFE), // Light blue for parameters
      ),
      'meta': const TextStyle(
        color: Color(0xFF569CD6), // Blue for meta information
      ),
      'operator': const TextStyle(
        color: Color(0xFFD4D4D4), // Default color for operators
      ),
    };
  }
}

// Static function for compute() - must be top-level or static
Widget _highlightInBackground(Map<String, dynamic> params) {
  final String code = params['code'];
  final String language = params['language'];
  final bool isDarkTheme = params['isDarkTheme'];
  
  // Create the theme
  final theme = isDarkTheme ? _createCustomDarkTheme() : gh_theme.githubTheme;
  
  return HighlightView(
    code,
    language: language.isEmpty ? null : language,
    theme: theme,
    tabSize: 2,
    textStyle: const TextStyle(
      fontFamily: 'Monaco',
      fontSize: 13,
    ),
  );
}

// Static function to create dark theme (for use in isolate)
Map<String, TextStyle> _createCustomDarkTheme() {
  return {
    'root': const TextStyle(
      backgroundColor: Color(0xFF1E1E1E),
      color: Color(0xFFD4D4D4),
    ),
    'keyword': const TextStyle(
      color: Color(0xFF569CD6),
      fontWeight: FontWeight.bold,
    ),
    'built_in': const TextStyle(
      color: Color(0xFF4EC9B0),
    ),
    'type': const TextStyle(
      color: Color(0xFF4EC9B0),
    ),
    'string': const TextStyle(
      color: Color(0xFFCE9178),
    ),
    'number': const TextStyle(
      color: Color(0xFFB5CEA8),
    ),
    'comment': const TextStyle(
      color: Color(0xFF6A9955),
      fontStyle: FontStyle.italic,
    ),
    'function': const TextStyle(
      color: Color(0xFFDCDCAA),
    ),
    'variable': const TextStyle(
      color: Color(0xFF9CDCFE),
    ),
    'property': const TextStyle(
      color: Color(0xFF9CDCFE),
    ),
    'attr': const TextStyle(
      color: Color(0xFF92C5F8),
    ),
    'symbol': const TextStyle(
      color: Color(0xFFD4D4D4),
    ),
    'punctuation': const TextStyle(
      color: Color(0xFFD4D4D4),
    ),
    'literal': const TextStyle(
      color: Color(0xFF569CD6),
    ),
    'tag': const TextStyle(
      color: Color(0xFF569CD6),
    ),
    'name': const TextStyle(
      color: Color(0xFF4FC1FF),
    ),
    'class': const TextStyle(
      color: Color(0xFF4EC9B0),
      fontWeight: FontWeight.bold,
    ),
    'title': const TextStyle(
      color: Color(0xFFDCDCAA),
      fontWeight: FontWeight.bold,
    ),
    'params': const TextStyle(
      color: Color(0xFF9CDCFE),
    ),
    'meta': const TextStyle(
      color: Color(0xFF569CD6),
    ),
    'operator': const TextStyle(
      color: Color(0xFFD4D4D4),
    ),
  };
}

class _CopyButton extends StatefulWidget {
  final String code;
  final bool isDarkTheme;

  const _CopyButton({
    required this.code,
    required this.isDarkTheme,
  });

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
    return InkWell(
      onTap: _copyToClipboard,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: _isCopied
              ? (widget.isDarkTheme ? Colors.green.shade700 : Colors.green.shade100)
              : (widget.isDarkTheme ? Colors.white : Colors.black).withOpacity(0.1),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _isCopied ? Icons.check : Icons.copy,
              size: 14,
              color: _isCopied
                  ? (widget.isDarkTheme ? Colors.green.shade300 : Colors.green.shade700)
                  : (widget.isDarkTheme ? Colors.white70 : Colors.black54),
            ),
            const SizedBox(width: 4),
            Text(
              _isCopied ? 'Copied!' : 'Copy',
              style: TextStyle(
                fontSize: 11,
                color: _isCopied
                    ? (widget.isDarkTheme ? Colors.green.shade300 : Colors.green.shade700)
                    : (widget.isDarkTheme ? Colors.white70 : Colors.black54),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}