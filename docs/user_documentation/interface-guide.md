# Interface Guide

This comprehensive guide covers all elements of MDTool's interface, helping you navigate and use every feature effectively.

## Main Window Overview

MDTool's interface is designed for productivity and focus, with clearly defined areas for different tasks:

```
┌─────────────────────────────────────────────────────┐
│ [Menu Bar] - File, Edit, View, Tools, Window, Help │
├─────────────────────────────────────────────────────┤
│ [📁][📄][💾] [B][I][U] [👁️] [🔍] [⚙️] [Chat][AI] │ ← Toolbar
├─────────────────────────────────────────────────────┤
│                 │ Document Tabs                     │
│ Folder          ├─────────────────────────────────│
│ Sidebar         │ #┃Editor Pane     ┃Preview Pane  │
│                 │  ┃                ┃              │
│ 📁 Documents    │  ┃# Heading       ┃# Heading     │
│   📄 readme.md  │  ┃                ┃              │
│   📄 notes.md   │  ┃**Bold text**   ┃**Bold text** │
│ 📁 Projects     │  ┃                ┃              │
│   📄 todo.md    │  ┃- List item     ┃• List item   │
│                 │  ┃                ┃              │
├─────────────────────────────────────────────────────┤
│ Status: Saved │ Words: 150 │ Lines: 45 │ [📊][🤖][⚙️]│ ← Status Bar
└─────────────────────────────────────────────────────┘
```

## Folder Sidebar

The left sidebar is your file navigation center, providing access to all your Markdown documents and folders.

### Sidebar Features

#### Tree Navigation
- **Expandable folders**: Click the triangle to expand/collapse folders
- **Nested structure**: Organize documents in a hierarchical folder structure  
- **Quick access**: Click any file to open it instantly
- **Visual indicators**: Icons distinguish between folders and files

#### Context Menus
**Right-click on folders** for options:
- **New Document** - Create a new .md file in this folder
- **New Folder** - Create a new subfolder
- **Set as Base Folder** - Make this the root folder for navigation
- **Rename** - Rename the folder
- **Reveal in Finder/Explorer** - Open the folder in your system file manager
- **Chat About Folder** - Use AI to discuss folder contents

**Right-click on files** for options:
- **Open in Current Window** - Open the file (same as single-click)
- **Rename** - Rename the file (preserves .md extension)
- **Chat About File** - Use AI to discuss this specific document

#### Sidebar Controls
- **Resize**: Drag the divider between sidebar and main pane
- **Hide/Show**: Toggle sidebar visibility with View > Toggle Sidebar
- **Refresh**: Right-click in empty space > Refresh to reload folder contents

### Setting Your Base Folder
1. Right-click on any folder in the sidebar
2. Select "Set as Base Folder"
3. The sidebar will now show this folder as the root
4. Navigate to parent folders using the breadcrumb bar above

## Toolbar

The toolbar provides quick access to frequently used features and is organized into logical groups.

### File Operations
- **📁 Open Folder** - Set a new base folder for the sidebar
- **📄 New Document** - Create a new Markdown file
- **💾 Save** - Save the current document (also Cmd/Ctrl + S)

### Text Formatting
- **B Bold** - Make selected text bold
- **I Italic** - Make selected text italic  
- **U Underline** - Underline selected text
- **Code** - Format as inline code
- **Quote** - Create a blockquote

### View Controls
- **👁️ Preview Toggle** - Switch between edit and preview modes
- **Split View** - Show editor and preview side-by-side
- **Focus Mode** - Hide sidebar for distraction-free writing

### Tools and Features
- **🔍 Find** - Search within the current document
- **Replace** - Find and replace text
- **Export PDF** - Generate PDF from current document
- **Diff Compare** - Compare document versions

### AI and Chat
- **Chat** - Open AI chat dialog for document assistance
- **AI Settings** - Configure AI services and preferences
- **Context Strategy** - Adjust AI context handling

## Main Content Area

The central area adapts based on your viewing mode and window configuration.

### Editor Mode
**Full editing interface** with:
- **Syntax highlighting**: Markdown syntax is color-coded
- **Line numbers**: Optional line numbering (toggle in preferences)
- **Word wrap**: Text wraps to window width
- **Cursor position**: Show line/column in status bar
- **Indentation guides**: Visual guides for nested lists and code blocks

### Preview Mode  
**Rendered Markdown** showing:
- **Styled headings**: Hierarchical heading styles
- **Formatted text**: Bold, italic, code, and other formatting
- **Interactive links**: Clickable links and references
- **Enhanced tables**: Clean table rendering
- **Code highlighting**: Syntax highlighting in code blocks
- **Diagrams**: Rendered Mermaid diagrams and charts

### Split View
**Side-by-side editing and preview**:
- **Live updates**: Changes in editor immediately appear in preview
- **Synchronized scrolling**: Optional scroll synchronization
- **Adjustable split**: Drag the divider to resize panes
- **Independent navigation**: Each pane can show different content

### Window Tabs
- **Multiple documents**: Each open document appears as a tab
- **Tab management**: Close, rearrange, or detach tabs
- **Unsaved indicators**: Asterisk (*) shows unsaved changes
- **Context menus**: Right-click tabs for additional options

### Window Panes
MDTool supports multiple window panes for advanced workflows:

