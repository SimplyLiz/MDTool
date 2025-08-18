import 'package:flutter/material.dart';
import 'package:th_diff_suite/th_diff_suite.dart';

class EnhancedDiffViewer extends StatefulWidget {
  final String leftText;
  final String rightText;
  final String? leftTitle;
  final String? rightTitle;
  final TextStyle? textStyle;
  final bool showLineNumbers;
  final double dividerWidth;

  const EnhancedDiffViewer({
    super.key,
    required this.leftText,
    required this.rightText,
    this.leftTitle,
    this.rightTitle,
    this.textStyle,
    this.showLineNumbers = true,
    this.dividerWidth = 2.0,
  });

  @override
  State<EnhancedDiffViewer> createState() => _EnhancedDiffViewerState();
}

class _EnhancedDiffViewerState extends State<EnhancedDiffViewer> {
  final ScrollController _leftScrollController = ScrollController();
  final ScrollController _rightScrollController = ScrollController();
  THDiffResult? diffResult;
  DiffColorScheme? colorScheme;

  @override
  void initState() {
    super.initState();
    _computeDiff();
    _syncScrollControllers();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _setupColorScheme();
  }

  @override
  void didUpdateWidget(EnhancedDiffViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.leftText != widget.leftText || oldWidget.rightText != widget.rightText) {
      _computeDiff();
    }
  }

  void _syncScrollControllers() {
    _leftScrollController.addListener(() {
      if (_leftScrollController.hasClients && _rightScrollController.hasClients) {
        if (_leftScrollController.offset != _rightScrollController.offset) {
          _rightScrollController.jumpTo(_leftScrollController.offset);
        }
      }
    });

    _rightScrollController.addListener(() {
      if (_rightScrollController.hasClients && _leftScrollController.hasClients) {
        if (_rightScrollController.offset != _leftScrollController.offset) {
          _leftScrollController.jumpTo(_rightScrollController.offset);
        }
      }
    });
  }

  void _computeDiff() {
    // Configure TH Diff Suite with word-level diffing
    final options = THDiffOptions(
      enableIntraLineDiff: true,
      wordLevelDiff: true,
      similarityThreshold: 0.3,
      contextLines: 3,
      ignoreWhitespace: false,
    );
    
    diffResult = THDiffSuite.compareTexts(widget.leftText, widget.rightText, options);
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
    _leftScrollController.dispose();
    _rightScrollController.dispose();
    super.dispose();
  }

  Widget _buildLineIndicator(THDiffLineType type) {
    if (colorScheme == null) return const SizedBox(width: 4);
    
    Color? color;
    switch (type) {
      case THDiffLineType.addition:
        color = colorScheme!.addition;
        break;
      case THDiffLineType.deletion:
        color = colorScheme!.deletion;
        break;
      case THDiffLineType.context:
        color = Colors.transparent;
        break;
    }
    
    return Container(
      width: 4,
      color: color,
      margin: const EdgeInsets.only(right: 4),
    );
  }

  Widget _buildTextWithHighlights(THDiffLine line, TextStyle baseStyle) {
    if (colorScheme == null) {
      return Text(
        line.content.isEmpty ? ' ' : line.content, 
        style: baseStyle,
        softWrap: true,
        overflow: TextOverflow.visible,
      );
    }
    
    if (!line.hasIntraLineDiff) {
      return Text(
        line.content.isEmpty ? ' ' : line.content, 
        style: baseStyle,
        softWrap: true,
        overflow: TextOverflow.visible,
      );
    }

    // Use TH Diff Suite UI helpers for precise intra-line highlighting
    final spans = DiffUIHelpers.createIntraLineTextSpans(
      line,
      colorScheme: colorScheme!,
      baseStyle: baseStyle,
    );

    return RichText(
      text: TextSpan(children: spans),
      softWrap: true,
      overflow: TextOverflow.visible,
    );
  }

  Widget _buildSide(bool isLeft) {
    if (diffResult == null || colorScheme == null) {
      return const Center(child: CircularProgressIndicator());
    }
    
    final title = isLeft ? widget.leftTitle : widget.rightTitle;
    final defaultTextStyle = widget.textStyle ?? 
        Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontFamily: 'Menlo',
          fontSize: 13,
        );

    // Get all lines for side-by-side display
    final allLines = DiffUIHelpers.getAllLines(diffResult!);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (title != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
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
              controller: isLeft ? _leftScrollController : _rightScrollController,
              itemCount: allLines.length,
              shrinkWrap: true,
              itemBuilder: (context, index) {
                final lineData = allLines[index];
                final line = lineData.line;
                
                // For side-by-side view, show/hide lines based on their type
                final shouldShow = isLeft 
                    ? (line.type != THDiffLineType.addition)
                    : (line.type != THDiffLineType.deletion);

                return Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: shouldShow ? DiffUIHelpers.getColorForLineType(
                      line.type, 
                      colorScheme: colorScheme!, 
                      isBackground: true,
                    ) : Colors.transparent,
                  ),
                  child: shouldShow ? IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLineIndicator(line.type),
                        if (widget.showLineNumbers) ...[
                          SizedBox(
                            width: 40,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Text(
                                (index + 1).toString(),
                                style: defaultTextStyle?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                  fontSize: 11,
                                ),
                                textAlign: TextAlign.right,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            child: _buildTextWithHighlights(line, defaultTextStyle!),
                          ),
                        ),
                      ],
                    ),
                  ) : const SizedBox(),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _buildSide(true)),
        Container(
          width: widget.dividerWidth,
          color: Theme.of(context).dividerColor,
        ),
        Expanded(child: _buildSide(false)),
      ],
    );
  }
}