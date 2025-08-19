# Mermaid Performance Test

This document contains various mermaid diagrams to test the performance optimizations.

## Simple Flowchart

```mermaid
graph TD
    A[Start] --> B{Is it working?}
    B -->|Yes| C[Great!]
    B -->|No| D[Debug]
    D --> A
```

## Sequence Diagram

```mermaid
sequenceDiagram
    participant Alice
    participant Bob
    Alice->>Bob: Hello Bob, how are you?
    Bob-->>Alice: Great, thanks for asking!
    Alice->>Bob: Want to grab coffee?
    Bob-->>Alice: Absolutely!
```

## State Diagram

```mermaid
stateDiagram-v2
    [*] --> Loading
    Loading --> Success
    Loading --> Error
    Success --> [*]
    Error --> Retry
    Retry --> Loading
```

This should render much faster now with:
- Local mermaid.js bundle (no CDN delays)
- Removed artificial timeouts
- Performance config optimizations