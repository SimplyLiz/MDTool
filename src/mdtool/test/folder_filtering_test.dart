import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;

/// Test suite that verifies the filtering logic MD Tool uses
/// This demonstrates why CLI file counts differ from MD Tool display
void main() {
  group('MD Tool File Filtering Logic Tests', () {
    late TestDirectoryBuilder builder;
    
    setUp(() {
      builder = TestDirectoryBuilder();
    });
    
    tearDown(() async {
      await builder.cleanup();
    });

    test('should filter out hidden directories starting with dot', () async {
      final testDir = await builder.createTestStructure('hidden_test', {
        'visible.md': '# Visible File',
        '.hidden/secret.md': '# Hidden File',
        '.git/config.md': '# Git Config',
        'normal/readme.md': '# Normal Readme'
      });
      
      final cliCount = await builder.countAllMarkdownFiles(testDir);
      final filteredCount = await builder.countMarkdownFilesWithMdToolFiltering(testDir);
      
      expect(cliCount, equals(4), reason: 'CLI should find all 4 markdown files');
      expect(filteredCount, equals(2), reason: 'MD Tool should filter out hidden directories, showing only 2 files');
      
      print('Hidden directory filtering: CLI found $cliCount, MD Tool shows $filteredCount');
    });
    
    test('should filter out excluded build/VCS directories', () async {
      final testDir = await builder.createTestStructure('excluded_test', {
        'README.md': '# Main Readme',
        'node_modules/package/readme.md': '# Package Readme',
        'build/docs.md': '# Build Docs',
        '.git/hooks/readme.md': '# Git Hooks',
        'dist/output.md': '# Dist Output',
        'src/main.md': '# Source Main'
      });
      
      final cliCount = await builder.countAllMarkdownFiles(testDir);
      final filteredCount = await builder.countMarkdownFilesWithMdToolFiltering(testDir);
      
      expect(cliCount, equals(6), reason: 'CLI should find all 6 markdown files');
      expect(filteredCount, equals(2), reason: 'MD Tool should exclude build/VCS dirs, showing only README.md and src/main.md');
      
      print('Excluded directory filtering: CLI found $cliCount, MD Tool shows $filteredCount');
    });
    
    test('should limit recursion depth to 10 levels', () async {
      final testDir = await builder.createDeepStructure(15); // Deeper than MD Tool's limit
      
      final cliCount = await builder.countAllMarkdownFiles(testDir);
      final filteredCount = await builder.countMarkdownFilesWithMdToolFiltering(testDir);
      
      expect(cliCount, greaterThan(filteredCount), 
        reason: 'CLI should find more files than MD Tool due to depth limit');
      expect(filteredCount, lessThanOrEqualTo(10), 
        reason: 'MD Tool should stop at depth 10');
        
      print('Depth filtering: CLI found $cliCount, MD Tool shows $filteredCount');
    });
    
    test('should demonstrate complete filtering behavior', () async {
      final testDir = await builder.createComplexStructure();
      
      final analysisWithFiltering = await builder.analyzeFilteringBehavior(testDir, enableFiltering: true);
      final analysisWithoutFiltering = await builder.analyzeFilteringBehavior(testDir, enableFiltering: false);
      
      expect(analysisWithFiltering.cliTotal, greaterThan(analysisWithFiltering.mdToolVisible), 
        reason: 'With filtering enabled, CLI should find more files than MD Tool');
      
      expect(analysisWithoutFiltering.cliTotal, equals(analysisWithoutFiltering.mdToolVisible),
        reason: 'With filtering disabled, CLI and MD Tool should find the same files');
      
      print('\n=== Complete Analysis ===');
      print('CLI Total: ${analysisWithFiltering.cliTotal} files');
      print('MD Tool Visible (with filtering): ${analysisWithFiltering.mdToolVisible} files');
      print('MD Tool Visible (without filtering): ${analysisWithoutFiltering.mdToolVisible} files');
      print('Hidden files filtered: ${analysisWithFiltering.hiddenFiltered}');
      print('Excluded directory files filtered: ${analysisWithFiltering.excludedFiltered}');  
      print('Deep files filtered: ${analysisWithFiltering.deepFiltered}');
      print('Total filtered: ${analysisWithFiltering.totalFiltered}');
      
      // Verify accounting
      expect(analysisWithFiltering.mdToolVisible + analysisWithFiltering.totalFiltered, equals(analysisWithFiltering.cliTotal),
        reason: 'Filtered + visible should equal CLI total');
    });
    
    test('should provide CLI commands to verify discrepancy', () {
      final knowledgeDbPath = '/Users/lisa/Work/Tools/knowledgedb'; // Example path
      
      final commands = builder.generateVerificationCommands(knowledgeDbPath);
      
      expect(commands, contains('find'));
      expect(commands, contains('.md'));
      
      print('\n=== Verification Commands ===');
      print(commands);
    });
  });
}

