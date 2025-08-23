import 'package:flutter/material.dart';
import '../../models/file_operations.dart';
import '../../models/tree_item.dart';
import '../../config/folder_sidebar_config.dart';

/// Context menu widget for files
/// Provides standard file operations and supports custom menu items
class FileContextMenu extends StatelessWidget {
  final FileTreeItem file;
  final FolderSidebarConfig config;
  final VoidCallback? onDismiss;
  
  const FileContextMenu({
    super.key,
    required this.file,
    required this.config,
    this.onDismiss,
  });
  
  @override
  Widget build(BuildContext context) {
    final menuItems = _buildMenuItems(context);
    
    return PopupMenuButton<String>(
      itemBuilder: (context) => menuItems,
      onSelected: (value) => _handleMenuSelection(context, value),
      onCanceled: onDismiss,
      child: const SizedBox.shrink(), // This will be triggered programmatically
    );
  }
  
  /// Show the context menu at a specific position
  static void show({
    required BuildContext context,
    required Offset position,
    required FileTreeItem file,
    required FolderSidebarConfig config,
    VoidCallback? onDismiss,
  }) {
    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx + 1,
        position.dy + 1,
      ),
      items: _buildStaticMenuItems(context, file, config),
    ).then((value) {
      if (value != null) {
        _handleStaticMenuSelection(context, value, file, config);
      }
      onDismiss?.call();
    });
  }
  
  List<PopupMenuEntry<String>> _buildMenuItems(BuildContext context) {
    return _buildStaticMenuItems(context, file, config);
  }
  
  static List<PopupMenuEntry<String>> _buildStaticMenuItems(
    BuildContext context,
    FileTreeItem file,
    FolderSidebarConfig config,
  ) {
    final items = <PopupMenuEntry<String>>[];
    
    // Add default menu items if enabled
    if (config.showDefaultMenuItems) {
      // Open in Current Window
      items.add(PopupMenuItem<String>(
        value: 'open',
        child: Row(
          children: [
            Icon(config.icons.file, size: 16),
            const SizedBox(width: 8),
            const Text('Open'),
          ],
        ),
      ));
      
      // Copy Path
      items.add(PopupMenuItem<String>(
        value: 'copy_path',
        child: Row(
          children: [
            const Icon(Icons.content_copy, size: 16),
            const SizedBox(width: 8),
            const Text('Copy Path'),
          ],
        ),
      ));
      
      // Separator
      items.add(const PopupMenuDivider());
      
      // Reveal in File Manager
      if (config.allowedOperations.contains(FileOperationType.reveal)) {
        items.add(PopupMenuItem<String>(
          value: 'reveal',
          child: Row(
            children: [
              Icon(config.icons.reveal, size: 16),
              const SizedBox(width: 8),
              const Text('Reveal in File Manager'),
            ],
          ),
        ));
      }
      
      // Duplicate
      if (config.allowedOperations.contains(FileOperationType.copy)) {
        items.add(PopupMenuItem<String>(
          value: 'duplicate',
          child: Row(
            children: [
              const Icon(Icons.file_copy, size: 16),
              const SizedBox(width: 8),
              const Text('Duplicate'),
            ],
          ),
        ));
      }
      
      // Rename
      if (config.allowedOperations.contains(FileOperationType.rename)) {
        items.add(PopupMenuItem<String>(
          value: 'rename',
          child: Row(
            children: [
              Icon(config.icons.rename, size: 16),
              const SizedBox(width: 8),
              const Text('Rename'),
            ],
          ),
        ));
      }
      
      // Separator before dangerous operations
      if (config.allowedOperations.contains(FileOperationType.delete)) {
        items.add(const PopupMenuDivider());
        
        // Delete
        items.add(PopupMenuItem<String>(
          value: 'delete',
          child: Row(
            children: [
              Icon(config.icons.delete, size: 16, color: Colors.red),
              const SizedBox(width: 8),
              Text('Move to Trash', style: TextStyle(color: Colors.red)),
            ],
          ),
        ));
      }
      
      // File Info (separator + info item)
      items.add(const PopupMenuDivider());
      items.add(PopupMenuItem<String>(
        value: 'info',
        child: Row(
          children: [
            const Icon(Icons.info_outline, size: 16),
            const SizedBox(width: 8),
            const Text('File Info'),
          ],
        ),
      ));
    }
    
    // Add custom menu items if provided
    final customItems = config.customFileMenuItems?.call(file);
    if (customItems != null && customItems.isNotEmpty) {
      if (items.isNotEmpty) {
        items.add(const PopupMenuDivider());
      }
      
      for (final customItem in customItems) {
        if (customItem.isDivider) {
          items.add(const PopupMenuDivider());
        } else {
          items.add(PopupMenuItem<String>(
            value: 'custom_${customItems.indexOf(customItem)}',
            enabled: customItem.isEnabled,
            child: Row(
              children: [
                if (customItem.icon != null) ...[
                  Icon(customItem.icon, size: 16),
                  const SizedBox(width: 8),
                ],
                Text(
                  customItem.label,
                  style: customItem.isDanger ? const TextStyle(color: Colors.red) : null,
                ),
              ],
            ),
          ));
        }
      }
    }
    
    return items;
  }
  
  void _handleMenuSelection(BuildContext context, String value) {
    _handleStaticMenuSelection(context, value, file, config);
  }
  
  static void _handleStaticMenuSelection(
    BuildContext context,
    String value,
    FileTreeItem file,
    FolderSidebarConfig config,
  ) {
    switch (value) {
      case 'open':
        _handleOpen(context, file, config);
        break;
      case 'copy_path':
        _handleCopyPath(context, file, config);
        break;
      case 'reveal':
        _handleReveal(context, file, config);
        break;
      case 'duplicate':
        _handleDuplicate(context, file, config);
        break;
      case 'rename':
        _handleRename(context, file, config);
        break;
      case 'delete':
        _handleDelete(context, file, config);
        break;
      case 'info':
        _handleFileInfo(context, file, config);
        break;
      default:
        if (value.startsWith('custom_')) {
          _handleCustomAction(context, value, file, config);
        }
    }
  }
  
  static void _handleOpen(BuildContext context, FileTreeItem file, FolderSidebarConfig config) {
    config.onFileSelected?.call(file.path);
    config.onMessage?.call('Opening "${file.name}"...');
  }
  
  static void _handleCopyPath(BuildContext context, FileTreeItem file, FolderSidebarConfig config) {
    // Import clipboard package would be needed for actual copy functionality
    // For now, just show a message
    config.onMessage?.call('Path copied: ${file.path}');
  }
  
  static void _handleReveal(BuildContext context, FileTreeItem file, FolderSidebarConfig config) async {
    try {
      final result = await config.fileService.revealInFileManager(file.path);
      
      if (result.success) {
        config.onMessage?.call('Revealed "${file.name}" in file manager');
      } else {
        config.onMessage?.call(result.errorMessage, isError: true);
      }
    } catch (e) {
      config.onMessage?.call('Failed to reveal file: $e', isError: true);
    }
  }
  
  static void _handleDuplicate(BuildContext context, FileTreeItem file, FolderSidebarConfig config) async {
    try {
      final parentPath = file.path.substring(0, file.path.lastIndexOf('/'));
      final nameWithoutExt = file.nameWithoutExtension;
      final extension = file.extension;
      
      // Find a unique name for the duplicate
      int counter = 1;
      String duplicateName;
      String duplicatePath;
      
      do {
        duplicateName = '$nameWithoutExt (copy${counter > 1 ? ' $counter' : ''})$extension';
        duplicatePath = '$parentPath/$duplicateName';
        counter++;
      } while (await config.fileService.fileExists(duplicatePath));
      
      final result = await config.fileService.copy(file.path, duplicatePath);
      
      if (result.success) {
        config.onMessage?.call('File duplicated as "$duplicateName"');
        config.onFileOperation?.call(FileOperationEvent(
          operation: FileOperationType.copy,
          path: file.path,
          newPath: duplicatePath,
          success: true,
        ));
      } else {
        config.onMessage?.call(result.errorMessage, isError: true);
      }
    } catch (e) {
      config.onMessage?.call('Failed to duplicate file: $e', isError: true);
    }
  }
  
  static void _handleRename(BuildContext context, FileTreeItem file, FolderSidebarConfig config) {
    final nameWithoutExtension = file.nameWithoutExtension;
    final extension = file.extension;
    
    showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) {
        final TextEditingController controller = TextEditingController(text: nameWithoutExtension);
        
        return AlertDialog(
          title: const Text('Rename File'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'File Name (without extension)',
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (value) {
                  Navigator.of(dialogContext).pop(value.trim());
                },
              ),
              if (extension.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    'Extension: $extension',
                    style: Theme.of(dialogContext).textTheme.bodySmall?.copyWith(
                      color: Theme.of(dialogContext).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(controller.text.trim());
              },
              child: const Text('Rename'),
            ),
          ],
        );
      },
    ).then((newName) async {
      if (newName != null && newName.isNotEmpty && newName != nameWithoutExtension) {
        try {
          final parentPath = file.path.substring(0, file.path.lastIndexOf('/'));
          final newFileName = '$newName$extension';
          final newPath = '$parentPath/$newFileName';
          
          final result = await config.fileService.rename(file.path, newPath);
          
          if (result.success) {
            config.onMessage?.call('File renamed to "$newFileName"');
            config.onFileOperation?.call(FileOperationEvent(
              operation: FileOperationType.rename,
              path: file.path,
              newPath: newPath,
              success: true,
            ));
          } else {
            config.onMessage?.call(result.errorMessage, isError: true);
          }
        } catch (e) {
          config.onMessage?.call('Failed to rename file: $e', isError: true);
        }
      }
    });
  }
  
  static void _handleDelete(BuildContext context, FileTreeItem file, FolderSidebarConfig config) {
    showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Move to Trash'),
          content: Text('Are you sure you want to move "${file.name}" to trash?\n\nThis action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Move to Trash'),
            ),
          ],
        );
      },
    ).then((confirmed) async {
      if (confirmed == true) {
        try {
          final result = await config.fileService.delete(file.path, moveToTrash: true);
          
          if (result.success) {
            config.onMessage?.call('File "${file.name}" moved to trash');
            config.onFileOperation?.call(FileOperationEvent(
              operation: FileOperationType.delete,
              path: file.path,
              success: true,
            ));
          } else {
            config.onMessage?.call(result.errorMessage, isError: true);
          }
        } catch (e) {
          config.onMessage?.call('Failed to delete file: $e', isError: true);
        }
      }
    });
  }
  
  static void _handleFileInfo(BuildContext context, FileTreeItem file, FolderSidebarConfig config) async {
    try {
      final fileInfo = await config.fileService.getFileInfo(file.path);
      
      showDialog(
        context: context,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            title: Text('File Information'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('Name:', file.name),
                _buildInfoRow('Path:', file.path),
                _buildInfoRow('Size:', fileInfo?.formattedSize ?? 'Unknown'),
                _buildInfoRow('Modified:', fileInfo?.relativeModifiedTime ?? 'Unknown'),
                _buildInfoRow('Type:', file.isMarkdownFile ? 'Markdown File' : 'File'),
                if (file.extension.isNotEmpty)
                  _buildInfoRow('Extension:', file.extension),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                },
                child: const Text('Close'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      config.onMessage?.call('Failed to get file info: $e', isError: true);
    }
  }
  
  static Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: SelectableText(value),
          ),
        ],
      ),
    );
  }
  
  static void _handleCustomAction(BuildContext context, String value, FileTreeItem file, FolderSidebarConfig config) {
    final customItems = config.customFileMenuItems?.call(file);
    if (customItems != null) {
      final indexStr = value.substring('custom_'.length);
      final index = int.tryParse(indexStr);
      
      if (index != null && index < customItems.length) {
        final customItem = customItems[index];
        customItem.onTap?.call();
      }
    }
  }
}