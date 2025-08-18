#!/usr/bin/env dart
/// Command-line utility to analyze why MD Tool shows fewer files than CLI tools
/// Usage: dart analyze_directory_discrepancy.dart /path/to/directory
/// 
/// This script compares CLI file counts with MD Tool's filtering logic
/// to identify exactly which files are being filtered out and why.

import 'dart:io';

void main(List<String> args) async {
  if (args.isEmpty) {
    print('Usage: dart analyze_directory_discrepancy.dart <directory_path>');
    print('Example: dart analyze_directory_discrepancy.dart ~/Work/Tools/knowledgedb');
    exit(1);
  }
  
  final directoryPath = args[0].replaceFirst('~', Platform.environment['HOME'] ?? '');
  final directory = Directory(directoryPath);
  
  if (!await directory.exists()) {
    print('Error: Directory does not exist: $directoryPath');
    exit(1);
  }
  
  print('🔍 Analyzing directory: $directoryPath');
  print('=' * 60);
  
  final analyzer = DirectoryAnalyzer();
  final analysis = await analyzer.analyzeDirectory(directory);
  
  print(analysis.generateDetailedReport());
  
  // Suggest CLI command to verify
  print('\n📋 To verify with CLI commands:');
  print('Total files:     find "$directoryPath" -type f | wc -l');
  print('Markdown files:  find "$directoryPath" -name "*.md" -o -name "*.markdown" -o -name "*.mdown" | wc -l');
  print('Hidden files:    find "$directoryPath" -path "*/.*" -name "*.md" | wc -l');
  print('Excluded dirs:   find "$directoryPath" -path "*/node_modules/*" -o -path "*/.git/*" -o -path "*/build/*" -name "*.md" | wc -l');
}

class DirectoryAnalyzer {
  Future<DirectoryAnalysisResult> analyzeDirectory(Directory directory) async {
    final result = DirectoryAnalysisResult(rootPath: directory.path);
    
    print('📊 Scanning directory recursively...');
    await _scanRecursively(directory, result, depth: 0);
    
    print('✅ Scan complete. Analyzing results...');
    return result;
  }
  
  Future<void> _scanRecursively(Directory directory, DirectoryAnalysisResult result, {required int depth}) async {
    try {
      await for (final entity in directory.list(followLinks: false)) {
        if (entity is File) {
          result.addFile(entity, depth);
        } else if (entity is Directory) {
          final dirName = entity.path.split(Platform.pathSeparator).last;
          final relativePath = entity.path.replaceFirst(result.rootPath, '').replaceFirst(RegExp(r'^/'), '');
          
          // Categorize directory
          if (dirName.startsWith('.')) {
            result.addHiddenDirectory(entity, depth);
            // Still scan inside for statistics
            if (depth < 15) { // Prevent infinite recursion
              await _scanRecursively(entity, result, depth: depth + 1);
            }
          } else if (_isExcludedDirectory(dirName)) {
            result.addExcludedDirectory(entity, depth);
            // Still scan inside for statistics  
            if (depth < 15) {
              await _scanRecursively(entity, result, depth: depth + 1);
            }
          } else if (depth >= 10) {
            result.addDeepDirectory(entity, depth);
            // Still scan to see what MD Tool is missing
            await _scanRecursively(entity, result, depth: depth + 1);
          } else {
            result.addVisibleDirectory(entity, depth);
            await _scanRecursively(entity, result, depth: depth + 1);
          }
        }
      }
    } catch (e) {
      result.addPermissionError(directory, e.toString());
    }
  }
  
  bool _isExcludedDirectory(String dirName) {
    const excludedDirs = {
      'node_modules', '.git', '.svn', '.hg', 
      'build', 'dist', 'target', '.DS_Store'
    };
    return excludedDirs.contains(dirName.toLowerCase());
  }
}

class DirectoryAnalysisResult {
  final String rootPath;
  
  // CLI-style counts (everything)
  int totalFiles = 0;
  int totalDirectories = 0;
  int totalMarkdownFiles = 0;
  
  // MD Tool visible counts
  int mdToolVisibleFiles = 0;
  int mdToolVisibleMarkdownFiles = 0;
  int mdToolVisibleDirectories = 0;
  
  // Filtered out by MD Tool
  final List<FileInfo> hiddenFiles = [];
  final List<FileInfo> excludedDirectoryFiles = [];
  final List<FileInfo> deepFiles = []; // Beyond depth 10
  final List<DirectoryInfo> emptyDirectories = []; // No markdown files
  
  // Directories by category  
  final List<DirectoryInfo> hiddenDirectories = [];
  final List<DirectoryInfo> excludedDirectories = [];
  final List<DirectoryInfo> deepDirectories = [];
  final List<DirectoryInfo> visibleDirectories = [];
  
  // Errors
  final List<ErrorInfo> permissionErrors = [];
  
  DirectoryAnalysisResult({required this.rootPath});
  
