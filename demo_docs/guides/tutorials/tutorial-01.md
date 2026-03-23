# Tutorial 01: Getting Started with Markdown Navigation

Welcome to the first tutorial in our series! This tutorial covers the basics of markdown document navigation.

## Navigation
- [🏠 Back to README](../../README.md)
- [📚 Tutorial 02](tutorial-02.md)
- [🚀 Getting Started Guide](../../docs/user-guide/getting-started.md)

## Introduction

This tutorial is part of the [tutorial series](../) and focuses on basic navigation concepts for the demo project.

## Learning Objectives

By the end of this tutorial, you will understand:
1. How to navigate between markdown documents
2. Different types of links and their usage
3. Best practices for document organization

## Prerequisites

Before starting, please read:
- [Project README](../../README.md) - Project overview
- [Getting Started Guide](../../docs/user-guide/getting-started.md) - Basic setup

## Basic Navigation Concepts

### Link Types

#### 1. Relative File Links
Navigate to files in the same directory or nearby:
```markdown
[Tutorial 02](tutorial-02.md)
[Getting Started](../../docs/user-guide/getting-started.md)
```

#### 2. Anchor Links
Jump to specific sections within documents:
```markdown
[Advanced Concepts](#advanced-concepts)
[External Section](tutorial-02.md#complex-navigation)
```

#### 3. External Links
Link to resources outside the project:
```markdown
[GitHub](https://github.com)
[Contact Email](mailto:tutorial@example.com)
```

## Practical Examples

### Example 1: Basic Navigation
Try navigating between these related documents:
- [Main Documentation](../../DOCUMENTATION.md)
- [API Overview](../../api/reference/api-overview.md)
- [Hello World Example](../../tests/basic/hello-world.md)

### Example 2: Cross-Directory Navigation
Navigate across different documentation categories:
- **From tutorials to guides**: [Deployment Guide](../how-to/deployment.md)
- **From tutorials to examples**: [Complex Example](../../tests/advanced/complex-example.md)
- **From tutorials to API**: [API Endpoints](../../api/reference/endpoints.md)

## Hands-On Exercises

### Exercise 1: Navigation Practice
1. Start from the [main README](../../README.md)
2. Navigate to [getting started](../../docs/user-guide/getting-started.md)
3. Follow the link to [advanced usage](../../docs/user-guide/advanced-usage.md)
4. Return to this tutorial using breadcrumb navigation

### Exercise 2: Anchor Navigation
Practice using anchor links:
1. Jump to [Advanced Concepts](#advanced-concepts) below
2. Navigate to [Tutorial 02 Advanced Section](tutorial-02.md#complex-features)
3. Return here using browser back button

### Exercise 3: Cross-Reference Following
Follow this navigation path:
1. [Architecture Overview](../../docs/developer-guide/architecture.md)
2. [Testing Guide](../../docs/developer-guide/testing.md)
3. [Troubleshooting](../how-to/troubleshooting.md)
4. Back to [Main README](../../README.md)

## Advanced Concepts

### Multi-Level Navigation
Understanding complex path structures:

#### Parent Directory Navigation
```markdown
[Two levels up](../../README.md)
[Sibling directory](../how-to/deployment.md)
```

#### Deep Directory Navigation
```markdown
[Deep nested file](../../api/reference/endpoints.md)
[Complex example](../../tests/advanced/complex-example.md)
```

### Best Practices

#### 1. Use Descriptive Link Text
```markdown
❌ [Click here](../../README.md)
✅ [Project README](../../README.md)
```

#### 2. Maintain Bidirectional Links
Always provide ways to navigate back:
```markdown
[Advanced Tutorial](tutorial-02.md) → [Back to Tutorial 01](tutorial-01.md)
```

#### 3. Group Related Links
Organize links logically:
```markdown
### User Resources
- [Getting Started](../../docs/user-guide/getting-started.md)
- [Advanced Usage](../../docs/user-guide/advanced-usage.md)

### Developer Resources
- [Architecture](../../docs/developer-guide/architecture.md)
- [Testing](../../docs/developer-guide/testing.md)
```

## Common Pitfalls

### 1. Broken Relative Paths
Always verify paths from the current file's location:
```markdown
❌ [Wrong path](docs/user-guide/getting-started.md)
✅ [Correct path](../../docs/user-guide/getting-started.md)
```

### 2. Missing Anchors
Ensure referenced sections exist:
```markdown
❌ [Non-existent section](#missing-section)
✅ [Existing section](#advanced-concepts)
```

## Testing Your Understanding

### Quiz Questions
1. How do you link to a file two directories up?
2. What's the syntax for anchoring to a section in another file?
3. When should you use relative vs absolute paths?

### Answers
1. Use `../../filename.md`
2. Use `[text](file.md#section-name)`
3. Use relative paths for project files, absolute for external resources

## Next Steps

### Continue Learning
1. **Advanced Tutorial**: [Tutorial 02](tutorial-02.md) - Complex navigation patterns
2. **How-to Guides**: [Deployment](../how-to/deployment.md) - Practical applications
3. **Examples**: [Hello World](../../tests/basic/hello-world.md) - Simple implementations

### Additional Resources
- [Advanced Usage Guide](../../docs/user-guide/advanced-usage.md) - Power user features
- [Architecture Overview](../../docs/developer-guide/architecture.md) - System design
- [API Documentation](../../api/reference/api-overview.md) - Technical reference

### Practice Projects
Try creating your own documentation with:
- [Contributing Guidelines](../../CONTRIBUTING.md) for best practices
- [Examples](../../tests/) for inspiration
- [API Reference](../../api/reference/) for technical documentation

## Summary

This tutorial covered:
- ✅ Basic navigation concepts
- ✅ Different link types and syntax
- ✅ Practical examples and exercises
- ✅ Best practices and common pitfalls
- ✅ Testing and next steps

## Related Documentation

### Tutorial Series
- [Tutorial 02: Advanced Features](tutorial-02.md) - Next in series
- [All Tutorials](../../guides/tutorials/) - Complete collection

### User Guides
- [Getting Started](../../docs/user-guide/getting-started.md) - Basic usage
- [Advanced Usage](../../docs/user-guide/advanced-usage.md) - Power features

### Examples
- [Hello World](../../tests/basic/hello-world.md) - Simple example
- [Complex Example](../../tests/advanced/complex-example.md) - Advanced example

---

*Continue to [Tutorial 02](tutorial-02.md) or return to the [main README](../../README.md).*