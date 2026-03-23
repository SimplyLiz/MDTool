# Preferences and Settings

MDTool offers extensive customization options through its preferences system. This guide covers all settings categories, helping you tailor the application to your specific workflow and preferences.

## Accessing Preferences

### Opening Preferences
- **macOS**: MDTool → Preferences or Cmd + ,
- **Windows**: File → Preferences or Ctrl + ,
- **Toolbar**: Click the settings gear icon in the toolbar
- **Status bar**: Click the settings icon in the status bar

### Preferences Organization
Preferences are organized into logical categories:
- **General**: Core application behavior
- **Editor**: Text editing and display settings
- **Preview**: Markdown rendering preferences
- **AI Settings**: AI service configuration
- **Files**: File handling and auto-save options
- **Appearance**: Themes and visual customization
- **Performance**: Optimization and resource settings
- **Advanced**: Developer and power-user options

## General Preferences

### Application Behavior
**Startup Options:**
- **Restore previous session**: Reopen documents from last session
- **Start with new document**: Always create blank document on startup
- **Show welcome screen**: Display welcome dialog on first launch
- **Check for updates**: Automatic update checking frequency

**Window Management:**
- **Single window mode**: Force all documents into one window
- **Remember window positions**: Save window positions between sessions
- **Native window controls**: Use system window decorations
- **Menu bar visibility**: Show/hide menu bar (Windows/Linux)

### Default Locations
**File Paths:**
- **Default save location**: Where new documents are saved by default
- **Base folder**: Default folder for file sidebar
- **Recent files limit**: Maximum number of recent files to remember
- **Backup location**: Where auto-backups are stored

**Export Defaults:**
- **PDF export location**: Default folder for PDF exports
- **Image export format**: Default format for exported images
- **Export quality settings**: Default quality for various export formats

## Editor Preferences

### Text Display
**Font Settings:**
- **Font family**: Choose from system fonts or custom fonts
- **Font size**: Text size in editor (8pt to 72pt)
- **Line height**: Spacing between lines (1.0x to 3.0x)
- **Character spacing**: Letter spacing adjustment
- **Ligature support**: Enable programming font ligatures

**Visual Elements:**
- **Line numbers**: Show/hide line numbers with optional relative numbering
- **Word wrap**: Enable/disable word wrapping
- **Whitespace display**: Show tabs, spaces, and line endings
- **Indent guides**: Visual guides for indentation levels
- **Current line highlight**: Highlight the current line

### Editing Behavior
**Smart Features:**
- **Auto-pairing**: Automatic closing of brackets, quotes, parentheses
- **Smart indentation**: Context-aware indentation for lists and code
- **Auto-completion**: Suggestions for Markdown syntax and words
- **Spell checking**: Built-in spell check with dictionary selection
- **Grammar checking**: Advanced grammar checking (if available)

**Text Input:**
- **Tab size**: Number of spaces per tab (2, 4, 8 spaces)
- **Use spaces for tabs**: Convert tabs to spaces
- **Auto-indent**: Automatically indent new lines
- **Backspace behavior**: How backspace handles indentation

### Cursor and Selection
**Cursor Options:**
- **Cursor style**: Block, line, or underline cursor
- **Cursor blinking**: Enable/disable cursor blinking
- **Multi-cursor**: Allow multiple cursors simultaneously
- **Block cursor width**: Width of block cursor

**Selection Display:**
- **Selection color**: Customize text selection color
- **Find highlight color**: Color for search result highlights
- **Bracket matching**: Highlight matching brackets/parentheses

## Preview Preferences

### Rendering Options
**Markdown Extensions:**
- **Tables**: Enhanced table rendering
- **Task lists**: Checkbox support in lists
- **Strikethrough**: Support for ~~strikethrough~~ text
- **Superscript/Subscript**: Support for super^script^ and sub~script~
- **Footnotes**: Footnote rendering and linking
- **Definition lists**: Definition list syntax support

