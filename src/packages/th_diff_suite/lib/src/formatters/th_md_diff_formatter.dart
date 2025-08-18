import '../models/th_diff_result.dart';
import '../models/th_diff_line.dart';
import '../models/th_diff_hunk.dart';

/// Formats diff results in TH MD custom format with annotations
class THMDDiffFormatter {
  /// Convert a THDiffResult to TH MD diff format with rich annotations
  static String format(THDiffResult result) {
    final buffer = StringBuffer();
    
    // TH MD Diff Header with metadata
    buffer.writeln('# TH MD Diff Report');
    buffer.writeln();
    buffer.writeln('## File Information');
    buffer.writeln('- **Original**: ${result.filePath1 ?? 'text input'}');
    buffer.writeln('- **Modified**: ${result.filePath2 ?? 'text input'}');
    buffer.writeln('- **Generated**: ${result.timestamp.toIso8601String()}');
    buffer.writeln();
    
    // Statistics section
    buffer.writeln('## Statistics');
    buffer.writeln('- **Total Lines**: ${result.stats.totalLines}');
    buffer.writeln('- **Added Lines**: ${result.stats.addedLines}');
    buffer.writeln('- **Deleted Lines**: ${result.stats.deletedLines}');
    buffer.writeln('- **Changed Lines**: ${result.stats.changedLines}');
    buffer.writeln('- **Unchanged Lines**: ${result.stats.unchangedLines}');
    buffer.writeln('- **Hunks**: ${result.stats.hunksCount}');
    buffer.writeln('- **Change Percentage**: ${result.stats.changePercentage.toStringAsFixed(1)}%');
    buffer.writeln();
    
    // No changes message
    if (!result.hasChanges) {
      buffer.writeln('## Result');
      buffer.writeln('**No differences found** - files are identical.');
      return buffer.toString();
    }
    
    // Changes overview
    buffer.writeln('## Changes Overview');
    for (int i = 0; i < result.hunks.length; i++) {
      final hunk = result.hunks[i];
      if (!hunk.hasChanges) continue;
      
      buffer.writeln('- **Hunk ${i + 1}**: Lines ${hunk.oldStart}-${hunk.oldStart + hunk.oldCount - 1} → ${hunk.newStart}-${hunk.newStart + hunk.newCount - 1}');
      buffer.writeln('  - Additions: ${hunk.additionCount}');
      buffer.writeln('  - Deletions: ${hunk.deletionCount}');
      if (hunk.sectionHeader != null) {
        buffer.writeln('  - Section: ${hunk.sectionHeader}');
      }
    }
    buffer.writeln();
    
    // Detailed changes
    buffer.writeln('## Detailed Changes');
    
    for (int i = 0; i < result.hunks.length; i++) {
      final hunk = result.hunks[i];
      if (!hunk.hasChanges) continue;
      
      buffer.writeln();
      buffer.writeln('### Hunk ${i + 1}');
      buffer.writeln();
      
      if (hunk.sectionHeader != null) {
        buffer.writeln('**Context**: ${hunk.sectionHeader}');
        buffer.writeln();
      }
      
      buffer.writeln('**Location**: Lines ${hunk.oldStart}-${hunk.oldStart + hunk.oldCount - 1} → ${hunk.newStart}-${hunk.newStart + hunk.newCount - 1}');
      buffer.writeln();
      
      // Render hunk with syntax highlighting and annotations
      buffer.writeln('```diff');
      for (final line in hunk.lines) {
        buffer.write(line.type.prefix);
        buffer.writeln(line.content);
      }
      buffer.writeln('```');
      
      // Add line-by-line annotations
      buffer.writeln();
      buffer.writeln('**Line Details**:');
      for (final line in hunk.lines) {
        if (line.isChange) {
          final lineInfo = _formatLineAnnotation(line);
          buffer.writeln('- $lineInfo');
        }
      }
    }
    
    // Configuration used
    buffer.writeln();
    buffer.writeln('## Configuration');
    buffer.writeln('- **Context Lines**: ${result.options.contextLines}');
    buffer.writeln('- **Timeout**: ${result.options.timeout}s');
    buffer.writeln('- **Semantic Cleanup**: ${result.options.enableSemanticCleanup}');
    buffer.writeln('- **Efficiency Cleanup**: ${result.options.enableEfficiencyCleanup}');
    buffer.writeln('- **Ignore Whitespace**: ${result.options.ignoreWhitespace}');
    buffer.writeln('- **Ignore Case**: ${result.options.ignoreCase}');
    
    return buffer.toString();
  }
  
