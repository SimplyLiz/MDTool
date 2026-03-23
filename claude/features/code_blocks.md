# Code Blocks Feature Documentation

## Overview

The MDTool application renders both inline code and fenced code blocks with consistent styling and enhanced functionality. This document covers the implementation, styling, and behavior of code blocks in the markdown preview.

## File Structure

### Primary Files
- `lib/ui/widgets/fenced_code_block_builder.dart` - Custom builder for fenced code blocks
- `lib/ui/widgets/markdown_preview.dart` - Main markdown rendering with inline code styling

### Key Dependencies
- `flutter_highlight` - Syntax highlighting for language-specific code blocks
- `flutter_markdown` - Base markdown rendering
- Material Design 3 theming system

## Code Block Types

### 1. Inline Code
```markdown
Here's some `inline code` in text.
```

**Implementation:**
- Handled by flutter_markdown's default inline code renderer
- Styled in `markdown_preview.dart` at line 605
- Background: `colorScheme.surfaceContainerHighest`
- Font: Monaco, slightly smaller than body text

### 2. Fenced Code Blocks (Plain)
```markdown
```
function hello() {
  console.log("Hello world!");
}
```
```

**Implementation:**
- Processed by `FencedCodeBlockBuilder`
- No syntax highlighting (uses plain Text widget)
- Same background styling as language-specific blocks
- Copy button positioned on the right

### 3. Fenced Code Blocks (Language-Specific)
```markdown
```javascript
function hello() {
  console.log("Hello world!");
}
```
```

**Implementation:**
- Processed by `FencedCodeBlockBuilder`
- Syntax highlighting via `HighlightView`
- Language label displayed in header
- Copy button positioned on the right

## Styling System

### Color Scheme (Material Design 3)
- **Main background**: `colorScheme.surfaceContainerHighest`
- **Header background**: `colorScheme.surfaceContainer`
- **Text colors**: `colorScheme.onSurface` with appropriate alpha values
- **Border radius**: 8px for consistent rounded corners

### Theme Handling
- Dark/light themes automatically handled through Material Design color scheme
- Only explicit dark/light check is for syntax highlighting theme selection
- No hardcoded colors (except for syntax highlighting themes)

## FencedCodeBlockBuilder Architecture

### Constructor
```dart
FencedCodeBlockBuilder({required this.context})
```
- Receives `BuildContext` to access theme colors
- Replaced previous `isDarkTheme` boolean parameter

### Element Processing
1. **Filter elements**: Only processes `<code>` elements
2. **Language detection**: Checks for `language-*` class attribute
3. **Content validation**: Skips empty code blocks
4. **Language normalization**: Maps common aliases (js→javascript, ts→typescript, etc.)

### Layout Structure
```
Container (main background)
├── Container (header with language + copy button)
│   └── Row
│       ├── Text (language label, if present)
│       ├── Spacer (always present)
│       └── CopyButton
└── Padding (code content area)
    └── Code rendering (HighlightView or Text)
```

### Performance Optimization
- **Async highlighting**: Large code blocks (>1000 chars or >50 lines) use `compute()` for background processing
- **Loading state**: Shows spinner and "Highlighting code..." message
- **Fallback handling**: Plain text rendering if highlighting fails

## Copy Button Component

### Features
- Visual feedback on copy (green background, checkmark icon)
- 2-second auto-reset to normal state
- Consistent theming across light/dark modes
- Positioned on right side for all code block types

### Styling
- **Normal state**: Subtle background with theme-based opacity
- **Copied state**: Green background with appropriate alpha for theme
- **Icon**: Copy → Check transition
- **Text**: "Copy" → "Copied!" transition

## Language Support

### Normalized Languages
The system maps common aliases to standard language identifiers:
- `js` → `javascript`
- `ts` → `typescript`
- `sh`/`shell` → `bash`
- `yml` → `yaml`
- `md` → `markdown`

### Syntax Highlighting Themes
- **Light mode**: GitHub theme (from flutter_highlight)
- **Dark mode**: Custom dark theme optimized for readability

### Custom Dark Theme Colors
- **Keywords**: `#569CD6` (blue)
- **Strings**: `#CE9178` (orange)
- **Comments**: `#6A9955` (green, italic)
- **Functions**: `#DCDCAA` (yellow)
- **Variables**: `#9CDCFE` (light blue)
- **Numbers**: `#B5CEA8` (light green)

## Integration with Markdown Preview

### Builder Registration
In `markdown_preview.dart`:
```dart
builders: {
  'code': FencedCodeBlockBuilder(context: context),
  'img': ImageElementBuilder(),
},
```

### Style Sheet Configuration
Inline code styling in `_buildStyleSheet()`:
```dart
code: TextStyle(
  color: colorScheme.onSurface,
  backgroundColor: colorScheme.surfaceContainerHighest,
  fontFamily: 'Monaco',
  fontSize: preferences.fontSize * 0.9
),
```

## Error Handling

### Common Issues & Solutions
1. **Null language parameter**: Plain code blocks use Text widget instead of HighlightView
2. **Empty content**: Early return prevents rendering empty blocks
3. **Large code blocks**: Async processing with loading states
4. **Highlighting failures**: Graceful fallback to plain text

### Debugging
- Check Flutter DevTools for rendering performance
- Verify theme colors in Material Theme Inspector
- Monitor async highlighting completion in large files

## Recent Changes (August 2025)

### Fixed Issues
1. **Background color consistency**: Both plain and language-specific blocks now use `surfaceContainerHighest`
2. **Copy button positioning**: Always appears on right side regardless of language presence
3. **Null language exceptions**: Proper handling of plain code blocks without syntax highlighting
4. **Deprecated APIs**: Replaced `withOpacity()` with `withValues(alpha:)`
5. **Theme integration**: Better use of Material Design 3 color system

### Architecture Improvements
- Simplified dark/light theme handling
- Better separation of concerns between styling and functionality
- More robust error handling and fallback mechanisms

## Testing

### Test Cases to Verify
1. Plain code blocks render with correct background
2. Language-specific code blocks show syntax highlighting
3. Copy button works for both plain and language blocks
4. Copy button positioned consistently on the right
5. Large code blocks load asynchronously
6. Theme changes update colors correctly
7. No null pointer exceptions with any code block type

### Test File
A test markdown file is available at `/Users/lisa/Work/MDTool/test_code_blocks.md` with various code block examples.

## Future Enhancements

### Potential Improvements
1. **Line numbers**: Optional line number display for long code blocks
2. **Code folding**: Collapse/expand functionality for large blocks
3. **More languages**: Extended syntax highlighting support
4. **Export options**: Include formatted code in export functions
5. **Search highlighting**: Highlight search terms within code blocks
6. **Custom themes**: User-configurable syntax highlighting themes

### Performance Considerations
- Monitor memory usage with many large code blocks
- Consider virtual scrolling for very long code files
- Optimize async highlighting thresholds based on device performance