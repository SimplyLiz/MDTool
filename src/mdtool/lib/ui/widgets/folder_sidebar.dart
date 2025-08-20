import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import 'dart:async';
import 'package:file_picker/file_picker.dart';
import '../../core/providers/app_state_provider.dart';
import '../../core/providers/preferences_provider.dart';
import '../../core/services/file_service.dart';
import '../../core/services/directory_permissions_service.dart';
import '../../core/services/folder_index_service.dart';
import '../../core/models/folder_metadata.dart';
import '../../core/providers/folder_state_provider.dart';

/// High-performance, virtualized folder sidebar optimized for large file counts
/// Uses lazy loading, virtualization, and efficient tree rendering
class FolderSidebar extends ConsumerStatefulWidget {
  final bool isVisible;

  const FolderSidebar({super.key, required this.isVisible});

  @override
  ConsumerState<FolderSidebar> createState() => _FolderSidebarState();
}

class _FolderSidebarState extends ConsumerState<FolderSidebar> {
  final TreeController _treeController = TreeController();
  bool _isLoading = false;
  String? _currentDirectory;
  int? _lastFolderPickerRequestId;
  
  // Virtualization support
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _listKey = GlobalKey();
  
  // Folder indexing
  final FolderIndexService _folderIndexService = FolderIndexService.instance;
  StreamSubscription<FolderScanProgress>? _scanProgressSubscription;
  
  // Selection state
  String? _selectedItemPath;
  
  
  @override
  void dispose() {
    _scrollController.dispose();
    _scanProgressSubscription?.cancel();
    super.dispose();
  }
  
  @override
  void initState() {
    super.initState();
    _setupScanProgressListener();
  }
  
  void _setupScanProgressListener() {
    _scanProgressSubscription = _folderIndexService.progressStream.listen(
      (progress) {
        if (!mounted) return;
        
        // Update UI based on scan progress
        if (progress.status == FolderScanStatus.completed) {
          setState(() {
            // Refresh tree with updated metadata
            _refreshTreeWithMetadata();
          });
        }
      },
    );
  }
  
  Future<void> _refreshTreeWithMetadata() async {
    // Update existing tree items with fresh metadata from the cache
    final flattenedItems = _treeController.getFlattenedVisibleItems();
    for (final item in flattenedItems) {
      if (item is FolderTreeItem) {
        final metadata = await _folderIndexService.getCachedMetadata(item.path);
        if (metadata != null) {
          item.fileCount = metadata.markdownFileCount;
        }
      }
    }
  }
  
