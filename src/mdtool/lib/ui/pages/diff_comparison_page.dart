import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../widgets/diff_viewer.dart';
import '../widgets/enhanced_diff_viewer.dart';
import '../widgets/th_diff_viewer.dart';

class DiffComparisonPage extends StatefulWidget {
  final String? initialLeftFile;
  final String? initialLeftContent;
  final String? initialRightFile;
  final String? initialRightContent;

  const DiffComparisonPage({
    super.key,
    this.initialLeftFile,
    this.initialLeftContent,
    this.initialRightFile,
    this.initialRightContent,
  });

  @override
  State<DiffComparisonPage> createState() => _DiffComparisonPageState();
}

class _DiffComparisonPageState extends State<DiffComparisonPage> {
  String _leftText = '';
  String _rightText = '';
  String? _leftFileName;
  String? _rightFileName;
  int _diffViewMode = 0; // 0 = TH Inline, 1 = TH Side by Side, 2 = Full File, 3 = Enhanced, 4 = Legacy
  final TextEditingController _leftController = TextEditingController();
  final TextEditingController _rightController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _leftController.addListener(_onLeftTextChanged);
    _rightController.addListener(_onRightTextChanged);
  }

  @override
  void dispose() {
    _leftController.dispose();
    _rightController.dispose();
    super.dispose();
  }

  void _onLeftTextChanged() {
    setState(() {
      _leftText = _leftController.text;
    });
  }

  void _onRightTextChanged() {
    setState(() {
      _rightText = _rightController.text;
    });
  }

  void _loadInitialData() {
    // Load from widget parameters if available
    if (widget.initialLeftContent != null || widget.initialRightContent != null) {
      final leftText = widget.initialLeftContent ?? '';
      final rightText = widget.initialRightContent ?? '';
      final leftFileName = widget.initialLeftFile != null 
          ? widget.initialLeftFile!.split('/').last 
          : 'Left File';
      final rightFileName = widget.initialRightFile != null 
          ? widget.initialRightFile!.split('/').last 
          : 'Right File';

      setState(() {
        _leftText = leftText;
        _rightText = rightText;
        _leftFileName = leftFileName;
        _rightFileName = rightFileName;
      });

      _leftController.text = leftText;
      _rightController.text = rightText;
    } else {
      _loadSampleData();
    }
  }

  void _loadSampleData() {
    const sampleLeft = '''# MD Tool Documentation - Version 1.0

## Overview
MD Tool is a simple markdown editor for macOS.

## Features
- Basic text editing
- Simple preview
- File operations (open, save)
- Split screen view

## Installation
1. Download the app from GitHub
2. Copy to Applications folder
3. Launch and enjoy

## Usage
To open a file:
- Use Cmd+O
- Navigate to your markdown file
- Click Open

## Keyboard Shortcuts
- Cmd+N: New file
- Cmd+O: Open file
- Cmd+S: Save file
- Cmd+R: Toggle preview

## System Requirements
- macOS 10.15 or later
- 50MB of disk space

## Conclusion
This is the first release of MD Tool.''';

    const sampleRight = '''# MD Tool Documentation - Version 2.0

## Overview
MD Tool is a powerful markdown editor and viewer for macOS with advanced features.

## Features
- Advanced text editing with syntax highlighting
- Live preview with scroll synchronization
- Enhanced file operations (open, save, auto-save)
- Split screen view with dual file editing
- PDF export capabilities
- Search and replace functionality
- Theme support (light/dark)

## Installation
1. Download the latest version from GitHub releases
2. Copy MD Tool.app to Applications folder
3. Grant necessary permissions when prompted
4. Launch and start editing

## Usage
To open a file:
- Use Cmd+O or click the Open button
- Navigate to your markdown file
- Click Open to load the content

You can also drag and drop files directly onto the app.

## Keyboard Shortcuts
- Cmd+N: Create new file
- Cmd+O: Open existing file
- Cmd+S: Save current file
- Cmd+Shift+S: Save As
- Cmd+R: Toggle preview mode
- Cmd+F: Find text
- Cmd+E: Export to PDF

## System Requirements
- macOS 11.0 or later (updated requirement)
- 100MB of disk space
- Intel or Apple Silicon processor

## New in Version 2.0
- Complete UI redesign
- Performance improvements
- Better file handling
- Enhanced export options

## Conclusion
This major update brings significant improvements and new features to MD Tool.''';

    setState(() {
      _leftText = sampleLeft;
      _rightText = sampleRight;
      _leftFileName = 'MD_Tool_v1.0.md';
      _rightFileName = 'MD_Tool_v2.0.md';
    });

    _leftController.text = sampleLeft;
    _rightController.text = sampleRight;
  }

  Future<void> _pickLeftFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['txt', 'md', 'dart', 'json', 'yaml', 'yml'],
      allowMultiple: false,
    );

    if (result != null && result.files.isNotEmpty) {
      final file = File(result.files.first.path!);
      final content = await file.readAsString();
      setState(() {
        _leftText = content;
        _leftFileName = result.files.first.name;
      });
      _leftController.text = content;
    }
  }

  Future<void> _pickRightFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['txt', 'md', 'dart', 'json', 'yaml', 'yml'],
      allowMultiple: false,
    );

    if (result != null && result.files.isNotEmpty) {
      final file = File(result.files.first.path!);
      final content = await file.readAsString();
      setState(() {
        _rightText = content;
        _rightFileName = result.files.first.name;
      });
      _rightController.text = content;
    }
  }

  List<DiffLine> _generateDiffLines() {
    final leftLines = _leftText.split('\n');
    final rightLines = _rightText.split('\n');
    final diffLines = <DiffLine>[];

    int leftIndex = 0;
    int rightIndex = 0;

    while (leftIndex < leftLines.length || rightIndex < rightLines.length) {
      if (leftIndex >= leftLines.length) {
        diffLines.add(DiffLine(
          content: rightLines[rightIndex],
          type: DiffLineType.added,
          leftLineNumber: null,
          rightLineNumber: rightIndex + 1,
        ));
        rightIndex++;
      } else if (rightIndex >= rightLines.length) {
        diffLines.add(DiffLine(
          content: leftLines[leftIndex],
          type: DiffLineType.removed,
          leftLineNumber: leftIndex + 1,
          rightLineNumber: null,
        ));
        leftIndex++;
      } else if (leftLines[leftIndex] == rightLines[rightIndex]) {
        diffLines.add(DiffLine(
          content: leftLines[leftIndex],
          type: DiffLineType.unchanged,
          leftLineNumber: leftIndex + 1,
          rightLineNumber: rightIndex + 1,
        ));
        leftIndex++;
        rightIndex++;
      } else {
        if (leftIndex + 1 < leftLines.length && 
            leftLines[leftIndex + 1] == rightLines[rightIndex]) {
          diffLines.add(DiffLine(
            content: leftLines[leftIndex],
            type: DiffLineType.removed,
            leftLineNumber: leftIndex + 1,
            rightLineNumber: null,
          ));
          leftIndex++;
        } else if (rightIndex + 1 < rightLines.length && 
                   leftLines[leftIndex] == rightLines[rightIndex + 1]) {
          diffLines.add(DiffLine(
            content: rightLines[rightIndex],
            type: DiffLineType.added,
            leftLineNumber: null,
            rightLineNumber: rightIndex + 1,
          ));
          rightIndex++;
        } else {
          diffLines.add(DiffLine(
            content: rightLines[rightIndex],
            type: DiffLineType.modified,
            leftLineNumber: leftIndex + 1,
            rightLineNumber: rightIndex + 1,
          ));
          leftIndex++;
          rightIndex++;
        }
      }
    }

    return diffLines;
  }

  String _getDiffModeLabel(int mode) {
    switch (mode) {
      case 0:
        return 'TH Inline';
      case 1:
        return 'TH Side by Side';
      case 2:
        return 'Full File';
      case 3:
        return 'Enhanced';
      case 4:
        return 'Legacy';
      default:
        return 'TH Inline';
    }
  }

  Widget _buildDiffViewer() {
    try {
      switch (_diffViewMode) {
        case 0: // TH Inline
          return THDiffViewer(
            leftText: _leftText,
            rightText: _rightText,
            leftTitle: _leftFileName,
            rightTitle: _rightFileName,
            displayMode: DiffDisplayMode.inline,
          );
        case 1: // TH Side by Side
          return THDiffViewer(
            leftText: _leftText,
            rightText: _rightText,
            leftTitle: _leftFileName,
            rightTitle: _rightFileName,
            displayMode: DiffDisplayMode.sideBySide,
          );
        case 2: // Full File
          return THDiffViewer(
            leftText: _leftText,
            rightText: _rightText,
            leftTitle: _leftFileName,
            rightTitle: _rightFileName,
            displayMode: DiffDisplayMode.fullFile,
          );
        case 3: // Enhanced
          return EnhancedDiffViewer(
            leftText: _leftText,
            rightText: _rightText,
            leftTitle: _leftFileName,
            rightTitle: _rightFileName,
          );
        case 4: // Legacy (Advanced/Unified)
          return AdvancedDiffViewer(
            diffLines: _generateDiffLines(),
            leftTitle: _leftFileName,
            rightTitle: _rightFileName,
            leftText: _leftText,
            rightText: _rightText,
          );
        default:
          return DiffViewer(
            leftText: _leftText,
            rightText: _rightText,
            leftTitle: _leftFileName,
            rightTitle: _rightFileName,
          );
      }
    } catch (e) {
      // Fallback to basic diff viewer if TH Diff Suite has issues
      return Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade300),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Advanced diff viewer unavailable. Using fallback mode.\nError: $e',
                      style: TextStyle(color: Colors.orange.shade700),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: DiffViewer(
                leftText: _leftText,
                rightText: _rightText,
                leftTitle: _leftFileName,
                rightTitle: _rightFileName,
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildToolbar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
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
            ElevatedButton.icon(
              onPressed: _pickLeftFile,
              icon: const Icon(Icons.upload_file),
              label: const Text('Load Left File'),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: _pickRightFile,
              icon: const Icon(Icons.upload_file),
              label: const Text('Load Right File'),
            ),
            const SizedBox(width: 24),
            ElevatedButton.icon(
              onPressed: _loadSampleData,
              icon: const Icon(Icons.refresh),
              label: const Text('Load Sample'),
            ),
            const SizedBox(width: 24),
            PopupMenuButton<int>(
              icon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _getDiffModeLabel(_diffViewMode),
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
              onSelected: (int newMode) {
                setState(() {
                  _diffViewMode = newMode;
                  print('Diff view mode changed to: $_diffViewMode'); // Debug print
                });
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 0,
                  child: Row(
                    children: [
                      Icon(Icons.view_agenda, size: 16),
                      SizedBox(width: 8),
                      Text('TH Inline'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 1,
                  child: Row(
                    children: [
                      Icon(Icons.view_column, size: 16),
                      SizedBox(width: 8),
                      Text('TH Side by Side'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 2,
                  child: Row(
                    children: [
                      Icon(Icons.description, size: 16),
                      SizedBox(width: 8),
                      Text('Full File'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 3,
                  child: Row(
                    children: [
                      Icon(Icons.compare_arrows, size: 16),
                      SizedBox(width: 8),
                      Text('Enhanced'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 4,
                  child: Row(
                    children: [
                      Icon(Icons.view_list, size: 16),
                      SizedBox(width: 8),
                      Text('Legacy'),
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

  Widget _buildEditMode() {
    return Expanded(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: TextField(
                    controller: _leftController,
                    maxLines: null,
                    expands: true,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.all(12),
                    ),
                    style: const TextStyle(
                      fontFamily: 'Menlo',
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: TextField(
                    controller: _rightController,
                    maxLines: null,
                    expands: true,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.all(12),
                    ),
                    style: const TextStyle(
                      fontFamily: 'Menlo',
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Text Diff Comparison'),
        backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
        elevation: 1,
      ),
      body: Column(
        children: [
          _buildToolbar(),
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).dividerColor,
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _buildDiffViewer(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}