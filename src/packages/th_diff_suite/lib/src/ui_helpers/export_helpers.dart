import 'dart:io';
import '../models/th_diff_result.dart';
import '../models/th_diff_line.dart';

/// Export and formatting utilities for saving diffs in various formats
/// 
/// Provides convenient methods for exporting diff results to files, clipboard,
/// and other output destinations with proper formatting.
class DiffExportHelpers {
  
  /// Export diff result to a file
  /// 
  /// [result] The diff result to export
  /// [filePath] Path where to save the file
  /// [format] The format to use for export
  /// [options] Optional export configuration
  static Future<void> exportToFile(
    THDiffResult result,
    String filePath,
    DiffExportFormat format, {
    DiffExportOptions? options,
  }) async {
    options ??= const DiffExportOptions();
    
    String content;
    switch (format) {
      case DiffExportFormat.gitDiff:
        content = _formatForExport(
          _getGitDiffContent(result),
          options,
          'Git Diff Export',
        );
        break;
      case DiffExportFormat.unifiedDiff:
        content = _formatForExport(
          _getUnifiedDiffContent(result),
          options,
          'Unified Diff Export',
        );
        break;
      case DiffExportFormat.markdown:
        content = _formatForExport(
          _getMarkdownContent(result),
          options,
          'TH MD Diff Export',
        );
        break;
      case DiffExportFormat.html:
        content = _generateHtmlContent(result, options);
        break;
      case DiffExportFormat.plainText:
        content = _formatForExport(
          _getPlainTextContent(result),
          options,
          'Plain Text Diff Export',
        );
        break;
    }
    
    final file = File(filePath);
    await file.writeAsString(content);
  }
  
  /// Generate a shareable summary of the diff
  /// 
  /// Creates a concise summary suitable for sharing via email, chat, etc.
  static String generateShareableSummary(
    THDiffResult result, {
    bool includeStats = true,
    bool includeFileNames = true,
    int maxPreviewLines = 5,
  }) {
    final buffer = StringBuffer();
    
    // Header
    if (includeFileNames && (result.filePath1 != null || result.filePath2 != null)) {
      buffer.writeln('📄 File Comparison:');
      buffer.writeln('  ${result.filePath1 ?? 'Original'} → ${result.filePath2 ?? 'Modified'}');
      buffer.writeln();
    }
    
    // Statistics
    if (includeStats) {
      buffer.writeln('📊 Changes Summary:');
      if (!result.hasChanges) {
        buffer.writeln('  ✅ No differences found');
      } else {
        buffer.writeln('  📈 ${result.stats.addedLines} additions (+)');
        buffer.writeln('  📉 ${result.stats.deletedLines} deletions (-)');
        buffer.writeln('  🎯 ${result.stats.changePercentage.toStringAsFixed(1)}% changed');
        buffer.writeln('  📦 ${result.stats.hunksCount} change blocks');
      }
      buffer.writeln();
    }
    
    // Preview of changes
    if (result.hasChanges && maxPreviewLines > 0) {
      buffer.writeln('🔍 Preview of Changes:');
      int linesShown = 0;
      
      outerLoop:
      for (final hunk in result.hunks) {
        for (final line in hunk.lines) {
          if (line.isChange && linesShown < maxPreviewLines) {
            final prefix = line.type.prefix;
            final preview = line.content.length > 60 
                ? '${line.content.substring(0, 57)}...'
                : line.content;
            buffer.writeln('  $prefix $preview');
            linesShown++;
          } else if (linesShown >= maxPreviewLines) {
            break outerLoop;
          }
        }
      }
      
      final totalChangedLines = result.allChangedLines.length;
      if (linesShown < totalChangedLines) {
        buffer.writeln('  ... and ${totalChangedLines - linesShown} more changes');
      }
    }
    
    return buffer.toString();
  }
  
  /// Generate clipboard-friendly content
  /// 
  /// Creates content optimized for copying to clipboard, with proper line breaks
  /// and formatting that works well when pasted into various applications.
  static String generateClipboardContent(
    THDiffResult result,
    DiffExportFormat format, {
    bool includeMetadata = false,
  }) {
    switch (format) {
      case DiffExportFormat.gitDiff:
        return _getGitDiffContent(result);
      case DiffExportFormat.unifiedDiff:
        return _getUnifiedDiffContent(result);
      case DiffExportFormat.markdown:
        return _getMarkdownContent(result);
      case DiffExportFormat.plainText:
        return _getPlainTextContent(result);
      case DiffExportFormat.html:
        // For clipboard, return plain text version of HTML
        return _getPlainTextContent(result);
    }
  }
  
