import 'th_diff_line.dart';

/// Represents a contiguous block of changes in a diff.
/// 
/// A hunk is a fundamental unit in diff output that groups related changes
/// together along with surrounding context lines. Each hunk represents a
/// continuous section where changes occurred, bounded by unchanged content.
/// 
/// Hunks contain:
/// - Position information (start line and count for both original and modified texts)
/// - A list of all lines in the hunk (both changed and context lines)
/// - Optional section header information (like function names)
/// 
/// The hunk format follows the unified diff standard where:
/// - Changes are grouped with surrounding context for readability
/// - Each hunk has a header indicating the line ranges it covers
/// - Lines within the hunk are marked as additions, deletions, or context
/// 
/// Example hunk representation:
/// ```
/// @@ -10,4 +10,4 @@ function example()
///  unchanged line
/// -deleted line
/// +added line
///  unchanged line
/// ```
class THDiffHunk {
  /// Starting line number in the original file.
  /// 
  /// This indicates the first line number from the original text
  /// that this hunk covers. Line numbers are 1-based following
  /// standard diff conventions.
  final int oldStart;
  
  /// Number of lines in the original file for this hunk.
  /// 
  /// This count includes both deleted lines and context lines
  /// that appear in the original file. Added lines are not
  /// counted since they don't exist in the original.
  final int oldCount;
  
  /// Starting line number in the modified file.
  /// 
  /// This indicates the first line number from the modified text
  /// that this hunk covers. Line numbers are 1-based following
  /// standard diff conventions.
  final int newStart;
  
  /// Number of lines in the modified file for this hunk.
  /// 
  /// This count includes both added lines and context lines
  /// that appear in the modified file. Deleted lines are not
  /// counted since they don't exist in the modified text.
  final int newCount;
  
  /// All lines in this hunk (context + changes).
  /// 
  /// This list contains every line that appears in the hunk,
  /// including context lines, additions, and deletions.
  /// The lines are ordered as they would appear in the
  /// diff output, with proper line type markers.
  final List<THDiffLine> lines;
  
  /// Optional section header (e.g., function name).
  /// 
  /// Some diff tools can detect and include contextual information
  /// such as the function or section name where changes occurred.
  /// This appears after the @@ line range in the hunk header.
  final String? sectionHeader;
  
  const THDiffHunk({
    required this.oldStart,
    required this.oldCount,
    required this.newStart,
    required this.newCount,
    required this.lines,
    this.sectionHeader,
  });
  
  /// Creates a copy of this hunk with some fields changed.
  /// 
  /// This method provides an immutable way to create a new THDiffHunk
  /// instance with modified fields while preserving all other data.
  /// 
  /// Parameters (all optional):
  /// - [oldStart]: New starting line number in original file
  /// - [oldCount]: New line count in original file
  /// - [newStart]: New starting line number in modified file
  /// - [newCount]: New line count in modified file
  /// - [lines]: New list of lines in the hunk
  /// - [sectionHeader]: New section header
  /// 
  /// Returns a new [THDiffHunk] instance with the specified fields updated.
  THDiffHunk copyWith({
    int? oldStart,
    int? oldCount,
    int? newStart,
    int? newCount,
    List<THDiffLine>? lines,
    String? sectionHeader,
  }) {
    return THDiffHunk(
      oldStart: oldStart ?? this.oldStart,
      oldCount: oldCount ?? this.oldCount,
      newStart: newStart ?? this.newStart,
      newCount: newCount ?? this.newCount,
      lines: lines ?? this.lines,
      sectionHeader: sectionHeader ?? this.sectionHeader,
    );
  }
  
  /// Gets the hunk header in unified diff format.
  /// 
  /// Returns a string representation of the hunk header following
  /// the unified diff format: `@@ -oldStart,oldCount +newStart,newCount @@`
  /// 
  /// The format indicates:
  /// - Line ranges affected in both original (-) and modified (+) files
  /// - Optional section header information if available
  /// 
  /// When counts are 1, they may be omitted for brevity.
  /// 
  /// Example outputs:
  /// - `@@ -10,4 +10,4 @@`
  /// - `@@ -1 +1 @@ function example()`
  String get header {
    final buffer = StringBuffer();
    buffer.write('@@ -$oldStart');
    
    if (oldCount != 1) {
      buffer.write(',$oldCount');
    }
    
    buffer.write(' +$newStart');
    
    if (newCount != 1) {
      buffer.write(',$newCount');
    }
    
    buffer.write(' @@');
    
    if (sectionHeader != null && sectionHeader!.isNotEmpty) {
      buffer.write(' $sectionHeader');
    }
    
    return buffer.toString();
  }
  
  /// Gets only the lines that represent changes (additions/deletions).
  /// 
  /// Returns a filtered list containing only the lines that represent
  /// actual changes - additions and deletions. Context lines are excluded.
  /// This is useful for analyzing the specific changes without the
  /// surrounding context.
  /// 
  /// Returns a list of [THDiffLine] objects where [THDiffLine.isChange] is true.
  List<THDiffLine> get changedLines {
    return lines.where((line) => line.isChange).toList();
  }
  
  /// Gets only the context lines.
  /// 
  /// Returns a filtered list containing only the unchanged lines that
  /// provide context around the changes. These lines exist in both
  /// the original and modified texts.
  /// 
  /// Returns a list of [THDiffLine] objects where [THDiffLine.isContext] is true.
  List<THDiffLine> get contextLines {
    return lines.where((line) => line.isContext).toList();
  }
  
  /// Gets the number of additions in this hunk.
  /// 
  /// Returns the count of lines that were added in the modified text.
  /// These lines appear with a '+' prefix in diff output.
  int get additionCount {
    return lines.where((line) => line.type == THDiffLineType.addition).length;
  }
  
  /// Gets the number of deletions in this hunk.
  /// 
  /// Returns the count of lines that were deleted from the original text.
  /// These lines appear with a '-' prefix in diff output.
  int get deletionCount {
    return lines.where((line) => line.type == THDiffLineType.deletion).length;
  }
  
  /// Whether this hunk contains any changes.
  /// 
  /// Returns `true` if the hunk contains any additions or deletions,
  /// `false` if it contains only context lines. This is a quick way
  /// to determine if a hunk represents actual changes or just context.
  bool get hasChanges {
    return changedLines.isNotEmpty;
  }
  
  @override
  String toString() {
    return 'THDiffHunk('
        'oldRange: $oldStart,$oldCount, '
        'newRange: $newStart,$newCount, '
        'lines: ${lines.length}, '
        'sectionHeader: $sectionHeader'
        ')';
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is THDiffHunk &&
        other.oldStart == oldStart &&
        other.oldCount == oldCount &&
        other.newStart == newStart &&
        other.newCount == newCount &&
        _listEquals(other.lines, lines) &&
        other.sectionHeader == sectionHeader;
  }
  
  @override
  int get hashCode {
    return Object.hash(
      oldStart,
      oldCount,
      newStart,
      newCount,
      Object.hashAll(lines),
      sectionHeader,
    );
  }
  
  // Helper method to compare lists
  bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}