# UI Integration Guide

This guide shows how to integrate TH Diff Suite with Flutter UI components in your MD Tool application.

## Overview

TH Diff Suite provides UI integration helpers that make it easy to build Flutter widgets for displaying diffs. The package includes:

- **Color schemes** for consistent diff visualization
- **Data transformation utilities** for UI optimization
- **Export helpers** for sharing and saving diffs
- **Navigation utilities** for implementing jump-to-change functionality

## Quick Start

```dart
import 'package:th_diff_suite/th_diff_suite.dart';

// 1. Generate diff data
final result = THDiffSuite.compareTexts(originalText, modifiedText);

// 2. Use UI helpers for display
final colorScheme = DiffUIHelpers.defaultColors;
final changeSummary = DiffUIHelpers.createChangeSummary(result);
final lineGroups = DiffUIHelpers.groupConsecutiveLines(result.allChangedLines);
```

## Color Schemes

### Using Default Colors

```dart
// Get default GitHub-style colors
final colors = DiffUIHelpers.defaultColors;

// Apply to widgets
Container(
  color: DiffUIHelpers.getColorForLineType(
    line.type, 
    colorScheme: colors,
    isBackground: true,
  ),
  child: Text(
    line.content,
    style: TextStyle(
      color: DiffUIHelpers.getColorForLineType(line.type, colorScheme: colors),
    ),
  ),
)
```

### Custom Color Scheme

```dart
// Create custom colors matching your app theme
final customColors = DiffColorScheme.fromTheme(
  primary: Theme.of(context).primaryColor,
  error: Theme.of(context).colorScheme.error,
  onSurface: Theme.of(context).colorScheme.onSurface,
  surface: Theme.of(context).colorScheme.surface,
);

// Or create completely custom scheme
final customColors = DiffColorScheme(
  addition: Colors.green.shade700,
  deletion: Colors.red.shade700,
  context: Colors.grey.shade600,
  additionBackground: Colors.green.shade50,
  deletionBackground: Colors.red.shade50,
  contextBackground: Colors.grey.shade50,
  lineNumber: Colors.grey.shade400,
);
```

## Building Diff UI Components

### Basic Diff Viewer

```dart
class SimpleDiffViewer extends StatelessWidget {
  final THDiffResult result;
  final DiffColorScheme? colorScheme;
  
  const SimpleDiffViewer({
    Key? key,
    required this.result,
    this.colorScheme,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colors = colorScheme ?? DiffUIHelpers.defaultColors;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary header
        _buildSummaryHeader(colors),
        
        // Diff content
        Expanded(
          child: ListView.builder(
            itemCount: result.hunks.length,
            itemBuilder: (context, index) => _buildHunk(result.hunks[index], colors),
          ),
        ),
      ],
    );
  }
  
  Widget _buildSummaryHeader(DiffColorScheme colors) {
    final summary = DiffUIHelpers.createChangeSummary(result);
    
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.contextBackground,
        border: Border(bottom: BorderSide(color: colors.context.withOpacity(0.3))),
      ),
      child: Row(
        children: [
          Icon(Icons.compare_arrows, color: colors.context),
          SizedBox(width: 8),
          Text(summary, style: TextStyle(color: colors.context, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
  
  Widget _buildHunk(THDiffHunk hunk, DiffColorScheme colors) {
    if (!hunk.hasChanges) return SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Hunk header
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: colors.context.withOpacity(0.1),
          child: Text(
            hunk.header,
            style: TextStyle(
              fontFamily: 'monospace',
              color: colors.context,
              fontSize: 12,
            ),
          ),
        ),
        
        // Hunk lines
        ...hunk.lines.map((line) => _buildLine(line, colors)).toList(),
      ],
    );
  }
  
  Widget _buildLine(THDiffLine line, DiffColorScheme colors) {
    return Container(
      color: DiffUIHelpers.getColorForLineType(line.type, colorScheme: colors, isBackground: true),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Line prefix (+, -, space)
            Container(
              width: 20,
              child: Text(
                DiffUIHelpers.getPrefixForLineType(line.type),
                style: TextStyle(
                  fontFamily: 'monospace',
                  color: DiffUIHelpers.getColorForLineType(line.type, colorScheme: colors),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            
            // Line content
            Expanded(
              child: Text(
                line.content,
                style: TextStyle(
                  fontFamily: 'monospace',
                  color: DiffUIHelpers.getColorForLineType(line.type, colorScheme: colors),
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

### Side-by-Side Diff Viewer

```dart
class SideBySideDiffViewer extends StatelessWidget {
  final THDiffResult result;
  
