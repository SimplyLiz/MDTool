import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/app_state_provider.dart';
import 'mac_breadcrumb_bar.dart';
import 'package:path/path.dart' as path;

class StatusBar extends ConsumerWidget {
  const StatusBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appState = ref.watch(appStateProvider);
    
    if (appState.currentFile == null) {
      return const SizedBox.shrink();
    }

    final stats = _calculateStats(appState.content);
    
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildBreadcrumb(context, appState.currentFile!, ref),
          ),
          const Spacer(),
          if (appState.isDirty) ...[
            Icon(
              Icons.circle,
              size: 8,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              'Modified',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 16),
          ],
          Text(
            '${stats.words} words',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 16),
          Text(
            '${stats.characters} chars',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 16),
          Text(
            '${stats.lines} lines',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 16),
          Text(
            appState.isEditMode ? 'Edit' : 'Preview',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _getFileName(String filePath) {
    return filePath.split('/').last;
  }

  /// Build breadcrumb widget for status bar
  Widget _buildBreadcrumb(BuildContext context, String currentFile, WidgetRef ref) {
    final breadcrumbItems = _buildBreadcrumbItems(currentFile, ref);
    
    if (breadcrumbItems.isEmpty) {
      return Text(
        _getFileName(currentFile),
        style: TextStyle(
          fontSize: 12,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w500,
        ),
      );
    }
    
    return MacBreadcrumbBar(
      leadingIcon: Icons.folder_open,
      maxSegments: 4,
      currentIsTappable: false,
      items: breadcrumbItems,
      onTap: (index, item) {}, // No action needed in status bar
    );
  }
  
  /// Build breadcrumb items from current file path
  List<BreadcrumbItem> _buildBreadcrumbItems(String currentFile, WidgetRef ref) {
    final appState = ref.read(appStateProvider);
    final folderRoot = appState.currentFolderRoot;
    
    if (folderRoot == null) {
      // Fallback to showing directory path without filename
      final directory = path.dirname(currentFile);
      final parts = directory.split('/').where((part) => part.isNotEmpty).toList();
      final items = <BreadcrumbItem>[];
      
      // Add root
      items.add(const BreadcrumbItem('/', fullPath: '/'));
      
      // Add each directory segment (excluding filename)
      String currentPath = '';
      for (int i = 0; i < parts.length; i++) {
        final part = parts[i];
        currentPath += '/$part';
        items.add(BreadcrumbItem(part, fullPath: currentPath));
      }
      
      return items;
    }
    
    // Show path from folder root to current directory (excluding filename)
    final directory = path.dirname(currentFile);
    final items = <BreadcrumbItem>[];
    
    // Show folder root as the first segment
    final rootName = path.basename(folderRoot);
    items.add(BreadcrumbItem(rootName, fullPath: folderRoot));
    
    // If current directory is deeper than root, add the relative path
    if (directory.startsWith(folderRoot) && directory.length > folderRoot.length) {
      final relativePath = directory.substring(folderRoot.length + 1);
      final parts = relativePath.split('/').where((part) => part.isNotEmpty).toList();
      
      String currentPath = folderRoot;
      for (final part in parts) {
        currentPath += '/$part';
        items.add(BreadcrumbItem(part, fullPath: currentPath));
      }
    }
    
    return items;
  }

  DocumentStats _calculateStats(String content) {
    if (content.isEmpty) {
      return DocumentStats(words: 0, characters: 0, lines: 0);
    }

    final lines = content.split('\n').length;
    final characters = content.length;
    
    // Count words (split by whitespace and filter empty strings)
    final words = content
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .length;

    return DocumentStats(
      words: words,
      characters: characters,
      lines: lines,
    );
  }
}

class DocumentStats {
  final int words;
  final int characters;
  final int lines;

  DocumentStats({
    required this.words,
    required this.characters,
    required this.lines,
  });
}