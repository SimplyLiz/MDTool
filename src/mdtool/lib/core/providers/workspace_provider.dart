import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import '../services/directory_permissions.dart';
import '../services/ollama_service.dart'; // if you want to reuse baseUrl normalization (optional)

const _kWorkspaceRootsKey = 'workspace_roots';
const _kWorkspaceBookmarksKey = 'workspace_bookmarks';

@immutable
class WorkspaceRoot {
  final String path;
  final String? bookmark; // base64, macOS
  const WorkspaceRoot(this.path, {this.bookmark});

  Map<String, String?> toJson() => {'path': path, 'bookmark': bookmark};
  factory WorkspaceRoot.fromJson(Map m) =>
      WorkspaceRoot((m['path'] ?? '') as String, bookmark: m['bookmark'] as String?);
}

@immutable
class FsNode {
  final String path;
  final bool isDir;
  final List<FsNode>? children; // null = not loaded yet (lazy)
  const FsNode({required this.path, required this.isDir, this.children});

  String get name => p.basename(path);
}

class WorkspaceNotifier extends StateNotifier<AsyncValue<List<WorkspaceRoot>>> {
  WorkspaceNotifier() : super(const AsyncValue.loading()) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final roots = (prefs.getStringList(_kWorkspaceRootsKey) ?? []).toList();
    final bms = (prefs.getStringList(_kWorkspaceBookmarksKey) ?? []).toList();
    final list = <WorkspaceRoot>[];
    for (var i = 0; i < roots.length; i++) {
      list.add(WorkspaceRoot(roots[i], bookmark: i < bms.length ? bms[i] : null));
    }

    // Try resolving bookmarks on macOS so we have access
    if (list.any((r) => (r.bookmark ?? '').isNotEmpty)) {
      try {
        final resolved = await DirectoryPermissions.resolve(
          list.map((r) => r.bookmark!).where((b) => b.isNotEmpty).toList(),
        );
        // we could refresh bookmarks if stale; keep it simple for now
      } catch (_) {}
    }

    state = AsyncValue.data(list);
  }

  Future<void> addRootsViaPicker() async {
    final picked = await DirectoryPermissions.pick(multiple: true);
    if (picked.isEmpty) return;
    final current = [...(state.value ?? [])];
    for (final r in picked) {
      if (current.indexWhere((x) => p.equals(x.path, r.path)) < 0) {
        current.add(WorkspaceRoot(r.path, bookmark: r.bookmark));
      }
    }
    await _persist(current);
  }

  Future<void> addRootPath(String path, {String? bookmark}) async {
    final current = [...(state.value ?? [])];
    if (current.indexWhere((x) => p.equals(x.path, path)) < 0) {
      current.add(WorkspaceRoot(path, bookmark: bookmark));
      await _persist(current);
    }
  }

  Future<void> removeRoot(String path) async {
    final current = [...(state.value ?? [])]
      ..removeWhere((x) => p.equals(x.path, path));
    await _persist(current);
  }

  Future<void> _persist(List<WorkspaceRoot> roots) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_kWorkspaceRootsKey, roots.map((r) => r.path).toList());
    await prefs.setStringList(
        _kWorkspaceBookmarksKey, roots.map((r) => r.bookmark ?? '').toList());
    state = AsyncValue.data(roots);
  }
}

final workspaceProvider =
    StateNotifierProvider<WorkspaceNotifier, AsyncValue<List<WorkspaceRoot>>>(
        (ref) => WorkspaceNotifier());

/// Lazy children loader that only returns directories and Markdown files.
/// Hidden files/folders are skipped by default.
Future<List<FsNode>> loadChildren(String dirPath,
    {bool showHidden = false}) async {
  final dir = Directory(dirPath);
  if (!await dir.exists()) return const [];
  final entities = await dir
      .list(recursive: false, followLinks: false)
      .where((e) => showHidden || !p.basename(e.path).startsWith('.'))
      .toList();

  entities.sort((a, b) {
    final ad = a is Directory ? 0 : 1;
    final bd = b is Directory ? 0 : 1;
    if (ad != bd) return ad - bd; // dirs first
    return p.basename(a.path).toLowerCase().compareTo(p.basename(b.path).toLowerCase());
  });

  final md = <FsNode>[];
  for (final e in entities) {
    if (e is Directory) {
      md.add(FsNode(path: e.path, isDir: true)); // children lazy
    } else if (e is File) {
      final ext = p.extension(e.path).toLowerCase();
      if (ext == '.md' || ext == '.markdown') {
        md.add(FsNode(path: e.path, isDir: false));
      }
    }
  }
  return md;
}