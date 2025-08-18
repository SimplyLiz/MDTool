import '../models/th_diff_result.dart';
import '../models/th_diff_line.dart';

/// Formats diff results in traditional unified diff format
class UnifiedDiffFormatter {
  /// Convert a THDiffResult to unified diff format string
  static String format(THDiffResult result) {
    final buffer = StringBuffer();
    
    // Unified diff header
    final fileName1 = result.filePath1 ?? 'original';
    final fileName2 = result.filePath2 ?? 'modified';
    
    // Timestamps (placeholder for now)
    final timestamp1 = result.options.includeTimestamps 
        ? '\t${_formatTimestamp(result.timestamp)}'
        : '';
    final timestamp2 = result.options.includeTimestamps
        ? '\t${_formatTimestamp(result.timestamp)}'
        : '';
    
    buffer.writeln('--- $fileName1$timestamp1');
    buffer.writeln('+++ $fileName2$timestamp2');
    
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
  
  /// Format with custom options
  static String formatWithOptions(
    THDiffResult result, {
    bool includeStats = false,
    bool includeFileInfo = true,
    String? customHeader,
  }) {
    final buffer = StringBuffer();
    
    // Custom header if provided
    if (customHeader != null) {
      buffer.writeln(customHeader);
    }
    
    // File info
    if (includeFileInfo) {
      buffer.write(format(result));
    } else {
      // Just the hunks without file headers
      for (final hunk in result.hunks) {
        if (!hunk.hasChanges) continue;
        
        buffer.writeln(hunk.header);
        
        for (final line in hunk.lines) {
          buffer.write(line.type.prefix);
          buffer.writeln(line.content);
        }
      }
    }
    
    // Statistics
    if (includeStats) {
      buffer.writeln();
      buffer.writeln(_formatStats(result.stats));
    }
    
    return buffer.toString();
  }
  
  /// Format minimal diff (just the changes, no headers)
  static String formatMinimal(THDiffResult result) {
    final buffer = StringBuffer();
    
    for (final hunk in result.hunks) {
      if (!hunk.hasChanges) continue;
      
      for (final line in hunk.lines) {
        if (line.isChange) {
          buffer.write(line.type.prefix);
          buffer.writeln(line.content);
        }
      }
    }
    
    return buffer.toString();
  }
  
  /// Format side-by-side diff (for display purposes)
  static String formatSideBySide(THDiffResult result, {int lineWidth = 80}) {
    final buffer = StringBuffer();
    final halfWidth = (lineWidth - 3) ~/ 2; // Account for separator " | "
    
    buffer.writeln('${'Original'.padRight(halfWidth)} | ${'Modified'.padRight(halfWidth)}');
    buffer.writeln('${'=' * halfWidth} | ${'=' * halfWidth}');
    
    for (final hunk in result.hunks) {
      if (!hunk.hasChanges) continue;
      
      buffer.writeln(); // Hunk separator
      
      for (final line in hunk.lines) {
        final content = line.content.length > halfWidth 
            ? '${line.content.substring(0, halfWidth - 3)}...'
            : line.content.padRight(halfWidth);
            
        switch (line.type) {
          case THDiffLineType.context:
            buffer.writeln('$content | $content');
            break;
          case THDiffLineType.deletion:
            buffer.writeln('$content | ${''.padRight(halfWidth)}');
            break;
          case THDiffLineType.addition:
            buffer.writeln('${''.padRight(halfWidth)} | $content');
            break;
        }
      }
    }
    
    return buffer.toString();
  }
  
  /// Format timestamp for unified diff
  static String _formatTimestamp(DateTime timestamp) {
    return timestamp.toIso8601String();
  }
  
  /// Format statistics summary
  static String _formatStats(THDiffStats stats) {
    final buffer = StringBuffer();
    buffer.writeln('Statistics:');
    buffer.writeln('  Total lines: ${stats.totalLines}');
    buffer.writeln('  Added: ${stats.addedLines}');
    buffer.writeln('  Deleted: ${stats.deletedLines}');
    buffer.writeln('  Changed: ${stats.changedLines}');
    buffer.writeln('  Unchanged: ${stats.unchangedLines}');
    buffer.writeln('  Hunks: ${stats.hunksCount}');
    buffer.writeln('  Change percentage: ${stats.changePercentage.toStringAsFixed(1)}%');
    return buffer.toString();
  }
}