import 'dart:ui';
import 'package:flutter/painting.dart';
import '../models/th_diff_line.dart';
import '../models/th_diff_hunk.dart';
import '../models/th_diff_result.dart';
import '../models/th_intra_line_diff.dart';

/// UI integration helpers for displaying diffs in Flutter applications
/// 
/// This class provides utilities for converting diff data into UI-friendly formats,
/// including color coding, styling suggestions, and data transformations that make
/// it easy to build Flutter widgets for diff visualization.
class DiffUIHelpers {
  
  /// Default color scheme for diff visualization
  static const DiffColorScheme defaultColors = DiffColorScheme(
    addition: Color(0xFF28A745),      // GitHub green
    deletion: Color(0xFFDC3545),     // GitHub red  
    context: Color(0xFF6C757D),      // Gray
    additionBackground: Color(0xFFE6FFED),
    deletionBackground: Color(0xFFFFEBEE),
    contextBackground: Color(0xFFF8F9FA),
    lineNumber: Color(0xFF586069),
  );
  
  /// Get the appropriate color for a diff line type
  /// 
  /// [lineType] The type of diff line
  /// [colorScheme] Optional custom color scheme (uses default if not provided)
  /// [isBackground] Whether to return background color instead of text color
  static Color getColorForLineType(
    THDiffLineType lineType, {
    DiffColorScheme colorScheme = defaultColors,
    bool isBackground = false,
  }) {
    switch (lineType) {
      case THDiffLineType.addition:
        return isBackground ? colorScheme.additionBackground : colorScheme.addition;
      case THDiffLineType.deletion:
        return isBackground ? colorScheme.deletionBackground : colorScheme.deletion;
      case THDiffLineType.context:
        return isBackground ? colorScheme.contextBackground : colorScheme.context;
    }
  }
  
  /// Get a prefix icon/symbol for a diff line type
  /// 
  /// Returns standard diff symbols: '+' for additions, '-' for deletions, ' ' for context
  static String getPrefixForLineType(THDiffLineType lineType) {
    return lineType.prefix;
  }
  
  /// Get a descriptive label for a diff line type (useful for accessibility)
  static String getAccessibilityLabelForLineType(THDiffLineType lineType) {
    switch (lineType) {
      case THDiffLineType.addition:
        return 'Added line';
      case THDiffLineType.deletion:
        return 'Deleted line';
      case THDiffLineType.context:
        return 'Unchanged line';
    }
  }
  
  /// Get the appropriate color for an intra-line diff segment type
  /// 
  /// [segmentType] The type of intra-line diff segment
  /// [colorScheme] Optional custom color scheme (uses default if not provided)
  /// [isBackground] Whether to return background color instead of text color
  static Color getColorForIntraLineType(
    THIntraLineDiffType segmentType, {
    DiffColorScheme colorScheme = defaultColors,
    bool isBackground = false,
  }) {
    switch (segmentType) {
      case THIntraLineDiffType.insert:
        return isBackground ? colorScheme.additionBackground : colorScheme.addition;
      case THIntraLineDiffType.delete:
        return isBackground ? colorScheme.deletionBackground : colorScheme.deletion;
      case THIntraLineDiffType.equal:
        return isBackground ? colorScheme.contextBackground : colorScheme.context;
    }
  }
  
  /// Create a list of styled text spans for a line with intra-line diffs
  /// 
  /// This helper creates Flutter TextSpan objects that can be used directly
  /// in RichText widgets for precise word/character-level highlighting.
  /// 
  /// [line] The diff line containing intra-line diff information
  /// [colorScheme] Optional custom color scheme
  /// [baseStyle] Base text style to apply to all segments
  static List<TextSpan> createIntraLineTextSpans(
    THDiffLine line, {
    DiffColorScheme colorScheme = defaultColors,
    TextStyle? baseStyle,
  }) {
    if (!line.hasIntraLineDiff) {
      // No intra-line diffs - return single span with line color
      return [
        TextSpan(
          text: line.content,
          style: baseStyle?.copyWith(
            color: getColorForLineType(line.type, colorScheme: colorScheme),
          ) ?? TextStyle(
            color: getColorForLineType(line.type, colorScheme: colorScheme),
          ),
        ),
      ];
    }
    
    // Create spans for each intra-line diff segment
    final spans = <TextSpan>[];
    for (final intraDiff in line.intraLineDiffs!) {
      final segmentColor = getColorForIntraLineType(
        intraDiff.type, 
        colorScheme: colorScheme,
      );
      
      spans.add(TextSpan(
        text: intraDiff.text,
        style: baseStyle?.copyWith(color: segmentColor) ?? 
               TextStyle(color: segmentColor),
      ));
    }
    
    return spans;
  }
  
