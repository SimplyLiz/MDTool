import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:path/path.dart' as path;
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import '../../core/providers/app_state_provider.dart';
import '../../core/providers/preferences_provider.dart';
import '../../core/services/scroll_sync_service.dart';
import '../../core/services/file_service.dart';
import '../../core/services/block_index.dart';
import 'fenced_code_block_builder.dart';
import 'simple_chart_renderer.dart';
import '../../core/services/graph_renderer.dart';

class MarkdownPreview extends ConsumerStatefulWidget {
  const MarkdownPreview({super.key});

  @override
  ConsumerState<MarkdownPreview> createState() => _MarkdownPreviewState();
}

class _MarkdownPreviewState extends ConsumerState<MarkdownPreview> {
  late ScrollController _scrollController;
  late ScrollSyncService _scrollSyncService;
  late BlockIndex _blockIndex;
  late GraphRenderingService _graphService;
  int? _lastScrollRequestId;
  final GlobalKey _markdownKey = GlobalKey();

  /// Expose block index for editor sync access
  BlockIndex get blockIndex => _blockIndex;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollSyncService = ScrollSyncService();
    _scrollSyncService.registerPreviewController(_scrollController);
    
    // Initialize graph rendering service
    _graphService = GraphRenderingService();
    
    // Initialize async and rebuild when done
    _initializeGraphService();

