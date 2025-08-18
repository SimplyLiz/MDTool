# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2025-08-12

### Added

#### Core Features
- **Text Comparison Engine**: Comprehensive line-based diff algorithm for comparing text strings and files
- **File Comparison**: Direct file-to-file comparison with automatic file reading and error handling
- **Multiple Output Formats**:
  - Git diff format (`toGitDiff()`) - Standard Git-style diff output with headers and metadata
  - Unified diff format (`toUnifiedDiff()`) - Classic unified diff format compatible with standard diff tools
  - TH MD diff format (`toMDDiff()`) - Custom Markdown-formatted diff with rich statistics and annotations

#### Configuration Options
- **THDiffOptions** class with comprehensive configuration:
  - `contextLines`: Configurable number of context lines around changes (default: 3)
  - `timeout`: Processing timeout in seconds for large files (default: 1.0)
  - `enableSemanticCleanup`: Intelligent cleanup of diff artifacts (default: true)
  - `enableEfficiencyCleanup`: Performance optimization for diff processing (default: true)
  - `ignoreWhitespace`: Option to ignore whitespace differences (default: false)
  - `ignoreCase`: Option to ignore case differences (default: false)

#### Data Models
- **THDiffResult**: Comprehensive result object containing:
  - List of hunks representing grouped changes
  - Detailed statistics and metrics
  - Original and modified text preservation
  - File path information for file comparisons
  - Timestamp and metadata
- **THDiffHunk**: Represents a group of related changes with:
  - Line ranges for old and new content
  - Collection of diff lines within the hunk
  - Statistics for additions and deletions within the hunk
- **THDiffLine**: Individual line representation with:
  - Line type (context, addition, deletion)
  - Line content and numbers
  - Helper methods for type checking
- **THDiffStats**: Rich statistics including:
  - Total, added, deleted, and unchanged line counts
  - Number of hunks generated
  - Change percentage calculation
  - Performance metrics

#### Analysis Features
- **Rich Statistics**: Comprehensive metrics about changes including:
  - Line-level statistics (added, deleted, changed, unchanged)
  - Change percentage calculations
  - Hunk count and distribution
  - Zero-division safe calculations
- **Change Analysis**: Detailed analysis of individual changes:
  - Access to all changed lines across hunks
  - Line-by-line change tracking
  - Context preservation around changes

#### Performance Features
- **Efficient Algorithm**: Optimized line-based diff algorithm using diff_match_patch
- **Large File Support**: Handles large text files efficiently with configurable timeouts
- **Memory Management**: Efficient memory usage for processing large diffs
- **Performance Testing**: Comprehensive tests ensuring fast processing of large datasets

#### Testing Infrastructure
- **Comprehensive Test Suite**: 
  - Unit tests for all core functionality
  - Reference comparison tests against standard diff tools
  - Edge case testing (empty files, large files, unicode, special characters)
  - Performance benchmarking tests
  - Error handling and validation tests
- **Test Data**: Realistic test documents and reference diff outputs for validation
- **Coverage**: High test coverage across all features and edge cases

#### Error Handling
- **File System Errors**: Proper handling of missing files and invalid paths
- **Validation**: Input validation with meaningful error messages
- **Future Compatibility**: Graceful handling of unimplemented features with clear error messages

#### Documentation
- **API Documentation**: Comprehensive inline documentation for all public APIs
- **Usage Examples**: Complete example demonstrating all major features
- **Code Comments**: Detailed code comments explaining algorithms and design decisions

### Technical Details

#### Dependencies
- `flutter`: Core Flutter framework support
- `diff_match_patch ^0.4.1`: High-performance text diffing algorithm
- `path ^1.8.3`: Cross-platform path handling utilities

#### Platform Support
- **Flutter**: Compatible with Flutter 1.17.0 and above
- **Dart SDK**: Requires Dart 3.8.1 or higher
- **Cross-platform**: Supports all platforms where Flutter runs (iOS, Android, Web, Desktop)

#### Architecture
- **Abstract API Design**: Clean static method API requiring no instantiation
- **Immutable Data Models**: All data structures are immutable for thread safety
- **Modular Formatters**: Pluggable formatter system for different output formats
- **Type Safety**: Full type safety with comprehensive type definitions

### Future Roadmap

#### Planned Features (Unimplemented)
The following features are planned for future releases and currently throw `UnimplementedError`:

- **Document Comparison**: Native support for TH MD Document objects
- **Context Diff Format**: Additional context diff output format
- **Directory Comparison**: Recursive directory comparison capabilities
- **Binary File Support**: Comparison of binary files with appropriate handling

#### API Stability
- Public API is considered stable for the 0.x series
- Breaking changes will result in major version increments
- Deprecated features will be marked and maintained for one major version

### License
- MIT License - see LICENSE file for details

### Contributing
- Issues and pull requests welcome at the project repository
- Follows standard Dart/Flutter development practices
- Comprehensive test coverage required for all new features

---

## [Unreleased]

### Planned
- Context diff format implementation
- TH MD Document comparison support
- Directory comparison functionality
- Binary file comparison capabilities
- Performance optimizations for very large files
- Additional configuration options for specialized use cases
