import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:th_diff_suite/th_diff_suite.dart';

class THDiffViewer extends StatefulWidget {
  final String leftText;
  final String rightText;
  final String? leftTitle;
  final String? rightTitle;
  final bool showLineNumbers;
  final DiffDisplayMode displayMode;

  const THDiffViewer({
    super.key,
    required this.leftText,
    required this.rightText,
    this.leftTitle,
    this.rightTitle,
    this.showLineNumbers = true,
    this.displayMode = DiffDisplayMode.sideBySide,
  });

  @override
  State<THDiffViewer> createState() => _THDiffViewerState();
}

class _THDiffViewerState extends State<THDiffViewer> {
  THDiffResult? diffResult;
  DiffColorScheme? colorScheme;
  late ScrollController _scrollController;
  List<int> changePositions = [];
  int currentChangeIndex = 0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _computeDiff();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _setupColorScheme();
  }

  @override
  void didUpdateWidget(THDiffViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.leftText != widget.leftText || oldWidget.rightText != widget.rightText) {
      _computeDiff();
    }
  }

  void _computeDiff() {
    // Configure options for enhanced intra-line diffing
    final options = THDiffOptions(
      enableIntraLineDiff: true,
      wordLevelDiff: true,
      similarityThreshold: 0.3,
      contextLines: 3,
      ignoreWhitespace: false, // Keep whitespace for precise diffing
    );
    
    diffResult = THDiffSuite.compareTexts(widget.leftText, widget.rightText, options);
    changePositions = DiffUIHelpers.getChangePositions(diffResult!);
    if (changePositions.isNotEmpty) {
      currentChangeIndex = 0;
    }
  }

  void _setupColorScheme() {
    colorScheme = DiffColorScheme.fromTheme(
      primary: Theme.of(context).primaryColor,
      error: Theme.of(context).colorScheme.error,
      onSurface: Theme.of(context).colorScheme.onSurface,
      surface: Theme.of(context).colorScheme.surface,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _jumpToNextChange() {
    if (currentChangeIndex < changePositions.length - 1) {
      setState(() {
        currentChangeIndex++;
      });
      _scrollToPosition(changePositions[currentChangeIndex]);
    }
  }

  void _jumpToPreviousChange() {
    if (currentChangeIndex > 0) {
      setState(() {
        currentChangeIndex--;
      });
      _scrollToPosition(changePositions[currentChangeIndex]);
    }
  }

  void _scrollToPosition(int position) {
    // Use estimated item height since content can vary
    const estimatedItemHeight = 24.0; // Slightly larger to account for multi-line content
    _scrollController.animateTo(
      position * estimatedItemHeight,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _copyDiffToClipboard() async {
    if (diffResult == null || !mounted) return;
    
    final content = DiffExportHelpers.generateClipboardContent(
      diffResult!, 
      DiffExportFormat.markdown,
    );
    await Clipboard.setData(ClipboardData(text: content));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Diff copied to clipboard')),
      );
    }
  }

  Future<void> _exportDiff(DiffExportFormat format) async {
    if (diffResult == null || !mounted) return;
    
    try {
      final fileName = 'diff_${DateTime.now().millisecondsSinceEpoch}';
      final extension = _getExtensionForFormat(format);
      
      await DiffExportHelpers.exportToFile(
        diffResult!,
        '$fileName.$extension',
        format,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Diff exported successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
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

  Widget _buildNavigationControls() {
    if (diffResult == null) {
      return const SizedBox.shrink();
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Navigation controls
            IconButton(
              icon: const Icon(Icons.keyboard_arrow_up, size: 20),
              onPressed: currentChangeIndex > 0 ? _jumpToPreviousChange : null,
              tooltip: 'Previous change',
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                changePositions.isEmpty 
                    ? 'No changes'
                    : '${currentChangeIndex + 1} of ${changePositions.length}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.keyboard_arrow_down, size: 20),
              onPressed: currentChangeIndex < changePositions.length - 1 
                  ? _jumpToNextChange 
                  : null,
              tooltip: 'Next change',
            ),
            
            const SizedBox(width: 16),
            
            // Export controls
            IconButton(
              icon: const Icon(Icons.copy, size: 20),
              onPressed: _copyDiffToClipboard,
              tooltip: 'Copy to clipboard',
            ),
            PopupMenuButton<DiffExportFormat>(
              icon: const Icon(Icons.share, size: 20),
              tooltip: 'Export diff',
              onSelected: _exportDiff,
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: DiffExportFormat.gitDiff,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.code, size: 16),
                      SizedBox(width: 8),
                      Text('Git Diff'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: DiffExportFormat.markdown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.description, size: 16),
                      SizedBox(width: 8),
                      Text('Markdown'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: DiffExportFormat.html,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.web, size: 16),
                      SizedBox(width: 8),
                      Text('HTML'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryHeader() {
    if (diffResult == null || colorScheme == null) {
      return const SizedBox.shrink();
    }
    
    final summary = DiffUIHelpers.createChangeSummary(diffResult!);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme!.contextBackground,
        border: Border(
          bottom: BorderSide(
            color: colorScheme!.context.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.compare_arrows, color: colorScheme!.context),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                summary,
                style: TextStyle(
                  color: colorScheme!.context, 
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 16),
            DiffSummaryCard(result: diffResult!),
          ],
        ),
      ),
    );
  }

  Widget _buildInlineDiffViewer() {
    if (diffResult == null) {
      return const Center(child: CircularProgressIndicator());
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSummaryHeader(),
        _buildNavigationControls(),
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            itemCount: diffResult!.hunks.length,
            shrinkWrap: true,
            itemBuilder: (context, index) => _buildHunk(diffResult!.hunks[index]),
          ),
        ),
      ],
    );
  }

  Widget _buildSideBySideDiffViewer() {
    if (diffResult == null) {
      return const Center(child: CircularProgressIndicator());
    }
    
    final allLines = DiffUIHelpers.getAllLines(diffResult!);
    final lineNumbers = DiffUIHelpers.extractLineNumbers(
      allLines.map((item) => item.line).toList(),
    );

    return Column(
      children: [
        _buildSummaryHeader(),
        _buildNavigationControls(),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final availableWidth = constraints.maxWidth;
              final lineNumbersWidth = widget.showLineNumbers ? 80.0 : 0.0;
              final dividerWidth = 2.0;
              final remainingWidth = availableWidth - lineNumbersWidth - dividerWidth;
              final sideWidth = remainingWidth / 2;
              
              return Row(
                children: [
                  // Line numbers column
                  if (widget.showLineNumbers)
                    SizedBox(
                      width: lineNumbersWidth,
                      child: Container(
                        color: Colors.grey.shade100,
                        child: ListView.builder(
                          controller: _scrollController,
                          itemCount: lineNumbers.length,
                          shrinkWrap: true,
                          itemBuilder: (context, index) => _buildLineNumbers(lineNumbers[index]),
                        ),
                      ),
                    ),
                  
                  // Left side (original)
                  Expanded(
                    child: ListView.builder(
                      controller: _scrollController,
                      itemCount: allLines.length,
                      shrinkWrap: true,
                      itemBuilder: (context, index) => _buildOriginalLine(allLines[index].line),
                    ),
                  ),
                  
                  // Divider
                  Container(
                    width: dividerWidth,
                    color: Theme.of(context).dividerColor,
                  ),
                  
                  // Right side (modified)
                  Expanded(
                    child: ListView.builder(
                      controller: _scrollController,
                      itemCount: allLines.length,
                      shrinkWrap: true,
                      itemBuilder: (context, index) => _buildModifiedLine(allLines[index].line),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHunk(THDiffHunk hunk) {
    if (!hunk.hasChanges || colorScheme == null) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Hunk header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: colorScheme!.context.withValues(alpha: 0.1),
          child: Text(
            hunk.header,
            style: TextStyle(
              fontFamily: 'monospace',
              color: colorScheme!.context,
              fontSize: 12,
            ),
          ),
        ),
        
        // Hunk lines
        ...hunk.lines.map((line) => _buildLine(line)),
      ],
    );
  }

  Widget _buildLine(THDiffLine line) {
    if (colorScheme == null) return const SizedBox.shrink();
    
    return Container(
      width: double.infinity,
      color: DiffUIHelpers.getColorForLineType(
        line.type, 
        colorScheme: colorScheme!, 
        isBackground: true,
      ),
      child: IntrinsicHeight(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Line prefix (+, -, space)
              SizedBox(
                width: 20,
                child: Text(
                  DiffUIHelpers.getPrefixForLineType(line.type),
                  style: TextStyle(
                    fontFamily: 'monospace',
                    color: DiffUIHelpers.getColorForLineType(
                      line.type, 
                      colorScheme: colorScheme!,
                    ),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              
              // Line content with intra-line diff support
              Flexible(
                child: _buildLineContent(line),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLineContent(THDiffLine line) {
    if (!line.hasIntraLineDiff) {
      // No intra-line diffs, render as simple text
      return Text(
        line.content,
        style: TextStyle(
          fontFamily: 'monospace',
          color: DiffUIHelpers.getColorForLineType(
            line.type, 
            colorScheme: colorScheme!,
          ),
          fontSize: 13,
        ),
        softWrap: true,
        overflow: TextOverflow.visible,
      );
    }

    // Build RichText with highlighted intra-line diffs
    final spans = <TextSpan>[];
    final baseColor = DiffUIHelpers.getColorForLineType(
      line.type, 
      colorScheme: colorScheme!,
    );
    
    for (final intraDiff in line.intraLineDiffs!) {
      Color textColor = baseColor;
      Color? backgroundColor;
      
      switch (intraDiff.type) {
        case THIntraLineDiffType.equal:
          // Keep default colors
          break;
        case THIntraLineDiffType.delete:
          textColor = colorScheme!.deletion;
          backgroundColor = colorScheme!.deletionBackground.withValues(alpha: 0.3);
          break;
        case THIntraLineDiffType.insert:
          textColor = colorScheme!.addition;
          backgroundColor = colorScheme!.additionBackground.withValues(alpha: 0.3);
          break;
      }
      
      spans.add(TextSpan(
        text: intraDiff.text,
        style: TextStyle(
          fontFamily: 'monospace',
          color: textColor,
          backgroundColor: backgroundColor,
          fontSize: 13,
        ),
      ));
    }
    
    return RichText(
      text: TextSpan(children: spans),
      softWrap: true,
      overflow: TextOverflow.visible,
    );
  }

  Widget _buildLineNumbers(DiffLineNumbers lineNumbers) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: IntrinsicHeight(
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
            const SizedBox(width: 8),
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
      ),
    );
  }

  Widget _buildOriginalLine(THDiffLine line) {
    if (colorScheme == null) return const SizedBox();
    
    final showLine = line.type != THDiffLineType.addition;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      color: line.type == THDiffLineType.deletion 
          ? colorScheme!.deletionBackground
          : Colors.transparent,
      child: showLine
          ? IntrinsicHeight(child: _buildSideBySideLineContent(line, isOriginal: true))
          : const SizedBox(),
    );
  }

  Widget _buildModifiedLine(THDiffLine line) {
    if (colorScheme == null) return const SizedBox();
    
    final showLine = line.type != THDiffLineType.deletion;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      color: line.type == THDiffLineType.addition 
          ? colorScheme!.additionBackground
          : Colors.transparent,
      child: showLine
          ? IntrinsicHeight(child: _buildSideBySideLineContent(line, isOriginal: false))
          : const SizedBox(),
    );
  }

  Widget _buildSideBySideLineContent(THDiffLine line, {required bool isOriginal}) {
    final defaultColor = line.type == THDiffLineType.deletion
        ? colorScheme!.deletion
        : line.type == THDiffLineType.addition
            ? colorScheme!.addition
            : colorScheme!.context;
    
    if (!line.hasIntraLineDiff) {
      // No intra-line diffs, render as simple text
      return Text(
        line.content,
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 13,
          color: defaultColor,
        ),
        softWrap: true,
        overflow: TextOverflow.visible,
      );
    }

    // Build RichText with highlighted intra-line diffs
    final spans = <TextSpan>[];
    
    for (final intraDiff in line.intraLineDiffs!) {
      Color textColor = defaultColor;
      Color? backgroundColor;
      
      // For side-by-side view, only highlight relevant changes
      switch (intraDiff.type) {
        case THIntraLineDiffType.equal:
          // Keep default color
          break;
        case THIntraLineDiffType.delete:
          if (isOriginal) {
            textColor = colorScheme!.deletion;
            backgroundColor = colorScheme!.deletionBackground.withValues(alpha: 0.4);
          }
          break;
        case THIntraLineDiffType.insert:
          if (!isOriginal) {
            textColor = colorScheme!.addition;
            backgroundColor = colorScheme!.additionBackground.withValues(alpha: 0.4);
          }
          break;
      }
      
      spans.add(TextSpan(
        text: intraDiff.text,
        style: TextStyle(
          fontFamily: 'monospace',
          color: textColor,
          backgroundColor: backgroundColor,
          fontSize: 13,
        ),
      ));
    }
    
    return RichText(
      text: TextSpan(children: spans),
      softWrap: true,
      overflow: TextOverflow.visible,
    );
  }

  Widget _buildFullFileDiffViewer() {
    if (diffResult == null) {
      return const Center(child: CircularProgressIndicator());
    }
    
    final fullFileLines = _generateFullFileView();
    
    return Column(
      children: [
        _buildSummaryHeader(),
        _buildNavigationControls(),
        // Header with file title
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).dividerColor,
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.description,
                size: 16,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.rightTitle ?? 'Modified File',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Full File View',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            itemCount: fullFileLines.length,
            shrinkWrap: true,
            itemBuilder: (context, index) => _buildFullFileLine(fullFileLines[index], index + 1),
          ),
        ),
      ],
    );
  }

  List<FullFileLine> _generateFullFileView() {
    if (diffResult == null) return [];
    
    final lines = <FullFileLine>[];
    final leftLines = widget.leftText.split('\n');
    final rightLines = widget.rightText.split('\n');
    
    // Simple line-by-line comparison for full file view
    final changedLines = <int>{};
    final addedLines = <int>{};
    final removedLines = <int>{};
    
    // Use a simple diff to identify changed lines
    final diffLines = _simpleLineDiff(leftLines, rightLines);
    
    // Process diff results to mark changed lines
    for (final diffLine in diffLines) {
      switch (diffLine.type) {
        case 'added':
          addedLines.add(diffLine.rightIndex!);
          break;
        case 'removed':
          removedLines.add(diffLine.leftIndex!);
          break;
        case 'changed':
          if (diffLine.rightIndex != null) {
            changedLines.add(diffLine.rightIndex!);
          }
          break;
      }
    }
    
    // Generate full file view based on the right (modified) file
    for (int i = 0; i < rightLines.length; i++) {
      final lineNumber = i + 1;
      final content = rightLines[i];
      
      THDiffLineType diffType;
      bool isHighlighted = false;
      
      if (addedLines.contains(i)) {
        diffType = THDiffLineType.addition;
        isHighlighted = true;
      } else if (changedLines.contains(i)) {
        diffType = THDiffLineType.addition; // Show as modified (use addition style)
        isHighlighted = true;
      } else {
        diffType = THDiffLineType.context;
      }
      
      // Check if this line is near changes
      final isInChangeBlock = _isNearChanges(i, addedLines, changedLines);
      
      lines.add(FullFileLine(
        content: content,
        lineNumber: lineNumber,
        diffType: diffType,
        isHighlighted: isHighlighted,
        isInChangeBlock: isInChangeBlock,
      ));
    }
    
    // Also add removed lines at appropriate positions
    final finalLines = <FullFileLine>[];
    int rightIndex = 0;
    
    for (final diffLine in diffLines) {
      if (diffLine.type == 'removed') {
        // Insert removed line
        finalLines.add(FullFileLine(
          content: diffLine.content,
          lineNumber: diffLine.leftIndex! + 1,
          diffType: THDiffLineType.deletion,
          isHighlighted: true,
          isInChangeBlock: true,
        ));
      } else if (diffLine.rightIndex != null) {
        // Add the corresponding line from our generated list
        if (rightIndex < lines.length) {
          finalLines.add(lines[rightIndex]);
          rightIndex++;
        }
      }
    }
    
    // Add any remaining lines
    while (rightIndex < lines.length) {
      finalLines.add(lines[rightIndex]);
      rightIndex++;
    }
    
    return finalLines.isNotEmpty ? finalLines : lines;
  }
  
  List<SimpleDiffLine> _simpleLineDiff(List<String> leftLines, List<String> rightLines) {
    final result = <SimpleDiffLine>[];
    int leftIndex = 0;
    int rightIndex = 0;
    
    while (leftIndex < leftLines.length || rightIndex < rightLines.length) {
      if (leftIndex >= leftLines.length) {
        // Remaining lines are added
        result.add(SimpleDiffLine(
          content: rightLines[rightIndex],
          type: 'added',
          rightIndex: rightIndex,
        ));
        rightIndex++;
      } else if (rightIndex >= rightLines.length) {
        // Remaining lines are removed
        result.add(SimpleDiffLine(
          content: leftLines[leftIndex],
          type: 'removed',
          leftIndex: leftIndex,
        ));
        leftIndex++;
      } else if (leftLines[leftIndex] == rightLines[rightIndex]) {
        // Lines are the same
        result.add(SimpleDiffLine(
          content: rightLines[rightIndex],
          type: 'unchanged',
          leftIndex: leftIndex,
          rightIndex: rightIndex,
        ));
        leftIndex++;
        rightIndex++;
      } else {
        // Lines are different - try to find the best match
        final leftLine = leftLines[leftIndex];
        final rightLine = rightLines[rightIndex];
        
        // Check if the left line exists further in the right
        final rightMatch = rightLines.skip(rightIndex + 1).toList().indexOf(leftLine);
        // Check if the right line exists further in the left
        final leftMatch = leftLines.skip(leftIndex + 1).toList().indexOf(rightLine);
        
        if (rightMatch != -1 && (leftMatch == -1 || rightMatch < leftMatch)) {
          // Left line was removed, right line was added
          result.add(SimpleDiffLine(
            content: leftLine,
            type: 'removed',
            leftIndex: leftIndex,
          ));
          leftIndex++;
        } else if (leftMatch != -1) {
          // Right line was added
          result.add(SimpleDiffLine(
            content: rightLine,
            type: 'added',
            rightIndex: rightIndex,
          ));
          rightIndex++;
        } else {
          // Lines were changed
          result.add(SimpleDiffLine(
            content: leftLine,
            type: 'removed',
            leftIndex: leftIndex,
          ));
          result.add(SimpleDiffLine(
            content: rightLine,
            type: 'changed',
            rightIndex: rightIndex,
          ));
          leftIndex++;
          rightIndex++;
        }
      }
    }
    
    return result;
  }
  
  bool _isNearChanges(int lineIndex, Set<int> addedLines, Set<int> changedLines) {
    // Check if this line or nearby lines have changes
    for (int i = lineIndex - 2; i <= lineIndex + 2; i++) {
      if (addedLines.contains(i) || changedLines.contains(i)) {
        return true;
      }
    }
    return false;
  }
  
  Widget _buildFullFileLine(FullFileLine line, int displayLineNumber) {
    if (colorScheme == null) return const SizedBox.shrink();
    
    Color? backgroundColor;
    Color? borderColor;
    
    switch (line.diffType) {
      case THDiffLineType.addition:
        backgroundColor = colorScheme!.additionBackground;
        borderColor = colorScheme!.addition;
        break;
      case THDiffLineType.deletion:
        backgroundColor = colorScheme!.deletionBackground;
        borderColor = colorScheme!.deletion;
        break;
      case THDiffLineType.context:
        backgroundColor = line.isInChangeBlock 
            ? colorScheme!.contextBackground.withValues(alpha: 0.3)
            : Colors.transparent;
        break;
    }
    
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        border: line.isHighlighted && borderColor != null
            ? Border(left: BorderSide(color: borderColor, width: 3))
            : null,
      ),
      child: Padding(
        padding: EdgeInsets.only(
          left: line.isHighlighted ? 13 : 16, // Account for border
          right: 16,
          top: 2,
          bottom: 2,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Line number
            if (widget.showLineNumbers) ...[
              SizedBox(
                width: 40,
                child: Text(
                  displayLineNumber.toString(),
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    color: line.isHighlighted
                        ? (line.diffType == THDiffLineType.addition
                            ? colorScheme!.addition
                            : colorScheme!.deletion)
                        : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
              const SizedBox(width: 8),
            ],
            
            // Diff indicator
            SizedBox(
              width: 20,
              child: line.isHighlighted
                  ? Text(
                      line.diffType == THDiffLineType.addition ? '+' : '-',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        color: line.diffType == THDiffLineType.addition
                            ? colorScheme!.addition
                            : colorScheme!.deletion,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            
            // Line content
            Expanded(
              child: RichText(
                text: _buildHighlightedText(line),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  TextSpan _buildHighlightedText(FullFileLine line) {
    if (colorScheme == null) {
      return TextSpan(
        text: line.content.isEmpty ? ' ' : line.content,
        style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
      );
    }
    
    final baseStyle = TextStyle(
      fontFamily: 'monospace',
      fontSize: 13,
      color: line.isHighlighted
          ? (line.diffType == THDiffLineType.addition
              ? colorScheme!.addition
              : colorScheme!.deletion)
          : colorScheme!.context,
    );
    
    // For now, simple highlighting - could be enhanced with word-level diffs
    return TextSpan(
      text: line.content.isEmpty ? ' ' : line.content,
      style: line.isHighlighted
          ? baseStyle.copyWith(
              backgroundColor: line.diffType == THDiffLineType.addition
                  ? colorScheme!.addition.withValues(alpha: 0.2)
                  : colorScheme!.deletion.withValues(alpha: 0.2),
            )
          : baseStyle,
    );
  }

  @override
  Widget build(BuildContext context) {
    switch (widget.displayMode) {
      case DiffDisplayMode.inline:
        return _buildInlineDiffViewer();
      case DiffDisplayMode.sideBySide:
        return _buildSideBySideDiffViewer();
      case DiffDisplayMode.fullFile:
        return _buildFullFileDiffViewer();
    }
  }
}

class DiffSummaryCard extends StatelessWidget {
  final THDiffResult result;
  
  const DiffSummaryCard({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final stats = result.stats;
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildStatItem('+${stats.addedLines}', Colors.green),
        const SizedBox(width: 8),
        _buildStatItem('-${stats.deletedLines}', Colors.red),
        const SizedBox(width: 8),
        _buildStatItem('${stats.changePercentage.toInt()}%', Colors.blue),
      ],
    );
  }
  
  Widget _buildStatItem(String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        value,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}

enum DiffDisplayMode {
  inline,
  sideBySide,
  fullFile,
}

class FullFileLine {
  final String content;
  final int lineNumber;
  final THDiffLineType diffType;
  final bool isHighlighted;
  final bool isInChangeBlock;

  const FullFileLine({
    required this.content,
    required this.lineNumber,
    required this.diffType,
    required this.isHighlighted,
    required this.isInChangeBlock,
  });
}

class SimpleDiffLine {
  final String content;
  final String type; // 'added', 'removed', 'changed', 'unchanged'
  final int? leftIndex;
  final int? rightIndex;

  const SimpleDiffLine({
    required this.content,
    required this.type,
    this.leftIndex,
    this.rightIndex,
  });
}