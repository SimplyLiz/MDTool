# MDTool Demo Documentation

Welcome to the comprehensive MDTool demo documentation! This collection showcases MDTool's capabilities for rendering graphs, managing cross-document navigation, and organizing complex documentation projects.

## 🚀 Quick Start

- **New to MDTool?** Start with [Getting Started Guide](docs/user-guide/getting-started.md)
- **Want to see graphs?** Check out [Native Graphs](tests/graphs/native_graphs.md) and [Mermaid Graphs](tests/graphs/mermaid_graphs.md)
- **Testing features?** Use [Code Block Tests](tests/code_blocks.md)
- **Full overview?** See [Project README](core/README.md)

## 📊 Graph Examples

### Native Graph Renderers (Non-Mermaid)
**[📊 Native Graph Examples](tests/graphs/native_graphs.md)**
- Statistical Charts: bar, line, pie, scatter, area charts
- Flowcharts: process flows with decision nodes
- Git Graphs: branch visualization and commit history
- PlantUML: sequence, class, use case, component diagrams

### Mermaid Diagrams
**[📈 Mermaid Graph Examples](tests/graphs/mermaid_graphs.md)**
- Flowcharts and system architecture
- Sequence diagrams and API flows  
- Class diagrams and database schemas
- State diagrams and workflows
- Gantt charts, timelines, and more

## 📚 Documentation Structure

### Core Documentation
- [📋 Project README](core/README.md) - Main project documentation
- [📖 Documentation Overview](core/DOCUMENTATION.md) - Feature details
- [🔄 Changelog](core/CHANGELOG.md) - Version history
- [🤝 Contributing](core/CONTRIBUTING.md) - Contribution guidelines

### User Guides
- [🚀 Getting Started](docs/user-guide/getting-started.md) - Basic usage
- [⚡ Advanced Usage](docs/user-guide/advanced-usage.md) - Power features

### Developer Resources
- [🏗️ Architecture](docs/developer-guide/architecture.md) - System design
- [🧪 Testing](docs/developer-guide/testing.md) - Testing procedures

### API Documentation
- [📊 API Overview](api/reference/api-overview.md) - Complete API guide
- [🔗 Endpoints](api/reference/endpoints.md) - Endpoint reference
- [📋 API Changelog](api/changelog/api-changelog.md) - API version history

### Learning Resources
- [📚 Tutorial 01: Basics](guides/tutorials/tutorial-01.md)
- [📚 Tutorial 02: Advanced Features](guides/tutorials/tutorial-02.md)
- [🚀 Deployment Guide](guides/how-to/deployment.md)
- [🛠️ Troubleshooting](guides/how-to/troubleshooting.md)

### Examples & Testing
- [👋 Hello World](tests/basic/hello-world.md) - Simple markdown usage
- [🔧 Complex Example](tests/advanced/complex-example.md) - Advanced patterns
- [💻 Code Block Tests](tests/code_blocks.md) - Syntax highlighting

## 🎯 Feature Testing Guide

### Graph Rendering Tests
1. **Statistical Charts**: Open [Native Graphs](tests/graphs/native_graphs.md) → Test bar, line, pie, scatter, area charts
2. **Flowcharts**: Test process flows and decision trees with various node types
3. **Git Graphs**: Verify branch visualization and commit history rendering
4. **PlantUML**: Test sequence, class, use case, and component diagrams
5. **Mermaid**: Open [Mermaid Graphs](tests/graphs/mermaid_graphs.md) → Test all Mermaid diagram types

### Navigation Tests  
1. **Cross-document Links**: Use this index to navigate between different sections
2. **Relative Paths**: Test links within subdirectories
3. **Anchor Links**: Test section jumps within documents
4. **Breadcrumb Navigation**: Follow navigation chains between related docs

### Code Highlighting Tests
1. **Multi-language**: Open [Code Block Tests](tests/code_blocks.md) → Verify JavaScript, Dart, Python, JSON, YAML, SQL
2. **Inline Code**: Test `inline code` styling throughout documents
3. **Plain Text**: Verify plain code blocks maintain formatting

## 📁 Project Structure

```
demo_docs/
├── index.md (this file)
├── core/                    # Core project files
├── docs/                    # User and developer guides
├── api/                     # API documentation
├── guides/                  # Tutorials and how-to guides
├── tests/                   # Usage examples
│   ├── basic/              # Simple examples
│   ├── advanced/           # Complex examples
│   └── graphs/             # Graph examples
│       ├── native_graphs.md    # Non-Mermaid graphs
│       └── mermaid_graphs.md   # Mermaid diagrams
└── tests/                   # Feature testing
    └── code_blocks.md      # Code highlighting tests
```

## 🔗 Key Features Demonstrated

### Graph Rendering Engine
- **Native Renderers**: Custom chart and diagram renderers built for MDTool
- **Mermaid Integration**: Full support for Mermaid diagram syntax
- **Interactive Features**: Hover states, tooltips, zoom capabilities
- **Theme Support**: Dark/light mode compatibility

### Document Navigation
- **Smart Linking**: Relative and absolute path support
- **Cross-references**: Bidirectional navigation between related documents  
- **Anchor Navigation**: Section-level linking within documents
- **Hierarchical Structure**: Logical organization with breadcrumbs

### Content Management
- **Structured Organization**: Clear hierarchy for complex documentation
- **Cross-document Search**: Content discovery across the entire project
- **Version Control**: Change tracking and history management
- **Template System**: Consistent formatting and structure

## 📝 Usage Examples

### Creating Charts
```markdown
```chart
type: bar
title: Sample Data
data:
Q1: 100
Q2: 150
Q3: 120
```
```

### Cross-document Links
```markdown
[Getting Started](docs/user-guide/getting-started.md)
[API Reference](api/reference/api-overview.md#authentication)
```

### Code Highlighting
```javascript
function example() {
  console.log("Properly highlighted code!");
}
```

## 🎨 Customization

This demo project can be customized for your needs:

1. **Graph Themes**: Modify colors and styling in graph examples
2. **Navigation Structure**: Reorganize directories to match your project
3. **Content Templates**: Use existing files as templates for new documentation
4. **Link Patterns**: Adapt navigation patterns to your workflow

## 🔄 Updates and Maintenance

- **Graph Examples**: Keep graph examples up-to-date with new renderer features
- **Link Validation**: Regularly verify all cross-document links work correctly
- **Content Sync**: Ensure examples match current MDTool capabilities
- **Structure Evolution**: Adapt organization as project needs change

---

**Ready to explore?** Start with [Getting Started Guide](docs/user-guide/getting-started.md) or jump directly to [Graph Examples](tests/graphs/native_graphs.md)!