#### Window Header
Each pane has a header with:
- **Document title**: Shows current file name
- **Modified indicator**: Asterisk for unsaved changes
- **Three-dot menu**: Access to pane-specific options:
  - Chat About This File
  - Export as PDF
  - Close Window

#### Pane Management
- **Create new pane**: File > New Window or detach a tab
- **Arrange panes**: Drag and dock windows as needed
- **Independent content**: Each pane can show different documents
- **Synchronized or independent**: Choose whether panes sync their content

## Status Bar

The bottom status bar provides document information and quick access to tools.

### Document Information (Left Side)
- **Save status**: "Saved", "Saving...", or "Modified"
- **Word count**: Total words in document
- **Line count**: Total lines in document
- **Character count**: Total characters (optional)
- **Current position**: Cursor line and column (in edit mode)

### Feature Access (Right Side)
- **📊 Metrics**: Performance and usage statistics
- **🤖 AI Status**: AI service connection and usage
- **⚙️ Settings**: Quick access to preferences
- **Context Strategy**: Current AI context handling mode
- **Token Usage**: API usage for AI features (when applicable)

## Menu Bar

### File Menu
- **New** (Cmd/Ctrl + N): Create new document
- **Open** (Cmd/Ctrl + O): Open existing file  
- **Open Folder**: Set base folder for sidebar
- **Save** (Cmd/Ctrl + S): Save current document
- **Save As**: Save with new name/location
- **Export PDF**: Generate PDF from current document
- **Recent Files**: Quick access to recently opened documents

### Edit Menu
- **Undo/Redo**: Standard text editing operations
- **Cut/Copy/Paste**: Clipboard operations
- **Find** (Cmd/Ctrl + F): Search within document
- **Find and Replace** (Cmd/Ctrl + H): Find and replace text
- **Select All** (Cmd/Ctrl + A): Select entire document

### View Menu
- **Toggle Sidebar**: Show/hide folder sidebar
- **Toggle Preview**: Switch between edit and preview modes
- **Split View**: Show editor and preview side-by-side
- **Full Screen**: Enter full-screen editing mode
- **Zoom In/Out**: Adjust interface scale
- **Toggle Line Numbers**: Show/hide line numbers in editor

### Tools Menu
- **Compare Documents**: Open diff comparison tool
- **AI Chat**: Open AI assistant dialog
- **Search Across Files**: Search multiple documents
- **Document Statistics**: Detailed document analysis
- **Performance Metrics**: View app performance data

### Window Menu
- **New Window**: Create new MDTool window
- **Close Window**: Close current window
- **Minimize**: Minimize current window
- **Bring All to Front**: Show all MDTool windows

### Help Menu
- **MDTool Help**: Open documentation
- **Keyboard Shortcuts**: View shortcut reference
- **About MDTool**: Version and system information

## Customizing the Interface

### Resizable Elements
- **Sidebar width**: Drag the divider to resize
- **Split pane position**: Adjust editor/preview ratio
- **Window size**: Standard window resizing
- **Tab arrangement**: Drag tabs to reorder

### View Options
**Toolbar visibility**: Toggle toolbar on/off
**Status bar**: Hide/show status information
**Sidebar**: Toggle sidebar visibility
**Line numbers**: Show/hide in editor mode
**Word wrap**: Enable/disable text wrapping

### Theme and Appearance
- **Light/Dark theme**: System preference or manual selection
- **Font selection**: Choose editor and preview fonts
- **Font size**: Adjust text size for better readability
- **Color schemes**: Customize syntax highlighting colors

## Accessibility Features

### Keyboard Navigation
- **Tab navigation**: Use Tab key to navigate interface elements
- **Menu access**: Alt/Option keys access menus
- **Document navigation**: Arrow keys and shortcuts for text navigation
- **Quick actions**: Keyboard shortcuts for all major features

### Screen Reader Support
- **VoiceOver (macOS)**: Full VoiceOver compatibility
- **NVDA/JAWS (Windows)**: Screen reader support
- **Accessible labels**: All interface elements have proper labels
- **Keyboard alternatives**: Non-mouse alternatives for all actions

### Visual Accessibility  
- **High contrast**: Support for high contrast display modes
- **Font scaling**: Respect system font size preferences
- **Focus indicators**: Clear visual focus indicators
- **Color alternatives**: Features don't rely solely on color

## Tips for Efficient Interface Use

### Keyboard-First Workflow
1. **Learn key shortcuts**: Master the essential shortcuts first
2. **Use Command Palette**: Quick access to all features (Cmd/Ctrl + Shift + P)
3. **Tab navigation**: Navigate between interface elements without mouse
4. **Text selection shortcuts**: Efficiently select and manipulate text

### Mouse and Touch
1. **Context menus**: Right-click for context-specific options
2. **Drag and drop**: Move files, resize panes, arrange windows
3. **Toolbar efficiency**: Customize toolbar for your most-used features
4. **Gesture support**: Use trackpad gestures where supported

### Multi-Document Workflows
1. **Tab management**: Keep related documents in tabs
2. **Window splitting**: Use multiple windows for comparison tasks
3. **Quick switching**: Use Cmd/Ctrl + Tab to switch between documents
4. **Sidebar organization**: Organize files logically for quick access