**Code Blocks:**
- **Syntax highlighting**: Enable/disable code syntax highlighting
- **Language detection**: Automatic language detection for code blocks
- **Line numbers in code**: Show line numbers in code blocks
- **Copy button**: Add copy button to code blocks
- **Theme selection**: Choose syntax highlighting theme

### Math and Diagrams
**Mathematical Notation:**
- **LaTeX math**: Enable LaTeX-style math rendering
- **Math delimiters**: Customize math block delimiters ($$ or \[ \])
- **Math renderer**: Choose rendering engine (MathJax, KaTeX)
- **Math font size**: Adjust math equation font size

**Diagram Support:**
- **Mermaid diagrams**: Enable Mermaid diagram rendering
- **Chart support**: Enable chart.js integration
- **PlantUML**: Support for PlantUML diagrams (if configured)
- **Graphviz**: Support for DOT language graphs

### Preview Styling
**Theme Selection:**
- **Preview theme**: Choose from built-in themes or custom CSS
- **Font selection**: Separate font settings for preview
- **Custom CSS**: Path to custom CSS file for preview styling
- **Print styles**: Different styling for print/PDF export

**Layout Options:**
- **Max width**: Maximum width for preview content
- **Margins**: Margins around preview content
- **Line height**: Line spacing in preview
- **Paragraph spacing**: Space between paragraphs

## AI Settings

### Service Configuration

#### OpenAI Settings
**API Configuration:**
- **API Key**: Your OpenAI API key (stored securely)
- **Organization ID**: Optional organization identifier
- **Base URL**: Custom API base URL (for compatible services)
- **Model selection**: Choose default GPT model (GPT-4, GPT-3.5-turbo, etc.)
- **Temperature**: Creativity/randomness setting (0.0 to 1.0)
- **Max tokens**: Maximum tokens per request

**Usage Controls:**
- **Daily spending limit**: Maximum daily API costs
- **Monthly spending limit**: Maximum monthly API costs
- **Rate limiting**: Requests per minute limit
- **Usage tracking**: Enable detailed usage analytics
- **Cost alerts**: Warnings when approaching spending limits

#### Ollama Settings
**Local Configuration:**
- **Server URL**: Ollama server address (default: localhost:11434)
- **Default model**: Primary model for document assistance
- **Model management**: Download/update available models
- **Context length**: Maximum context window size
- **Keep alive**: How long to keep model in memory

**Performance:**
- **GPU acceleration**: Enable GPU support if available
- **Memory usage**: Memory allocation for model inference
- **Thread count**: CPU threads for model processing
- **Response streaming**: Enable streaming responses

### Context Strategy Settings
**Strategy Selection:**
- **Progressive Context**: Smart context selection with token optimization
- **Enhanced Progressive**: Multi-document aware context
- **Full Document**: Include entire document (for smaller files)
- **Custom Strategy**: Advanced users can define custom strategies

**Context Parameters:**
- **Context window size**: Maximum tokens for context
- **Priority weighting**: How to prioritize different content types
- **Semantic chunking**: Enable intelligent content chunking
- **Cross-document references**: Include references from other documents

### Chat Behavior
**Interface Options:**
- **Chat window position**: Docked or floating chat windows
- **Auto-focus**: Automatically focus chat input
- **History preservation**: Save chat history between sessions
- **Export conversations**: Export chat logs for reference

**Response Formatting:**
- **Markdown rendering**: Render AI responses as Markdown
- **Code highlighting**: Syntax highlighting in AI code responses
- **Copy buttons**: Add copy buttons to AI code blocks
- **Response streaming**: Show responses as they're generated

## File Preferences

### Auto-Save Settings
**Save Behavior:**
- **Auto-save enabled**: Enable/disable automatic saving
- **Save interval**: Time between auto-saves (10s to 10min)
- **Save on focus loss**: Save when switching away from MDTool
- **Save on idle**: Save after period of inactivity
- **Backup retention**: Number of backup copies to keep

