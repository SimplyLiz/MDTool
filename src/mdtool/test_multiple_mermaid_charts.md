# Phase 2 Performance Test - Multiple Mermaid Charts

This document tests WebView pooling with multiple charts that should render much faster with reused WebView instances.

## Chart 1: Simple Flowchart

```mermaid
graph LR
    A[User] --> B[Login]
    B --> C{Valid?}
    C -->|Yes| D[Dashboard]
    C -->|No| E[Error]
    E --> B
```

## Chart 2: Sequence Diagram

```mermaid
sequenceDiagram
    participant U as User
    participant A as App
    participant S as Server
    U->>A: Click Login
    A->>S: Validate Credentials
    S-->>A: Success
    A-->>U: Show Dashboard
```

## Chart 3: State Diagram

```mermaid
stateDiagram-v2
    [*] --> Idle
    Idle --> Loading : user_action
    Loading --> Success : data_loaded
    Loading --> Error : network_error
    Success --> Idle : timeout
    Error --> Idle : retry
```

## Chart 4: Gantt Chart

```mermaid
gantt
    title Development Timeline
    dateFormat YYYY-MM-DD
    section Phase 1
    Research     :done, research, 2024-01-01, 2024-01-07
    Design       :done, design, 2024-01-08, 2024-01-15
    section Phase 2
    Development  :active, dev, 2024-01-16, 2024-02-15
    Testing      :test, after dev, 10d
```

## Chart 5: Class Diagram

```mermaid
classDiagram
    class WebViewPool {
        -availableControllers: List
        -usedControllers: Set
        +getController(): WebViewController
        +returnController(controller): void
    }
    
    class MermaidRenderer {
        +render(): Widget
        +validate(): Result
    }
    
    WebViewPool <-- MermaidRenderer : uses
```

**Expected Performance with Phase 2:**
- First chart: ~500ms (pool initialization)  
- Subsequent charts: ~100-200ms (reused WebView)
- Memory usage: ~150MB total vs ~500MB+ without pooling
- Global mermaid initialization happens only once