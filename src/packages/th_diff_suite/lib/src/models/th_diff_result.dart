import 'package:diff_match_patch/diff_match_patch.dart';
import 'th_diff_options.dart';
import 'th_diff_hunk.dart';
import 'th_diff_line.dart';
import '../line_diff_algorithm.dart';

/// Contains the complete result of a diff operation.
/// 
/// This class encapsulates all information about a text comparison operation,
/// including the original and modified texts, a list of hunks representing
/// the differences, statistics about the changes, and metadata such as
/// file paths and timestamps.
/// 
/// The result provides multiple ways to access and analyze the differences:
/// - [hunks]: Organized groups of changes with context
/// - [stats]: Numerical statistics about additions, deletions, and changes
/// - [hasChanges]: Quick check for whether any differences were found
/// - [allChangedLines]: Flat list of all changed lines across all hunks
/// 
/// Example usage:
/// ```dart
/// final result = THDiffSuite.compareTexts(oldText, newText);
/// 
/// if (result.hasChanges) {
///   print('Found ${result.stats.changedLines} changes in ${result.hunks.length} hunks');
///   
///   for (final hunk in result.hunks) {
///     print('Hunk: ${hunk.header}');
///     for (final line in hunk.changedLines) {
///       print('  ${line.type.prefix}${line.content}');
///     }
///   }
/// }
/// ```
class THDiffResult {
  /// The original text that was compared (left side of comparison).
  /// 
  /// This contains the complete text content that served as the baseline
  /// for the comparison operation.
  final String originalText;
  
  /// The modified text that was compared (right side of comparison).
  /// 
  /// This contains the complete text content that was compared against
  /// the original text to detect changes.
  final String modifiedText;
  
  /// List of hunks representing the differences between the texts.
  /// 
  /// Each hunk contains a contiguous block of changes along with
  /// surrounding context lines. Hunks are ordered by their position
  /// in the files from beginning to end.
  final List<THDiffHunk> hunks;
  
  /// The configuration options that were used for this diff operation.
  /// 
  /// These options control various aspects of the diff algorithm and
  /// output formatting, such as context lines and cleanup settings.
  final THDiffOptions options;
  
  /// Optional file path for the original file.
  /// 
  /// When comparing files (rather than raw text), this contains the
  /// basename of the original file path for reference in output formatting.
  final String? filePath1;
  
  /// Optional file path for the modified file.
  /// 
  /// When comparing files (rather than raw text), this contains the
  /// basename of the modified file path for reference in output formatting.
  final String? filePath2;
  
  /// Timestamp indicating when this diff was created.
  /// 
  /// This is automatically set to the current time when the diff
  /// operation is performed and can be used for tracking and display purposes.
  final DateTime timestamp;
  
  /// Statistical information about the differences found.
  /// 
  /// Contains counts of added lines, deleted lines, unchanged lines,
  /// and other metrics that provide a quantitative summary of the changes.
  final THDiffStats stats;
  
  const THDiffResult({
    required this.originalText,
    required this.modifiedText,
    required this.hunks,
    required this.options,
    this.filePath1,
    this.filePath2,
    required this.timestamp,
    required this.stats,
  });
  
  /// Creates a THDiffResult from line-based comparison.
  /// 
  /// This factory constructor performs a line-by-line comparison of the provided
  /// text lists and generates a comprehensive diff result. It uses an optimized
  /// line-based algorithm to detect changes and groups them into hunks with
  /// appropriate context.
  /// 
  /// Parameters:
  /// - [lines1]: List of lines from the original text
  /// - [lines2]: List of lines from the modified text
  /// - [originalText]: Complete original text for reference
  /// - [modifiedText]: Complete modified text for reference
  /// - [options]: Configuration options for the diff operation
  /// - [filePath1]: Optional original file path for metadata
  /// - [filePath2]: Optional modified file path for metadata
  /// 
  /// Returns a fully populated [THDiffResult] with hunks, statistics, and metadata.
  factory THDiffResult.fromLineComparison(
    List<String> lines1,
    List<String> lines2, {
    required String originalText,
    required String modifiedText,
    required THDiffOptions options,
    String? filePath1,
    String? filePath2,
  }) {
    // Use our line-based diff algorithm with enhanced intra-line support
    final allLines = LineDiffAlgorithm.diffLines(lines1, lines2, options: options);
    
    // Group lines into hunks
    final hunks = _createHunks(allLines, options.contextLines);
    
    // Calculate statistics
    final additionCount = allLines.where((l) => l.type == THDiffLineType.addition).length;
    final deletionCount = allLines.where((l) => l.type == THDiffLineType.deletion).length;
    final unchangedCount = allLines.where((l) => l.type == THDiffLineType.context).length;
    
    final stats = THDiffStats(
      totalLines: lines1.length + lines2.length,
      addedLines: additionCount,
      deletedLines: deletionCount,
      unchangedLines: unchangedCount,
      hunksCount: hunks.length,
    );
    
    return THDiffResult(
      originalText: originalText,
      modifiedText: modifiedText,
      hunks: hunks,
      options: options,
      filePath1: filePath1,
      filePath2: filePath2,
      timestamp: DateTime.now(),
      stats: stats,
    );
  }
  
