# MDTool Demo Project Documentation

Welcome to the MDTool Demo Project! This project demonstrates comprehensive markdown link navigation, graph rendering, and document organization.

## 📁 Project Structure

```
demo_docs/
├── index.md (main navigation)
├── core/
│   ├── README.md (you are here)
│   ├── DOCUMENTATION.md
│   ├── CHANGELOG.md
│   └── CONTRIBUTING.md
├── docs/
│   ├── user-guide/
│   │   ├── getting-started.md
│   │   └── advanced-usage.md
│   └── developer-guide/
│       ├── architecture.md
│       └── testing.md
├── guides/
│   ├── tutorials/
│   │   ├── tutorial-01.md
│   │   └── tutorial-02.md
│   └── how-to/
│       ├── deployment.md
│       └── troubleshooting.md
├── api/
│   ├── reference/
│   │   ├── api-overview.md
│   │   └── endpoints.md
│   └── changelog/
│       └── api-changelog.md
├── examples/
│   ├── basic/
│   │   └── hello-world.md
│   ├── advanced/
│   │   └── complex-example.md
│   └── graphs/
│       ├── native_graphs.md
│       └── mermaid_graphs.md
└── tests/
    └── code_blocks.md
```

## 📖 Documentation Navigation

### Core Documentation

- [🏠 Main Index](../index.md) - Project overview and main navigation
- [📋 Documentation](DOCUMENTATION.md) - Project details and features
- [🔄 Changelog](CHANGELOG.md) - Version history and changes
- [🤝 Contributing Guide](CONTRIBUTING.md) - How to contribute to the project

### User Documentation

- [🚀 Getting Started Guide](../docs/user-guide/getting-started.md)
- [⚡ Advanced Usage](../docs/user-guide/advanced-usage.md)

### Developer Resources

- [🏗️ Architecture Overview](../docs/developer-guide/architecture.md)
- [🧪 Testing Documentation](../docs/developer-guide/testing.md)

### Tutorials & Guides

- [📚 Tutorial 01: Basics](../guides/tutorials/tutorial-01.md)
- [📚 Tutorial 02: Advanced Features](../guides/tutorials/tutorial-02.md)
- [🚀 Deployment Guide](../guides/how-to/deployment.md)
- [🛠️ Troubleshooting](../guides/how-to/troubleshooting.md)

### API Documentation

- [📊 API Overview](../api/reference/api-overview.md)
- [🔗 API Endpoints](../api/reference/endpoints.md)
- [📋 API Changelog](../api/changelog/api-changelog.md)

### Examples & Testing

- [👋 Hello World Example](../examples/basic/hello-world.md)
- [🔧 Complex Example](../examples/advanced/complex-example.md)
- [📊 Native Graph Examples](../examples/graphs/native_graphs.md) - Charts, flowcharts, git graphs, PlantUML
- [📈 Mermaid Graph Examples](../examples/graphs/mermaid_graphs.md) - All Mermaid diagram types
- [💻 Code Block Tests](../tests/code_blocks.md) - Syntax highlighting examples

## 🔗 Key Features Demonstrated

### Graph Rendering
- **Native Graphs**: Statistical charts, flowcharts, git graphs, PlantUML diagrams
- **Mermaid Graphs**: Comprehensive collection of Mermaid diagrams
- **Interactive Elements**: Hover states, tooltips, zoom capabilities

### Link Navigation
- **Relative Links**: Links using relative paths from current file
- **Cross-document Navigation**: Links between different markdown files
- **Anchor Links**: Jump to specific sections within documents
- **Directory Traversal**: Navigation across folder structures

### Code Highlighting
- **Multi-language Support**: JavaScript, Dart, Python, JSON, YAML, SQL
- **Inline Code**: Proper styling for `inline code` elements
- **Plain Text Blocks**: Formatted code blocks without syntax highlighting

### Document Organization
- **Hierarchical Structure**: Logical organization of content
- **Cross-references**: Links between related documents
- **Navigation Aids**: Consistent navigation patterns

## 🎯 Testing Guide

Use this demo project to test MDTool features:

1. **Graph Rendering**: Open the graph examples to test all chart and diagram types
2. **Link Navigation**: Use the various README links to test cross-document navigation
3. **Code Highlighting**: Check the code block tests for syntax highlighting
4. **File Structure**: Browse through the organized documentation hierarchy

## 📝 Usage Examples

### Basic Navigation
```markdown
[Link to another document](../docs/user-guide/getting-started.md)
[Link with anchor](../api/reference/api-overview.md#authentication)
```

### Graph Embedding
```markdown
```chart
type: bar
title: Sample Chart
data:
Item A: 10
Item B: 20
```
```

### Code Highlighting
```javascript
function example() {
  console.log("Syntax highlighted!");
}
```

---

*Return to [Main Index](../index.md) for complete project navigation.*