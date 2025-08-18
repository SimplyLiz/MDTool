import 'dart:io';
import 'package:flutter/material.dart';

/// Finder-style path bar:
/// - Editable path text field
/// - Dropdown of ancestor folders (root → current)
/// - Optional "Browse…" button (hook to your folder picker)
///
/// Usage:
/// FinderPathBar(
///   path: currentDirectoryPath,
///   onNavigate: (newPath) => _scanForMarkdownFiles(directoryPath: newPath),
///   onBrowsePressed: _pickFolder, // optional
/// )
class FinderPathBar extends StatefulWidget {
  final String path;
  final ValueChanged<String> onNavigate;

  /// Optional: called when the little folder button is pressed.
  final VoidCallback? onBrowsePressed;

  /// Optional: async validator; return false to block navigation.
  final Future<bool> Function(String path)? validatePath;

  /// Optional: hint text in the TextField
  final String hintText;

  const FinderPathBar({
    super.key,
    required this.path,
    required this.onNavigate,
    this.onBrowsePressed,
    this.validatePath,
    this.hintText = 'Enter a folder path…',
  });

  @override
  State<FinderPathBar> createState() => _FinderPathBarState();
}

class _FinderPathBarState extends State<FinderPathBar> {
  late final TextEditingController _controller;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _normalize(widget.path));
  }

  @override
  void didUpdateWidget(covariant FinderPathBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_normalize(widget.path) != _normalize(oldWidget.path)) {
      // external path changed → reflect in text field
      _controller.text = _normalize(widget.path);
      _errorText = null;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Split a path into parts and also return the cumulative ancestor paths.
  /// Example (macOS):
  ///   "/Users/lisa/Projects" ->
  ///     parts:   ["/", "Users", "lisa", "Projects"]
  ///     paths:   ["/", "/Users", "/Users/lisa", "/Users/lisa/Projects"]
  ///
  /// Example (Windows):
  ///   "C:\Users\Lisa\Projects" ->
  ///     parts: ["C:\\", "Users", "Lisa", "Projects"]
  ///     paths: ["C:\\", "C:\\Users", "C:\\Users\\Lisa", "C:\\Users\\Lisa\\Projects"]
  _Ancestors _buildAncestors(String rawPath) {
    final sep = Platform.pathSeparator;
    final path = _normalize(rawPath);

    if (path.isEmpty) {
      return _Ancestors(parts: const [], paths: const []);
    }

    // Windows drive handling
    if (_isWindows) {
      final driveMatch = RegExp(r'^[A-Za-z]:[\\/]*').firstMatch(path);
      final drive = driveMatch?.group(0) ?? '';
      final rest = path.substring(drive.length);
      final components = rest
          .split(RegExp(r'[\\/]'))
          .where((e) => e.isNotEmpty)
          .toList();

      final parts = <String>[];
      final paths = <String>[];

      if (drive.isNotEmpty) {
        final normalizedDrive = drive.endsWith(sep) ? drive : '$drive$sep';
        parts.add(normalizedDrive);
        paths.add(normalizedDrive);
      }

      var acc = paths.isEmpty ? '' : paths.first;
      for (final c in components) {
        acc = acc.endsWith(sep) ? '$acc$c' : '$acc$sep$c';
        parts.add(c);
        paths.add(acc);
      }
      return _Ancestors(parts: parts, paths: paths);
    }

    // POSIX (macOS/Linux)
    final isAbsolute = path.startsWith(sep);
    final cleaned = path.split(sep).where((e) => e.isNotEmpty).toList();

    final parts = <String>[];
    final paths = <String>[];

    if (isAbsolute) {
      parts.add(sep); // represent root
      paths.add(sep);
    }

    var acc = isAbsolute ? sep : '';
    for (final c in cleaned) {
      acc = (acc == sep || acc.isEmpty) ? '$acc$c' : '$acc$sep$c';
      parts.add(c);
      paths.add(acc);
    }
    return _Ancestors(parts: parts, paths: paths);
  }

  Future<void> _submit(String nextPath) async {
    final normalized = _normalize(nextPath);
    final ok = await _isPathAccessible(normalized);
    if (!mounted) return;

    if (!ok) {
      setState(() => _errorText = 'Folder not accessible or does not exist');
      return;
    }
    setState(() => _errorText = null);
    widget.onNavigate(normalized);
  }

  Future<bool> _isPathAccessible(String p) async {
    if (widget.validatePath != null) {
      return await widget.validatePath!(p);
    }
    final dir = Directory(p);
    if (!await dir.exists()) return false;
    try {
      // Try to list one entry; this will throw on EPERM (macOS sandbox) or EACCES.
      await dir.list(followLinks: false).take(1).toList();
      return true;
    } on FileSystemException {
      return false;
    }
  }

  String _normalize(String p) {
    var s = (p).trim();
    if (s.isEmpty) return s;

    // Expand ~ to home on POSIX
    if (!_isWindows && s.startsWith('~')) {
      final home = Platform.environment['HOME'];
      if (home != null && home.isNotEmpty) {
        s = s.replaceFirst('~', home);
      }
    }

    // Normalize separators on Windows
    if (_isWindows) {
      s = s.replaceAll('/', '\\');
    }
    return s;
  }

  static bool get _isWindows => Platform.isWindows;

  @override
  Widget build(BuildContext context) {
    final ancestors = _buildAncestors(_controller.text);

    return Row(
      children: [
        // Editable path
        Expanded(
          child: TextField(
            controller: _controller,
            decoration: InputDecoration(
              prefixIcon: widget.onBrowsePressed != null
                  ? IconButton(
                      tooltip: 'Browse…',
                      icon: const Icon(Icons.folder_open),
                      onPressed: widget.onBrowsePressed,
                    )
                  : const Icon(Icons.folder),
              hintText: widget.hintText,
              border: const OutlineInputBorder(),
              isDense: true,
              errorText: _errorText,
            ),
            onSubmitted: _submit,
          ),
        ),

        const SizedBox(width: 6),

        // Dropdown that lists ancestors (root → current)
        PopupMenuButton<String>(
          tooltip: 'Path menu',
          icon: const Icon(Icons.arrow_drop_down),
          itemBuilder: (context) {
            final items = <PopupMenuEntry<String>>[];
            for (int i = 0; i < ancestors.parts.length; i++) {
              final label = ancestors.parts[i];
              final targetPath = ancestors.paths[i];

              // Nice label for root on POSIX
              final display = (!_isWindows && label == Platform.pathSeparator)
                  ? 'Macintosh HD /' // feel free to localize/rename
                  : label;

              items.add(
                PopupMenuItem<String>(
                  value: targetPath,
                  child: Row(
                    children: [
                      const Icon(Icons.folder, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          display,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
            if (items.isEmpty) {
              items.add(const PopupMenuItem<String>(
                enabled: false,
                child: Text('No path'),
              ));
            }
            return items;
          },
          onSelected: (value) {
            _controller.text = value;
            _submit(value);
          },
        ),
      ],
    );
  }
}

class _Ancestors {
  final List<String> parts;
  final List<String> paths;
  const _Ancestors({required this.parts, required this.paths});
}