    // Initialize block index with current content
    final appState = ref.read(appStateProvider);
    _blockIndex = buildBlockIndex(appState.content);
    _scrollSyncService.registerBlockIndex(_blockIndex);
  }
  
  Future<void> _initializeGraphService() async {
    await _graphService.initialize();
    if (mounted) {
      setState(() {
        // Force rebuild after graph service is initialized
      });
    }
  }

  @override
  void didUpdateWidget(MarkdownPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update block index when content changes
    final appState = ref.read(appStateProvider);
    _blockIndex = buildBlockIndex(appState.content);
    _scrollSyncService.registerBlockIndex(_blockIndex);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _handleScrollRequest(String? heading, int? requestId) {
    if (heading == null || requestId == null || _lastScrollRequestId == requestId) {
      return;
    }

    _lastScrollRequestId = requestId;
    print('Handling scroll request for heading: $heading');

    // Clear the scroll request after handling
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(appStateProvider.notifier).clearScrollRequest();
    });

    _scrollToHeadingInContent(heading);
  }

  void _scrollToHeadingInContent(String heading) {
    if (!_scrollController.hasClients) return;

    // Simple approach: try to find the heading text in the content and estimate position
    final appState = ref.read(appStateProvider);
    final content = appState.content;
    final lines = content.split('\n');

    int targetLine = 0;
    bool found = false;

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      // Check for markdown headings that contain our target text
      if (line.startsWith('#') && line.toLowerCase().contains(heading.toLowerCase())) {
        targetLine = i;
        found = true;
        print('Found heading "$heading" at line $targetLine');
        break;
      }
    }

    if (found) {
      // Estimate scroll position based on line number
      // This is a rough approximation - in a real implementation you'd want
      // to measure actual rendered heights
      final estimatedHeight = targetLine * 24.0; // Approximate line height
      final maxScroll = _scrollController.position.maxScrollExtent;
      final targetScroll = (estimatedHeight).clamp(0.0, maxScroll);

      _scrollController.animateTo(targetScroll, duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);

      print('Scrolling to estimated position: $targetScroll');
    } else {
      print('Heading "$heading" not found in content');
    }
  }

  void _handleLinkTap(String? href) async {
    if (href == null || href.isEmpty) return;

    // Handle different types of links
    if (href.startsWith('http://') || href.startsWith('https://')) {
      // External URL - open in browser
      await _openExternalLink(href);
    } else if (href.startsWith('#')) {
      // Anchor link within same document - scroll to heading
      final heading = href.substring(1); // Remove the #
      _scrollToHeadingInContent(heading);
    } else if (href.endsWith('.md') || href.endsWith('.markdown') || href.contains('.md#') || href.contains('.markdown#')) {
      // Relative markdown file link
      await _openMarkdownLink(href);
    } else if (href.startsWith('mailto:')) {
      // Email link
      await _openExternalLink(href);
    } else {
      // Treat as relative markdown file (might not have extension)
      await _openMarkdownLink(href);
    }
  }

  Future<void> _openExternalLink(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        _showLinkError('Cannot open URL: $url');
      }
    } catch (e) {
      _showLinkError('Failed to open link: $e');
    }
  }

  Future<void> _openMarkdownLink(String href) async {
    try {
      final appState = ref.read(appStateProvider);
      if (appState.currentFile == null) {
        _showLinkError('No current file to resolve relative path');
        return;
      }

      // Parse the link to separate file path and anchor
      final parts = href.split('#');
      String relativePath = parts[0];
      String? anchor = parts.length > 1 ? parts[1] : null;

      // If the path doesn't have an extension, assume it's a markdown file
      if (path.extension(relativePath).isEmpty) {
        relativePath = '$relativePath.md';
      }

      // Resolve relative path based on current file's directory
      final currentFileDir = path.dirname(appState.currentFile!);
      final targetPath = path.join(currentFileDir, relativePath);
      final normalizedPath = path.normalize(targetPath);

      // Check if the target file exists
      final fileService = FileService();
      if (await fileService.fileExists(normalizedPath)) {
        if (fileService.isMarkdownFile(normalizedPath)) {
          // Open the markdown file
          final content = await fileService.readFile(normalizedPath);
          ref.read(appStateProvider.notifier).openFile(normalizedPath, content);

          // If there's an anchor, scroll to it after a brief delay
          if (anchor != null && anchor.isNotEmpty) {
            // Wait for the file to load and render
            Future.delayed(const Duration(milliseconds: 300), () {
              _scrollToHeadingInContent(anchor);
            });
          }
        } else {
          _showLinkError('File is not a supported markdown format: $normalizedPath');
        }
      } else {
        _showLinkError('File not found: $normalizedPath');
      }
    } catch (e) {
      _showLinkError('Failed to open markdown link: $e');
    }
  }

  void _showLinkError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Theme.of(context).colorScheme.error, behavior: SnackBarBehavior.floating, duration: const Duration(seconds: 3)));
  }

  void _selectAll() {
    // Try to access SelectableRegionState directly which has a selectAll() method
    final context = _markdownKey.currentContext;
    if (context != null && mounted) {
      try {
        // Find the SelectableRegion state in the widget tree
        final selectableRegionState = context.findAncestorStateOfType<SelectableRegionState>();
        if (selectableRegionState != null) {
          // Use the built-in selectAll method which might work better
          selectableRegionState.selectAll();
        } else {
          // Fallback to the standard approach
          Actions.invoke(context, SelectAllTextIntent(SelectionChangedCause.keyboard));
        }
      } catch (e) {
        // Last fallback
        try {
          Actions.invoke(context, SelectAllTextIntent(SelectionChangedCause.keyboard));
        } catch (e2) {
          print('Select all failed: $e2');
        }
      }
    }
  }

  void _copyMarkdownAsFormatted() async {
    final appState = ref.read(appStateProvider);
    final content = appState.content;

    // Convert markdown to HTML
    final html = md.markdownToHtml(content, extensionSet: md.ExtensionSet.gitHubFlavored);

    try {
      // Create a temporary HTML file
      final tempDir = Directory.systemTemp;
      final tempFile = File('${tempDir.path}/temp_markdown.html');

      // Write HTML with basic styling
      final styledHtml =
          '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <style>
        body { font-family: -apple-system, BlinkMacSystemFont, sans-serif; line-height: 1.6; }
        h1, h2, h3, h4, h5, h6 { font-weight: bold; margin: 1em 0 0.5em 0; }
        p { margin: 0.5em 0; }
        code { font-family: Monaco, Courier, monospace; background-color: #f5f5f5; padding: 2px 4px; }
        pre { background-color: #f5f5f5; padding: 10px; border-radius: 4px; }
        blockquote { margin-left: 20px; padding-left: 10px; border-left: 4px solid #ccc; color: #666; }
        ul, ol { margin: 0.5em 0; padding-left: 2em; }
    </style>
</head>
<body>
$html
</body>
</html>
''';

      await tempFile.writeAsString(styledHtml);

      // Use textutil to convert HTML to RTF and copy to clipboard
      final result = await Process.run('sh', ['-c', 'textutil -convert rtf -stdout "${tempFile.path}" | pbcopy']);

      // Clean up temp file
      if (await tempFile.exists()) {
        await tempFile.delete();
      }

      if (result.exitCode == 0) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Rich text copied to clipboard'), behavior: SnackBarBehavior.floating, duration: Duration(seconds: 2)));
      } else {
        throw Exception('textutil failed: ${result.stderr}');
      }
    } catch (e) {
      // Fallback to plain text if RTF conversion fails
      Clipboard.setData(ClipboardData(text: content));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied as plain text (RTF conversion failed)'), behavior: SnackBarBehavior.floating, duration: Duration(seconds: 2)));
    }
  }

  void _copyAsRichText() async {
    final appState = ref.read(appStateProvider);
    final content = appState.content;

    // Convert markdown to HTML
    final html = md.markdownToHtml(content, extensionSet: md.ExtensionSet.gitHubFlavored);

    try {
      // Create a temporary HTML file
      final tempDir = Directory.systemTemp;
      final tempFile = File('${tempDir.path}/temp_markdown.html');

      // Write HTML with basic styling
      final styledHtml =
          '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <style>
        body { font-family: -apple-system, BlinkMacSystemFont, sans-serif; line-height: 1.6; }
        h1, h2, h3, h4, h5, h6 { font-weight: bold; margin: 1em 0 0.5em 0; }
        p { margin: 0.5em 0; }
        code { font-family: Monaco, Courier, monospace; background-color: #f5f5f5; padding: 2px 4px; }
        pre { background-color: #f5f5f5; padding: 10px; border-radius: 4px; }
        blockquote { margin-left: 20px; padding-left: 10px; border-left: 4px solid #ccc; color: #666; }
        ul, ol { margin: 0.5em 0; padding-left: 2em; }
    </style>
</head>
<body>
$html
</body>
</html>
''';

      await tempFile.writeAsString(styledHtml);

      // Use textutil to convert HTML to RTF and copy to clipboard
      final result = await Process.run('sh', ['-c', 'textutil -convert rtf -stdout "${tempFile.path}" | pbcopy']);

      // Clean up temp file
      if (await tempFile.exists()) {
        await tempFile.delete();
      }

      if (result.exitCode == 0) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Rich text copied to clipboard (paste into Word)'), behavior: SnackBarBehavior.floating, duration: Duration(seconds: 3)));
      } else {
        throw Exception('textutil failed: ${result.stderr}');
      }
    } catch (e) {
      // Fallback to plain text if RTF conversion fails
      Clipboard.setData(ClipboardData(text: content));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied as plain text (RTF conversion failed)'), behavior: SnackBarBehavior.floating, duration: Duration(seconds: 2)));
    }
  }

  String _convertHtmlToRtf(String html) {
    // Simple HTML to RTF converter for basic formatting
    String rtf = html;

    // RTF header with font table
    String rtfHeader = r'{\rtf1\ansi\deff0 {\fonttbl {\f0 Times New Roman;} {\f1 Courier New;}}';

    // Escape RTF special characters first (before adding RTF codes)
    rtf = rtf.replaceAll('\\', r'\\');
    rtf = rtf.replaceAll('{', r'\{');
    rtf = rtf.replaceAll('}', r'\}');

    // Convert headings with proper font sizes (RTF font sizes are in half-points)
    rtf = rtf.replaceAll('<h1>', r'{\fs36\b '); // 18pt
    rtf = rtf.replaceAll('</h1>', r'}\par\par ');
    rtf = rtf.replaceAll('<h2>', r'{\fs32\b '); // 16pt
    rtf = rtf.replaceAll('</h2>', r'}\par\par ');
    rtf = rtf.replaceAll('<h3>', r'{\fs28\b '); // 14pt
    rtf = rtf.replaceAll('</h3>', r'}\par\par ');
    rtf = rtf.replaceAll('<h4>', r'{\fs24\b '); // 12pt
    rtf = rtf.replaceAll('</h4>', r'}\par\par ');
    rtf = rtf.replaceAll('<h5>', r'{\fs22\b '); // 11pt
    rtf = rtf.replaceAll('</h5>', r'}\par\par ');
    rtf = rtf.replaceAll('<h6>', r'{\fs20\b '); // 10pt
    rtf = rtf.replaceAll('</h6>', r'}\par\par ');

    // Bold and italic text
    rtf = rtf.replaceAll('<strong>', r'{\b ');
    rtf = rtf.replaceAll('</strong>', r'}');
    rtf = rtf.replaceAll('<b>', r'{\b ');
    rtf = rtf.replaceAll('</b>', r'}');
    rtf = rtf.replaceAll('<em>', r'{\i ');
    rtf = rtf.replaceAll('</em>', r'}');
    rtf = rtf.replaceAll('<i>', r'{\i ');
    rtf = rtf.replaceAll('</i>', r'}');

    // Paragraphs and line breaks
    rtf = rtf.replaceAll('<p>', '');
    rtf = rtf.replaceAll('</p>', r'\par ');
    rtf = rtf.replaceAll('<br>', r'\line ');
    rtf = rtf.replaceAll('<br/>', r'\line ');
    rtf = rtf.replaceAll('<br />', r'\line ');

    // Code formatting - use monospace font
    rtf = rtf.replaceAll('<code>', r'{\f1\fs18 '); // Courier New, 9pt
    rtf = rtf.replaceAll('</code>', r'}');
    rtf = rtf.replaceAll('<pre><code>', r'{\f1\fs18\par ');
    rtf = rtf.replaceAll('</code></pre>', r'}\par ');
    rtf = rtf.replaceAll('<pre>', r'{\f1\fs18\par ');
    rtf = rtf.replaceAll('</pre>', r'}\par ');

    // Lists with proper indentation
    rtf = rtf.replaceAll('<ul>', r'{\pard\fi-360\li720 ');
    rtf = rtf.replaceAll('</ul>', r'}\par ');
    rtf = rtf.replaceAll('<ol>', r'{\pard\fi-360\li720 ');
    rtf = rtf.replaceAll('</ol>', r'}\par ');
    rtf = rtf.replaceAll('<li>', r'\bullet\tab ');
    rtf = rtf.replaceAll('</li>', r'\par ');

    // Tables (basic support)
    rtf = rtf.replaceAll('<table>', r'{\pard ');
    rtf = rtf.replaceAll('</table>', r'}\par ');
    rtf = rtf.replaceAll('<tr>', '');
    rtf = rtf.replaceAll('</tr>', r'\par ');
    rtf = rtf.replaceAll('<td>', r'{\b ');
    rtf = rtf.replaceAll('</td>', r'}\tab ');
    rtf = rtf.replaceAll('<th>', r'{\b ');
    rtf = rtf.replaceAll('</th>', r'}\tab ');

    // Blockquotes
    rtf = rtf.replaceAll('<blockquote>', r'{\pard\li720\ri720\i ');
    rtf = rtf.replaceAll('</blockquote>', r'}\par ');

    // Links (just show the text)
    rtf = rtf.replaceAll(RegExp(r'<a[^>]*>'), '');
    rtf = rtf.replaceAll('</a>', '');

    // Remove any remaining HTML tags
    rtf = rtf.replaceAll(RegExp(r'<[^>]*>'), '');

    // Clean up multiple paragraph breaks
    rtf = rtf.replaceAll(RegExp(r'\\par\s*\\par\s*\\par'), r'\par\par');

    return '$rtfHeader $rtf}';
  }

  void _showContextMenu(Offset position) {
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(position.dx, position.dy, position.dx + 1, position.dy + 1),
      items: [
        PopupMenuItem(
          onTap: _copyMarkdownAsFormatted,
          child: const Row(children: [Icon(Icons.copy), SizedBox(width: 8), Text('Copy All as Markdown')]),
        ),
        PopupMenuItem(
          onTap: _copyAsRichText,
          child: const Row(children: [Icon(Icons.copy_all), SizedBox(width: 8), Text('Copy All as Rich Text')]),
        ),
        PopupMenuItem(
          onTap: _selectAll,
          child: const Row(children: [Icon(Icons.select_all), SizedBox(width: 8), Text('Select All Text')]),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(appStateProvider);
    final preferencesAsync = ref.watch(preferencesProvider);

    // Handle scroll requests
    _handleScrollRequest(appState.scrollToHeading, appState.scrollRequestId);

    return preferencesAsync.when(
      data: (preferences) => GestureDetector(
        onSecondaryTapDown: (details) {
          _showContextMenu(details.globalPosition);
        },
        child: SelectionArea(
              child: CallbackShortcuts(
                bindings: {const SingleActivator(LogicalKeyboardKey.keyA, meta: true): _selectAll, const SingleActivator(LogicalKeyboardKey.keyC, meta: true): _copyMarkdownAsFormatted, const SingleActivator(LogicalKeyboardKey.keyC, meta: true, shift: true): _copyAsRichText},
                child: NotificationListener<ScrollNotification>(
                  onNotification: (n) {
                    // Editor is always leader for now - preview doesn't drive sync
                    return false;
                  },
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final block in _blockIndex.blocks)
                          GestureDetector(
                            onTapDown: (details) => _onBlockTap(block, details, appState.content),
                            child: Container(key: block.key, padding: const EdgeInsets.symmetric(vertical: 2), child: _buildBlock(appState.content, block, preferences)),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error loading preferences: $error')),
    );
  }

  void _onBlockTap(MdBlock block, TapDownDetails details, String content) {
    final renderObj = block.key.currentContext?.findRenderObject() as RenderBox?;
    if (renderObj == null) return;

    final relY = ScrollSyncService.tapRelYInViewport(context, details);

    final localTapY = details.localPosition.dy;
    final blockHeight = renderObj.size.height;
    final intraRatio = blockHeight > 0 ? (localTapY / blockHeight).clamp(0.0, 1.0) : 0.0;

    // Determine if this block is "special" by inspecting the source lines
    final lines = content.split('\n');
    final blockLines = lines.sublist(block.startLine, (block.endLine + 1).clamp(0, lines.length));

    final firstLine = blockLines.isNotEmpty ? blockLines.first.trimLeft() : '';
    final isCodeBlock = firstLine.startsWith('```');
    final isHeading = firstLine.startsWith('#');
    final isList = firstLine.startsWith('- ') || firstLine.startsWith('* ') || RegExp(r'^\d+\.\s').hasMatch(firstLine);

    final isTallBlock = (block.endLine - block.startLine) > 8;
    final isSpecialType = isCodeBlock || isHeading || isList;

    int targetLine;
    if (isTallBlock || isSpecialType) {
      // Fallback: top-align the block
      targetLine = block.startLine;
    } else {
      // Relative line inside block
      final lineWithinBlock = (intraRatio * block.length).floor();
      targetLine = block.startLine + lineWithinBlock;
    }

    final textOffset = _lineToOffset(targetLine, content);

    // For special/tall blocks, force top alignment by setting relY to 0
    final effectiveRelY = (isTallBlock || isSpecialType) ? 0.0 : relY;
    _scrollSyncService.requestCaretPositionWithHeight(textOffset, effectiveRelY);
  }

  int _lineToOffset(int targetLine, String content) {
    final lines = content.split('\n');
    if (targetLine >= lines.length) return content.length;

    int offset = 0;
    for (int i = 0; i < targetLine && i < lines.length; i++) {
      offset += lines[i].length + 1; // +1 for newline
    }
    return offset.clamp(0, content.length);
  }

  Widget _buildBlock(String source, MdBlock block, dynamic preferences) {
    final lines = source.split('\n');

    // Extract the text for this block
    if (block.startLine >= lines.length) {
      return const SizedBox.shrink();
    }

    final endLine = block.endLine.clamp(0, lines.length - 1);
    final blockLines = lines.sublist(block.startLine, endLine + 1);
    final text = blockLines.join('\n');

    if (text.trim().isEmpty) {
      return const SizedBox(height: 8); // Empty line spacing
    }

    // Check if this block contains charts and render accordingly
    if (text.contains('```mermaid') || text.contains('```chart')) {
      // Use simple chart renderer for blocks with charts
      final widgets = SimpleChartRenderer.processMarkdown(text, context);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: widgets,
      );
    }
    
    // Use flutter_markdown for regular content
    return MarkdownBody(
      data: text,
      selectable: false,
      styleSheet: _buildStyleSheet(context, preferences),
      extensionSet: md.ExtensionSet([...md.ExtensionSet.gitHubFlavored.blockSyntaxes, md.TableSyntax()], [md.EmojiSyntax(), ...md.ExtensionSet.gitHubFlavored.inlineSyntaxes]),
      builders: {
        'code': FencedCodeBlockBuilder(context: context),
        'img': ImageElementBuilder(),
      },
      onTapLink: (text, href, title) {
        _handleLinkTap(href);
      },
    );
  }

  MarkdownStyleSheet _buildStyleSheet(BuildContext context, dynamic preferences) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return MarkdownStyleSheet(
      // Headers
      h1: textTheme.headlineLarge?.copyWith(color: colorScheme.onSurface, fontWeight: FontWeight.bold, fontFamily: preferences.fontFamily),
      h2: textTheme.headlineMedium?.copyWith(color: colorScheme.onSurface, fontWeight: FontWeight.bold, fontFamily: preferences.fontFamily),
      h3: textTheme.headlineSmall?.copyWith(color: colorScheme.onSurface, fontWeight: FontWeight.w600, fontFamily: preferences.fontFamily),
      h4: textTheme.titleLarge?.copyWith(color: colorScheme.onSurface, fontWeight: FontWeight.w600, fontFamily: preferences.fontFamily),
      h5: textTheme.titleMedium?.copyWith(color: colorScheme.onSurface, fontWeight: FontWeight.w600, fontFamily: preferences.fontFamily),
      h6: textTheme.titleSmall?.copyWith(color: colorScheme.onSurface, fontWeight: FontWeight.w600, fontFamily: preferences.fontFamily),

      // Body text
      p: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface, height: 1.6, fontFamily: preferences.fontFamily, fontSize: preferences.fontSize),

      // Links
      a: TextStyle(color: colorScheme.primary, decoration: TextDecoration.underline, fontFamily: preferences.fontFamily),

      // Code
      code: TextStyle(color: colorScheme.onSurface, backgroundColor: colorScheme.surfaceContainerHighest, fontFamily: 'Monaco', fontSize: preferences.fontSize * 0.9),
      codeblockDecoration: const BoxDecoration(color: Colors.transparent),
      codeblockPadding: const EdgeInsets.all(12),

      // Lists
      listBullet: TextStyle(color: colorScheme.onSurface, fontFamily: preferences.fontFamily),

      // Blockquotes
      blockquote: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.8), fontStyle: FontStyle.italic, fontFamily: preferences.fontFamily, fontSize: preferences.fontSize),
      blockquoteDecoration: BoxDecoration(
        border: Border(left: BorderSide(color: colorScheme.primary, width: 4)),
      ),
      blockquotePadding: const EdgeInsets.only(left: 16, top: 8, bottom: 8),

      // Tables
      tableHead: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.bold, fontFamily: preferences.fontFamily, fontSize: preferences.fontSize),
      tableBody: TextStyle(color: colorScheme.onSurface, fontFamily: preferences.fontFamily, fontSize: preferences.fontSize),
      tableHeadAlign: TextAlign.left,
      tableBorder: TableBorder.all(color: colorScheme.outline.withValues(alpha: 0.3), width: 1),
      tableColumnWidth: const FlexColumnWidth(),
      tableCellsPadding: const EdgeInsets.all(8),

      // Horizontal rules
      horizontalRuleDecoration: BoxDecoration(
        border: Border(top: BorderSide(color: colorScheme.outline.withValues(alpha: 0.3), width: 1)),
      ),
    );
  }
}

class ImageElementBuilder extends MarkdownElementBuilder {
  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    final String? src = element.attributes['src'];
    final String? alt = element.attributes['alt'];
    final String? title = element.attributes['title'];

    if (src == null) return null;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              src,
              fit: BoxFit.contain,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  height: 200,
                  alignment: Alignment.center,
                  child: CircularProgressIndicator(value: loadingProgress.expectedTotalBytes != null ? loadingProgress.cumulativeBytesLoaded / (loadingProgress.expectedTotalBytes ?? 1) : null),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.broken_image, size: 32, color: Colors.grey),
                      const SizedBox(height: 8),
                      Text('Failed to load image', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                      if (alt?.isNotEmpty == true)
                        Text(
                          alt!,
                          style: TextStyle(color: Colors.grey[500], fontSize: 10),
                          textAlign: TextAlign.center,
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
          if (title?.isNotEmpty == true) ...[
            const SizedBox(height: 4),
            Text(
              title!,
              style: TextStyle(fontSize: 12, color: Colors.grey[600], fontStyle: FontStyle.italic),
            ),
          ],
        ],
      ),
    );
  }
}