/// Helper class that builds test directory structures and applies MD Tool filtering logic
class TestDirectoryBuilder {
  final List<Directory> _createdDirectories = [];
  
  /// Creates a test directory structure from a map of relative paths to content
  Future<Directory> createTestStructure(String name, Map<String, String> structure) async {
    final tempDir = Directory.systemTemp;
    final testDir = Directory(path.join(tempDir.path, 'md_tool_test_$name'));
    
    if (await testDir.exists()) {
      await testDir.delete(recursive: true);
    }
    await testDir.create();
    _createdDirectories.add(testDir);
    
    for (final entry in structure.entries) {
      final filePath = path.join(testDir.path, entry.key);
      final file = File(filePath);
      
      // Create parent directories if needed
      final parentDir = file.parent;
      if (!await parentDir.exists()) {
        await parentDir.create(recursive: true);
      }
      
      await file.writeAsString(entry.value);
    }
    
    return testDir;
  }
  
  /// Creates a deeply nested structure beyond MD Tool's recursion limit
  Future<Directory> createDeepStructure(int depth) async {
    final tempDir = Directory.systemTemp;
    final testDir = Directory(path.join(tempDir.path, 'md_tool_deep_test'));
    
    if (await testDir.exists()) {
      await testDir.delete(recursive: true);
    }
    await testDir.create();
    _createdDirectories.add(testDir);
    
    Directory currentDir = testDir;
    for (int i = 0; i < depth; i++) {
      currentDir = Directory(path.join(currentDir.path, 'level_$i'));
      await currentDir.create();
      
      final mdFile = File(path.join(currentDir.path, 'level_$i.md'));
      await mdFile.writeAsString('# Level $i Content');
    }
    
    return testDir;
  }
  
  /// Creates a complex structure with multiple filtering scenarios
  Future<Directory> createComplexStructure() async {
    return await createTestStructure('complex', {
      // Visible files
      'README.md': '# Main Readme',
      'docs/guide.md': '# User Guide',
      
      // Hidden directory files  
      '.hidden/secret.md': '# Secret File',
      '.DS_Store/metadata.md': '# DS Store Metadata',
      
      // Excluded directory files
      'node_modules/lib/readme.md': '# Node Module',
      '.git/hooks/pre-commit.md': '# Git Hook',
      'build/output/final.md': '# Build Output',
      'dist/bundle/info.md': '# Distribution Info',
      
      // Deep nested files (will create 12 levels)
      'deep/l1/l2/l3/l4/l5/l6/l7/l8/l9/l10/l11/deep.md': '# Deep File',
      
      // Non-markdown files (should not affect count)
      'data.txt': 'Text data',
      'config.json': '{"config": true}',
    });
  }
  
  /// Count all markdown files like CLI tools would (no filtering)
  Future<int> countAllMarkdownFiles(Directory dir) async {
    int count = 0;
    await for (final entity in dir.list(recursive: true, followLinks: false)) {
      if (entity is File && _isMarkdownFile(entity.path)) {
        count++;
      }
    }
    return count;
  }
  
  /// Count markdown files with MD Tool's filtering logic applied
  Future<int> countMarkdownFilesWithMdToolFiltering(Directory dir) async {
    return await _scanWithMdToolLogic(dir, enableFiltering: true);
  }
  
  /// Simulates MD Tool's _scanDirectoryRecursively filtering logic
  Future<int> _scanWithMdToolLogic(Directory directory, {int depth = 0, bool enableFiltering = true}) async {
    int count = 0;
    
    // MD Tool's depth limit (only if filtering is enabled)
    if (enableFiltering && depth >= 10) {
      return count;
    }
    
    try {
      await for (final entity in directory.list(followLinks: false)) {
        if (entity is File) {
          if (_isMarkdownFile(entity.path)) {
            count++;
          }
        } else if (entity is Directory) {
          final dirName = path.basename(entity.path);
          
          // MD Tool's filtering logic: Skip hidden directories only if filtering enabled
          if (enableFiltering && dirName.startsWith('.')) {
            continue;
          }
          
          // MD Tool's filtering logic: Skip excluded directories only if filtering enabled
          const excludedDirs = {'node_modules', '.git', '.svn', '.hg', 'build', 'dist', 'target', '.DS_Store'};
          if (enableFiltering && excludedDirs.contains(dirName.toLowerCase())) {
            continue;
          }
          
          // Recursively scan (with depth limit)
          count += await _scanWithMdToolLogic(entity, depth: depth + 1, enableFiltering: enableFiltering);
        }
      }
    } catch (e) {
      // MD Tool continues on permission errors
    }
    
    return count;
  }
  