  /// Trigger quick scan for a folder to populate provider cache with file counts
  void _triggerQuickScanForFolder(String folderPath) {
    // Use fire-and-forget quick scan to populate the provider cache
    // This ensures folders show file counts even when collapsed
    _folderIndexService.quickScan(folderPath).then((_) {
      // Success - metadata is now cached for the provider
    }).catchError((error) {
      // Ignore errors from quick scans - they're just for display enhancement
      debugPrint('Quick scan failed for $folderPath: $error');
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(appStateProvider, (previous, current) {
      if (previous?.currentFile != current.currentFile) {
        final currentFile = current.currentFile;
        if (currentFile != null) {
          final fileDirectory = currentFile.substring(0, currentFile.lastIndexOf('/'));
          
          // Check if auto-navigation is enabled
          final preferences = ref.read(preferencesProvider).valueOrNull;
          final autoNavigate = preferences?.autoNavigateToFileFolder ?? false;
          
          // Auto-navigate to file's directory if enabled, different from current, and no explicit folder root
          if (autoNavigate && _currentDirectory != fileDirectory && current.currentFolderRoot == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _scanForMarkdownFiles(directoryPath: fileDirectory);
            });
          }
        }
      }
      
      // Handle folder picker requests from toolbar
      if (previous?.folderPickerRequestId != current.folderPickerRequestId) {
        _handleFolderPickerRequest(current.folderPickerRequestId);
      }
      
      // Handle dropped folders
      if (previous?.droppedFolder != current.droppedFolder && 
          current.droppedFolder != null && 
          current.droppedFolder!.isNotEmpty) {
        _handleDroppedFolder(current.droppedFolder!);
      }
    });

    if (!widget.isVisible) return const SizedBox.shrink();

    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(right: BorderSide(color: Theme.of(context).dividerColor, width: 1)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4, offset: const Offset(2, 0))],
      ),
      child: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : _buildVirtualizedTree(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Row(
        children: [
          Icon(Icons.folder_open, color: Colors.orange, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Markdown Files',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)
            ),
          ),
          IconButton(
            icon: const Icon(Icons.create_new_folder, size: 18),
            tooltip: 'Add Folder',
            onPressed: _pickFolder,
          ),
          IconButton(
            icon: const Icon(Icons.refresh, size: 18), 
            onPressed: _scanForMarkdownFiles, 
            tooltip: 'Refresh'
          ),
        ],
      ),
    );
  }
  
  /// Build virtualized tree using ListView.builder for optimal performance
  Widget _buildVirtualizedTree() {
    final flattenedItems = _treeController.getFlattenedVisibleItems();
    
    if (flattenedItems.isEmpty) {
      return _buildEmptyState();
    }
    
    return ListView.builder(
      key: _listKey,
      controller: _scrollController,
      itemCount: flattenedItems.length,
      // Optimize item extent for better scrolling performance
      itemExtent: 40.0, // Fixed height for consistency
      itemBuilder: (context, index) {
        final item = flattenedItems[index];
        return _buildTreeItem(item, index);
      },
    );
  }
  
  Widget _buildTreeItem(TreeItem item, int index) {
    switch (item.type) {
      case TreeItemType.folder:
        return _buildFolderItem(item as FolderTreeItem);
      case TreeItemType.file:
        return _buildFileItem(item as FileTreeItem);
    }
  }
  
  Widget _buildFolderItem(FolderTreeItem folder) {
    // Use efficient provider pattern instead of nested FutureBuilders
    return Consumer(
      builder: (context, ref, child) {
        final folderStateAsync = ref.watch(individualFolderStateProvider(folder.path));
        
        return folderStateAsync.when(
          data: (folderState) => _buildFolderItemContent(folder, folderState),
          loading: () => _buildFolderItemContent(folder, const FolderState()),
          error: (error, stack) => _buildFolderItemContent(folder, const FolderState()),
        );
      },
    );
  }
  
  Widget _buildFolderItemContent(FolderTreeItem folder, FolderState folderState) {
    final metadata = folderState.metadata;
    final isScanning = folderState.isScanning;
    final scanProgress = folderState.scanProgress;
    
    String? subtitleText;
    if (isScanning && scanProgress != null) {
      if (scanProgress.totalFolders > 0) {
        final percentage = (scanProgress.progress * 100).toStringAsFixed(0);
        subtitleText = 'Scanning… $percentage%';
      } else {
        subtitleText = 'Scanning…';
      }
    } else if (metadata != null) {
      subtitleText = metadata.detailedCountDisplayText;
    } else if (folder.isLoaded) {
      subtitleText = '${folder.fileCount} markdown files';
    } else if (folder.fileCount > 0) {
      // Show file count from quick scan even if folder isn't fully loaded
      subtitleText = '${folder.fileCount} markdown files';
    }
    
    return GestureDetector(
      onTap: () => _toggleFolder(folder),
      onSecondaryTapUp: (details) => _showFolderContextMenu(context, folder, details.globalPosition),
      child: ListTile(
        key: ValueKey('folder_${folder.path}'),
        dense: true,
        contentPadding: EdgeInsets.only(left: 16 + folder.depth * 16.0, right: 16),
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: () => _toggleFolder(folder),
              child: Icon(
                folder.isExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right,
                size: 16,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(width: 4),
            Stack(
              children: [
                Icon(
                  folder.isExpanded ? Icons.folder_open : Icons.folder,
                  color: Colors.amber[700],
                  size: 16,
                ),
                if (isScanning)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
        title: Text(
          folder.name,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w500,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        subtitle: subtitleText != null 
          ? Text(
              subtitleText, 
              style: TextStyle(
                fontSize: 11, 
                color: isScanning ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                fontStyle: isScanning ? FontStyle.italic : FontStyle.normal,
              )
            )
          : null,
        selected: _selectedItemPath == folder.path,
        selectedTileColor: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.2),
      ),
    );
  }
  
  Widget _buildFileItem(FileTreeItem file) {
    final appState = ref.watch(appStateProvider);
    final isCurrentFile = appState.currentFile == file.path;
    final isSelected = _selectedItemPath == file.path;
    
    return Draggable<String>(
      data: file.path,
      feedback: Material(
        elevation: 4.0,
        child: Container(
          width: 200,
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.description,
                size: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  file.name,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.5,
        child: _buildFileListTile(file, isCurrentFile, isSelected),
      ),
      child: GestureDetector(
        onTap: () => _selectItem(file.path),
        onDoubleTap: () => _openFile(file.path),
        onSecondaryTapUp: (details) => _showFileContextMenu(context, file, details.globalPosition),
        child: _buildFileListTile(file, isCurrentFile, isSelected),
      ),
    );
  }
  
  Widget _buildFileListTile(FileTreeItem file, bool isCurrentFile, bool isSelected) {
    return ListTile(
      key: ValueKey('file_${file.path}'),
      dense: true,
      contentPadding: EdgeInsets.only(left: 16 + file.depth * 16.0 + 16.0, right: 16),
      leading: Icon(
        Icons.description, 
        size: 16, 
        color: isCurrentFile ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)
      ),
      title: Text(
        file.name,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          fontWeight: isCurrentFile ? FontWeight.w600 : FontWeight.normal, 
          color: isCurrentFile ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface,
        ),
      ),
      selected: isSelected,
      selectedTileColor: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
      tileColor: isSelected ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.1) : null,
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_open, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text('No directory selected', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 14)),
          const SizedBox(height: 8),
          Text(
            'Open a markdown file or select a folder to explore',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 12),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _pickFolder,
            icon: const Icon(Icons.folder_open, size: 18),
            label: const Text('Choose Folder'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
            ),
          ),
        ],
      ),
    );
  }
  
  /// Toggle folder expansion, loading contents if needed
  Future<void> _toggleFolder(FolderTreeItem folder) async {
    // If folder is not loaded, load contents first
    if (!folder.isLoaded) {
      await _loadFolderContents(folder);
    }
    
    // Toggle expansion state and trigger rebuild
    setState(() {
      _treeController.toggleExpansion(folder);
    });
  }
  
  /// Lazy load folder contents on-demand with progress updates
  Future<void> _loadFolderContents(FolderTreeItem folder) async {
    // Don't load if already loading or loaded
    if (folder.isLoading || folder.isLoaded) return;
    
    try {
      final preferences = ref.read(preferencesProvider).value;
      final shouldFilter = preferences?.filterDirectories ?? false;
      
      // Set loading state immediately and trigger rebuild
      if (mounted) {
        setState(() {
          folder.isLoading = true;
        });
      }
      
      // Use folder index service for efficient scanning
      // Force a full scan (not quickScan) to get actual file/folder lists
      final metadata = await _folderIndexService.getFolderMetadata(
        folder.path,
        shouldFilter: shouldFilter,
        forceRefresh: true, // Force full scan to get subfolders/markdownFiles lists
      );
      
      
      // Convert metadata to tree items
      final contents = <TreeItem>[];
      
      // Add subfolders
      for (final subfolderMeta in metadata.subfolders) {
        final subfolderItem = FolderTreeItem(
          name: subfolderMeta.name,
          path: subfolderMeta.path,
          depth: folder.depth + 1,
          fileCount: subfolderMeta.markdownFileCount,
        );
        contents.add(subfolderItem);
        
        // Trigger quick scan for immediate file count display in provider
        // Schedule outside of setState to avoid provider conflicts
        Future(() => _triggerQuickScanForFolder(subfolderItem.path));
      }
      
      // Add markdown files
      for (final fileMeta in metadata.markdownFiles) {
        final fileItem = FileTreeItem(
          name: fileMeta.name,
          path: fileMeta.path,
          depth: folder.depth + 1,
        );
        contents.add(fileItem);
      }
      
      // Update UI only if widget is still mounted
      if (mounted) {
        setState(() {
          folder.children.clear();
          folder.children.addAll(contents);
          
          // Set correct depth for all children
          for (final child in contents) {
            child.depth = folder.depth + 1;
            if (child is FolderTreeItem) {
              _updateChildDepths(child, child.depth);
            }
          }
          
          folder.isLoaded = true;
          folder.isLoading = false;
          folder.fileCount = metadata.markdownFileCount;
          
        });
      }
    } catch (e) {
      debugPrint('Error loading folder ${folder.path}: $e');
      // Ensure folder is marked as loaded even on error to prevent infinite loading
      if (mounted) {
        setState(() {
          folder.isLoaded = true;
          folder.isLoading = false;
          folder.children.clear(); // Clear any partial content
        });
      }
    }
  }
  

  /// Recursively update depths for all child items
  void _updateChildDepths(FolderTreeItem folder, int depth) {
    for (final child in folder.children) {
      child.depth = depth + 1;
      if (child is FolderTreeItem) {
        _updateChildDepths(child, child.depth);
      }
    }
  }

  
  
  
  
  Future<void> _scanForMarkdownFiles({String? directoryPath}) async {
    setState(() => _isLoading = true);
    
    try {
      String searchDirectory;
      
      if (directoryPath != null) {
        // Use the provided directory as the new root
        searchDirectory = directoryPath;
      } else {
        final appState = ref.read(appStateProvider);
        // If we have a current folder root, always use that instead of file's parent
        if (appState.currentFolderRoot != null) {
          searchDirectory = appState.currentFolderRoot!;
        } else if (appState.currentFile != null) {
          final file = File(appState.currentFile!);
          searchDirectory = file.parent.path;
        } else {
          setState(() => _isLoading = false);
          return;
        }
      }
      
      _currentDirectory = searchDirectory;
      final preferences = ref.read(preferencesProvider).value;
      final shouldFilter = preferences?.filterDirectories ?? false;
      
      // Set up active root watcher and scan
      await _folderIndexService.setActiveRoot(searchDirectory);
      
      // Use folder index service for efficient scanning
      final metadata = await _folderIndexService.getFolderMetadata(
        searchDirectory,
        shouldFilter: shouldFilter,
        forceRefresh: true, // Force refresh for root scan
      );
      
      // Create a single root folder item that contains everything
      final rootFolderName = searchDirectory.split('/').last;
      final rootFolderItem = FolderTreeItem(
        name: rootFolderName,
        path: searchDirectory,
        depth: 0,
        fileCount: metadata.markdownFileCount,
        isExpanded: true, // Start expanded to show contents
        isLoaded: true,   // Mark as loaded since we have the metadata
      );
      
      // Add subfolders to the root folder
      for (final subfolderMeta in metadata.subfolders) {
        final subfolderItem = FolderTreeItem(
          name: subfolderMeta.name,
          path: subfolderMeta.path,
          depth: 1,
          fileCount: subfolderMeta.markdownFileCount,
        );
        rootFolderItem.children.add(subfolderItem);
        
        // Trigger quick scan for immediate file count display in provider
        // Schedule outside of setState to avoid provider conflicts
        Future(() => _triggerQuickScanForFolder(subfolderItem.path));
      }
      
      // Add markdown files to the root folder
      for (final fileMeta in metadata.markdownFiles) {
        final fileItem = FileTreeItem(
          name: fileMeta.name,
          path: fileMeta.path,
          depth: 1,
        );
        rootFolderItem.children.add(fileItem);
      }
      
      // Update the app state with the current folder root
      ref.read(appStateProvider.notifier).setCurrentFolderRoot(searchDirectory);
      
      setState(() {
        _treeController.setRootItems([rootFolderItem]);
        _isLoading = false;
      });
      
      // Add to recent folders if this was a manually selected directory (not from current file)
      if (directoryPath != null && searchDirectory.trim().isNotEmpty) {
        ref.read(appStateProvider.notifier).addRecentFolder(searchDirectory);
      }
    } catch (e) {
      debugPrint('Error scanning for markdown files: $e');
      setState(() => _isLoading = false);
    }
  }
  
  Future<void> _pickFolder() async {
    try {
      // Determine starting directory from current file
      String? initialDirectory;
      final appState = ref.read(appStateProvider);
      if (appState.currentFile != null) {
        final file = File(appState.currentFile!);
        initialDirectory = file.parent.path;
      }
      
      String? pickedPath;
      if (Platform.isMacOS) {
        final dps = await DirectoryPermissionsService.getInstance();
        final dirs = await dps.pickDirectories(allowMultiple: false);
        
        if (dirs.isEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('No folder was selected'))
            );
          }
          return;
        }
        
        pickedPath = dirs.first.path;
      } else {
        pickedPath = await FilePicker.platform.getDirectoryPath(
          dialogTitle: 'Choose a folder to scan',
          initialDirectory: initialDirectory,
        );
      }
      
      if (pickedPath == null) {
        return;
      }
      
      await _scanForMarkdownFiles(directoryPath: pickedPath);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Scanning folder: ${pickedPath.split('/').last}'))
        );
      }
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to select folder: $e')));
      }
    }
  }
  
  Future<void> _openFile(String filePath) async {
    try {
      final fileService = FileService();
      final content = await fileService.readFile(filePath);
      ref.read(appStateProvider.notifier).openFile(filePath, content);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to open file: $e'))
        );
      }
    }
  }
  
  void _selectItem(String itemPath) {
    setState(() {
      _selectedItemPath = itemPath;
    });
  }
  
  void _showFolderContextMenu(BuildContext context, FolderTreeItem folder, Offset position) {
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx + 1,
        position.dy + 1,
      ),
      items: [
        PopupMenuItem(
          child: Row(
            children: [
              Icon(Icons.folder_open, size: 16),
              SizedBox(width: 8),
              Text('Set as Base Folder'),
            ],
          ),
          onTap: () => _setAsBaseFolder(folder.path),
        ),
        PopupMenuItem(
          child: Row(
            children: [
              Icon(Icons.delete_outline, size: 16, color: Colors.red),
              SizedBox(width: 8),
              Text('Move to Trash', style: TextStyle(color: Colors.red)),
            ],
          ),
          onTap: () => _deleteFolder(folder.path),
        ),
        PopupMenuItem(
          child: Row(
            children: [
              Icon(Icons.chat, size: 16),
              SizedBox(width: 8),
              Text('Chat About Folder'),
            ],
          ),
          onTap: () => _chatAboutFolder(folder.path),
        ),
      ],
    );
  }
  
  void _showFileContextMenu(BuildContext context, FileTreeItem file, Offset position) {
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx + 1,
        position.dy + 1,
      ),
      items: [
        PopupMenuItem(
          child: Row(
            children: [
              Icon(Icons.open_in_new, size: 16),
              SizedBox(width: 8),
              Text('Open in Current Window'),
            ],
          ),
          onTap: () => _openFile(file.path),
        ),
        PopupMenuItem(
          child: Row(
            children: [
              Icon(Icons.delete_outline, size: 16, color: Colors.red),
              SizedBox(width: 8),
              Text('Move to Trash', style: TextStyle(color: Colors.red)),
            ],
          ),
          onTap: () => _deleteFile(file.path),
        ),
        PopupMenuItem(
          child: Row(
            children: [
              Icon(Icons.chat, size: 16),
              SizedBox(width: 8),
              Text('Chat About File'),
            ],
          ),
          onTap: () => _chatAboutFile(file.path),
        ),
      ],
    );
  }
  
  void _setAsBaseFolder(String folderPath) {
    _scanForMarkdownFiles(directoryPath: folderPath);
  }
  
  void _deleteFolder(String folderPath) {
    // TODO: Implement folder deletion (move to trash)
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Folder deletion not yet implemented'))
      );
    }
  }
  
  void _deleteFile(String filePath) {
    // TODO: Implement file deletion (move to trash)
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('File deletion not yet implemented'))
      );
    }
  }
  
  void _chatAboutFolder(String folderPath) {
    // TODO: Implement chat about folder functionality
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Chat about folder not yet implemented'))
      );
    }
  }
  
  void _chatAboutFile(String filePath) {
    // TODO: Implement chat about file functionality
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Chat about file not yet implemented'))
      );
    }
  }
  
  void _handleFolderPickerRequest(int? requestId) {
    if (requestId == null || _lastFolderPickerRequestId == requestId) {
      return;
    }
    
    _lastFolderPickerRequestId = requestId;
    
    // Trigger folder picker
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pickFolder();
    });
  }

  void _handleDroppedFolder(String folderPath) {
    // Scan the dropped folder
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scanForMarkdownFiles(directoryPath: folderPath);
      
      // Clear the dropped folder state after scanning is initiated
      ref.read(appStateProvider.notifier).clearDroppedFolder();
    });
  }
  
}