  /// Creates a THDiffResult from diff-match-patch output (legacy method).
  /// 
  /// This factory constructor is provided for backward compatibility with
  /// diff-match-patch library output. It converts the diff-match-patch
  /// results to the line-based format used internally by this library.
  /// 
  /// Note: This method is deprecated and will redirect to the line-based
  /// comparison for better performance and accuracy.
  /// 
  /// Parameters:
  /// - [diffs]: List of diff operations from diff-match-patch
  /// - [originalText]: Complete original text for reference
  /// - [modifiedText]: Complete modified text for reference
  /// - [options]: Configuration options for the diff operation
  /// - [filePath1]: Optional original file path for metadata
  /// - [filePath2]: Optional modified file path for metadata
  /// 
  /// Returns a [THDiffResult] equivalent to line-based comparison.
  factory THDiffResult.fromDiffMatchPatch(
    List<Diff> diffs, {
    required String originalText,
    required String modifiedText,
    required THDiffOptions options,
    String? filePath1,
    String? filePath2,
  }) {
    // Convert to line-based comparison for better results
    final lines1 = originalText.split('\n');
    final lines2 = modifiedText.split('\n');
    
    return THDiffResult.fromLineComparison(
      lines1,
      lines2,
      originalText: originalText,
      modifiedText: modifiedText,
      options: options,
      filePath1: filePath1,
      filePath2: filePath2,
    );
  }
  
  /// Create hunks from a list of diff lines
  static List<THDiffHunk> _createHunks(List<THDiffLine> lines, int contextLines) {
    if (lines.isEmpty) return [];
    
    final hunks = <THDiffHunk>[];
    var currentHunkLines = <THDiffLine>[];
    var hunkStartOld = 1;
    var hunkStartNew = 1;
    
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      
      // Start a new hunk if we have changes or are within context of changes
      if (line.isChange || _isWithinContext(lines, i, contextLines)) {
        if (currentHunkLines.isEmpty) {
          hunkStartOld = (line.oldLineNumber ?? 1) - _getLeadingContext(lines, i, contextLines);
          hunkStartNew = (line.newLineNumber ?? 1) - _getLeadingContext(lines, i, contextLines);
        }
        currentHunkLines.add(line);
      } else if (currentHunkLines.isNotEmpty) {
        // End current hunk
        hunks.add(_createHunk(currentHunkLines, hunkStartOld, hunkStartNew));
        currentHunkLines = [];
      }
    }
    
    // Add final hunk if exists
    if (currentHunkLines.isNotEmpty) {
      hunks.add(_createHunk(currentHunkLines, hunkStartOld, hunkStartNew));
    }
    
    return hunks;
  }
  
  static bool _isWithinContext(List<THDiffLine> lines, int index, int contextLines) {
    // Check if there's a change within contextLines distance
    final start = (index - contextLines).clamp(0, lines.length - 1);
    final end = (index + contextLines).clamp(0, lines.length - 1);
    
    for (int i = start; i <= end; i++) {
      if (lines[i].isChange) return true;
    }
    return false;
  }
  
  static int _getLeadingContext(List<THDiffLine> lines, int index, int contextLines) {
    int count = 0;
    for (int i = index - 1; i >= 0 && count < contextLines; i--) {
      if (lines[i].isContext) count++;
      else break;
    }
    return count;
  }
  
  static THDiffHunk _createHunk(List<THDiffLine> lines, int startOld, int startNew) {
    final oldCount = lines.where((l) => l.type != THDiffLineType.addition).length;
    final newCount = lines.where((l) => l.type != THDiffLineType.deletion).length;
    
    return THDiffHunk(
      oldStart: startOld,
      oldCount: oldCount,
      newStart: startNew,
      newCount: newCount,
      lines: lines,
    );
  }
  
  /// Creates a copy of this result with some fields changed.
  /// 
  /// This method provides an immutable way to create a new THDiffResult
  /// with modified fields while preserving all other data. This is useful
  /// for adding metadata like file paths after the initial comparison.
  /// 
  /// Parameters:
  /// - [originalText]: New original text (optional)
  /// - [modifiedText]: New modified text (optional)
  /// - [hunks]: New list of hunks (optional)
  /// - [options]: New options (optional)
  /// - [filePath1]: New original file path (optional)
  /// - [filePath2]: New modified file path (optional)
  /// - [timestamp]: New timestamp (optional)
  /// - [stats]: New statistics (optional)
  /// 
  /// Returns a new [THDiffResult] with the specified fields updated.
  THDiffResult copyWith({
    String? originalText,
    String? modifiedText,
    List<THDiffHunk>? hunks,
    THDiffOptions? options,
    String? filePath1,
    String? filePath2,
    DateTime? timestamp,
    THDiffStats? stats,
  }) {
    return THDiffResult(
      originalText: originalText ?? this.originalText,
      modifiedText: modifiedText ?? this.modifiedText,
      hunks: hunks ?? this.hunks,
      options: options ?? this.options,
      filePath1: filePath1 ?? this.filePath1,
      filePath2: filePath2 ?? this.filePath2,
      timestamp: timestamp ?? this.timestamp,
      stats: stats ?? this.stats,
    );
  }
  
  /// Whether the diff contains any changes.
  /// 
  /// Returns `true` if any hunks contain changes (additions or deletions),
  /// `false` if the texts are identical or only contain context lines.
  /// 
  /// This is a convenient way to quickly check if a diff operation found
  /// any differences without examining the details.
  bool get hasChanges => hunks.any((hunk) => hunk.hasChanges);
  
  /// Gets all changed lines across all hunks.
  /// 
  /// Returns a flattened list containing only the lines that represent
  /// changes (additions and deletions), excluding context lines. This is
  /// useful for analyzing or processing all changes without iterating
  /// through each hunk individually.
  /// 
  /// The lines are returned in the order they appear in the diff.
  List<THDiffLine> get allChangedLines {
    return hunks.expand((hunk) => hunk.changedLines).toList();
  }
  
  @override
  String toString() {
    return 'THDiffResult('
        'hunks: ${hunks.length}, '
        'stats: $stats, '
        'files: $filePath1 -> $filePath2'
        ')';
  }
}

