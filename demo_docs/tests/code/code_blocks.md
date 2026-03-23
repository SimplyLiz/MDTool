# Code Block Test

Testing various code block syntax highlighting and rendering.

## Navigation
- [🏠 Back to Main Index](../index.md)
- [📊 Native Graph Examples](../graphs/native_graphs.md)
- [📈 Mermaid Graph Examples](../graphs/mermaid_graphs.md)

## Plain Code Block (no language)

```
function hello() {
  console.log("Hello world!");
}
```

## JavaScript Code Block

```javascript
function hello() {
  console.log("Hello world!");
}
```

## Dart Code Block

```dart
void main() {
  print('Hello, World!');
}
```

## Python Code Block

```python
def hello_world():
    print("Hello, World!")
    return "success"

if __name__ == "__main__":
    hello_world()
```

## JSON Code Block

```json
{
  "name": "MDTool Demo",
  "version": "1.0.0",
  "description": "Comprehensive demo documentation",
  "features": [
    "Graph rendering",
    "Code highlighting", 
    "Link navigation"
  ]
}
```

## YAML Code Block

```yaml
version: 1.0
project:
  name: MDTool Demo
  features:
    - graph_rendering
    - code_highlighting
    - link_navigation
  config:
    theme: auto
    render_graphs: true
```

## SQL Code Block

```sql
SELECT 
    users.name,
    users.email,
    COUNT(orders.id) as order_count
FROM users
LEFT JOIN orders ON users.id = orders.user_id
WHERE users.active = true
GROUP BY users.id, users.name, users.email
ORDER BY order_count DESC;
```

## Another Plain Code Block

```
Some plain text
without syntax highlighting
that should maintain formatting
```

## Inline code test

Here's some `inline code` that should also have proper background styling.

The `console.log()` function and `print()` statement should be highlighted inline.

---

*Return to [Main Index](../index.md) for complete project navigation.*