/// Efficient tree controller for managing large hierarchical data
class TreeController {
  final List<TreeItem> _rootItems = [];
  
  void setRootItems(List<TreeItem> items) {
    _rootItems.clear();
    _rootItems.addAll(items);
    _updateDepths();
  }
  
  void toggleExpansion(FolderTreeItem folder) {
    folder.isExpanded = !folder.isExpanded;
  }
  
  /// Get flattened list of only visible items for virtualization
  List<TreeItem> getFlattenedVisibleItems() {
    final result = <TreeItem>[];
    _flattenVisible(_rootItems, result, 0);
    return result;
  }
  
  void _flattenVisible(List<TreeItem> items, List<TreeItem> result, int depth) {
    for (final item in items) {
      item.depth = depth;
      result.add(item);
      
      if (item is FolderTreeItem && item.isExpanded) {
        _flattenVisible(item.children, result, depth + 1);
      }
    }
  }
  
  void _updateDepths() {
    _updateItemDepths(_rootItems, 0);
  }
  
  void _updateItemDepths(List<TreeItem> items, int depth) {
    for (final item in items) {
      item.depth = depth;
      if (item is FolderTreeItem) {
        _updateItemDepths(item.children, depth + 1);
      }
    }
  }
}

/// Base class for tree items
abstract class TreeItem {
  final String name;
  final String path;
  int depth;
  TreeItemType get type;
  
  TreeItem({required this.name, required this.path, this.depth = 0});
}

/// Folder tree item with lazy loading support
class FolderTreeItem extends TreeItem {
  bool isExpanded;
  bool isLoaded;
  bool isLoading;
  int fileCount;
  final List<TreeItem> children = [];
  
  @override
  TreeItemType get type => TreeItemType.folder;
  
  FolderTreeItem({
    required super.name,
    required super.path,
    super.depth,
    this.isExpanded = false,
    this.isLoaded = false,
    this.isLoading = false,
    this.fileCount = 0,
  });
}

/// File tree item
class FileTreeItem extends TreeItem {
  @override
  TreeItemType get type => TreeItemType.file;
  
  FileTreeItem({
    required super.name,
    required super.path,
    super.depth,
  });
}

enum TreeItemType { folder, file }