  /// Format for interactive display (JSON-like structure)
  static String formatInteractive(THDiffResult result) {
    final buffer = StringBuffer();
    
    buffer.writeln('```json');
    buffer.writeln('{');
    buffer.writeln('  "type": "th_md_diff",');
    buffer.writeln('  "version": "1.0",');
    buffer.writeln('  "metadata": {');
    buffer.writeln('    "original_file": "${result.filePath1 ?? 'text_input'}",');
    buffer.writeln('    "modified_file": "${result.filePath2 ?? 'text_input'}",');
    buffer.writeln('    "timestamp": "${result.timestamp.toIso8601String()}",');
    buffer.writeln('    "has_changes": ${result.hasChanges}');
    buffer.writeln('  },');
    buffer.writeln('  "statistics": {');
    buffer.writeln('    "total_lines": ${result.stats.totalLines},');
    buffer.writeln('    "added_lines": ${result.stats.addedLines},');
    buffer.writeln('    "deleted_lines": ${result.stats.deletedLines},');
    buffer.writeln('    "unchanged_lines": ${result.stats.unchangedLines},');
    buffer.writeln('    "hunks_count": ${result.stats.hunksCount},');
    buffer.writeln('    "change_percentage": ${result.stats.changePercentage}');
    buffer.writeln('  },');
    buffer.writeln('  "hunks": [');
    
    for (int i = 0; i < result.hunks.length; i++) {
      final hunk = result.hunks[i];
      if (!hunk.hasChanges) continue;
      
      buffer.writeln('    {');
      buffer.writeln('      "id": ${i + 1},');
      buffer.writeln('      "old_range": {"start": ${hunk.oldStart}, "count": ${hunk.oldCount}},');
      buffer.writeln('      "new_range": {"start": ${hunk.newStart}, "count": ${hunk.newCount}},');
      buffer.writeln('      "section_header": ${hunk.sectionHeader != null ? '"${hunk.sectionHeader}"' : 'null'},');
      buffer.writeln('      "additions": ${hunk.additionCount},');
      buffer.writeln('      "deletions": ${hunk.deletionCount},');
      buffer.writeln('      "lines": [');
      
      for (int j = 0; j < hunk.lines.length; j++) {
        final line = hunk.lines[j];
        final comma = j < hunk.lines.length - 1 ? ',' : '';
        buffer.writeln('        {');
        buffer.writeln('          "type": "${line.type.name}",');
        buffer.writeln('          "content": "${_escapeJson(line.content)}",');
        buffer.writeln('          "old_line": ${line.oldLineNumber},');
        buffer.writeln('          "new_line": ${line.newLineNumber}');
        buffer.writeln('        }$comma');
      }
      
      buffer.writeln('      ]');
      final comma = i < result.hunks.length - 1 ? ',' : '';
      buffer.writeln('    }$comma');
    }
    
    buffer.writeln('  ]');
    buffer.writeln('}');
    buffer.writeln('```');
    
    return buffer.toString();
  }
  
  /// Format for compact display
  static String formatCompact(THDiffResult result) {
    if (!result.hasChanges) {
      return '**No changes detected**';
    }
    
    final buffer = StringBuffer();
    buffer.writeln('**Changes**: +${result.stats.addedLines} -${result.stats.deletedLines} (~${result.stats.changePercentage.toStringAsFixed(1)}%)');
    
    for (int i = 0; i < result.hunks.length; i++) {
      final hunk = result.hunks[i];
      if (!hunk.hasChanges) continue;
      
      buffer.writeln();
      buffer.writeln('**Hunk ${i + 1}** `@@ -${hunk.oldStart},${hunk.oldCount} +${hunk.newStart},${hunk.newCount} @@`');
      
      // Show only a few representative lines
      final changedLines = hunk.changedLines.take(3).toList();
      for (final line in changedLines) {
        final prefix = line.type == THDiffLineType.addition ? '+' : '-';
        final content = line.content.length > 60 
            ? '${line.content.substring(0, 57)}...'
            : line.content;
        buffer.writeln('  `$prefix $content`');
      }
      
      if (hunk.changedLines.length > 3) {
        buffer.writeln('  `... and ${hunk.changedLines.length - 3} more changes`');
      }
    }
    
    return buffer.toString();
  }
  
  /// Format line annotation with detailed information
  static String _formatLineAnnotation(THDiffLine line) {
    final type = line.type == THDiffLineType.addition ? 'Added' : 'Deleted';
    final lineNum = line.type == THDiffLineType.addition 
        ? line.newLineNumber ?? '?'
        : line.oldLineNumber ?? '?';
    
    final content = line.content.length > 50 
        ? '${line.content.substring(0, 47)}...'
        : line.content;
    
    return '**$type** at line $lineNum: `$content`';
  }
  
  /// Escape JSON special characters
  static String _escapeJson(String text) {
    return text
        .replaceAll('\\', '\\\\')
        .replaceAll('"', '\\"')
        .replaceAll('\n', '\\n')
        .replaceAll('\r', '\\r')
        .replaceAll('\t', '\\t');
  }
}