  @override
  Widget build(BuildContext context) {
    final allLines = DiffUIHelpers.getAllLines(result);
    final lineNumbers = DiffUIHelpers.extractLineNumbers(
      allLines.map((item) => item.line).toList()
    );
    
    return Row(
      children: [
        // Line numbers column
        Container(
          width: 80,
          color: Colors.grey.shade100,
          child: ListView.builder(
            itemCount: lineNumbers.length,
            itemBuilder: (context, index) => _buildLineNumbers(lineNumbers[index]),
          ),
        ),
        
        // Left side (original)
        Expanded(
          child: ListView.builder(
            itemCount: allLines.length,
            itemBuilder: (context, index) => _buildOriginalLine(allLines[index].line),
          ),
        ),
        
        // Right side (modified)
        Expanded(
          child: ListView.builder(
            itemCount: allLines.length,
            itemBuilder: (context, index) => _buildModifiedLine(allLines[index].line),
          ),
        ),
      ],
    );
  }
  
  Widget _buildLineNumbers(DiffLineNumbers lineNumbers) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              lineNumbers.oldNumber ?? '',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.right,
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              lineNumbers.newNumber ?? '',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildOriginalLine(THDiffLine line) {
    final showLine = line.type != THDiffLineType.addition;
    
    return Container(
      height: 20,
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      color: line.type == THDiffLineType.deletion 
          ? Colors.red.shade50 
          : Colors.transparent,
      child: showLine
          ? Text(
              line.content,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
                color: line.type == THDiffLineType.deletion
                    ? Colors.red.shade700
                    : Colors.black,
              ),
            )
          : null,
    );
  }
  
  Widget _buildModifiedLine(THDiffLine line) {
    final showLine = line.type != THDiffLineType.deletion;
    
    return Container(
      height: 20,
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      color: line.type == THDiffLineType.addition 
          ? Colors.green.shade50 
          : Colors.transparent,
      child: showLine
          ? Text(
              line.content,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
                color: line.type == THDiffLineType.addition
                    ? Colors.green.shade700
                    : Colors.black,
              ),
            )
          : null,
    );
  }
}
```

## Performance Optimization

### Grouping Lines for Better Performance

```dart
// Group consecutive lines of the same type
final lineGroups = DiffUIHelpers.groupConsecutiveLines(result.allChangedLines);

// Render groups instead of individual lines
ListView.builder(
  itemCount: lineGroups.length,
  itemBuilder: (context, index) {
    final group = lineGroups[index];
    
    if (group.lineCount > 10) {
      // For large groups, show a summary
      return _buildGroupSummary(group);
    } else {
      // For small groups, show all lines
      return _buildGroupLines(group);
    }
  },
)
```

### Virtual Scrolling for Large Diffs

```dart
class VirtualizedDiffViewer extends StatelessWidget {
  final THDiffResult result;
  
  @override
  Widget build(BuildContext context) {
    final allLines = DiffUIHelpers.getAllLines(result);
    
    return ListView.builder(
      itemCount: allLines.length,
      itemExtent: 20.0, // Fixed height for better performance
      itemBuilder: (context, index) {
        final item = allLines[index];
        return _buildVirtualizedLine(item.line);
      },
    );
  }
  