  /// Create a summary of intra-line changes for display
  /// 
  /// Returns a human-readable description of what changed within a line,
  /// useful for tooltips, status bars, or accessibility descriptions.
  static String createIntraLineSummary(THDiffLine line) {
    if (!line.hasIntraLineDiff) {
      return 'Line ${line.type.displayName.toLowerCase()}';
    }
    
    final changes = line.intraLineChanges;
    if (changes.isEmpty) {
      return 'Line ${line.type.displayName.toLowerCase()}';
    }
    
    final insertions = changes.where((c) => c.type == THIntraLineDiffType.insert).length;
    final deletions = changes.where((c) => c.type == THIntraLineDiffType.delete).length;
    
    final parts = <String>[];
    if (insertions > 0) {
      parts.add('$insertions insertion${insertions != 1 ? 's' : ''}');
    }
    if (deletions > 0) {
      parts.add('$deletions deletion${deletions != 1 ? 's' : ''}');
    }
    
    return 'Line with ${parts.join(' and ')}';
  }
  
  /// Group diff lines for optimized UI rendering
  /// 
  /// Groups consecutive lines of the same type together to reduce widget count
  /// and improve scrolling performance in large diffs.
  /// 
  /// Returns a list of [DiffLineGroup] objects that can be rendered as single widgets.
  static List<DiffLineGroup> groupConsecutiveLines(List<THDiffLine> lines) {
    if (lines.isEmpty) return [];
    
    final groups = <DiffLineGroup>[];
    var currentGroup = <THDiffLine>[];
    var currentType = lines.first.type;
    
    for (final line in lines) {
      if (line.type == currentType) {
        currentGroup.add(line);
      } else {
        // Start new group
        groups.add(DiffLineGroup(type: currentType, lines: List.from(currentGroup)));
        currentGroup = [line];
        currentType = line.type;
      }
    }
    
    // Add final group
    if (currentGroup.isNotEmpty) {
      groups.add(DiffLineGroup(type: currentType, lines: currentGroup));
    }
    
    return groups;
  }
  
  /// Create a summary of changes for display in headers or overviews
  /// 
  /// [result] The diff result to summarize
  /// [compact] Whether to use compact format (e.g., "+5 -2") vs verbose
  static String createChangeSummary(THDiffResult result, {bool compact = false}) {
    if (!result.hasChanges) {
      return compact ? "No changes" : "No changes detected";
    }
    
    final stats = result.stats;
    
    if (compact) {
      return "+${stats.addedLines} -${stats.deletedLines}";
    } else {
      final parts = <String>[];
      if (stats.addedLines > 0) {
        parts.add("${stats.addedLines} addition${stats.addedLines != 1 ? 's' : ''}");
      }
      if (stats.deletedLines > 0) {
        parts.add("${stats.deletedLines} deletion${stats.deletedLines != 1 ? 's' : ''}");
      }
      
      final changeText = parts.join(", ");
      final percentage = "(${stats.changePercentage.toStringAsFixed(1)}% changed)";
      
      return "$changeText $percentage";
    }
  }
  
  /// Extract line numbers for display in a separate column
  /// 
  /// Returns a list of formatted line numbers that can be displayed alongside
  /// the diff content. Handles the case where additions don't have old line numbers
  /// and deletions don't have new line numbers.
  static List<DiffLineNumbers> extractLineNumbers(List<THDiffLine> lines) {
    return lines.map((line) => DiffLineNumbers(
      oldNumber: line.oldLineNumber?.toString(),
      newNumber: line.newLineNumber?.toString(),
      type: line.type,
    )).toList();
  }
  
  /// Filter hunks to show only those containing actual changes
  /// 
  /// Useful for condensed views that hide context-only hunks
  static List<THDiffHunk> getHunksWithChanges(THDiffResult result) {
    return result.hunks.where((hunk) => hunk.hasChanges).toList();
  }
  
