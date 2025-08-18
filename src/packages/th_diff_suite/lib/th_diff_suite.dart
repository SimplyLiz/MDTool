/// TH Diff Suite - A comprehensive text diff and comparison package
/// 
/// This library provides text comparison functionality with support for
/// multiple output formats including Git diff, unified diff, and custom formats.
library th_diff_suite;

export 'src/th_diff_suite.dart';
export 'src/models/th_diff_result.dart';
export 'src/models/th_diff_options.dart';
export 'src/models/th_diff_hunk.dart';
export 'src/models/th_diff_line.dart';
export 'src/models/th_intra_line_diff.dart';
export 'src/formatters/git_diff_formatter.dart';
export 'src/formatters/unified_diff_formatter.dart';
export 'src/formatters/th_md_diff_formatter.dart';
export 'src/line_diff_algorithm.dart';
export 'src/intra_line_diff_algorithm.dart';
export 'src/ui_helpers/diff_ui_helpers.dart';
export 'src/ui_helpers/export_helpers.dart';
