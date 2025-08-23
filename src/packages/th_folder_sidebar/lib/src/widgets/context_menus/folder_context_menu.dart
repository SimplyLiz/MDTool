import 'package:flutter/material.dart';
import '../../models/file_operations.dart';
import '../../models/tree_item.dart';
import '../../config/folder_sidebar_config.dart';

/// Context menu widget for folders
/// Provides standard folder operations and supports custom menu items
class FolderContextMenu extends StatelessWidget {
  final FolderTreeItem folder;
  final FolderSidebarConfig config;
  final VoidCallback? onDismiss;
  
  const FolderContextMenu({
    super.key,
    required this.folder,
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
    required FolderTreeItem folder,
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
      items: _buildStaticMenuItems(context, folder, config),
    ).then((value) {
      if (value != null) {
        _handleStaticMenuSelection(context, value, folder, config);
      }
      onDismiss?.call();
    });
  }
  
  List<PopupMenuEntry<String>> _buildMenuItems(BuildContext context) {
    return _buildStaticMenuItems(context, folder, config);
  }
  
  static List<PopupMenuEntry<String>> _buildStaticMenuItems(
    BuildContext context,
    FolderTreeItem folder,
    FolderSidebarConfig config,
  ) {
    final items = <PopupMenuEntry<String>>[];
    
    // Add default menu items if enabled
    if (config.showDefaultMenuItems) {
      // New Folder
      if (config.allowedOperations.contains(FileOperationType.create)) {
        items.add(PopupMenuItem<String>(
          value: 'new_folder',
          child: Row(
            children: [
              Icon(config.icons.addFolder, size: 16),
              const SizedBox(width: 8),
              const Text('New Folder'),
            ],
          ),
        ));
      }
      
      // New Document
      if (config.allowedOperations.contains(FileOperationType.create)) {
        items.add(PopupMenuItem<String>(
          value: 'new_document',
          child: Row(
            children: [
              Icon(config.icons.addFile, size: 16),
              const SizedBox(width: 8),
              const Text('New Document'),
            ],
          ),
        ));
      }
      
      // Separator
      if (items.isNotEmpty) {
        items.add(const PopupMenuDivider());
      }
      
      // Set as Base Folder
      items.add(PopupMenuItem<String>(
        value: 'set_base_folder',
        child: Row(
          children: [
            Icon(config.icons.folderOpen, size: 16),
            const SizedBox(width: 8),
            const Text('Set as Base Folder'),
          ],
        ),
      ));
      
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
      
      // Refresh
      items.add(PopupMenuItem<String>(
        value: 'refresh',
        child: Row(
          children: [
            Icon(config.icons.refresh, size: 16),
            const SizedBox(width: 8),
            const Text('Refresh'),
          ],
        ),
      ));
      
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
    }
    
    // Add custom menu items if provided
    final customItems = config.customFolderMenuItems?.call(folder);
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
    _handleStaticMenuSelection(context, value, folder, config);
  }
  
  static void _handleStaticMenuSelection(
    BuildContext context,
    String value,
    FolderTreeItem folder,
    FolderSidebarConfig config,
  ) {
    switch (value) {
      case 'new_folder':
        _handleNewFolder(context, folder, config);
        break;
      case 'new_document':
        _handleNewDocument(context, folder, config);
        break;
      case 'set_base_folder':
        _handleSetBaseFolder(context, folder, config);
        break;
      case 'reveal':
        _handleReveal(context, folder, config);
        break;
      case 'rename':
        _handleRename(context, folder, config);
        break;
      case 'refresh':
        _handleRefresh(context, folder, config);
        break;
      case 'delete':
        _handleDelete(context, folder, config);
        break;
      default:
        if (value.startsWith('custom_')) {
          _handleCustomAction(context, value, folder, config);
        }
    }
  }
  
