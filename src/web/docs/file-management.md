# File Management

MDTool provides comprehensive file management capabilities through its integrated folder sidebar, file operations, and organizational tools. This guide covers everything from basic file operations to advanced organization strategies.

## Folder Sidebar Overview

The folder sidebar is your primary interface for managing Markdown files and folders. It provides a hierarchical view of your documents with powerful management features.

### Sidebar Navigation
- **Tree structure**: Hierarchical view of folders and files
- **Expandable folders**: Click triangles to expand/collapse folders
- **Quick file access**: Single-click any file to open it
- **Visual indicators**: Different icons for folders and files
- **Sorting options**: Files and folders sorted alphabetically

### Setting Your Base Folder
The base folder determines what appears in your sidebar:

1. **From sidebar**: Right-click any folder → "Set as Base Folder"
2. **From menu**: File → Open Folder
3. **Drag and drop**: Drag a folder onto MDTool window
4. **Recent folders**: Quick access to recently used base folders

## File Operations

### Creating Files and Folders

#### New Documents
**Method 1: Context Menu**
1. Right-click on any folder in the sidebar
2. Select "New Document" 
3. A new file named "New Document.md" is created
4. File opens automatically for editing
5. Use Save As to rename if desired

**Method 2: File Menu**
1. File → New (Cmd/Ctrl + N)
2. Creates new untitled document
3. Use Save (Cmd/Ctrl + S) to save in desired location

**Method 3: Toolbar**
1. Click the "New Document" button in toolbar
2. Same behavior as File menu method

#### New Folders
1. Right-click in sidebar or on existing folder
2. Select "New Folder"
3. Enter folder name in dialog
4. Press Enter or click Create
5. New folder appears and is selected

### Opening Files

#### Multiple Ways to Open
- **Single-click**: Open file in current window
- **Double-click**: Alternative opening method
- **Drag and drop**: Drag .md files onto MDTool window
- **File associations**: Double-click .md files in Finder/Explorer
- **Recent files**: File → Recent Files menu

#### File Confirmation
When opening a file with unsaved changes in the current document:
1. **Save changes dialog** appears with options:
   - **Save**: Save current document and open new file
   - **Discard**: Discard changes and open new file  
   - **Cancel**: Keep current document, don't open new file

### Renaming Files and Folders

#### Renaming Files
1. Right-click on file in sidebar
2. Select "Rename"
3. Edit name in dialog (file extension preserved automatically)
4. Press Enter or click Rename
5. File updates immediately in sidebar

#### Renaming Folders
1. Right-click on folder in sidebar  
2. Select "Rename"
3. Enter new folder name in dialog
4. Press Enter or click Rename
5. Folder and all contents update paths

#### Smart Renaming Features
- **Extension preservation**: File extensions (.md) are automatically maintained
- **Collision detection**: Warns if name already exists
- **Path updates**: All internal references update automatically
- **Undo support**: Rename operations can be undone

### File System Integration

#### Reveal in File Manager
Access files in your system file manager:
1. Right-click any file or folder
2. Select "Reveal in Finder" (macOS) or "Reveal in Explorer" (Windows)
3. File manager opens with item selected
4. Useful for advanced file operations outside MDTool

#### File Associations
MDTool integrates with your operating system for seamless file handling:

**macOS Integration:**
- "Open with MDTool" in Finder context menu
- Set as default application for Markdown files
- Quick Look preview support
- Spotlight search integration

**Windows Integration:**
- "Open with MDTool" in Explorer context menu
- Default program association for .md files
- Windows Search integration
- Thumbnail preview support

## Document Organization

### Folder Structure Best Practices

#### Hierarchical Organization
```
📁 My Documents/
├── 📁 Projects/
│   ├── 📁 Project A/
│   │   ├── 📄 readme.md
│   │   ├── 📄 notes.md
│   │   └── 📄 todo.md
│   └── 📁 Project B/
│       ├── 📄 specification.md
│       └── 📄 progress.md
├── 📁 Personal/
│   ├── 📄 journal.md
│   ├── 📄 ideas.md
│   └── 📁 Travel/
│       ├── 📄 trip-2024.md
│       └── 📄 packing-list.md
└── 📁 Archive/
    └── 📁 Old Projects/
```

#### Naming Conventions
**Files:**
- Use descriptive names: `project-specification.md`
- Include dates when relevant: `meeting-notes-2024-01-15.md`
- Use hyphens instead of spaces: `user-guide.md`
- Keep names concise but clear

**Folders:**
- Use title case: `Project Documents`
- Group by purpose: `Active Projects`, `Archive`, `Templates`
- Avoid deep nesting (3-4 levels maximum)

### Recent Files

#### Accessing Recent Files
- **File menu**: File → Recent Files
- **Quick access**: Recently opened files appear at top of sidebar
- **Cross-session**: Recent files persist between application launches
- **Clear list**: Option to clear recent files list

#### Recent Files Features
- **Last modified date**: Shows when file was last changed
- **Full path**: Tooltip shows complete file path
- **Missing file handling**: Gracefully handles files that have been moved or deleted
- **Configurable limit**: Set maximum number of recent files to remember

### Favorites System

#### Adding Favorites
1. Right-click on any file or folder
2. Select "Add to Favorites" 
3. Item appears in Favorites section of sidebar
4. Quick access regardless of current base folder