  Widget _buildVirtualizedLine(THDiffLine line) {
    // Simplified rendering for performance
    return Container(
      height: 20,
      padding: EdgeInsets.symmetric(horizontal: 8),
      color: DiffUIHelpers.getColorForLineType(line.type, isBackground: true),
      child: Text(
        '${line.type.prefix} ${line.content}',
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 12,
          color: DiffUIHelpers.getColorForLineType(line.type),
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
```

## Navigation Features

### Jump to Changes

```dart
class DiffNavigator extends StatefulWidget {
  final THDiffResult result;
  final ScrollController scrollController;
  
  @override
  _DiffNavigatorState createState() => _DiffNavigatorState();
}

class _DiffNavigatorState extends State<DiffNavigator> {
  late List<int> changePositions;
  int currentChangeIndex = 0;
  
  @override
  void initState() {
    super.initState();
    changePositions = DiffUIHelpers.getChangePositions(widget.result);
  }
  
  void jumpToNextChange() {
    if (currentChangeIndex < changePositions.length - 1) {
      currentChangeIndex++;
      _scrollToPosition(changePositions[currentChangeIndex]);
    }
  }
  
  void jumpToPreviousChange() {
    if (currentChangeIndex > 0) {
      currentChangeIndex--;
      _scrollToPosition(changePositions[currentChangeIndex]);
    }
  }
  
  void _scrollToPosition(int position) {
    const itemHeight = 20.0;
    widget.scrollController.animateTo(
      position * itemHeight,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: Icon(Icons.keyboard_arrow_up),
          onPressed: currentChangeIndex > 0 ? jumpToPreviousChange : null,
        ),
        Text('${currentChangeIndex + 1} of ${changePositions.length}'),
        IconButton(
          icon: Icon(Icons.keyboard_arrow_down),
          onPressed: currentChangeIndex < changePositions.length - 1 
              ? jumpToNextChange 
              : null,
        ),
      ],
    );
  }
}
```

## Export and Sharing

### Export Menu

```dart
class DiffExportMenu extends StatelessWidget {
  final THDiffResult result;
  
  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<DiffExportFormat>(
      icon: Icon(Icons.share),
      onSelected: (format) => _exportDiff(context, format),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: DiffExportFormat.gitDiff,
          child: ListTile(
            leading: Icon(Icons.code),
            title: Text('Git Diff'),
            subtitle: Text('Standard Git format'),
          ),
        ),
        PopupMenuItem(
          value: DiffExportFormat.markdown,
          child: ListTile(
            leading: Icon(Icons.description),
            title: Text('Markdown'),
            subtitle: Text('Rich format with annotations'),
          ),
        ),
        PopupMenuItem(
          value: DiffExportFormat.html,
          child: ListTile(
            leading: Icon(Icons.web),
            title: Text('HTML'),
            subtitle: Text('For web sharing'),
          ),
        ),
      ],
    );
  }
  
  Future<void> _exportDiff(BuildContext context, DiffExportFormat format) async {
    try {
      // Show file picker or share sheet
      final fileName = 'diff_${DateTime.now().millisecondsSinceEpoch}';
      final extension = _getExtensionForFormat(format);
      
      await DiffExportHelpers.exportToFile(
        result,
        '$fileName.$extension',
        format,
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Diff exported successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export failed: $e')),
      );
    }
  }
  
  String _getExtensionForFormat(DiffExportFormat format) {
    switch (format) {
      case DiffExportFormat.gitDiff:
      case DiffExportFormat.unifiedDiff:
        return 'diff';
      case DiffExportFormat.markdown:
        return 'md';
      case DiffExportFormat.html:
        return 'html';
      case DiffExportFormat.plainText:
        return 'txt';
    }
  }
}
```

### Copy to Clipboard

```dart
void copyDiffToClipboard(THDiffResult result, DiffExportFormat format) {
  final content = DiffExportHelpers.generateClipboardContent(result, format);
  Clipboard.setData(ClipboardData(text: content));
}

// Usage in widget
IconButton(
  icon: Icon(Icons.copy),
  onPressed: () {
    copyDiffToClipboard(result, DiffExportFormat.markdown);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Diff copied to clipboard')),
    );
  },
)
```

## Summary Statistics Widget

```dart
class DiffSummaryCard extends StatelessWidget {
  final THDiffResult result;
  
  @override
  Widget build(BuildContext context) {
    final stats = result.stats;
    final summary = DiffUIHelpers.createChangeSummary(result, compact: true);
    
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Diff Summary',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SizedBox(height: 8),
            
            // Change summary
            Text(summary),
            SizedBox(height: 12),
            
            // Statistics grid
            Row(
              children: [
                _buildStatItem('Added', stats.addedLines, Colors.green),
                _buildStatItem('Deleted', stats.deletedLines, Colors.red),
                _buildStatItem('Changed', stats.changePercentage.toInt(), Colors.blue, suffix: '%'),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatItem(String label, int value, Color color, {String suffix = ''}) {
    return Expanded(
      child: Column(
        children: [
          Text(
            '$value$suffix',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
```

## Integration Checklist

When integrating TH Diff Suite into your MD Tool:

- [ ] **Import UI helpers**: Add `import 'package:th_diff_suite/th_diff_suite.dart';`
- [ ] **Choose color scheme**: Use default or create custom colors matching your theme
- [ ] **Select display format**: Inline, side-by-side, or custom layout
- [ ] **Add navigation**: Implement jump-to-change functionality
- [ ] **Include export options**: Allow users to save/share diffs
- [ ] **Optimize performance**: Use line grouping for large diffs
- [ ] **Add accessibility**: Include proper semantic labels and keyboard navigation
- [ ] **Test with real data**: Verify with actual markdown documents from your use case

These helpers provide everything you need to create a professional diff viewer that integrates seamlessly with your MD Tool's existing design system.