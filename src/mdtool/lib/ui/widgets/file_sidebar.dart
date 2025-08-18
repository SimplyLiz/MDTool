import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import '../../core/providers/workspace_provider.dart';
import '../../core/providers/preferences_provider.dart'; // for lastOpenedFile, optional open
// import your editor/navigation action that opens a file: openMarkdownFile(path)

class f extends ConsumerStatefulWidget {
  final void Function(String path)? onOpenFile;
  const FileSidebar({super.key, this.onOpenFile});

  @override
  ConsumerState<FileSidebar> createState() => _FileSidebarState();
}

class _FileSidebarState extends ConsumerState<FileSidebar> {
  final Map<String, Future<List<FsNode>>> _futures = {};
  final Set<String> _expandedDirs = {};

  @override
  void initState() {
    super.initState();
    _maybeAddPdfRootOnce();
  }

  Future<void> _maybeAddPdfRootOnce() async {
    // Auto-add folder of lastOpenedFile if it's a PDF and not already in roots
    final prefs = ref.read(preferencesProvider).value;
    final pdf = prefs?.lastOpenedFile ?? '';
    if (pdf.isEmpty || !pdf.toLowerCase().endsWith('.pdf')) return;
    final dir = p.dirname(pdf);
    final roots = ref.read(workspaceProvider).value ?? [];
    if (roots.indexWhere((r) => p.equals(r.path, dir)) < 0) {
      await ref.read(workspaceProvider.notifier).addRootPath(dir);
    }
  }

  Future<List<FsNode>> _load(String dir) {
    return _futures.putIfAbsent(dir, () => loadChildren(dir));
  }

  @override
  Widget build(BuildContext context) {
    final rootsAsync = ref.watch(workspaceProvider);

    return Container(
      width: 300,
      color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.35),
      child: rootsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Workspace error: $e')),
        data: (roots) {
          if (roots.isEmpty) {
            return _emptyState(context);
          }
          return Column(
            children: [
              _toolbar(context),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  itemCount: roots.length,
                  itemBuilder: (context, i) {
                    final root = roots[i];
                    return _DirectoryTile(
                      path: root.path,
                      initiallyExpanded: false,
                      loadChildren: _load,
                      expandedDirs: _expandedDirs,
                      onOpenFile: widget.onOpenFile,
                      onRemoveRoot: () =>
                          ref.read(workspaceProvider.notifier).removeRoot(root.path),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _toolbar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text('Locations',
                style: Theme.of(context).textTheme.titleSmall),
          ),
          IconButton(
            tooltip: 'Add locations…',
            icon: const Icon(Icons.create_new_folder_outlined),
            onPressed: () async {
              await ref.read(workspaceProvider.notifier).addRootsViaPicker();
              setState(() {}); // refresh view
            },
          ),
        ],
      ),
    );
  }

  Widget _emptyState(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.folder_open, size: 40),
        const SizedBox(height: 8),
        const Text('No locations added'),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: () async {
            await ref.read(workspaceProvider.notifier).addRootsViaPicker();
            setState(() {});
          },
          child: const Text('Add locations…'),
        ),
      ],
    );
  }
}

class _DirectoryTile extends StatefulWidget {
  final String path;
  final bool initiallyExpanded;
  final Future<List<FsNode>> Function(String dir) loadChildren;
  final Set<String> expandedDirs;
  final VoidCallback onRemoveRoot;
  final void Function(String path)? onOpenFile;

  const _DirectoryTile({
    required this.path,
    required this.initiallyExpanded,
    required this.loadChildren,
    required this.expandedDirs,
    required this.onRemoveRoot,
    this.onOpenFile,
  });

  @override
  State<_DirectoryTile> createState() => _DirectoryTileState();
}

class _DirectoryTileState extends State<_DirectoryTile> {
  late Future<List<FsNode>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.loadChildren(widget.path);
  }

  @override
  Widget build(BuildContext context) {
    final isExpanded = widget.expandedDirs.contains(widget.path);
    return ExpansionTile(
      key: PageStorageKey(widget.path),
      initiallyExpanded: widget.initiallyExpanded,
      title: Row(
        children: [
          const Icon(Icons.folder, size: 18),
          const SizedBox(width: 6),
          Expanded(child: Text(p.basename(widget.path))),
          IconButton(
            tooltip: 'Remove location',
            icon: const Icon(Icons.close, size: 16),
            onPressed: widget.onRemoveRoot,
          ),
        ],
      ),
      onExpansionChanged: (v) {
        setState(() {
          if (v) {
            widget.expandedDirs.add(widget.path);
            _future = widget.loadChildren(widget.path);
          } else {
            widget.expandedDirs.remove(widget.path);
          }
        });
      },
      children: [
        FutureBuilder<List<FsNode>>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: LinearProgressIndicator(minHeight: 2),
              );
            }
            final children = snap.data ?? const <FsNode>[];
            if (children.isEmpty) {
              return const ListTile(
                  dense: true, title: Text('Empty', style: TextStyle(fontSize: 13)));
            }
            return _ChildrenList(
              parent: widget.path,
              nodes: children,
              loadChildren: widget.loadChildren,
              expandedDirs: widget.expandedDirs,
              onOpenFile: widget.onOpenFile,
            );
          },
        ),
      ],
    );
  }
}

class _ChildrenList extends StatelessWidget {
  final String parent;
  final List<FsNode> nodes;
  final Future<List<FsNode>> Function(String dir) loadChildren;
  final Set<String> expandedDirs;
  final void Function(String path)? onOpenFile;

  const _ChildrenList({
    required this.parent,
    required this.nodes,
    required this.loadChildren,
    required this.expandedDirs,
    this.onOpenFile,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: nodes.map((n) {
        if (n.isDir) {
          return _DirectoryTile(
            path: n.path,
            initiallyExpanded: false,
            loadChildren: loadChildren,
            expandedDirs: expandedDirs,
            onRemoveRoot: () {}, // not shown for non-root dirs
            onOpenFile: onOpenFile,
          );
        } else {
          return ListTile(
            dense: true,
            leading: const Icon(Icons.insert_drive_file, size: 16),
            title: Text(p.basename(n.path)),
            onTap: () => onOpenFile?.call(n.path),
          );
        }
      }).toList(),
    );
  }
}