**File Monitoring:**
- **External change detection**: Monitor files for external changes
- **Auto-reload**: Automatically reload externally changed files
- **Conflict resolution**: How to handle edit conflicts
- **Lock file creation**: Create lock files to prevent conflicts

### File Association
**Supported Extensions:**
- **.md**: Standard Markdown files
- **.markdown**: Full-name Markdown files
- **.mdown**: Alternative Markdown extension
- **.mkd, .mkdn**: Additional Markdown variants
- **Custom extensions**: Add custom file extensions

**Association Behavior:**
- **Set as default**: Make MDTool default for Markdown files
- **Context menu**: Add "Open with MDTool" to system context menu
- **Quick Look**: Enable Quick Look preview on macOS
- **Shell integration**: Command-line tools and scripts

### Recent Files and Favorites
**Recent Files:**
- **Maximum recent files**: Limit for recent files list
- **Clear on exit**: Clear recent files when quitting
- **Cross-platform sync**: Sync recent files across devices
- **Missing file handling**: How to handle deleted/moved files

**Favorites System:**
- **Favorites location**: Where to store favorites data
- **Sync favorites**: Synchronize favorites across installations
- **Backup favorites**: Include favorites in backup data
- **Import/export**: Transfer favorites between installations

## Appearance Preferences

### Theme Selection
**Interface Themes:**
- **System theme**: Follow system light/dark preference
- **Light theme**: Always use light interface
- **Dark theme**: Always use dark interface
- **High contrast**: High contrast mode for accessibility
- **Custom themes**: Import custom theme files

**Color Customization:**
- **Accent color**: Primary accent color for interface elements
- **Syntax colors**: Customize syntax highlighting colors
- **UI element colors**: Modify colors of interface components
- **Export/import**: Share color schemes with others

### Typography
**Interface Fonts:**
- **UI font**: Font for menus, buttons, and interface elements
- **Monospace font**: Font for code elements in UI
- **Font scaling**: Overall font size scaling for interface
- **ClearType (Windows)**: Font smoothing options

**Document Fonts:**
- **Editor font**: Separate font for text editing
- **Preview font**: Font used in preview mode
- **Code font**: Monospace font for code blocks
- **Math font**: Font for mathematical equations

### Visual Effects
**Animation Settings:**
- **Smooth transitions**: Enable/disable UI animations
- **Fade effects**: Fade in/out effects for dialogs
- **Scroll smoothing**: Smooth scrolling in editor and preview
- **Reduced motion**: Accessibility option for motion sensitivity

**Visual Indicators:**
- **Progress bars**: Style and behavior of progress indicators
- **Loading overlays**: Appearance of loading screens
- **Status indicators**: Style of status and notification elements
- **Focus indicators**: Visual focus indicators for accessibility

## Performance Preferences

### Memory Management
**Memory Usage:**
- **Memory limit**: Maximum memory usage for MDTool
- **Cache size**: Size of internal caches
- **Garbage collection**: Frequency of memory cleanup
- **Large file handling**: Special handling for large documents

**Buffer Management:**
- **Undo history size**: Number of undo operations to remember
- **Clipboard history**: Number of clipboard items to retain
- **Preview cache**: Cache size for rendered preview content
- **Image cache**: Cache size for embedded images

### Rendering Performance
**Editor Performance:**
- **Lazy rendering**: Render only visible content
- **Syntax highlighting limit**: File size limit for syntax highlighting
- **Line number limit**: When to disable line numbers for performance
- **Word wrap performance**: Optimizations for word wrapping

**Preview Performance:**
- **Incremental rendering**: Update only changed parts of preview
- **Image lazy loading**: Load images only when visible
- **Diagram caching**: Cache rendered diagrams for reuse
- **Math rendering cache**: Cache mathematical equation rendering

