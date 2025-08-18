import '../models/th_diff_result.dart';
import '../models/th_diff_line.dart';

/// Formats diff results in Git diff format
class GitDiffFormatter {
  /// Convert a THDiffResult to Git diff format string
  static String format(THDiffResult result) {
    final buffer = StringBuffer();
    
    // Git diff header
    final fileName1 = result.filePath1 ?? 'a/file';
    final fileName2 = result.filePath2 ?? 'b/file';
    
    buffer.writeln('diff --git a/$fileName1 b/$fileName2');
    
    // Index line (placeholder for now since we don't have git hashes)
    buffer.writeln('index 0000000..1111111 100644');
    
    // File paths
    buffer.writeln('--- a/$fileName1');
    buffer.writeln('+++ b/$fileName2');
    
    // If no changes, return early
    if (!result.hasChanges) {
      return buffer.toString();
    }
    
    // Hunks
    for (final hunk in result.hunks) {
      if (!hunk.hasChanges) continue;
      
      // Hunk header
      buffer.writeln(hunk.header);
      
      // Hunk lines
      for (final line in hunk.lines) {
        buffer.write(line.type.prefix);
        buffer.writeln(line.content);
      }
    }
    
    return buffer.toString();
  }
  
  /// Format with additional Git metadata
  static String formatWithMetadata(
    THDiffResult result, {
    String? commitHash,
    String? authorName,
    String? authorEmail,
    DateTime? commitDate,
    String? commitMessage,
  }) {
    final buffer = StringBuffer();
    
    // Extended Git metadata (for git format-patch style)
    if (commitHash != null) {
      buffer.writeln('From $commitHash Mon Sep 17 00:00:00 2001');
    }
    
    if (authorName != null && authorEmail != null) {
      buffer.writeln('From: $authorName <$authorEmail>');
    }
    
    if (commitDate != null) {
      buffer.writeln('Date: ${_formatGitDate(commitDate)}');
    }
    
    if (commitMessage != null) {
      buffer.writeln('Subject: $commitMessage');
      buffer.writeln();
    }
    
    // Standard diff content
    buffer.write(format(result));
    
    // Git patch metadata
    buffer.writeln('--');
    buffer.writeln('${result.stats.addedLines} insertions(+), ${result.stats.deletedLines} deletions(-)');
    
    return buffer.toString();
  }
  
  /// Format Git date in the standard format
  static String _formatGitDate(DateTime date) {
    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    
    final weekday = weekdays[date.weekday - 1];
    final month = months[date.month - 1];
    
    return '$weekday ${month} ${date.day.toString().padLeft(2, '0')} '
           '${date.hour.toString().padLeft(2, '0')}:'
           '${date.minute.toString().padLeft(2, '0')}:'
           '${date.second.toString().padLeft(2, '0')} '
           '${date.year} ${_getTimezoneOffset(date)}';
  }
  
  /// Get timezone offset in Git format (e.g., +0200)
  static String _getTimezoneOffset(DateTime date) {
    final offset = date.timeZoneOffset;
    final sign = offset.isNegative ? '-' : '+';
    final hours = offset.inHours.abs().toString().padLeft(2, '0');
    final minutes = (offset.inMinutes.abs() % 60).toString().padLeft(2, '0');
    return '$sign$hours$minutes';
  }
}