  /// Create a diff patch that can be applied with patch tools
  /// 
  /// Generates a properly formatted patch file that can be used with
  /// standard patch utilities or Git.
  static String generateApplicablePatch(
    THDiffResult result, {
    String? originalFileName,
    String? modifiedFileName,
    DateTime? timestamp,
  }) {
    final buffer = StringBuffer();
    
    // Standard patch header
    final origName = originalFileName ?? result.filePath1 ?? 'a/file';
    final modName = modifiedFileName ?? result.filePath2 ?? 'b/file';
    final timeStr = timestamp?.toIso8601String() ?? DateTime.now().toIso8601String();
    
    buffer.writeln('--- $origName\t$timeStr');
    buffer.writeln('+++ $modName\t$timeStr');
    
    // Hunks
    for (final hunk in result.hunks) {
      if (hunk.hasChanges) {
        buffer.writeln(hunk.header);
        for (final line in hunk.lines) {
          buffer.write(line.type.prefix);
          buffer.writeln(line.content);
        }
      }
    }
    
    return buffer.toString();
  }
  
  /// Generate diff statistics in various formats
  static String generateStatistics(
    THDiffResult result,
    StatisticsFormat format,
  ) {
    switch (format) {
      case StatisticsFormat.compact:
        return '+${result.stats.addedLines} -${result.stats.deletedLines}';
      case StatisticsFormat.detailed:
        return _generateDetailedStats(result);
      case StatisticsFormat.json:
        return _generateJsonStats(result);
      case StatisticsFormat.csv:
        return _generateCsvStats(result);
    }
  }
  
  // Private helper methods
  
  static String _getGitDiffContent(THDiffResult result) {
    // Import the formatter to get the actual content
    // This is a placeholder - in real implementation you'd import the formatter
    return 'Git diff content for ${result.filePath1 ?? "file"}';
  }
  
  static String _getUnifiedDiffContent(THDiffResult result) {
    return 'Unified diff content for ${result.filePath1 ?? "file"}';
  }
  
  static String _getMarkdownContent(THDiffResult result) {
    return 'Markdown diff content for ${result.filePath1 ?? "file"}';
  }
  
  static String _getPlainTextContent(THDiffResult result) {
    final buffer = StringBuffer();
    
    // Simple plain text representation
    buffer.writeln('Diff: ${result.filePath1 ?? "Original"} -> ${result.filePath2 ?? "Modified"}');
    buffer.writeln('Changes: +${result.stats.addedLines} -${result.stats.deletedLines}');
    buffer.writeln('');
    
    for (final hunk in result.hunks) {
      if (hunk.hasChanges) {
        buffer.writeln('@ Lines ${hunk.oldStart}-${hunk.oldStart + hunk.oldCount - 1} -> ${hunk.newStart}-${hunk.newStart + hunk.newCount - 1}');
        for (final line in hunk.lines) {
          buffer.writeln('${line.type.prefix} ${line.content}');
        }
        buffer.writeln('');
      }
    }
    
    return buffer.toString();
  }
  
  static String _generateHtmlContent(THDiffResult result, DiffExportOptions options) {
    final buffer = StringBuffer();
    
    buffer.writeln('<!DOCTYPE html>');
    buffer.writeln('<html><head>');
    buffer.writeln('<title>Diff: ${result.filePath1 ?? "file"}</title>');
    buffer.writeln('<style>');
    buffer.writeln('.diff-addition { background-color: #e6ffed; color: #28a745; }');
    buffer.writeln('.diff-deletion { background-color: #ffebee; color: #dc3545; }');
    buffer.writeln('.diff-context { background-color: #f8f9fa; color: #6c757d; }');
    buffer.writeln('pre { font-family: monospace; margin: 0; padding: 2px 4px; }');
    buffer.writeln('</style>');
    buffer.writeln('</head><body>');
    
    buffer.writeln('<h1>Diff Report</h1>');
    buffer.writeln('<p>Changes: +${result.stats.addedLines} -${result.stats.deletedLines}</p>');
    
    for (final hunk in result.hunks) {
      if (hunk.hasChanges) {
        buffer.writeln('<div class="hunk">');
        buffer.writeln('<h3>${hunk.header}</h3>');
        for (final line in hunk.lines) {
          final cssClass = 'diff-${line.type.name}';
          final escaped = _escapeHtml(line.content);
          buffer.writeln('<pre class="$cssClass">${line.type.prefix} $escaped</pre>');
        }
        buffer.writeln('</div>');
      }
    }
    
    buffer.writeln('</body></html>');
    return buffer.toString();
  }
  