### Background Operations
**Threading:**
- **Background file monitoring**: Use separate thread for file watching
- **Async operations**: Enable asynchronous file operations
- **Parallel processing**: Use multiple CPU cores when possible
- **Priority settings**: Process priority for background tasks

**Network Operations:**
- **Concurrent connections**: Maximum simultaneous network requests
- **Timeout settings**: Network operation timeouts
- **Retry behavior**: How to handle failed network operations
- **Offline mode**: Behavior when network is unavailable

## Advanced Preferences

### Developer Options
**Debug Settings:**
- **Debug mode**: Enable debug logging and information
- **Performance metrics**: Show detailed performance information
- **Memory usage display**: Show real-time memory usage
- **Console access**: Enable developer console access

**Logging:**
- **Log level**: Verbosity of application logging
- **Log file location**: Where to store log files
- **Log retention**: How long to keep log files
- **Export logs**: Easy export of logs for troubleshooting

### Experimental Features
**Beta Features:**
- **New renderer**: Experimental preview renderer
- **Enhanced AI**: Beta AI features and models
- **Performance improvements**: Experimental optimizations
- **UI enhancements**: New interface elements

**Feature Flags:**
- **Enable/disable features**: Toggle experimental features
- **Rollback options**: Easy rollback of problematic features
- **Feedback submission**: Report issues with experimental features
- **Update channels**: Choose stable or beta update channel

### Integration Settings
**System Integration:**
- **Shell commands**: Enable shell command integration
- **URL handling**: Handle mdtool:// URLs
- **System notifications**: Integration with system notification center
- **Global shortcuts**: System-wide keyboard shortcuts

**External Tools:**
- **Git integration**: Enable Git repository features
- **External editor**: Configure external editor for special cases
- **Diff tool**: Configure external diff/merge tools
- **PDF viewer**: Default PDF viewer for exported documents

## Importing and Exporting Settings

### Settings Backup
**Export Settings:**
1. Go to Advanced preferences
2. Click "Export Settings"
3. Choose location for settings file
4. Settings saved as JSON file

**Import Settings:**
1. Go to Advanced preferences
2. Click "Import Settings"
3. Select previously exported settings file
4. Choose which settings to import
5. Restart MDTool if required

### Cross-Platform Sync
**Cloud Sync:**
- **iCloud (macOS)**: Sync settings via iCloud
- **OneDrive (Windows)**: Sync via Microsoft OneDrive
- **Manual sync**: Export/import settings files manually
- **Selective sync**: Choose which settings to sync

### Settings Reset
**Reset Options:**
- **Reset to defaults**: Restore all settings to default values
- **Reset specific category**: Reset only one category of settings
- **Backup before reset**: Automatically backup current settings
- **Confirmation dialogs**: Confirm before making major changes

## Tips for Optimizing Settings

### Performance Optimization
1. **Large files**: Disable syntax highlighting for files over 1MB
2. **Memory usage**: Reduce cache sizes if experiencing memory issues
3. **Network operations**: Adjust timeout settings based on connection speed
4. **Background tasks**: Disable unnecessary background operations

### Workflow Optimization
1. **Keyboard shortcuts**: Customize shortcuts for frequently used features
2. **Auto-save**: Set appropriate auto-save interval for your workflow
3. **File organization**: Configure default locations to match your file structure
4. **AI settings**: Optimize context strategy for your typical document length

### Accessibility
1. **Visual**: Use high contrast themes and larger fonts if needed
2. **Motor**: Configure keyboard shortcuts for easier access
3. **Cognitive**: Enable/disable features based on complexity needs
4. **Platform**: Use platform-specific accessibility features

### Security and Privacy
1. **API keys**: Store securely and rotate regularly
2. **Local models**: Use Ollama for privacy-sensitive documents
3. **File permissions**: Configure appropriate file access permissions
4. **Network**: Disable network features if working with sensitive content