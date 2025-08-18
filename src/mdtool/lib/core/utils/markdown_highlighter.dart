import 'package:flutter/material.dart';
import 'package:highlight/highlight.dart';

class MarkdownHighlighter {
  static final Map<String, TextStyle> _lightTheme = {
    'root': const TextStyle(color: Color(0xFF24292E)),
    'title': const TextStyle(color: Color(0xFF0969DA), fontWeight: FontWeight.bold),
    'section': const TextStyle(color: Color(0xFF0969DA), fontWeight: FontWeight.bold),
    'strong': const TextStyle(fontWeight: FontWeight.bold),
    'emphasis': const TextStyle(fontStyle: FontStyle.italic),
    'code': const TextStyle(
      color: Color(0xFFE36209),
      fontFamily: 'Monaco',
      backgroundColor: Color(0xFFF6F8FA),
    ),
    'string': const TextStyle(color: Color(0xFF0A3069)),
    'link': const TextStyle(color: Color(0xFF0969DA), decoration: TextDecoration.underline),
    'quote': const TextStyle(color: Color(0xFF656D76), fontStyle: FontStyle.italic),
    'comment': const TextStyle(color: Color(0xFF656D76)),
    'meta': const TextStyle(color: Color(0xFF8250DF)),
    'keyword': const TextStyle(color: Color(0xFFCF222E), fontWeight: FontWeight.bold),
    'bullet': const TextStyle(color: Color(0xFF0969DA)),
    'number': const TextStyle(color: Color(0xFF0969DA)),
  };

  static final Map<String, TextStyle> _darkTheme = {
    'root': const TextStyle(color: Color(0xFFC9D1D9)),
    'title': const TextStyle(color: Color(0xFF58A6FF), fontWeight: FontWeight.bold),
    'section': const TextStyle(color: Color(0xFF58A6FF), fontWeight: FontWeight.bold),
    'strong': const TextStyle(fontWeight: FontWeight.bold),
    'emphasis': const TextStyle(fontStyle: FontStyle.italic),
    'code': const TextStyle(
      color: Color(0xFFFFA657),
      fontFamily: 'Monaco',
      backgroundColor: Color(0xFF21262D),
    ),
    'string': const TextStyle(color: Color(0xFF7EE787)),
    'link': const TextStyle(color: Color(0xFF58A6FF), decoration: TextDecoration.underline),
    'quote': const TextStyle(color: Color(0xFF8B949E), fontStyle: FontStyle.italic),
    'comment': const TextStyle(color: Color(0xFF8B949E)),
    'meta': const TextStyle(color: Color(0xFFD2A8FF)),
    'keyword': const TextStyle(color: Color(0xFFFF7B72), fontWeight: FontWeight.bold),
    'bullet': const TextStyle(color: Color(0xFF58A6FF)),
    'number': const TextStyle(color: Color(0xFF58A6FF)),
  };

  static Map<String, TextStyle> getTheme(bool isDarkMode) {
    return isDarkMode ? _darkTheme : _lightTheme;
  }

  static TextSpan highlightMarkdown(String code, bool isDarkMode) {
    final theme = getTheme(isDarkMode);
    
    // Basic Markdown highlighting patterns
    final patterns = [
      // Headers
      RegExp(r'^#{1,6}\s+.*$', multiLine: true),
      // Bold
      RegExp(r'\*\*[^*]+\*\*'),
      // Italic
      RegExp(r'\*[^*]+\*'),
      // Code blocks
      RegExp(r'```[\s\S]*?```'),
      // Inline code
      RegExp(r'`[^`]+`'),
      // Links
      RegExp(r'\[([^\]]+)\]\(([^)]+)\)'),
      // Lists
      RegExp(r'^[-*+]\s+', multiLine: true),
      // Blockquotes
      RegExp(r'^>\s+.*$', multiLine: true),
    ];

    List<TextSpan> spans = [];
    int lastIndex = 0;

    // Simple highlighting - this is a basic implementation
    // In a production app, you'd want a more sophisticated parser
    
    // For now, let's create a simple styled version
    final lines = code.split('\n');
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      TextStyle? lineStyle;
      
      if (line.startsWith('#')) {
        lineStyle = theme['title'];
      } else if (line.startsWith('>')) {
        lineStyle = theme['quote'];
      } else if (line.startsWith('- ') || line.startsWith('* ') || line.startsWith('+ ')) {
        lineStyle = theme['bullet'];
      } else {
        lineStyle = theme['root'];
      }
      
      spans.add(TextSpan(
        text: line + (i < lines.length - 1 ? '\n' : ''),
        style: lineStyle,
      ));
    }

    return TextSpan(children: spans);
  }
}