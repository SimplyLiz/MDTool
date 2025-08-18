# MDTool

A minimal, native macOS Markdown viewer and editor built with Flutter, featuring AI-powered analytics, integrated chat functionality, and advanced document management capabilities.

## Features

### Core Functionality
- **Native macOS Integration**: Built specifically for macOS with native UI components and system integration
- **Markdown Editing & Preview**: Real-time markdown editing with live preview and syntax highlighting
- **Split Screen View**: Side-by-side editing and preview modes
- **File Management**: Comprehensive file browser with folder navigation and recent items tracking

### Advanced Features
- **AI Analytics & Chat**: Integrated AI services with OpenAI and Ollama support
- **Context-Aware Processing**: Smart context strategies for enhanced AI interactions
- **PDF Export**: High-quality PDF generation from markdown documents
- **Diff Viewer**: Advanced diff comparison with multiple viewing modes
- **Search & Navigation**: Full-text search across documents with quick navigation
- **Graph Visualization**: Support for Mermaid diagrams, flowcharts, and other graph renderers

### Developer Features
- **Performance Monitoring**: Built-in metrics and performance tracking
- **Auto-save**: Automatic document saving with configurable intervals
- **Preferences Management**: Comprehensive settings and customization options
- **Multi-window Support**: Detached chat windows and flexible workspace management

## Requirements

- **macOS**: macOS 10.15 or later
- **Flutter**: Flutter 3.8.1 or later
- **Dart SDK**: 3.8.1 or later

## Installation

1. Clone the repository:
   ```bash
   git clone [repository-url]
   cd MDTool
   ```

2. Navigate to the project directory:
   ```bash
   cd src/mdtool
   ```

3. Install Flutter dependencies:
   ```bash
   flutter pub get
   ```

4. Install CocoaPods dependencies (for macOS):
   ```bash
   cd macos
   pod install
   cd ..
   ```

5. Run the application:
   ```bash
   flutter run -d macos
   ```

## Building

### Development Build
```bash
flutter build macos --debug
```

### Release Build
```bash
flutter build macos --release
```

The built application will be available in `build/macos/Build/Products/Release/md_tool.app`

## Project Structure

```
src/mdtool/
├── lib/
│   ├── core/                    # Core application logic
│   │   ├── models/             # Data models
│   │   ├── providers/          # Riverpod state providers
│   │   ├── services/           # Business logic services
│   │   └── utils/              # Utility functions
│   ├── ui/                     # User interface components
│   │   ├── dialogs/            # Modal dialogs
│   │   ├── pages/              # Main application pages
│   │   ├── themes/             # App theming
│   │   └── widgets/            # Reusable UI widgets
│   └── main.dart               # Application entry point
├── macos/                      # macOS-specific configuration
├── test/                       # Unit and widget tests
└── scripts/                    # Build and deployment scripts
```

## Key Services

- **AI Services**: OpenAI and Ollama integration for intelligent document processing
- **File Service**: Advanced file operations with permission handling
- **Chat Service**: Real-time chat functionality with AI assistants
- **PDF Export**: Professional document export capabilities
- **Search Service**: Fast full-text search across documents
- **Metrics Service**: Performance monitoring and usage analytics

## Configuration

The application supports various configuration options through:
- User preferences stored locally
- Environment-specific settings
- AI service configurations
- Custom context strategies

## Testing

Run the test suite:
```bash
flutter test
```

For performance testing:
```bash
flutter test test/performance_test.dart
```

## Development

### Adding New Features
1. Create models in `lib/core/models/`
2. Implement services in `lib/core/services/`
3. Add providers in `lib/core/providers/`
4. Build UI components in `lib/ui/widgets/`
5. Create tests in `test/`

### Code Style
The project follows Dart/Flutter best practices with:
- Riverpod for state management
- Service-based architecture
- Comprehensive error handling
- Performance optimization

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Submit a pull request

## License

[Add appropriate license information]

## Support

For issues and questions, please check the project's issue tracker or documentation.