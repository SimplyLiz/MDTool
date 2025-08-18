import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:cross_file/cross_file.dart';
import 'package:file_picker/file_picker.dart';
import '../widgets/editor_view.dart';
import '../widgets/split_screen_view.dart';
import '../widgets/toolbar.dart';
import '../widgets/status_bar.dart';
import '../widgets/folder_sidebar.dart';
import '../widgets/window_header.dart';
import '../../core/providers/app_state_provider.dart';
import '../../core/providers/preferences_provider.dart';
import '../../core/models/app_state.dart';
import '../../core/models/recent_item.dart';
import '../../core/models/favorite_item.dart';
import '../../core/services/file_service.dart';
import '../../core/services/native_bridge_service.dart';
import '../../core/services/scroll_sync_service.dart';
import '../../core/services/directory_permissions_service.dart';
import 'dart:io';
import 'package:path/path.dart' as path;

class MainPage extends ConsumerStatefulWidget {
  const MainPage({super.key});

  @override
  ConsumerState<MainPage> createState() => _MainPageState();
}

class _MainPageState extends ConsumerState<MainPage> with SingleTickerProviderStateMixin {
  bool _isDragging = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(appStateProvider);
    final preferences = ref.watch(preferencesProvider);
    
    // Initialize ScrollSyncService with preferences - moved outside build cycle
    ref.listen(preferencesProvider, (previous, next) {
      next.whenData((prefs) {
        // Check if both sync modes are enabled (legacy preferences)
        final bothEnabled = prefs.defaultScrollSyncEnabled && prefs.defaultCaretSyncEnabled;
        
        ScrollSyncService().initializeFromPreferences(
          scrollSyncEnabled: prefs.defaultScrollSyncEnabled,
          caretSyncEnabled: prefs.defaultCaretSyncEnabled,
        );
        
        // If we corrected mutual exclusivity, update saved preferences
        if (bothEnabled) {
          Future(() async {
            final preferencesNotifier = ref.read(preferencesProvider.notifier);
            await preferencesNotifier.updatePreferences(prefs.copyWith(
              defaultScrollSyncEnabled: false,
              defaultCaretSyncEnabled: true,
            ));
          });
        }
        
        // Also update the UI state provider
        Future(() {
          final syncStateNotifier = ref.read(syncStateProvider.notifier);
          syncStateNotifier.initializeFromService();
        });
      });
    });
    