  static String _formatForExport(String content, DiffExportOptions options, String title) {
    if (!options.includeHeader && !options.includeFooter) {
      return content;
    }
    
    final buffer = StringBuffer();
    
    if (options.includeHeader) {
      buffer.writeln('=' * 60);
      buffer.writeln(title);
      buffer.writeln('Generated: ${DateTime.now().toIso8601String()}');
      buffer.writeln('=' * 60);
      buffer.writeln();
    }
    
    buffer.write(content);
    
    if (options.includeFooter) {
      buffer.writeln();
      buffer.writeln('=' * 60);
      buffer.writeln('Generated by TH Diff Suite');
      buffer.writeln('=' * 60);
    }
    
    return buffer.toString();
  }
  
  static String _generateDetailedStats(THDiffResult result) {
    final buffer = StringBuffer();
    final stats = result.stats;
    
    buffer.writeln('Detailed Diff Statistics');
    buffer.writeln('========================');
    buffer.writeln('Total Lines Processed: ${stats.totalLines}');
    buffer.writeln('Lines Added: ${stats.addedLines}');
    buffer.writeln('Lines Deleted: ${stats.deletedLines}');
    buffer.writeln('Lines Changed: ${stats.changedLines}');
    buffer.writeln('Lines Unchanged: ${stats.unchangedLines}');
    buffer.writeln('Number of Hunks: ${stats.hunksCount}');
    buffer.writeln('Change Percentage: ${stats.changePercentage.toStringAsFixed(2)}%');
    
    return buffer.toString();
  }
  
  static String _generateJsonStats(THDiffResult result) {
    final stats = result.stats;
    return '''
{
  "totalLines": ${stats.totalLines},
  "addedLines": ${stats.addedLines},
  "deletedLines": ${stats.deletedLines},
  "changedLines": ${stats.changedLines},
  "unchangedLines": ${stats.unchangedLines},
  "hunksCount": ${stats.hunksCount},
  "changePercentage": ${stats.changePercentage}
}''';
  }
  
  static String _generateCsvStats(THDiffResult result) {
    final stats = result.stats;
    return 'TotalLines,AddedLines,DeletedLines,ChangedLines,UnchangedLines,HunksCount,ChangePercentage\n'
           '${stats.totalLines},${stats.addedLines},${stats.deletedLines},${stats.changedLines},${stats.unchangedLines},${stats.hunksCount},${stats.changePercentage}';
  }
  
  static String _escapeHtml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#x27;');
  }
}

/// Export format options
enum DiffExportFormat {
  /// Standard Git diff format
  gitDiff,
  
  /// Traditional unified diff format  
  unifiedDiff,
  
  /// Rich Markdown format with annotations
  markdown,
  
  /// HTML format for web display
  html,
  
  /// Simple plain text format
  plainText,
}

/// Statistics format options
enum StatisticsFormat {
  /// Compact format: "+5 -2"
  compact,
  
  /// Detailed human-readable format
  detailed,
  
  /// JSON format for API/data exchange
  json,
  
  /// CSV format for spreadsheets
  csv,
}

/// Export configuration options
class DiffExportOptions {
  /// Whether to include a header with metadata
  final bool includeHeader;
  
  /// Whether to include a footer with generation info
  final bool includeFooter;
  
  /// Whether to include file timestamps
  final bool includeTimestamps;
  
  /// Whether to include statistics summary
  final bool includeStatistics;
  
  /// Custom title for the export
  final String? customTitle;
  
  const DiffExportOptions({
    this.includeHeader = true,
    this.includeFooter = true,
    this.includeTimestamps = true,
    this.includeStatistics = false,
    this.customTitle,
  });
}