  /// Create a flat list of all changed lines (for search, highlighting, etc.)
  /// 
  /// [result] The diff result
  /// [includeContext] Whether to include context lines in the result
  static List<DiffLineWithLocation> getAllLines(
    THDiffResult result, {
    bool includeContext = true,
  }) {
    final allLines = <DiffLineWithLocation>[];
    
    for (int hunkIndex = 0; hunkIndex < result.hunks.length; hunkIndex++) {
      final hunk = result.hunks[hunkIndex];
      
      for (int lineIndex = 0; lineIndex < hunk.lines.length; lineIndex++) {
        final line = hunk.lines[lineIndex];
        
        if (includeContext || line.isChange) {
          allLines.add(DiffLineWithLocation(
            line: line,
            hunkIndex: hunkIndex,
            lineIndex: lineIndex,
          ));
        }
      }
    }
    
    return allLines;
  }
  
  /// Calculate scrolling positions for navigation (e.g., "go to next change")
  /// 
  /// Returns a list of line indices where changes occur, useful for implementing
  /// "jump to next/previous change" functionality.
  static List<int> getChangePositions(THDiffResult result) {
    final positions = <int>[];
    int globalLineIndex = 0;
    
    for (final hunk in result.hunks) {
      for (final line in hunk.lines) {
        if (line.isChange) {
          positions.add(globalLineIndex);
        }
        globalLineIndex++;
      }
    }
    
    return positions;
  }
}

/// Color scheme for diff visualization
/// 
/// Defines the colors used for different types of diff lines and backgrounds.
/// Can be customized to match your app's theme.
class DiffColorScheme {
  /// Color for added lines text
  final Color addition;
  
  /// Color for deleted lines text
  final Color deletion;
  
  /// Color for context lines text
  final Color context;
  
  /// Background color for added lines
  final Color additionBackground;
  
  /// Background color for deleted lines
  final Color deletionBackground;
  
  /// Background color for context lines
  final Color contextBackground;
  
  /// Color for line numbers
  final Color lineNumber;
  
  const DiffColorScheme({
    required this.addition,
    required this.deletion,
    required this.context,
    required this.additionBackground,
    required this.deletionBackground,
    required this.contextBackground,
    required this.lineNumber,
  });
  
  /// Create a color scheme based on your app's theme colors
  factory DiffColorScheme.fromTheme({
    required Color primary,
    required Color error,
    required Color onSurface,
    required Color surface,
  }) {
    return DiffColorScheme(
      addition: primary,
      deletion: error,
      context: onSurface,
      additionBackground: primary.withOpacity(0.1),
      deletionBackground: error.withOpacity(0.1),
      contextBackground: surface,
      lineNumber: onSurface.withOpacity(0.6),
    );
  }
}

/// A group of consecutive diff lines of the same type
/// 
/// Useful for optimizing UI rendering by treating consecutive similar lines
/// as a single widget.
class DiffLineGroup {
  /// The type of lines in this group
  final THDiffLineType type;
  
  /// All lines in this group (guaranteed to have the same type)
  final List<THDiffLine> lines;
  
  const DiffLineGroup({
    required this.type,
    required this.lines,
  });
  
  /// Whether this group contains changes (additions or deletions)
  bool get hasChanges => type != THDiffLineType.context;
  
  /// The number of lines in this group
  int get lineCount => lines.length;
}

/// Line numbers for a diff line (old and new)
/// 
/// Used for displaying line numbers in a separate column
class DiffLineNumbers {
  /// Line number in the original file (null for additions)
  final String? oldNumber;
  
  /// Line number in the modified file (null for deletions)
  final String? newNumber;
  
  /// The type of change for this line
  final THDiffLineType type;
  
  const DiffLineNumbers({
    required this.oldNumber,
    required this.newNumber,
    required this.type,
  });
}

/// A diff line with its location in the overall diff
/// 
/// Useful for navigation, searching, and providing context about where
/// a line appears in the diff structure.
class DiffLineWithLocation {
  /// The diff line
  final THDiffLine line;
  
  /// Index of the hunk containing this line
  final int hunkIndex;
  
  /// Index of this line within its hunk
  final int lineIndex;
  
  const DiffLineWithLocation({
    required this.line,
    required this.hunkIndex,
    required this.lineIndex,
  });
}