    return Scaffold(
      appBar: const MDToolbar(),
      body: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                // Folder Sidebar
                FolderSidebar(
                  isVisible: appState.isFolderSidebarVisible,
                ),
                
                // Main Content Area  
                Expanded(
                  child: DropTarget(
                    onDragEntered: (details) {
                      setState(() {
                        _isDragging = true;
                      });
                    },
                    onDragExited: (details) {
                      setState(() {
                        _isDragging = false;
                      });
                    },
                    onDragDone: (details) {
                      setState(() {
                        _isDragging = false;
                      });
                      _handleDroppedFiles(details.files);
                    },
                    child: DragTarget<String>(
                      onAccept: (filePath) => _handleInternalFileDrop(filePath),
                      onWillAccept: (data) => data != null && data.isNotEmpty,
                      builder: (context, candidateStringData, rejectedStringData) {
                        return Container(
                          decoration: (_isDragging || candidateStringData.isNotEmpty)
                              ? BoxDecoration(
                                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                                  border: Border.all(
                                    color: Theme.of(context).primaryColor,
                                    width: 2,
                                    style: BorderStyle.solid,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                )
                              : null,
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            child: appState.currentFile != null
                                ? (appState.isSplitScreenMode 
                                    ? const SplitScreenView()
                                    : Column(
                                        children: [
                                          WindowHeader(
                                            windowType: appState.isEditMode ? WindowType.editor : WindowType.preview,
                                            activeWindowType: ActiveWindow.primary,
                                            filePath: appState.currentFile,
                                            onOpenFile: () => WindowHeaderActions.openFileDialog(ref),
                                            onNewFile: () => WindowHeaderActions.createNewFile(ref),
                                            onChat: appState.currentFile != null 
                                                ? () => WindowHeaderActions.openChatWithFile(context, appState.currentFile)
                                                : null,
                                            onClose: appState.currentFile != null
                                                ? () => ref.read(appStateProvider.notifier).closeFile()
                                                : null,
                                            onTap: () => ref.read(appStateProvider.notifier).setActiveWindow(ActiveWindow.primary),
                                          ),
                                          Expanded(
                                            child: GestureDetector(
                                              onTap: () => ref.read(appStateProvider.notifier).setActiveWindow(ActiveWindow.primary),
                                              child: const EditorView(),
                                            ),
                                          ),
                                        ],
                                      ))
                                : _buildWelcomeView(ref),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          const StatusBar(),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
            child: Text(
              '© 2025 Tastehub GmbH',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeView(WidgetRef ref) {
    final preferences = ref.watch(preferencesProvider);
    
    return Row(
      children: [
        // Left side - Welcome message and buttons
        Expanded(
          flex: 1,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _isDragging ? Icons.file_upload : Icons.description_outlined,
                  size: 80,
                  color: _isDragging 
                      ? Theme.of(context).primaryColor 
                      : Colors.grey[400],
                ),
                const SizedBox(height: 16),
                TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 800),
                  tween: Tween(begin: 0.0, end: 1.0),
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: 0.5 + (value * 0.5),
                      child: Opacity(
                        opacity: value,
                        child: Text(
                          'MD Tool',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w300,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  _isDragging 
                      ? 'Drop your Markdown file here'
                      : 'Open a Markdown file to get started',
                  style: TextStyle(
                    fontSize: 16,
                    color: _isDragging 
                        ? Theme.of(context).primaryColor 
                        : Colors.grey[600],
                  ),
                ),
                if (!_isDragging) ...[
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: () => _openFileDialog(ref),
                        child: const Text('Open File'),
                      ),
                      const SizedBox(width: 16),
                      OutlinedButton.icon(
                        onPressed: () => WindowHeaderActions.openChatWithoutFile(context),
                        icon: const Icon(Icons.chat, size: 18),
                        label: const Text('Chat'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'or drag and drop a .md file',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        
        // Right side - Recent items (only show on start screen)
        if (!_isDragging) ...[
          Container(
            width: 1,
            height: 400,
            color: Colors.grey[300],
            margin: const EdgeInsets.symmetric(horizontal: 32),
          ),
          Expanded(
            flex: 1,
            child: _buildRecentAndFavoritesView(ref, preferences),
          ),
        ],
      ],
    );
  }

  Widget _buildRecentAndFavoritesView(WidgetRef ref, AsyncValue<dynamic> preferencesAsync) {
    return preferencesAsync.when(
      data: (preferences) {
        return Column(
          children: [
            // Custom segmented control
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).dividerColor.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _tabController.animateTo(0),
                      child: AnimatedBuilder(
                        animation: _tabController,
                        builder: (context, child) {
                          final isSelected = _tabController.index == 0;
                          return Container(
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                            decoration: BoxDecoration(
                              color: isSelected 
                                ? Theme.of(context).colorScheme.primary.withOpacity(0.9)
                                : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                                      blurRadius: 4,
                                      offset: const Offset(0, 1),
                                    ),
                                  ]
                                : null,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.history,
                                  size: 18,
                                  color: isSelected 
                                    ? Theme.of(context).colorScheme.onPrimary
                                    : Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Recent',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                    color: isSelected 
                                      ? Theme.of(context).colorScheme.onPrimary
                                      : Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _tabController.animateTo(1),
                      child: AnimatedBuilder(
                        animation: _tabController,
                        builder: (context, child) {
                          final isSelected = _tabController.index == 1;
                          return Container(
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                            decoration: BoxDecoration(
                              color: isSelected 
                                ? Theme.of(context).colorScheme.primary.withOpacity(0.9)
                                : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                                      blurRadius: 4,
                                      offset: const Offset(0, 1),
                                    ),
                                  ]
                                : null,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.star,
                                  size: 18,
                                  color: isSelected 
                                    ? Theme.of(context).colorScheme.onPrimary
                                    : Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Favorites',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                    color: isSelected 
                                      ? Theme.of(context).colorScheme.onPrimary
                                      : Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Tab view
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildRecentItemsList(ref, preferences),
                  _buildFavoriteItemsList(ref, preferences),
                ],
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, color: Colors.red[400], size: 48),
            const SizedBox(height: 8),
            Text('Failed to load data'),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentItemsList(WidgetRef ref, dynamic preferences) {
    final recentItems = preferences.recentItems as List<RecentItem>;
    
    if (recentItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No Recent Items',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Open files and folders to see them here',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.history, color: Theme.of(context).primaryColor, size: 24),
              const SizedBox(width: 8),
              Text(
                'Recent',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              const Spacer(),
              if (recentItems.isNotEmpty)
                IconButton(
                  icon: Icon(Icons.clear_all, size: 18, color: Colors.grey[600]),
                  onPressed: () => _clearRecentItems(ref),
                  tooltip: 'Clear all recent items',
                ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: recentItems.length,
            itemBuilder: (context, index) {
              final item = recentItems[index];
              return _buildRecentItemTile(ref, item);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFavoriteItemsList(WidgetRef ref, dynamic preferences) {
    final favoriteItems = preferences.favoriteItems as List<FavoriteItem>;
    
    if (favoriteItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.star_outline, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No Favorites',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Bookmark files and folders to see them here',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.star, color: Theme.of(context).primaryColor, size: 24),
              const SizedBox(width: 8),
              Text(
                'Favorites',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              const Spacer(),
              if (favoriteItems.isNotEmpty)
                IconButton(
                  icon: Icon(Icons.clear_all, size: 18, color: Colors.grey[600]),
                  onPressed: () => _clearFavoriteItems(ref),
                  tooltip: 'Clear all favorites',
                ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: favoriteItems.length,
            itemBuilder: (context, index) {
              final item = favoriteItems[index];
              return _buildFavoriteItemTile(ref, item);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRecentItemTile(WidgetRef ref, RecentItem item) {
    final isFile = item.type == RecentItemType.file;
    final icon = isFile ? Icons.description : Icons.folder;
    final subtitle = isFile ? 'File' : 'Folder';
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Icon(icon, color: isFile ? Colors.blue[600] : Colors.amber[700]),
        title: Text(
          item.name,
          style: const TextStyle(fontWeight: FontWeight.w500),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Row(
          children: [
            Flexible(
              child: Text(
                subtitle,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '•',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                _formatDate(item.lastAccessed),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              iconSize: 16,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              padding: const EdgeInsets.all(4),
              icon: Icon(
                ref.watch(preferencesProvider.notifier).isFavorite(item.path) 
                  ? Icons.star 
                  : Icons.star_outline,
                color: ref.watch(preferencesProvider.notifier).isFavorite(item.path) 
                  ? Colors.amber[700] 
                  : Colors.grey[600],
              ),
              onPressed: () => _toggleFavorite(ref, item.path, item.type == RecentItemType.file ? FavoriteItemType.file : FavoriteItemType.folder),
              tooltip: ref.watch(preferencesProvider.notifier).isFavorite(item.path) ? 'Remove from favorites' : 'Add to favorites',
            ),
            IconButton(
              iconSize: 16,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              padding: const EdgeInsets.all(4),
              icon: Icon(Icons.close, color: Colors.grey[600]),
              onPressed: () => _removeRecentItem(ref, item.path),
              tooltip: 'Remove from recent',
            ),
          ],
        ),
        onTap: () => _openRecentItem(ref, item),
      ),
    );
  }

  Widget _buildFavoriteItemTile(WidgetRef ref, FavoriteItem item) {
    final isFile = item.type == FavoriteItemType.file;
    final icon = isFile ? Icons.description : Icons.folder;
    final subtitle = isFile ? 'File' : 'Folder';
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Icon(icon, color: isFile ? Colors.blue[600] : Colors.amber[700]),
        title: Text(
          item.name,
          style: const TextStyle(fontWeight: FontWeight.w500),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Row(
          children: [
            Flexible(
              child: Text(
                subtitle,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '•',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                _formatDate(item.dateAdded),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              iconSize: 16,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              padding: const EdgeInsets.all(4),
              icon: Icon(Icons.star, color: Colors.amber[700]),
              onPressed: () => _removeFavoriteItem(ref, item.path),
              tooltip: 'Remove from favorites',
            ),
          ],
        ),
        onTap: () => _openFavoriteItem(ref, item),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 7) {
      return '${date.day}/${date.month}/${date.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }

  void _handleDroppedFiles(List<XFile> files) async {
    if (files.isEmpty) return;

    final droppedItem = files.first;
    final itemPath = droppedItem.path;
    
    // Only handle files, not directories
    final file = File(itemPath);
    
    try {
      if (await file.exists()) {
        // Handle dropped file
        print('DEBUG: File dropped: $itemPath');
        await _handleDroppedFile(itemPath);
      } else {
        _showErrorDialog('Please drop a Markdown file (.md, .markdown, etc.)');
      }
    } catch (e) {
      print('ERROR: Failed to handle dropped item: $e');
      _showErrorDialog('Failed to handle dropped item: $e');
    }
  }

  Future<void> _handleInternalFileDrop(String filePath) async {
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

  Future<void> _handleDroppedFile(String filePath) async {
    final fileService = FileService();
    if (!fileService.isMarkdownFile(filePath)) {
      _showErrorDialog('Please drop a Markdown file (.md, .markdown, etc.) or a folder containing Markdown files');
      return;
    }

    try {
      final content = await fileService.readFile(filePath);
      ref.read(appStateProvider.notifier).openFile(filePath, content);
    } catch (e) {
      _showErrorDialog('Failed to open file: $e');
    }
  }


  void _openFileDialog(WidgetRef ref) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['md', 'markdown', 'mdown', 'mkd', 'mkdn'],
      );

      if (result != null && result.files.single.path != null) {
        final filePath = result.files.single.path!;
        final fileService = FileService();
        final content = await fileService.readFile(filePath);
        ref.read(appStateProvider.notifier).openFile(filePath, content);
      }
    } catch (e) {
      _showErrorDialog('Failed to open file: $e');
    }
  }

  void _saveFileDialog(WidgetRef ref) async {
    try {
      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Markdown File',
        fileName: 'document.md',
        type: FileType.custom,
        allowedExtensions: ['md', 'markdown'],
      );

      if (outputFile != null) {
        final appState = ref.read(appStateProvider);
        final fileService = FileService();
        await fileService.ensureDirectoryExists(outputFile);
        await fileService.writeFile(outputFile, appState.content);
        ref.read(appStateProvider.notifier).openFile(outputFile, appState.content);
        ref.read(appStateProvider.notifier).saveFile();
      }
    } catch (e) {
      _showErrorDialog('Failed to save file: $e');
    }
  }

  void _openSecondaryFileDialog(WidgetRef ref) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['md', 'markdown', 'mdown', 'mkd', 'mkdn'],
      );

      if (result != null && result.files.single.path != null) {
        final filePath = result.files.single.path!;
        final fileService = FileService();
        final content = await fileService.readFile(filePath);
        ref.read(appStateProvider.notifier).openSecondaryFile(filePath, content);
      }
    } catch (e) {
      _showErrorDialog('Failed to open secondary file: $e');
    }
  }


  void _showQuickLookForCurrentFile(WidgetRef ref) async {
    final appState = ref.read(appStateProvider);
    if (appState.currentFile != null) {
      await NativeBridgeService.showQuickLook(appState.currentFile!);
    }
  }


  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Open a recent item (file or folder)
  void _openRecentItem(WidgetRef ref, RecentItem item) async {
    try {
      if (item.type == RecentItemType.file) {
        // Check if file still exists
        if (!await File(item.path).exists()) {
          _showErrorDialog('File no longer exists: ${item.name}');
          // Remove from recent items
          ref.read(preferencesProvider.notifier).removeRecentItem(item.path);
          return;
        }

        final dirService = await DirectoryPermissionsService.getInstance();
        
        // First check if we can access the file using existing bookmarks
        final canAccess = await dirService.canAccessFile(item.path);
        
        if (canAccess) {
          // We have access, try to read the file
          try {
            final fileService = FileService();
            final content = await fileService.readFile(item.path);
            ref.read(appStateProvider.notifier).openFile(item.path, content);
            return;
          } catch (e) {
            print('Failed to read file even with bookmark access: $e');
          }
        }
        
        // If we don't have access or reading failed, request permission
        final parentDir = path.dirname(item.path);
        
        if (!mounted) return;
        
        final result = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('File Access Required'),
            content: Text(
              'To access "${path.basename(item.path)}", please grant permission to its parent folder:\n\n${path.basename(parentDir)}'
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Grant Access'),
              ),
            ],
          ),
        );
        
        if (result != true) return;
        
        // Request directory access
        final accessGranted = await dirService.requestAccessToDirectory(parentDir);
        
        if (!accessGranted) {
          _showErrorDialog('Access not granted. Unable to open the file.');
          return;
        }
        
        // Try opening the file again with the new access
        try {
          final fileService = FileService();
          final content = await fileService.readFile(item.path);
          ref.read(appStateProvider.notifier).openFile(item.path, content);
        } catch (e2) {
          _showErrorDialog('Unable to access file: ${e2.toString()}');
          // Remove from recent items if still can't access
          ref.read(preferencesProvider.notifier).removeRecentItem(item.path);
        }
      } else {
        // Handle folder opening
        if (!await Directory(item.path).exists()) {
          _showErrorDialog('Folder no longer exists: ${item.name}');
          // Remove from recent items
          ref.read(preferencesProvider.notifier).removeRecentItem(item.path);
          return;
        }

        // Check folder permissions similar to file handling
        final dirService = await DirectoryPermissionsService.getInstance();
        
        // First check if we can access the folder using existing bookmarks
        final canAccess = await dirService.canAccessDirectory(item.path);
        
        if (!canAccess) {
          // Request folder permission
          if (!mounted) return;
          
          final result = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Folder Access Required'),
              content: Text(
                'To access the folder "${path.basename(item.path)}", please grant permission.'
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Grant Access'),
                ),
              ],
            ),
          );
          
          if (result != true) return;
          
          // Request directory access
          final accessGranted = await dirService.requestAccessToDirectory(item.path);
          
          if (!accessGranted) {
            _showErrorDialog('Access not granted. Unable to open the folder.');
            return;
          }
        }

        // Show sidebar if not visible
        final appState = ref.read(appStateProvider);
        if (!appState.isFolderSidebarVisible) {
          ref.read(appStateProvider.notifier).toggleFolderSidebar();
        }
        
        // Wait a moment for sidebar to appear, then trigger folder scanning
        await Future.delayed(const Duration(milliseconds: 200));
        
        // Use the existing dropped folder mechanism to automatically scan the folder
        ref.read(appStateProvider.notifier).setDroppedFolder(item.path);
        
        // Add to recent folders
        if (item.path.trim().isNotEmpty) {
          ref.read(appStateProvider.notifier).addRecentFolder(item.path);
        }
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Opening folder: ${item.name}'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      _showErrorDialog('Failed to open ${item.name}: $e');
    }
  }

  /// Remove a recent item
  void _removeRecentItem(WidgetRef ref, String path) {
    ref.read(preferencesProvider.notifier).removeRecentItem(path);
  }

  /// Clear all recent items
  void _clearRecentItems(WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Recent Items'),
        content: const Text('Are you sure you want to clear all recent items?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(preferencesProvider.notifier).clearRecentItems();
              Navigator.of(context).pop();
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  /// Toggle favorite status for a path
  void _toggleFavorite(WidgetRef ref, String path, FavoriteItemType type) {
    ref.read(preferencesProvider.notifier).toggleFavorite(path, type);
  }

  /// Remove a favorite item
  void _removeFavoriteItem(WidgetRef ref, String path) {
    ref.read(preferencesProvider.notifier).removeFavoriteItem(path);
  }

  /// Clear all favorite items
  void _clearFavoriteItems(WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Favorites'),
        content: const Text('Are you sure you want to clear all favorites?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(preferencesProvider.notifier).clearFavoriteItems();
              Navigator.of(context).pop();
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  /// Open a favorite item (file or folder)
  void _openFavoriteItem(WidgetRef ref, FavoriteItem item) async {
    try {
      if (item.type == FavoriteItemType.file) {
        // Check if file still exists
        if (!await File(item.path).exists()) {
          _showErrorDialog('File no longer exists: ${item.name}');
          // Remove from favorites
          ref.read(preferencesProvider.notifier).removeFavoriteItem(item.path);
          return;
        }

        // Use the same permission handling as recent files
        final dirService = await DirectoryPermissionsService.getInstance();
        
        // First check if we can access the file using existing bookmarks
        final canAccess = await dirService.canAccessFile(item.path);
        
        if (canAccess) {
          // We have access, try to read the file
          try {
            final fileService = FileService();
            final content = await fileService.readFile(item.path);
            ref.read(appStateProvider.notifier).openFile(item.path, content);
            return;
          } catch (e) {
            print('Failed to read favorite file even with bookmark access: $e');
          }
        }
        
        // If we don't have access or reading failed, request permission
        final parentDir = path.dirname(item.path);
        
        if (!mounted) return;
        
        final result = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('File Access Required'),
            content: Text(
              'To access "${path.basename(item.path)}", please grant permission to its parent folder:\n\n${path.basename(parentDir)}'
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Grant Access'),
              ),
            ],
          ),
        );
        
        if (result != true) return;
        
        // Request directory access
        final accessGranted = await dirService.requestAccessToDirectory(parentDir);
        
        if (!accessGranted) {
          _showErrorDialog('Access not granted. Unable to open the file.');
          return;
        }
        
        // Try opening the file again with the new access
        try {
          final fileService = FileService();
          final content = await fileService.readFile(item.path);
          ref.read(appStateProvider.notifier).openFile(item.path, content);
        } catch (e2) {
          _showErrorDialog('Unable to access file: ${e2.toString()}');
          // Remove from favorites if still can't access
          ref.read(preferencesProvider.notifier).removeFavoriteItem(item.path);
        }
      } else {
        // Handle favorite folder opening
        if (!await Directory(item.path).exists()) {
          _showErrorDialog('Folder no longer exists: ${item.name}');
          // Remove from favorites
          ref.read(preferencesProvider.notifier).removeFavoriteItem(item.path);
          return;
        }

        // Check folder permissions similar to file handling
        final dirService = await DirectoryPermissionsService.getInstance();
        
        // First check if we can access the folder using existing bookmarks
        final canAccess = await dirService.canAccessDirectory(item.path);
        
        if (!canAccess) {
          // Request folder permission
          if (!mounted) return;
          
          final result = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Folder Access Required'),
              content: Text(
                'To access the folder "${path.basename(item.path)}", please grant permission.'
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Grant Access'),
                ),
              ],
            ),
          );
          
          if (result != true) return;
          
          // Request directory access
          final accessGranted = await dirService.requestAccessToDirectory(item.path);
          
          if (!accessGranted) {
            _showErrorDialog('Access not granted. Unable to open the folder.');
            return;
          }
        }

        // Show sidebar if not visible
        final appState = ref.read(appStateProvider);
        if (!appState.isFolderSidebarVisible) {
          ref.read(appStateProvider.notifier).toggleFolderSidebar();
        }
        
        // Wait a moment for sidebar to appear, then trigger folder scanning
        await Future.delayed(const Duration(milliseconds: 200));
        
        // Use the existing dropped folder mechanism to automatically scan the folder
        ref.read(appStateProvider.notifier).setDroppedFolder(item.path);
        
        // Add to recent folders
        if (item.path.trim().isNotEmpty) {
          ref.read(appStateProvider.notifier).addRecentFolder(item.path);
        }
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Opening folder: ${item.name}'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      _showErrorDialog('Failed to open ${item.name}: $e');
    }
  }
}