  /// Analyzes filtering behavior and returns detailed breakdown
  Future<FilteringAnalysis> analyzeFilteringBehavior(Directory dir, {bool enableFiltering = true}) async {
    final cliTotal = await countAllMarkdownFiles(dir);
    final mdToolVisible = await _scanWithMdToolLogic(dir, enableFiltering: enableFiltering);
    
    // Count files in each filtered category
    int hiddenFiltered = 0;
    int excludedFiltered = 0;
    int deepFiltered = 0;
    
    await for (final entity in dir.list(recursive: true, followLinks: false)) {
      if (entity is File && _isMarkdownFile(entity.path)) {
        final relativePath = path.relative(entity.path, from: dir.path);
        
        if (_isInHiddenDirectory(relativePath)) {
          hiddenFiltered++;
        } else if (_isInExcludedDirectory(relativePath)) {
          excludedFiltered++;
        } else if (_getDepth(relativePath) > 10) {
          deepFiltered++;
        }
      }
    }
    
    return FilteringAnalysis(
      cliTotal: cliTotal,
      mdToolVisible: mdToolVisible,
      hiddenFiltered: hiddenFiltered,
      excludedFiltered: excludedFiltered,
      deepFiltered: deepFiltered,
    );
  }
  
  /// Generates CLI commands to verify file counts
  String generateVerificationCommands(String directoryPath) {
    return '''
# Verify file count discrepancy with these CLI commands:

# Total files (like CLI tools count):
find "$directoryPath" -type f | wc -l

# Total markdown files (CLI count):
find "$directoryPath" -name "*.md" -o -name "*.markdown" -o -name "*.mdown" | wc -l

# Files in hidden directories (MD Tool filters these out):
find "$directoryPath" -path "*/.*" -name "*.md" | wc -l

# Files in excluded directories (MD Tool filters these out):
find "$directoryPath" \\( -path "*/node_modules/*" -o -path "*/.git/*" -o -path "*/build/*" -o -path "*/dist/*" \\) -name "*.md" | wc -l

# Files deeper than 10 levels (MD Tool depth limit):
find "$directoryPath" -mindepth 12 -name "*.md" | wc -l

# Analysis tool (run from project root):
dart src/md_tool/test/tools/analyze_directory_discrepancy.dart "$directoryPath"
''';
  }
  
  bool _isMarkdownFile(String filePath) {
    const extensions = ['.md', '.markdown', '.mdown', '.mkd', '.mkdn'];
    final extension = path.extension(filePath).toLowerCase();
    return extensions.contains(extension);
  }
  
  bool _isInHiddenDirectory(String relativePath) {
    return relativePath.split(Platform.pathSeparator).any((part) => part.startsWith('.') && part != '.');
  }
  
  bool _isInExcludedDirectory(String relativePath) {
    const excludedDirs = {'node_modules', '.git', '.svn', '.hg', 'build', 'dist', 'target'};
    return relativePath.split(Platform.pathSeparator).any((part) => excludedDirs.contains(part.toLowerCase()));
  }
  
  int _getDepth(String relativePath) {
    return relativePath.split(Platform.pathSeparator).length - 1;
  }
  
  Future<void> cleanup() async {
    for (final dir in _createdDirectories) {
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
    }
    _createdDirectories.clear();
  }
}

class FilteringAnalysis {
  final int cliTotal;
  final int mdToolVisible;
  final int hiddenFiltered;
  final int excludedFiltered;
  final int deepFiltered;
  
  FilteringAnalysis({
    required this.cliTotal,
    required this.mdToolVisible,
    required this.hiddenFiltered,
    required this.excludedFiltered,
    required this.deepFiltered,
  });
  
  int get totalFiltered => hiddenFiltered + excludedFiltered + deepFiltered;
}