# TH Diff Suite - Project Planning Document

## Overview

TH Diff Suite is a comprehensive text diff and comparison package for Flutter applications. It provides robust text comparison functionality with support for multiple output formats including Git diff, unified diff, and custom TH MD format.

## Project Structure

```
th_diff_suite/
├── lib/
│   ├── th_diff_suite.dart          # Main export file
│   └── src/
│       ├── th_diff_suite.dart      # Core API class
│       ├── models/                 # Data models
│       │   ├── th_diff_result.dart # Complete diff result
│       │   ├── th_diff_options.dart # Configuration options
│       │   ├── th_diff_hunk.dart   # Diff hunk representation
│       │   └── th_diff_line.dart   # Individual line changes
│       └── formatters/             # Output formatters
│           ├── git_diff_formatter.dart
│           ├── unified_diff_formatter.dart
│           └── th_md_diff_formatter.dart
├── docs/
│   └── PLANNING.md                 # This file
├── example/                        # Example usage
├── test/                          # Test files
├── pubspec.yaml                   # Package configuration
└── README.md                      # Package documentation
```

## Core Architecture

### Models

1. **THDiffResult**: Contains the complete result of a diff operation
   - Original and modified text
   - List of hunks representing differences
   - Configuration options used
   - File paths (optional)
   - Timestamp and statistics

2. **THDiffHunk**: Represents a contiguous block of changes
   - Line ranges for old and new files
   - Collection of THDiffLine objects
   - Optional section headers

3. **THDiffLine**: Individual line with change type
   - Line content
   - Change type (context, addition, deletion)
   - Line numbers in both files

4. **THDiffOptions**: Configuration for diff behavior
   - Timeout settings
   - Context lines count
   - Cleanup options
   - Formatting preferences

### Core API

The main `THDiffSuite` class provides static methods for:

**Current Implementation (Phase 1):**
- `compareTexts(String, String, [options])` - Compare two text strings
- `compareFiles(String, String, [options])` - Compare two files
- `toGitDiff(THDiffResult)` - Export as Git diff format
- `toUnifiedDiff(THDiffResult)` - Export as unified diff format
- `toMDDiff(THDiffResult)` - Export as custom TH MD format

**Future Implementation (Planned):**
- `compareDocuments(doc1, doc2, [options])` - Compare TH MD documents
- `toContextDiff(THDiffResult)` - Context diff format
- `compareDirectories(path1, path2, [options])` - Directory comparison
- `compareBinaryFiles(path1, path2, [options])` - Binary file support

### Formatters

1. **GitDiffFormatter**: Git-compatible diff output
   - Standard Git diff headers
   - Index lines with hashes
   - Support for metadata (author, commit info)
   - Compatible with `git apply`

2. **UnifiedDiffFormatter**: Traditional unified diff
   - Standard unified diff format
   - Configurable context lines
   - Side-by-side rendering option
   - Statistics summary

3. **THMDDiffFormatter**: Custom format for MD tool integration
   - Markdown-formatted output with rich annotations
   - Interactive JSON structure option
   - Compact summary format
   - Line-by-line detailed analysis

## Implementation Phases

### Phase 1: Foundation (Completed)
✅ Project structure setup
✅ Core data models
✅ Basic diff algorithm integration
✅ Text and file comparison
✅ Three output formatters
✅ Package configuration

### Phase 2: Testing & Validation (Next)
- [ ] Comprehensive unit tests
- [ ] Integration tests
- [ ] Performance benchmarks
- [ ] Edge case handling
- [ ] Documentation examples

### Phase 3: Advanced Features
- [ ] TH MD Document integration
- [ ] Directory comparison
- [ ] Binary file support
- [ ] Context diff format
- [ ] Performance optimizations

### Phase 4: UI Integration
- [ ] Flutter widgets for diff display
- [ ] Syntax highlighting
- [ ] Interactive diff viewer
- [ ] Export functionality

## Dependencies

### Production Dependencies
- `flutter`: Flutter SDK
- `diff_match_patch`: ^0.4.1 - Google's diff algorithm
- `path`: ^1.8.3 - Path manipulation utilities

### Development Dependencies
- `flutter_test`: Flutter testing framework
- `flutter_lints`: Linting rules
- `test`: ^1.24.0 - Additional testing utilities

## API Design Principles

1. **Simplicity**: Clean, intuitive API that's easy to use
2. **Flexibility**: Multiple input methods and output formats
3. **Performance**: Efficient algorithms with configurable timeouts
4. **Extensibility**: Easy to add new formatters and features
5. **Compatibility**: Standard diff formats for interoperability

## Usage Patterns

### Basic Text Comparison
```dart
final result = THDiffSuite.compareTexts(text1, text2);
final gitDiff = THDiffSuite.toGitDiff(result);
```

### File Comparison with Options
```dart
final options = THDiffOptions(contextLines: 5, ignoreWhitespace: true);
final result = await THDiffSuite.compareFiles('file1.txt', 'file2.txt', options);
final mdDiff = THDiffSuite.toMDDiff(result);
```

### Custom Formatting
```dart
final result = THDiffSuite.compareTexts(text1, text2);
print('Changes: +${result.stats.addedLines} -${result.stats.deletedLines}');
```

## Integration with MD Tool

The package is designed for seamless integration with the MD Tool application:

1. **Custom TH MD Format**: Rich markdown output with annotations
2. **Document Object Support**: Planned integration with TH_MD_Document
3. **Visual Display**: Structured data for UI rendering
4. **Export Options**: Multiple formats for user preference

## Testing Strategy

1. **Unit Tests**: Each model and formatter class
2. **Integration Tests**: End-to-end diff operations
3. **Performance Tests**: Large file handling
4. **Edge Case Tests**: Empty files, identical files, binary content
5. **Format Tests**: Output format compliance

## Performance Considerations

1. **Algorithm Choice**: Using proven diff-match-patch library
2. **Memory Management**: Streaming for large files
3. **Timeout Handling**: Configurable timeouts for long operations
4. **Cleanup Options**: Semantic and efficiency cleanup toggles

## Security Considerations

1. **File Access**: Proper permission checking
2. **Path Validation**: Prevent directory traversal
3. **Memory Limits**: Protection against excessive memory usage
4. **Input Sanitization**: Safe handling of user input

## Future Enhancements

1. **Machine Learning**: Intelligent diff suggestions
2. **Collaborative Features**: Multi-user diff resolution
3. **Version Control**: Git integration features
4. **Cloud Storage**: Remote file comparison
5. **Mobile Optimization**: Touch-friendly diff viewing

## Maintenance Plan

1. **Regular Updates**: Keep dependencies current
2. **Bug Fixes**: Responsive issue resolution
3. **Feature Requests**: Community-driven enhancements
4. **Documentation**: Comprehensive guides and examples
5. **Performance Monitoring**: Continuous optimization

---

*Last Updated: 2025-01-11*
*Status: Phase 1 Complete, Ready for Testing*