  void addFile(File file, int depth) {
    totalFiles++;
    final isMarkdown = _isMarkdownFile(file.path);
    if (isMarkdown) totalMarkdownFiles++;
    
    final relativePath = file.path.replaceFirst(rootPath, '').replaceFirst(RegExp(r'^/'), '');
    final fileInfo = FileInfo(
      path: file.path,
      relativePath: relativePath,
      isMarkdown: isMarkdown,
      depth: depth,
    );
    
    // Categorize why MD Tool might filter this file
    if (_isInHiddenDirectory(relativePath)) {
      hiddenFiles.add(fileInfo);
    } else if (_isInExcludedDirectory(relativePath)) {
      excludedDirectoryFiles.add(fileInfo);
    } else if (depth > 10) {
      deepFiles.add(fileInfo);
    } else {
      // This file would be visible in MD Tool
      mdToolVisibleFiles++;
      if (isMarkdown) mdToolVisibleMarkdownFiles++;
    }
  }
  
  void addVisibleDirectory(Directory dir, int depth) {
    totalDirectories++;
    mdToolVisibleDirectories++;
    
    final relativePath = dir.path.replaceFirst(rootPath, '').replaceFirst(RegExp(r'^/'), '');
    visibleDirectories.add(DirectoryInfo(
      path: dir.path,
      relativePath: relativePath,
      depth: depth,
    ));
  }
  
  void addHiddenDirectory(Directory dir, int depth) {
    totalDirectories++;
    
    final relativePath = dir.path.replaceFirst(rootPath, '').replaceFirst(RegExp(r'^/'), '');
    hiddenDirectories.add(DirectoryInfo(
      path: dir.path,
      relativePath: relativePath,
      depth: depth,
    ));
  }
  
  void addExcludedDirectory(Directory dir, int depth) {
    totalDirectories++;
    
    final relativePath = dir.path.replaceFirst(rootPath, '').replaceFirst(RegExp(r'^/'), '');
    excludedDirectories.add(DirectoryInfo(
      path: dir.path,
      relativePath: relativePath,
      depth: depth,
    ));
  }
  
  void addDeepDirectory(Directory dir, int depth) {
    totalDirectories++;
    
    final relativePath = dir.path.replaceFirst(rootPath, '').replaceFirst(RegExp(r'^/'), '');
    deepDirectories.add(DirectoryInfo(
      path: dir.path,
      relativePath: relativePath,
      depth: depth,
    ));
  }
  
  void addPermissionError(Directory dir, String error) {
    final relativePath = dir.path.replaceFirst(rootPath, '').replaceFirst(RegExp(r'^/'), '');
    permissionErrors.add(ErrorInfo(
      path: dir.path,
      relativePath: relativePath,
      error: error,
    ));
  }
  