  static void _handleNewFolder(BuildContext context, FolderTreeItem folder, FolderSidebarConfig config) {
    showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) {
        final TextEditingController controller = TextEditingController(text: 'New Folder');
        
        return AlertDialog(
          title: const Text('New Folder'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Folder Name',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (value) {
              Navigator.of(dialogContext).pop(value.trim());
            },
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
              child: const Text('Create'),
            ),
          ],
        );
      },
    ).then((folderName) async {
      if (folderName != null && folderName.isNotEmpty) {
        try {
          final newFolderPath = '${folder.path}/$folderName';
          final result = await config.fileService.createDirectory(newFolderPath);
          
          if (result.success) {
            config.onMessage?.call('Folder "$folderName" created successfully');
            config.onFileOperation?.call(FileOperationEvent(
              operation: FileOperationType.create,
              path: newFolderPath,
              success: true,
            ));
          } else {
            config.onMessage?.call(result.errorMessage, isError: true);
          }
        } catch (e) {
          config.onMessage?.call('Failed to create folder: $e', isError: true);
        }
      }
    });
  }
  
  static void _handleNewDocument(BuildContext context, FolderTreeItem folder, FolderSidebarConfig config) {
    showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) {
        final TextEditingController controller = TextEditingController(text: 'New Document');
        
        return AlertDialog(
          title: const Text('New Document'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Document Name (without extension)',
              border: OutlineInputBorder(),
              helperText: 'Extension .md will be added automatically',
            ),
            onSubmitted: (value) {
              Navigator.of(dialogContext).pop(value.trim());
            },
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
              child: const Text('Create'),
            ),
          ],
        );
      },
    ).then((fileName) async {
      if (fileName != null && fileName.isNotEmpty) {
        try {
          final newFilePath = '${folder.path}/$fileName.md';
          final initialContent = '''# $fileName

Start writing your markdown content here...
''';
          
          final result = await config.fileService.createFile(newFilePath, content: initialContent);
          
          if (result.success) {
            config.onMessage?.call('Document "$fileName.md" created successfully');
            config.onFileOperation?.call(FileOperationEvent(
              operation: FileOperationType.create,
              path: newFilePath,
              success: true,
            ));
            
            // Optionally open the file
            config.onFileSelected?.call(newFilePath);
          } else {
            config.onMessage?.call(result.errorMessage, isError: true);
          }
        } catch (e) {
          config.onMessage?.call('Failed to create document: $e', isError: true);
        }
      }
    });
  }
  
  static void _handleSetBaseFolder(BuildContext context, FolderTreeItem folder, FolderSidebarConfig config) {
    config.stateManager.updateCurrentFolderRoot(folder.path);
    config.onFolderSelected?.call(folder.path);
    config.onMessage?.call('Set "${folder.name}" as base folder');
  }
  
  static void _handleReveal(BuildContext context, FolderTreeItem folder, FolderSidebarConfig config) async {
    try {
      final result = await config.fileService.revealInFileManager(folder.path);
      
      if (result.success) {
        config.onMessage?.call('Revealed "${folder.name}" in file manager');
      } else {
        config.onMessage?.call(result.errorMessage, isError: true);
      }
    } catch (e) {
      config.onMessage?.call('Failed to reveal folder: $e', isError: true);
    }
  }
  
  static void _handleRename(BuildContext context, FolderTreeItem folder, FolderSidebarConfig config) {
    showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) {
        final TextEditingController controller = TextEditingController(text: folder.name);
        
        return AlertDialog(
          title: const Text('Rename Folder'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Folder Name',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (value) {
              Navigator.of(dialogContext).pop(value.trim());
            },
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
      if (newName != null && newName.isNotEmpty && newName != folder.name) {
        try {
          final parentPath = folder.path.substring(0, folder.path.lastIndexOf('/'));
          final newPath = '$parentPath/$newName';
          
          final result = await config.fileService.rename(folder.path, newPath);
          
          if (result.success) {
            config.onMessage?.call('Folder renamed to "$newName"');
            config.onFileOperation?.call(FileOperationEvent(
              operation: FileOperationType.rename,
              path: folder.path,
              newPath: newPath,
              success: true,
            ));
          } else {
            config.onMessage?.call(result.errorMessage, isError: true);
          }
        } catch (e) {
          config.onMessage?.call('Failed to rename folder: $e', isError: true);
        }
      }
    });
  }
  
  static void _handleRefresh(BuildContext context, FolderTreeItem folder, FolderSidebarConfig config) {
    // Clear the folder's loaded state to force refresh
    folder.isLoaded = false;
    folder.children.clear();
    
    config.onMessage?.call('Refreshing "${folder.name}"...');
    config.onFileOperation?.call(FileOperationEvent(
      operation: FileOperationType.read,
      path: folder.path,
      success: true,
    ));
  }
  
  static void _handleDelete(BuildContext context, FolderTreeItem folder, FolderSidebarConfig config) {
    showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Move to Trash'),
          content: Text('Are you sure you want to move "${folder.name}" to trash?\n\nThis action cannot be undone.'),
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
          final result = await config.fileService.delete(folder.path, moveToTrash: true, recursive: true);
          
          if (result.success) {
            config.onMessage?.call('Folder "${folder.name}" moved to trash');
            config.onFileOperation?.call(FileOperationEvent(
              operation: FileOperationType.delete,
              path: folder.path,
              success: true,
            ));
          } else {
            config.onMessage?.call(result.errorMessage, isError: true);
          }
        } catch (e) {
          config.onMessage?.call('Failed to delete folder: $e', isError: true);
        }
      }
    });
  }
  
  static void _handleCustomAction(BuildContext context, String value, FolderTreeItem folder, FolderSidebarConfig config) {
    final customItems = config.customFolderMenuItems?.call(folder);
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