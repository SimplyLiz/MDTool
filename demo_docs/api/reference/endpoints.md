# API Endpoints Reference

Detailed documentation for all API endpoints with navigation examples.

## Navigation
- [🏠 Back to README](../../README.md)
- [📊 API Overview](api-overview.md)
- [📋 API Changelog](../changelog/api-changelog.md)

## Authentication

### API Key Setup
Configure API authentication:
- [Setup Guide](api-overview.md#api-key-authentication)
- [Security Best Practices](../../docs/developer-guide/architecture.md#security-patterns)

## Data Operations

### CRUD Endpoints
Basic data operations:
- GET /api/data - List all data
- POST /api/data - Create new data
- GET /api/data/{id} - Get specific data
- PUT /api/data/{id} - Update data
- DELETE /api/data/{id} - Delete data

## Rate Limiting

Rate limits apply to all endpoints:
- 1000 requests per hour for authenticated users
- 100 requests per hour for unauthenticated users

For details, see [API Overview](api-overview.md#rate-limiting).

## Related Documentation
- [API Overview](api-overview.md) - Complete API guide
- [Examples](../../examples/advanced/complex-example.md) - Integration examples
- [Troubleshooting](../../guides/how-to/troubleshooting.md) - Common issues

---

*Return to [API Overview](api-overview.md) or [main README](../../README.md).*