  String generateDetailedReport() {
    final buffer = StringBuffer();
    
    // Summary
    buffer.writeln('📈 DIRECTORY ANALYSIS SUMMARY');
    buffer.writeln('═' * 50);
    buffer.writeln('Root: $rootPath');
    buffer.writeln();
    
    buffer.writeln('📁 TOTAL COUNTS (like CLI tools):');
    buffer.writeln('  Total files: $totalFiles');
    buffer.writeln('  Markdown files: $totalMarkdownFiles');
    buffer.writeln('  Directories: $totalDirectories');
    buffer.writeln();
    
    buffer.writeln('👁  MD TOOL VISIBLE COUNTS:');
    buffer.writeln('  Visible files: $mdToolVisibleFiles');
    buffer.writeln('  Visible markdown files: $mdToolVisibleMarkdownFiles');
    buffer.writeln('  Visible directories: $mdToolVisibleDirectories');
    buffer.writeln();
    
    buffer.writeln('🚫 FILTERED OUT BY MD TOOL:');
    buffer.writeln('  Hidden files (in .directories): ${hiddenFiles.length} (${hiddenFiles.where((f) => f.isMarkdown).length} markdown)');
    buffer.writeln('  Excluded directory files: ${excludedDirectoryFiles.length} (${excludedDirectoryFiles.where((f) => f.isMarkdown).length} markdown)');
    buffer.writeln('  Deep files (>10 levels): ${deepFiles.length} (${deepFiles.where((f) => f.isMarkdown).length} markdown)');
    buffer.writeln();
    
    buffer.writeln('📂 DIRECTORY BREAKDOWN:');
    buffer.writeln('  Visible directories: ${visibleDirectories.length}');
    buffer.writeln('  Hidden directories: ${hiddenDirectories.length}');
    buffer.writeln('  Excluded directories: ${excludedDirectories.length}');
    buffer.writeln('  Deep directories: ${deepDirectories.length}');
    buffer.writeln();
    
    if (permissionErrors.isNotEmpty) {
      buffer.writeln('⚠️  PERMISSION ERRORS: ${permissionErrors.length}');
      for (final error in permissionErrors.take(5)) {
        buffer.writeln('  • ${error.relativePath}: ${error.error}');
      }
      if (permissionErrors.length > 5) {
        buffer.writeln('  ... and ${permissionErrors.length - 5} more');
      }
      buffer.writeln();
    }
    
    // Detailed breakdown
    if (hiddenFiles.isNotEmpty) {
      buffer.writeln('🕵️ HIDDEN FILES (first 10):');
      for (final file in hiddenFiles.take(10)) {
        final type = file.isMarkdown ? '[MD]' : '[FILE]';
        buffer.writeln('  $type ${file.relativePath}');
      }
      if (hiddenFiles.length > 10) {
        buffer.writeln('  ... and ${hiddenFiles.length - 10} more hidden files');
      }
      buffer.writeln();
    }
    
    if (excludedDirectoryFiles.isNotEmpty) {
      buffer.writeln('🚷 EXCLUDED DIRECTORY FILES (first 10):');
      for (final file in excludedDirectoryFiles.take(10)) {
        final type = file.isMarkdown ? '[MD]' : '[FILE]';
        buffer.writeln('  $type ${file.relativePath}');
      }
      if (excludedDirectoryFiles.length > 10) {
        buffer.writeln('  ... and ${excludedDirectoryFiles.length - 10} more excluded files');
      }
      buffer.writeln();
    }
    
    if (deepFiles.isNotEmpty) {
      buffer.writeln('🏔️ DEEP FILES (beyond 10 levels):');
      for (final file in deepFiles.take(10)) {
        final type = file.isMarkdown ? '[MD]' : '[FILE]';
        buffer.writeln('  $type ${file.relativePath} (depth: ${file.depth})');
      }
      if (deepFiles.length > 10) {
        buffer.writeln('  ... and ${deepFiles.length - 10} more deep files');
      }
      buffer.writeln();
    }
    
    // Summary of why counts differ
    final totalFiltered = hiddenFiles.length + excludedDirectoryFiles.length + deepFiles.length;
    final markdownFiltered = hiddenFiles.where((f) => f.isMarkdown).length + 
                            excludedDirectoryFiles.where((f) => f.isMarkdown).length +
                            deepFiles.where((f) => f.isMarkdown).length;
    
    buffer.writeln('💡 CONCLUSION:');
    buffer.writeln('  CLI tools count: $totalFiles total files, $totalMarkdownFiles markdown files');
    buffer.writeln('  MD Tool shows: $mdToolVisibleFiles total files, $mdToolVisibleMarkdownFiles markdown files');
    buffer.writeln('  Difference: $totalFiltered files filtered out ($markdownFiltered markdown)');
    buffer.writeln();
    
    buffer.writeln('🔧 MAIN REASONS FOR DISCREPANCY:');
    if (hiddenFiles.isNotEmpty) {
      buffer.writeln('  • Hidden directories (${hiddenDirectories.length} dirs, ${hiddenFiles.length} files)');
    }
    if (excludedDirectoryFiles.isNotEmpty) {
      buffer.writeln('  • Excluded directories like .git, node_modules (${excludedDirectories.length} dirs, ${excludedDirectoryFiles.length} files)');
    }
    if (deepFiles.isNotEmpty) {
      buffer.writeln('  • Deep nesting >10 levels (${deepDirectories.length} dirs, ${deepFiles.length} files)');
    }
    if (permissionErrors.isNotEmpty) {
      buffer.writeln('  • Permission errors (${permissionErrors.length} directories)');
    }
    
    return buffer.toString();
  }
  
  bool _isMarkdownFile(String filePath) {
    const extensions = ['.md', '.markdown', '.mdown', '.mkd', '.mkdn'];
    final parts = filePath.split('.');
    final extension = parts.length > 1 ? '.${parts.last}' : '';
    final extensionLower = extension.toLowerCase();
    return extensions.contains(extensionLower);
  }
  
  bool _isInHiddenDirectory(String relativePath) {
    return relativePath.split(Platform.pathSeparator).any((part) => part.startsWith('.') && part != '.');
  }
  
  bool _isInExcludedDirectory(String relativePath) {
    const excludedDirs = {'node_modules', '.git', '.svn', '.hg', 'build', 'dist', 'target'};
    return relativePath.split(Platform.pathSeparator).any((part) => excludedDirs.contains(part.toLowerCase()));
  }
}

class FileInfo {
  final String path;
  final String relativePath;
  final bool isMarkdown;
  final int depth;
  
  FileInfo({
    required this.path,
    required this.relativePath,
    required this.isMarkdown,
    required this.depth,
  });
}

class DirectoryInfo {
  final String path;
  final String relativePath;
  final int depth;
  
  DirectoryInfo({
    required this.path,
    required this.relativePath,
    required this.depth,
  });
}

class ErrorInfo {
  final String path;
  final String relativePath;
  final String error;
  
  ErrorInfo({
    required this.path,
    required this.relativePath,
    required this.error,
  });
}