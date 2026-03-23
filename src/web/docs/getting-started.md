# Getting Started with MDTool

This guide will help you get up and running with MDTool in just a few minutes. We'll cover the basics of opening, editing, and previewing Markdown documents.

## Your First Document

### Opening an Existing File
1. **Launch MDTool** from Applications (macOS) or Start Menu (Windows)
2. **Open a file** using any of these methods:
   - **File menu**: File > Open (Cmd/Ctrl + O)
   - **Drag and drop**: Drag a .md file into the MDTool window
   - **File association**: Double-click any Markdown file in Finder/Explorer
   - **Folder sidebar**: Navigate and click on files in the left panel

### Creating a New Document
1. **New document**: File > New (Cmd/Ctrl + N)
2. **Start typing** - MDTool uses standard Markdown syntax
3. **Save your work**: File > Save (Cmd/Ctrl + S)

## Understanding the Interface

### Main Window Layout
MDTool's interface is designed for distraction-free writing:

```
┌─────────────────────────────────────────────────────┐
│ File   Edit   View   Tools          [Window Controls]│
├─────────────────────────────────────────────────────┤
│ [Folder Sidebar] │ [Editor/Preview Pane]           │
│                  │                                 │
│ 📁 Documents     │ # Your Markdown Document        │
│ 📁 Projects      │                                 │
│ 📄 notes.md      │ This is **bold** text          │
│ 📄 todo.md       │                                 │
│                  │ - List item 1                   │
│                  │ - List item 2                   │
├─────────────────────────────────────────────────────┤
│ Status: Ready    │ Words: 23  Lines: 8    [AI] [⚙️]│
└─────────────────────────────────────────────────────┘
```

### Key Areas
- **Folder Sidebar** (left): Navigate your files and folders
- **Editor/Preview** (center): Edit text or view rendered output  
- **Toolbar** (top): Quick access to formatting and tools
- **Status Bar** (bottom): Document stats and feature access

## Basic Editing

### Markdown Syntax Refresher
MDTool supports standard Markdown with syntax highlighting:

```markdown
# Heading 1
## Heading 2

**Bold text** and *italic text*

- Unordered list item
- Another item

1. Ordered list item
2. Another numbered item

[Link text](https://example.com)

`inline code` and:

```
code blocks
```

> Blockquote text
```

### Live Preview
- **Split view**: See your edits rendered in real-time
- **Toggle preview**: Click the preview button in the toolbar
- **Preview-only mode**: Focus on the rendered output

## Essential Features

### Auto-Save
MDTool automatically saves your work every few seconds. You'll see:
- **Status indicator**: "Saved" appears in the status bar
- **Unsaved changes**: An asterisk (*) next to the filename when there are unsaved changes
- **Save confirmation**: MDTool asks before closing unsaved documents

### File Navigation
Use the **folder sidebar** to organize your documents:
- **Set base folder**: Right-click any folder > "Set as Base Folder"
- **Create new files**: Right-click in a folder > "New Document"
- **Create folders**: Right-click > "New Folder"
- **Quick switching**: Click any file to open it instantly

### Search and Find
- **Find in document**: Cmd/Ctrl + F
- **Find and replace**: Cmd/Ctrl + H
- **Search across files**: Use the search tools in the toolbar

## Keyboard Shortcuts

### Essential Shortcuts
| Action | macOS | Windows |
|--------|-------|---------|
| New document | Cmd + N | Ctrl + N |
| Open file | Cmd + O | Ctrl + O |
| Save | Cmd + S | Ctrl + S |
| Find | Cmd + F | Ctrl + F |
| Find & Replace | Cmd + H | Ctrl + H |
| Preview toggle | Cmd + P | Ctrl + P |
| Bold text | Cmd + B | Ctrl + B |
| Italic text | Cmd + I | Ctrl + I |

### Advanced Shortcuts
| Action | macOS | Windows |
|--------|-------|---------|
| Export PDF | Cmd + E | Ctrl + E |
| AI Chat | Cmd + K | Ctrl + K |
| Preferences | Cmd + , | Ctrl + , |
| Full screen | Cmd + Ctrl + F | F11 |

## Working with Multiple Documents

### Tabs and Windows
- **Multiple tabs**: Each document opens in its own tab
- **New window**: File > New Window for side-by-side editing
- **Window management**: Drag tabs to create new windows

### Comparing Documents
- **Diff view**: Tools > Compare Documents
- **Version comparison**: Compare different versions of the same file
- **Side-by-side**: View changes highlighted in different colors

## Quick Tips for New Users

### 1. Set Up Your Workspace
- Choose a base folder for your documents
- Create a folder structure that makes sense for your work
- Pin frequently used files using the favorites feature

### 2. Customize Your Experience
- Go to Preferences (Cmd/Ctrl + ,) to adjust:
  - Font size and family
  - Theme (light/dark)
  - Auto-save frequency
  - Preview behavior

### 3. Learn the Markdown Extensions
MDTool supports enhanced Markdown features:
- **Mermaid diagrams**: Create flowcharts and diagrams
- **Math equations**: Use LaTeX-style math notation
- **Tables**: Enhanced table editing and rendering
- **Code highlighting**: Syntax highlighting for many languages

### 4. Explore AI Features
If you have AI configured:
- **Chat about documents**: Get help with writing and editing
- **Content generation**: Generate outlines, summaries, and more
- **Smart suggestions**: Context-aware writing assistance

## Common First-Day Tasks

### Task 1: Import Your Existing Notes
1. Create a new folder for your imported documents
2. Copy your existing .md files into this folder
3. Set it as your base folder in MDTool
4. Browse and organize using the folder sidebar

### Task 2: Create Your First Document
1. File > New (Cmd/Ctrl + N)
2. Add a title: `# My First MDTool Document`
3. Write a few paragraphs using Markdown syntax
4. Save the document (Cmd/Ctrl + S)
5. Toggle to preview mode to see the rendered output

### Task 3: Try the Advanced Features
1. **Export to PDF**: Tools > Export PDF
2. **AI Chat**: Try asking questions about your document
3. **Create a diagram**: Add a Mermaid flowchart
4. **Compare versions**: Make edits and use the diff viewer

## What's Next?

Now that you're familiar with the basics:

- **[Interface Guide](interface-guide.md)** - Learn about all the interface elements
- **[Editing Features](editing-features.md)** - Master the editing tools
- **[File Management](file-management.md)** - Organize your documents effectively
- **[Advanced Features](advanced-features.md)** - Explore AI, PDF export, and more

## Need Help?

- **In-app help**: Press F1 or check the Help menu
- **Troubleshooting**: See [Troubleshooting Guide](troubleshooting.md)
- **Keyboard shortcuts**: Help > Keyboard Shortcuts