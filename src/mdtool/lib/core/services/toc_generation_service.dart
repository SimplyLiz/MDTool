import 'dart:io';

class TocGenerationService {
  static const String _tocFileName = 'README.md';
  
  /// Generates a table of contents from Markdown files in a directory
  Future<String> generateTocForDirectory(String directoryPath, List<File> markdownFiles) async {
    final buffer = StringBuffer();
    
    // Add header
    buffer.writeln('# Table of Contents\n');
    buffer.writeln('Auto-generated table of contents for this directory.\n');
    
    // Group files by categories if possible
    final Map<String, List<File>> categorizedFiles = _categorizeFiles(markdownFiles);
    
    if (categorizedFiles.containsKey('index')) {
      // Add index files first
      final indexFiles = categorizedFiles['index']!;
      if (indexFiles.isNotEmpty) {
        buffer.writeln('## Index\n');
        for (final file in indexFiles) {
          await _addFileToToc(buffer, file, directoryPath);
        }
        buffer.writeln();
      }
    }
    
    if (categorizedFiles.containsKey('readme')) {
      // Add readme files
      final readmeFiles = categorizedFiles['readme']!;
      if (readmeFiles.isNotEmpty) {
        buffer.writeln('## Documentation\n');
        for (final file in readmeFiles) {
          await _addFileToToc(buffer, file, directoryPath);
        }
        buffer.writeln();
      }
    }
    
    // Add remaining files by alphabetical order
    final otherFiles = markdownFiles.where((file) {
      final fileName = file.path.split('/').last.toLowerCase();
      return !fileName.startsWith('readme') && !fileName.startsWith('index') && fileName != 'toc.md';
    }).toList();
    
    otherFiles.sort((a, b) => a.path.split('/').last.compareTo(b.path.split('/').last));
    
    if (otherFiles.isNotEmpty) {
      buffer.writeln('## Files\n');
      for (final file in otherFiles) {
        await _addFileToToc(buffer, file, directoryPath);
      }
    }
    
    // Add generation timestamp
    buffer.writeln('\n---');
    buffer.writeln('*Generated on ${DateTime.now().toString().split('.')[0]}*');
    
    return buffer.toString();
  }
  
  /// Generates TOC from a single Markdown file's headings
  Future<String> generateTocFromContent(String content, String fileName) async {
    final buffer = StringBuffer();
    
    // Add header
    buffer.writeln('# Table of Contents: $fileName\n');
    
    final lines = content.split('\n');
    final headings = <TocHeading>[];
    
    // Extract headings
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.startsWith('#')) {
        final match = RegExp(r'^(#{1,6})\s+(.+)').firstMatch(line);
        if (match != null) {
          final level = match.group(1)!.length;
          final text = match.group(2)!.trim();
          final anchor = _createAnchor(text);
          headings.add(TocHeading(level: level, text: text, anchor: anchor));
        }
      }
    }
    
    // Generate TOC
    if (headings.isEmpty) {
      buffer.writeln('*No headings found in this document.*');
    } else {
      for (final heading in headings) {
        final indent = '  ' * (heading.level - 1);
        buffer.writeln('$indent- [${heading.text}](#${heading.anchor})');
      }
    }
    
    buffer.writeln('\n---');
    buffer.writeln('*Generated on ${DateTime.now().toString().split('.')[0]}*');
    
    return buffer.toString();
  }
  
  /// Creates a list of headings from markdown content for navigation
  List<TocHeading> extractHeadingsFromContent(String content) {
    final headings = <TocHeading>[];
    final lines = content.split('\n');
    
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.startsWith('#')) {
        final match = RegExp(r'^(#{1,6})\s+(.+)').firstMatch(line);
        if (match != null) {
          final level = match.group(1)!.length;
          final text = match.group(2)!.trim();
          final anchor = _createAnchor(text);
          headings.add(TocHeading(level: level, text: text, anchor: anchor, lineNumber: i));
        }
      }
    }
    
    return headings;
  }
  
  /// Saves generated TOC to a file
  Future<bool> saveTocToFile(String directoryPath, String tocContent) async {
    try {
      final tocFile = File('$directoryPath/$_tocFileName');
      await tocFile.writeAsString(tocContent);
      return true;
    } catch (e) {
      print('Error saving TOC file: $e');
      return false;
    }
  }
  
  /// Checks if it makes sense to generate a TOC (has multiple files or complex content)
  bool shouldShowGenerateButton(List<File> markdownFiles, String? currentContent) {
    // Show if there are multiple markdown files
    if (markdownFiles.length > 1) return true;
    
    // Show if current file has multiple headings
    if (currentContent != null) {
      final headings = extractHeadingsFromContent(currentContent);
      return headings.length > 3;
    }
    
    return false;
  }
  
  Map<String, List<File>> _categorizeFiles(List<File> files) {
    final categories = <String, List<File>>{
      'index': [],
      'readme': [],
      'other': [],
    };
    
    for (final file in files) {
      final fileName = file.path.split('/').last.toLowerCase();
      if (fileName.startsWith('index')) {
        categories['index']!.add(file);
      } else if (fileName.startsWith('readme') || fileName == 'toc.md') {
        categories['readme']!.add(file);
      } else {
        categories['other']!.add(file);
      }
    }
    
    return categories;
  }
  
  Future<void> _addFileToToc(StringBuffer buffer, File file, String directoryPath) async {
    try {
      final fileName = file.path.split('/').last;
      final fileNameWithoutExtension = fileName.replaceAll(RegExp(r'\.[^.]+$'), '');
      final relativePath = file.path.replaceFirst('$directoryPath/', '');
      
      // Try to get the first heading or title from the file
      final content = await file.readAsString();
      final firstHeading = _getFirstHeading(content);
      
      final title = firstHeading ?? fileNameWithoutExtension;
      buffer.writeln('- [$title]($relativePath)');
      
      // Add sub-headings if file has a clear structure
      final headings = extractHeadingsFromContent(content);
      final mainHeadings = headings.where((h) => h.level <= 2).take(3);
      
      for (final heading in mainHeadings) {
        if (heading.text.toLowerCase() != title.toLowerCase()) {
          buffer.writeln('  - [${heading.text}]($relativePath#${heading.anchor})');
        }
      }
    } catch (e) {
      // Fallback if can't read file
      final fileName = file.path.split('/').last;
      final fileNameWithoutExtension = fileName.replaceAll(RegExp(r'\.[^.]+$'), '');
      final relativePath = file.path.replaceFirst('$directoryPath/', '');
      buffer.writeln('- [$fileNameWithoutExtension]($relativePath)');
    }
  }
  
  String? _getFirstHeading(String content) {
    final lines = content.split('\n');
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.startsWith('#')) {
        final match = RegExp(r'^#+\s+(.+)').firstMatch(trimmed);
        if (match != null) {
          return match.group(1)!.trim();
        }
      }
    }
    return null;
  }
  
  String _createAnchor(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
  }
}

class TocHeading {
  final int level;
  final String text;
  final String anchor;
  final int? lineNumber;
  
  const TocHeading({
    required this.level,
    required this.text,
    required this.anchor,
    this.lineNumber,
  });
  
  @override
  String toString() => '${'#' * level} $text';
}