/// Statistical information about a diff result.
/// 
/// This class provides quantitative metrics about the differences found
/// during a text comparison operation. It includes counts of various types
/// of lines and derived metrics for understanding the scope of changes.
/// 
/// The statistics are calculated automatically during diff processing and
/// provide insights into:
/// - The total amount of content processed
/// - How many lines were added, deleted, or unchanged
/// - The number of hunks (change groups) found
/// - Percentage of content that changed
/// 
/// Example usage:
/// ```dart
/// final result = THDiffSuite.compareTexts(oldText, newText);
/// final stats = result.stats;
/// 
/// print('Processed ${stats.totalLines} lines');
/// print('Changes: +${stats.addedLines} -${stats.deletedLines}');
/// print('${stats.changePercentage.toStringAsFixed(1)}% of content changed');
/// ```
class THDiffStats {
  /// Total number of lines processed across both texts.
  /// 
  /// This represents the combined line count from both the original
  /// and modified texts, providing a sense of the overall scope
  /// of the comparison operation.
  final int totalLines;
  
  /// Number of lines that were added in the modified text.
  /// 
  /// These are lines that exist in the modified text but not
  /// in the original text. They appear with a '+' prefix in
  /// diff output formats.
  final int addedLines;
  
  /// Number of lines that were deleted from the original text.
  /// 
  /// These are lines that exist in the original text but not
  /// in the modified text. They appear with a '-' prefix in
  /// diff output formats.
  final int deletedLines;
  
  /// Number of lines that remained unchanged between texts.
  /// 
  /// These are lines that appear identically in both the original
  /// and modified texts. They serve as context around changes and
  /// appear with a space prefix in diff output formats.
  final int unchangedLines;
  
  /// Number of hunks (change groups) in the diff.
  /// 
  /// Hunks represent contiguous blocks of changes along with their
  /// surrounding context. A higher hunk count generally indicates
  /// more scattered changes throughout the text.
  final int hunksCount;
  
  const THDiffStats({
    required this.totalLines,
    required this.addedLines,
    required this.deletedLines,
    required this.unchangedLines,
    required this.hunksCount,
  });
  
  /// Gets the total number of changed lines (additions + deletions).
  /// 
  /// This provides a quick metric for the overall amount of change
  /// by combining both additions and deletions into a single number.
  /// 
  /// Returns the sum of [addedLines] and [deletedLines].
  int get changedLines => addedLines + deletedLines;
  
  /// Gets the percentage of content that changed.
  /// 
  /// This calculates what proportion of the total content was affected
  /// by changes. The percentage is based on the ratio of changed lines
  /// to total lines processed.
  /// 
  /// Returns a value between 0.0 and 100.0, where:
  /// - 0.0 indicates no changes were found
  /// - 100.0 indicates all content was changed
  /// - Values in between indicate partial changes
  /// 
  /// If [totalLines] is 0, returns 0.0 to avoid division by zero.
  double get changePercentage {
    if (totalLines == 0) return 0.0;
    return (changedLines / totalLines) * 100.0;
  }
  
  @override
  String toString() {
    return 'THDiffStats('
        'total: $totalLines, '
        '+$addedLines, '
        '-$deletedLines, '
        'unchanged: $unchangedLines, '
        'hunks: $hunksCount'
        ')';
  }
}