#### Managing Favorites
- **Remove**: Right-click favorite → "Remove from Favorites"
- **Reorder**: Drag and drop to reorder favorites
- **Organize**: Create favorite folders for better organization
- **Cross-platform sync**: Favorites sync across devices (if configured)

## Search and Discovery

### File Search
**Search within current folder:**
1. Use search box in sidebar header
2. Type filename or partial filename
3. Results filter in real-time
4. Clear search to return to full view

**Search across all files:**
1. Tools → Search Across Files
2. Enter search terms
3. Results show matching files with context
4. Click result to open file at matching location

### Content Search
**Find in current document:**
- Cmd/Ctrl + F for find dialog
- Search within currently open document
- Navigate between matches

**Find and replace:**
- Cmd/Ctrl + H for find and replace
- Replace single matches or all at once
- Regular expression support

**Global content search:**
- Search text content across all files
- Full-text indexing for fast searches
- Search results show file and line context

## File Monitoring and Updates

### Auto-Refresh
MDTool automatically monitors your file system:
- **New files**: Automatically appear in sidebar
- **Deleted files**: Removed from sidebar immediately  
- **Renamed files**: Updates reflected instantly
- **Folder changes**: Structure updates in real-time

### External Editor Integration
When files are modified by external editors:
- **Change detection**: MDTool detects when files change externally
- **Reload prompt**: Option to reload changed files
- **Conflict resolution**: Handle conflicts between internal and external changes
- **Auto-reload**: Configure automatic reloading of externally changed files

### File Watching
- **Real-time monitoring**: File system changes reflected immediately
- **Performance optimization**: Efficient monitoring without system impact
- **Large folder handling**: Optimized for folders with many files
- **Network drive support**: Works with network-mounted drives

## Advanced File Management

### Bulk Operations
While MDTool focuses on individual file operations, you can perform bulk operations by:
1. Using "Reveal in Finder/Explorer" 
2. Performing bulk operations in file manager
3. Changes automatically reflected in MDTool

### Import and Export

#### Importing Documents
- **Drag and drop**: Drag multiple files into MDTool
- **Copy to folder**: Copy files into your base folder using file manager
- **Import from other formats**: Convert other formats to Markdown

#### Exporting Documents
- **PDF Export**: Export individual documents to PDF
- **Copy to other locations**: Use file manager integration
- **Batch export**: Use external tools for bulk operations

### File Templates
Create and manage document templates:
1. Create template documents in special Templates folder
2. Use "New from Template" option
3. Templates can include:
   - Standard document structure
   - Common metadata
   - Placeholder text
   - Standard formatting

## Performance Considerations

### Large Folder Handling
MDTool is optimized for large collections of files:
- **Lazy loading**: Folders load contents on demand
- **Virtual scrolling**: Efficient display of many files
- **Background indexing**: File indexing happens in background
- **Memory optimization**: Minimal memory usage for file listings

### Network Drives
Working with network-mounted drives:
- **Caching**: Frequently accessed files cached locally
- **Offline mode**: Basic functionality when network unavailable
- **Sync conflict resolution**: Handle sync conflicts gracefully
- **Performance optimization**: Minimize network requests

## Troubleshooting File Operations

### Permission Issues
**macOS:**
- Grant Full Disk Access in System Preferences → Security & Privacy
- Use "Reveal in Finder" for files requiring special permissions
- Check folder permissions in Finder Get Info

**Windows:**
- Run MDTool as Administrator for system folders
- Check folder permissions in Properties → Security
- Verify antivirus isn't blocking file operations

### Common Issues
**Files not appearing:**
- Check if folder is set as base folder correctly
- Verify files have .md extension
- Refresh folder view (right-click → Refresh)

**Can't create files/folders:**
- Check write permissions on target folder
- Ensure adequate disk space
- Verify folder isn't read-only

**Files opening in wrong application:**
- Check file associations in system settings
- Reinstall MDTool file associations
- Use "Open with" → MDTool as temporary solution

## Integration with Version Control

### Git Integration
MDTool works well with Git repositories:
- **Ignore patterns**: .mdtool files can be added to .gitignore
- **File monitoring**: Git operations update sidebar automatically
- **Branch switching**: File changes reflected when switching branches
- **Conflict handling**: External merge tools can be used for conflicts

### Other Version Control
- **SVN**: Similar integration capabilities
- **Manual backup**: Use file manager for manual version control
- **Cloud sync**: Works with Dropbox, OneDrive, iCloud Drive
- **Backup strategies**: Regular backups recommended for important documents

## Tips for Effective File Management

### Organization Strategies
1. **Start simple**: Begin with basic folder structure, expand as needed
2. **Consistent naming**: Develop and stick to naming conventions
3. **Regular cleanup**: Periodically archive old or unused files
4. **Use favorites**: Pin frequently accessed files and folders

### Workflow Optimization
1. **Set logical base folder**: Choose base folder that matches your workflow
2. **Use recent files**: Take advantage of recent files for quick access
3. **Keyboard shortcuts**: Learn shortcuts for common file operations
4. **External tools**: Use file manager for operations MDTool doesn't support

### Backup and Safety
1. **Regular backups**: Keep backups of important documents
2. **Version control**: Use Git or other VCS for important projects
3. **Cloud sync**: Sync important folders to cloud storage
4. **Test recovery**: Periodically test backup and recovery procedures