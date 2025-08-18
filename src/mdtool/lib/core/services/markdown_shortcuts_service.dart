import 'package:flutter/material.dart';

class MarkdownShortcutsService {
  static String wrapSelectedText(
    String text,
    TextSelection selection,
    String prefix, [
    String? suffix,
  ]) {
    suffix ??= prefix;
    
    if (selection.isCollapsed) {
      // No selection, just insert the markers
      final beforeCursor = text.substring(0, selection.baseOffset);
      final afterCursor = text.substring(selection.baseOffset);
      return beforeCursor + prefix + suffix + afterCursor;
    } else {
      // Wrap selected text
      final beforeSelection = text.substring(0, selection.start);
      final selectedText = text.substring(selection.start, selection.end);
      final afterSelection = text.substring(selection.end);
      return beforeSelection + prefix + selectedText + suffix + afterSelection;
    }
  }

  static TextSelection getNewSelection(
    TextSelection oldSelection,
    String prefix, [
    String? suffix,
  ]) {
    suffix ??= prefix;
    
    if (oldSelection.isCollapsed) {
      // Cursor between markers
      final newOffset = oldSelection.baseOffset + prefix.length;
      return TextSelection.collapsed(offset: newOffset);
    } else {
      // Keep selection but adjust for added prefix/suffix
      return TextSelection(
        baseOffset: oldSelection.baseOffset + prefix.length,
        extentOffset: oldSelection.extentOffset + prefix.length,
      );
    }
  }

  // Common Markdown operations
  static MarkdownOperation makeBold(String text, TextSelection selection) {
    return MarkdownOperation(
      newText: wrapSelectedText(text, selection, '**'),
      newSelection: getNewSelection(selection, '**'),
    );
  }

  static MarkdownOperation makeItalic(String text, TextSelection selection) {
    return MarkdownOperation(
      newText: wrapSelectedText(text, selection, '*'),
      newSelection: getNewSelection(selection, '*'),
    );
  }

  static MarkdownOperation makeCode(String text, TextSelection selection) {
    return MarkdownOperation(
      newText: wrapSelectedText(text, selection, '`'),
      newSelection: getNewSelection(selection, '`'),
    );
  }

  static MarkdownOperation makeStrikethrough(String text, TextSelection selection) {
    return MarkdownOperation(
      newText: wrapSelectedText(text, selection, '~~'),
      newSelection: getNewSelection(selection, '~~'),
    );
  }

  static MarkdownOperation makeLink(String text, TextSelection selection) {
    final selectedText = selection.isCollapsed 
        ? 'Link Text' 
        : text.substring(selection.start, selection.end);
    
    final beforeSelection = text.substring(0, selection.start);
    final afterSelection = text.substring(selection.end);
    final linkText = '[$selectedText](https://example.com)';
    
    return MarkdownOperation(
      newText: beforeSelection + linkText + afterSelection,
      newSelection: TextSelection(
        baseOffset: beforeSelection.length + selectedText.length + 3, // Position at URL
        extentOffset: beforeSelection.length + selectedText.length + 23, // Select URL
      ),
    );
  }

  static MarkdownOperation insertHeader(String text, TextSelection selection, int level) {
    final prefix = '${'#' * level} ';
    final lines = text.split('\n');
    final cursorLine = _getLineAtOffset(text, selection.baseOffset);
    
    if (cursorLine < lines.length) {
      lines[cursorLine] = prefix + lines[cursorLine].replaceFirst(RegExp(r'^#{1,6}\s*'), '');
    }
    
    return MarkdownOperation(
      newText: lines.join('\n'),
      newSelection: TextSelection.collapsed(
        offset: selection.baseOffset + prefix.length,
      ),
    );
  }

  static MarkdownOperation insertUnorderedList(String text, TextSelection selection) {
    return _insertListItem(text, selection, '- ');
  }

  static MarkdownOperation insertOrderedList(String text, TextSelection selection) {
    return _insertListItem(text, selection, '1. ');
  }

  static MarkdownOperation insertCheckbox(String text, TextSelection selection) {
    return _insertListItem(text, selection, '- [ ] ');
  }

  static MarkdownOperation insertCodeBlock(String text, TextSelection selection) {
    final beforeSelection = text.substring(0, selection.start);
    final selectedText = selection.isCollapsed 
        ? 'code here' 
        : text.substring(selection.start, selection.end);
    final afterSelection = text.substring(selection.end);
    
    final codeBlock = '```\n$selectedText\n```';
    
    return MarkdownOperation(
      newText: beforeSelection + codeBlock + afterSelection,
      newSelection: TextSelection(
        baseOffset: beforeSelection.length + 4, // After ```\n
        extentOffset: beforeSelection.length + 4 + selectedText.length,
      ),
    );
  }

  static MarkdownOperation insertQuote(String text, TextSelection selection) {
    final lines = text.split('\n');
    final startLine = _getLineAtOffset(text, selection.start);
    final endLine = _getLineAtOffset(text, selection.end);
    
    for (int i = startLine; i <= endLine && i < lines.length; i++) {
      if (!lines[i].startsWith('> ')) {
        lines[i] = '> ${lines[i]}';
      }
    }
    
    return MarkdownOperation(
      newText: lines.join('\n'),
      newSelection: TextSelection(
        baseOffset: selection.baseOffset + 2,
        extentOffset: selection.extentOffset + (2 * (endLine - startLine + 1)),
      ),
    );
  }

  static MarkdownOperation _insertListItem(String text, TextSelection selection, String prefix) {
    final lines = text.split('\n');
    final cursorLine = _getLineAtOffset(text, selection.baseOffset);
    
    if (cursorLine < lines.length) {
      lines[cursorLine] = prefix + lines[cursorLine];
    }
    
    return MarkdownOperation(
      newText: lines.join('\n'),
      newSelection: TextSelection.collapsed(
        offset: selection.baseOffset + prefix.length,
      ),
    );
  }

  static int _getLineAtOffset(String text, int offset) {
    return text.substring(0, offset).split('\n').length - 1;
  }
}

class MarkdownOperation {
  final String newText;
  final TextSelection newSelection;

  MarkdownOperation({
    required this.newText,
    required this.newSelection,
  });
}