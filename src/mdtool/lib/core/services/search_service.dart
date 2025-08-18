import 'package:flutter/material.dart';

class SearchMatch {
  final int start;
  final int end;
  final String text;

  SearchMatch({
    required this.start,
    required this.end,
    required this.text,
  });
}

class SearchService {
  static List<SearchMatch> findMatches(
    String text,
    String query, {
    bool matchCase = false,
    bool wholeWord = false,
  }) {
    if (query.isEmpty || text.isEmpty) {
      return [];
    }

    final List<SearchMatch> matches = [];
    final searchText = matchCase ? text : text.toLowerCase();
    final searchQuery = matchCase ? query : query.toLowerCase();

    int startIndex = 0;
    while (true) {
      final index = searchText.indexOf(searchQuery, startIndex);
      if (index == -1) break;

      // Check whole word constraint
      if (wholeWord) {
        final isStartWordBoundary = index == 0 || 
            !_isWordCharacter(searchText[index - 1]);
        final isEndWordBoundary = index + searchQuery.length >= searchText.length ||
            !_isWordCharacter(searchText[index + searchQuery.length]);
        
        if (!isStartWordBoundary || !isEndWordBoundary) {
          startIndex = index + 1;
          continue;
        }
      }

      matches.add(SearchMatch(
        start: index,
        end: index + searchQuery.length,
        text: text.substring(index, index + searchQuery.length),
      ));

      startIndex = index + 1;
    }

    return matches;
  }

  static bool _isWordCharacter(String char) {
    return RegExp(r'[a-zA-Z0-9_]').hasMatch(char);
  }

  static TextSpan highlightMatches(
    String text,
    List<SearchMatch> matches,
    int currentMatchIndex, {
    TextStyle? normalStyle,
    TextStyle? highlightStyle,
    TextStyle? currentHighlightStyle,
  }) {
    if (matches.isEmpty) {
      return TextSpan(text: text, style: normalStyle);
    }

    final List<TextSpan> spans = [];
    int lastEnd = 0;

    for (int i = 0; i < matches.length; i++) {
      final match = matches[i];
      final isCurrentMatch = i == currentMatchIndex;

      // Add text before match
      if (match.start > lastEnd) {
        spans.add(TextSpan(
          text: text.substring(lastEnd, match.start),
          style: normalStyle,
        ));
      }

      // Add highlighted match
      spans.add(TextSpan(
        text: match.text,
        style: isCurrentMatch ? currentHighlightStyle : highlightStyle,
      ));

      lastEnd = match.end;
    }

    // Add remaining text
    if (lastEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastEnd),
        style: normalStyle,
      ));
    }

    return TextSpan(children: spans);
  }

  static int getNextMatchIndex(int currentIndex, int totalMatches, bool forward) {
    if (totalMatches == 0) return -1;
    
    if (forward) {
      return (currentIndex + 1) % totalMatches;
    } else {
      return currentIndex > 0 ? currentIndex - 1 : totalMatches - 1;
    }
  }
}