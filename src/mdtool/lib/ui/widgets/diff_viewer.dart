import 'package:flutter/material.dart';
import 'package:th_diff_suite/th_diff_suite.dart';
import 'dart:math' as math;

class DiffViewer extends StatefulWidget {
  final String leftText;
  final String rightText;
  final String? leftTitle;
  final String? rightTitle;
  final TextStyle? textStyle;
  final bool showLineNumbers;
  final double dividerWidth;

  const DiffViewer({
    super.key,
    required this.leftText,
    required this.rightText,
    this.leftTitle,
    this.rightTitle,
    this.textStyle,
    this.showLineNumbers = true,
    this.dividerWidth = 1.0,
  });

  @override
  State<DiffViewer> createState() => _DiffViewerState();
}

class _DiffViewerState extends State<DiffViewer> {
  final ScrollController _leftScrollController = ScrollController();
  final ScrollController _rightScrollController = ScrollController();
  List<String> _leftLines = [];
  List<String> _rightLines = [];
  List<DiffLineComparison> _lineComparisons = [];

  @override
  void initState() {
    super.initState();
    _computeLineComparisons();
    _syncScrollControllers();
  }

  @override
  void didUpdateWidget(DiffViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.leftText != widget.leftText || oldWidget.rightText != widget.rightText) {
      _computeLineComparisons();
    }
  }

  void _computeLineComparisons() {
    _leftLines = widget.leftText.split('\n');
    _rightLines = widget.rightText.split('\n');
    _lineComparisons.clear();

    final maxLength = math.max(_leftLines.length, _rightLines.length);
    for (int i = 0; i < maxLength; i++) {
      final leftLine = i < _leftLines.length ? _leftLines[i] : null;
      final rightLine = i < _rightLines.length ? _rightLines[i] : null;

      DiffLineComparisonType type;
      if (leftLine == null) {
        type = DiffLineComparisonType.added;
      } else if (rightLine == null) {
        type = DiffLineComparisonType.removed;
      } else if (leftLine == rightLine) {
        type = DiffLineComparisonType.unchanged;
      } else {
        type = DiffLineComparisonType.modified;
      }

      _lineComparisons.add(DiffLineComparison(
        leftContent: leftLine,
        rightContent: rightLine,
        type: type,
      ));
    }
  }

  void _syncScrollControllers() {
    _leftScrollController.addListener(() {
      if (_leftScrollController.hasClients && _rightScrollController.hasClients) {
        _rightScrollController.jumpTo(_leftScrollController.offset);
      }
    });

    _rightScrollController.addListener(() {
      if (_rightScrollController.hasClients && _leftScrollController.hasClients) {
        _leftScrollController.jumpTo(_rightScrollController.offset);
      }
    });
  }

  @override
  void dispose() {
    _leftScrollController.dispose();
    _rightScrollController.dispose();
    super.dispose();
  }

  Widget _buildTextPanel({
    required String text,
    required ScrollController scrollController,
    String? title,
    bool isLeft = true,
  }) {
    final defaultTextStyle = widget.textStyle ?? 
        Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontFamily: 'Menlo',
          fontSize: 13,
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (title != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant,
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).dividerColor,
                  width: 1,
                ),
              ),
            ),
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border.all(
                color: Theme.of(context).dividerColor,
                width: 0.5,
              ),
            ),
            child: ListView.builder(
              controller: scrollController,
              itemCount: _lineComparisons.length,
              itemBuilder: (context, index) {
                final comparison = _lineComparisons[index];
                final line = isLeft ? comparison.leftContent : comparison.rightContent;
                
                // Show line if it exists and is relevant for this side
                final shouldShow = line != null && 
                    (isLeft 
                        ? comparison.type != DiffLineComparisonType.added
                        : comparison.type != DiffLineComparisonType.removed);

                Color? backgroundColor;
                switch (comparison.type) {
                  case DiffLineComparisonType.added:
                    backgroundColor = isLeft ? null : Colors.green.withOpacity(0.1);
                    break;
                  case DiffLineComparisonType.removed:
                    backgroundColor = isLeft ? Colors.red.withOpacity(0.1) : null;
                    break;
                  case DiffLineComparisonType.modified:
                    backgroundColor = Colors.orange.withOpacity(0.1);
                    break;
                  case DiffLineComparisonType.unchanged:
                    backgroundColor = null;
                    break;
                }

                return Container(
                  height: 20,
                  decoration: BoxDecoration(
                    color: shouldShow ? backgroundColor : null,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  child: shouldShow ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Diff indicator
                      SizedBox(
                        width: 20,
                        child: comparison.type != DiffLineComparisonType.unchanged 
                            ? Text(
                                _getDiffIndicator(comparison.type, isLeft),
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  color: _getDiffIndicatorColor(comparison.type),
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : null,
                      ),
                      if (widget.showLineNumbers) ...[
                        SizedBox(
                          width: 40,
                          child: Text(
                            '${index + 1}',
                            style: defaultTextStyle?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                              fontSize: 11,
                            ),
                            textAlign: TextAlign.right,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Expanded(
                        child: Text(
                          line!.isEmpty ? ' ' : line,
                          style: defaultTextStyle,
                        ),
                      ),
                    ],
                  ) : null,
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  String _getDiffIndicator(DiffLineComparisonType type, bool isLeft) {
    switch (type) {
      case DiffLineComparisonType.added:
        return isLeft ? '' : '+';
      case DiffLineComparisonType.removed:
        return isLeft ? '-' : '';
      case DiffLineComparisonType.modified:
        return '~';
      case DiffLineComparisonType.unchanged:
        return '';
    }
  }

  Color _getDiffIndicatorColor(DiffLineComparisonType type) {
    switch (type) {
      case DiffLineComparisonType.added:
        return Colors.green;
      case DiffLineComparisonType.removed:
        return Colors.red;
      case DiffLineComparisonType.modified:
        return Colors.orange;
      case DiffLineComparisonType.unchanged:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildTextPanel(
            text: widget.leftText,
            scrollController: _leftScrollController,
            title: widget.leftTitle,
            isLeft: true,
          ),
        ),
        Container(
          width: widget.dividerWidth,
          color: Theme.of(context).dividerColor,
        ),
        Expanded(
          child: _buildTextPanel(
            text: widget.rightText,
            scrollController: _rightScrollController,
            title: widget.rightTitle,
            isLeft: false,
          ),
        ),
      ],
    );
  }
}

class DiffLineComparison {
  final String? leftContent;
  final String? rightContent;
  final DiffLineComparisonType type;

  const DiffLineComparison({
    this.leftContent,
    this.rightContent,
    required this.type,
  });
}

enum DiffLineComparisonType {
  unchanged,
  added,
  removed,
  modified,
}

class DiffLine {
  final String content;
  final DiffLineType type;
  final int? leftLineNumber;
  final int? rightLineNumber;

  const DiffLine({
    required this.content,
    required this.type,
    this.leftLineNumber,
    this.rightLineNumber,
  });
}

enum DiffLineType {
  unchanged,
  added,
  removed,
  modified,
}

class AdvancedDiffViewer extends StatefulWidget {
  final List<DiffLine> diffLines;
  final String? leftTitle;
  final String? rightTitle;
  final TextStyle? textStyle;
  final Color? addedColor;
  final Color? removedColor;
  final Color? modifiedColor;
  final String? leftText;
  final String? rightText;

  const AdvancedDiffViewer({
    super.key,
    required this.diffLines,
    this.leftTitle,
    this.rightTitle,
    this.textStyle,
    this.addedColor,
    this.removedColor,
    this.modifiedColor,
    this.leftText,
    this.rightText,
  });

  @override
  State<AdvancedDiffViewer> createState() => _AdvancedDiffViewerState();
}

class _AdvancedDiffViewerState extends State<AdvancedDiffViewer> {
  final ScrollController _scrollController = ScrollController();
  THDiffResult? _thDiffResult;
  DiffColorScheme? _colorScheme;
  Map<String, THDiffLine> _thLineCache = {};

  @override
  void initState() {
    super.initState();
    _computeThDiff();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _setupColorScheme();
  }

  void _computeThDiff() {
    if (widget.leftText != null && widget.rightText != null) {
      final options = THDiffOptions(
        enableIntraLineDiff: true,
        wordLevelDiff: true,
        similarityThreshold: 0.3,
        contextLines: 0, // Show all lines for advanced view
      );
      
      _thDiffResult = THDiffSuite.compareTexts(widget.leftText!, widget.rightText!, options);
      _buildLineCache();
    }
  }

  void _buildLineCache() {
    if (_thDiffResult == null) return;
    
    _thLineCache.clear();
    for (final hunk in _thDiffResult!.hunks) {
      for (final line in hunk.lines) {
        _thLineCache[line.content] = line;
      }
    }
  }

  void _setupColorScheme() {
    _colorScheme = DiffColorScheme.fromTheme(
      primary: Theme.of(context).primaryColor,
      error: Theme.of(context).colorScheme.error,
      onSurface: Theme.of(context).colorScheme.onSurface,
      surface: Theme.of(context).colorScheme.surface,
    );
  }

  Color _getBackgroundColor(DiffLineType type) {
    switch (type) {
      case DiffLineType.added:
        return widget.addedColor ?? Colors.green.withOpacity(0.2);
      case DiffLineType.removed:
        return widget.removedColor ?? Colors.red.withOpacity(0.2);
      case DiffLineType.modified:
        return widget.modifiedColor ?? Colors.orange.withOpacity(0.2);
      case DiffLineType.unchanged:
        return Colors.transparent;
    }
  }

  String _getLinePrefix(DiffLineType type) {
    switch (type) {
      case DiffLineType.added:
        return '+';
      case DiffLineType.removed:
        return '-';
      case DiffLineType.modified:
        return '~';
      case DiffLineType.unchanged:
        return ' ';
    }
  }

  Widget _buildLineContentWithHighlights(DiffLine diffLine, TextStyle? defaultTextStyle) {
    if (_colorScheme == null || _thDiffResult == null) {
      // Fallback to simple text if no TH Diff Suite data
      return Text(
        diffLine.content.isEmpty ? ' ' : diffLine.content,
        style: defaultTextStyle,
      );
    }

    // Try to find corresponding TH Diff Suite line with intra-line diff data
    final thLine = _thLineCache[diffLine.content];
    if (thLine != null && thLine.hasIntraLineDiff) {
      // Use TH Diff Suite UI helpers for precise highlighting
      final spans = DiffUIHelpers.createIntraLineTextSpans(
        thLine,
        colorScheme: _colorScheme!,
        baseStyle: defaultTextStyle ?? const TextStyle(fontFamily: 'monospace', fontSize: 13),
      );

      return RichText(
        text: TextSpan(children: spans),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      );
    }

    // Default to simple text
    return Text(
      diffLine.content.isEmpty ? ' ' : diffLine.content,
      style: defaultTextStyle,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final defaultTextStyle = widget.textStyle ?? 
        Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontFamily: 'Menlo',
          fontSize: 13,
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.leftTitle != null || widget.rightTitle != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant,
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).dividerColor,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                if (widget.leftTitle != null)
                  Expanded(
                    child: Text(
                      widget.leftTitle!,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                if (widget.rightTitle != null)
                  Expanded(
                    child: Text(
                      widget.rightTitle!,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
              ],
            ),
          ),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border.all(
                color: Theme.of(context).dividerColor,
                width: 0.5,
              ),
            ),
            child: ListView.builder(
              controller: _scrollController,
              itemCount: widget.diffLines.length,
              itemBuilder: (context, index) {
                final diffLine = widget.diffLines[index];
                return Container(
                  color: _getBackgroundColor(diffLine.type),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 20,
                        child: Text(
                          _getLinePrefix(diffLine.type),
                          style: defaultTextStyle?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 40,
                        child: Text(
                          diffLine.leftLineNumber?.toString() ?? '',
                          style: defaultTextStyle?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            fontSize: 11,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 40,
                        child: Text(
                          diffLine.rightLineNumber?.toString() ?? '',
                          style: defaultTextStyle?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            fontSize: 11,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildLineContentWithHighlights(diffLine, defaultTextStyle),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

