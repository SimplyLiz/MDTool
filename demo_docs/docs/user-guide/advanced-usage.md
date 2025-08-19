# Advanced Usage Guide

This guide covers advanced features and configuration options.

## Navigation
- [🏠 Back to README](../../README.md)
- [🚀 Getting Started](getting-started.md)
- [🏗️ Architecture Overview](../developer-guide/architecture.md)

## Advanced Features

### Complex Link Navigation
This document demonstrates advanced linking patterns:

#### Multi-level Directory Navigation
- **Up two levels**: `[text](../../file.md)`
- **Cross-directory**: `[text](../developer-guide/file.md)`
- **Deep nesting**: `[text](../../guides/tutorials/tutorial-01.md)`

#### Anchor Links with Paths
- [Jump to Configuration Section](#configuration-management)
- [Link to Architecture Patterns](../developer-guide/architecture.md#design-patterns)
- [Reference API Endpoints](../../api/reference/endpoints.md#authentication)

### Configuration Management

Advanced configuration options for power users:

#### Link Behavior Settings
- **Relative path resolution**: Automatically resolves `../` and `./` paths
- **Anchor navigation**: Supports `#section` links within and across documents
- **File extension handling**: Auto-adds `.md` for extensionless links

#### Cross-Reference Features
- [API Integration](../../api/reference/api-overview.md#integration-guide)
- [Deployment Strategies](../../guides/how-to/deployment.md#advanced-deployment)
- [Testing Methodologies](../developer-guide/testing.md#integration-testing)

## Advanced Examples

### Complex Documentation Structures
See how we handle complex navigation:
- [Complex Example](../../tests/advanced/complex-example.md) - Comprehensive example
- [Tutorial 02](../../guides/tutorials/tutorial-02.md) - Advanced tutorial content

### API Integration Examples
- [API Overview](../../api/reference/api-overview.md) - Complete API documentation
- [Endpoint Reference](../../api/reference/endpoints.md) - Detailed endpoint information
- [API Changelog](../../api/changelog/api-changelog.md) - Version-specific changes

## Performance Optimization

### Link Resolution Performance
- **Relative paths** are resolved faster than absolute paths
- **Cached file lookups** improve navigation speed
- **Anchor jumping** uses smooth scrolling for better UX

### Best Practices
1. Use [relative links](getting-started.md) for same-project references
2. Implement [proper anchor naming](#anchor-links-with-paths) conventions
3. Maintain consistent [documentation structure](../../DOCUMENTATION.md#navigation)

## Integration Patterns

### Cross-Document References
- [Contributing Guidelines](../../CONTRIBUTING.md#documentation-improvements)
- [Architecture Decisions](../developer-guide/architecture.md#design-decisions)
- [Testing Strategies](../developer-guide/testing.md#testing-strategies)

### External Integrations
- [GitHub Repository](https://github.com/example/demo-project) - External link
- [Documentation Site](https://docs.example.com) - External documentation
- [Contact Email](mailto:support@example.com) - Email integration

## Troubleshooting Advanced Issues

### Link Resolution Problems
If links aren't working:
1. Check [troubleshooting guide](../../guides/how-to/troubleshooting.md#link-issues)
2. Verify [file paths](../../guides/how-to/troubleshooting.md#path-resolution)
3. Review [anchor syntax](../../guides/how-to/troubleshooting.md#anchor-links)

### Performance Issues
For performance optimization:
- See [deployment guide](../../guides/how-to/deployment.md#performance-optimization)
- Check [architecture patterns](../developer-guide/architecture.md#performance-patterns)

## Power User Features

### Bulk Navigation
- [All Tutorials](../../guides/tutorials/) - Complete tutorial collection
- [All Examples](../../tests/) - Comprehensive examples
- [Complete API Reference](../../api/) - Full API documentation

### Advanced Customization
- [Developer Setup](../developer-guide/architecture.md#development-setup)
- [Testing Configuration](../developer-guide/testing.md#configuration)
- [Deployment Customization](../../guides/how-to/deployment.md#custom-deployment)

## Related Documentation

### User Guides
- [Getting Started](getting-started.md) - Basic introduction
- [Main Documentation](../../DOCUMENTATION.md) - Project overview

### Developer Resources
- [Architecture Guide](../developer-guide/architecture.md) - System design
- [Testing Guide](../developer-guide/testing.md) - Testing procedures
- [Contributing Guide](../../CONTRIBUTING.md) - Contribution guidelines

### Tutorials and Examples
- [Tutorial 01](../../guides/tutorials/tutorial-01.md) - Basic tutorial
- [Tutorial 02](../../guides/tutorials/tutorial-02.md) - Advanced tutorial
- [Hello World](../../tests/basic/hello-world.md) - Simple example
- [Complex Example](../../tests/advanced/complex-example.md) - Advanced example

---

*Return to [Getting Started](getting-started.md) or explore the [main README](../../README.md) for more options.*