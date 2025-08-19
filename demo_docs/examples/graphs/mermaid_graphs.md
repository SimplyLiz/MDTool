# Mermaid Graph Examples

Comprehensive collection of graphs, charts, and diagrams using Mermaid syntax.

## Navigation
- [🏠 Back to Main Index](../../index.md)
- [📊 Native Graph Examples](native_graphs.md) - Non-Mermaid graphs
- [👋 Hello World Example](../basic/hello-world.md)
- [🔧 Complex Example](../advanced/complex-example.md)
- [📚 Tutorial 01](../../guides/tutorials/tutorial-01.md)

## Introduction

This document demonstrates various types of graphs, charts, and diagrams that can be embedded in markdown documents. These examples showcase different visualization techniques for documentation, system design, and data presentation.

## Table of Contents
- [Mermaid Diagrams](#mermaid-diagrams)
- [ASCII Art Graphs](#ascii-art-graphs)
- [Mathematical Expressions](#mathematical-expressions)
- [Data Visualization](#data-visualization)

## Mermaid Diagrams

### Flowcharts

#### Basic Flowchart
```mermaid
flowchart TD
    A[Start] --> B{Decision}
    B -->|Yes| C[Process A]
    B -->|No| D[Process B]
    C --> E[End]
    D --> E
```

#### Complex System Architecture
```mermaid
flowchart TB
    subgraph "User Layer"
        U1[Web Browser]
        U2[Mobile App]
        U3[Desktop App]
    end
    
    subgraph "API Gateway"
        AG[Load Balancer]
        A1[Auth Service]
        A2[Rate Limiter]
    end
    
    subgraph "Microservices"
        MS1[User Service]
        MS2[Data Service]
        MS3[Notification Service]
        MS4[Analytics Service]
    end
    
    subgraph "Data Layer"
        DB1[(Primary DB)]
        DB2[(Cache Redis)]
        DB3[(Analytics DB)]
        S3[File Storage]
    end
    
    U1 --> AG
    U2 --> AG
    U3 --> AG
    
    AG --> A1
    AG --> A2
    A1 --> MS1
    A2 --> MS2
    
    MS1 --> DB1
    MS2 --> DB1
    MS2 --> DB2
    MS3 --> DB1
    MS4 --> DB3
    MS2 --> S3
```

### Sequence Diagrams

#### API Authentication Flow
```mermaid
sequenceDiagram
    participant User
    participant App
    participant AuthServer
    participant API
    participant Database
    
    User->>App: Login Request
    App->>AuthServer: Authenticate
    AuthServer->>Database: Verify Credentials
    Database-->>AuthServer: User Valid
    AuthServer-->>App: JWT Token
    App->>API: API Request + Token
    API->>AuthServer: Validate Token
    AuthServer-->>API: Token Valid
    API->>Database: Query Data
    Database-->>API: Return Data
    API-->>App: Response
    App-->>User: Display Data
```

#### Microservices Communication
```mermaid
sequenceDiagram
    participant Client
    participant Gateway
    participant UserService
    participant DataService
    participant NotificationService
    participant Database
    participant Queue
    
    Client->>Gateway: Request User Data
    Gateway->>UserService: Get User Info
    UserService->>Database: Query User
    Database-->>UserService: User Data
    
    UserService->>DataService: Get Related Data
    DataService->>Database: Query Data
    Database-->>DataService: Data Results
    
    DataService->>Queue: Log Activity
    Queue->>NotificationService: Send Notification
    NotificationService->>Client: Push Notification
    
    DataService-->>UserService: Data Response
    UserService-->>Gateway: Complete Response
    Gateway-->>Client: Final Response
```

### Class Diagrams

#### Object-Oriented Design
```mermaid
classDiagram
    class User {
        +String id
        +String name
        +String email
        +Date createdAt
        +authenticate()
        +updateProfile()
        +deactivate()
    }
    
    class Document {
        +String id
        +String title
        +String content
        +Date modifiedAt
        +User author
        +save()
        +delete()
        +share()
    }
    
    class Project {
        +String id
        +String name
        +String description
        +User[] members
        +Document[] documents
        +addMember()
        +removeMember()
        +archive()
    }
    
    class Permission {
        +String id
        +String type
        +String resource
        +User user
        +grant()
        +revoke()
    }
    
    User ||--o{ Document : "authors"
    User ||--o{ Project : "member of"
    Project ||--o{ Document : "contains"
    User ||--o{ Permission : "has"
    Document ||--o{ Permission : "protected by"
```

### State Diagrams

#### Document Workflow
```mermaid
stateDiagram-v2
    [*] --> Draft
    Draft --> Review : submit
    Draft --> Archived : cancel
    
    Review --> Approved : approve
    Review --> Rejected : reject
    Review --> Draft : request_changes
    
    Approved --> Published : publish
    Approved --> Archived : archive
    
    Rejected --> Draft : revise
    Rejected --> Archived : abandon
    
    Published --> Archived : retire
    Published --> Review : update
    
    Archived --> [*]
```

#### User Session Management
```mermaid
stateDiagram-v2
    [*] --> Logged_Out
    Logged_Out --> Authenticating : login
    Authenticating --> Logged_In : success
    Authenticating --> Logged_Out : failure
    
    Logged_In --> Active : activity
    Logged_In --> Idle : timeout
    
    Active --> Idle : no_activity
    Idle --> Active : user_action
    Idle --> Logged_Out : session_timeout
    
    Logged_In --> Logged_Out : logout
    Active --> Logged_Out : logout
```

### Entity Relationship Diagrams

#### Database Schema
```mermaid
erDiagram
    USER {
        string id PK
        string email UK
        string name
        string password_hash
        datetime created_at
        datetime updated_at
        boolean active
    }
    
    PROJECT {
        string id PK
        string name
        string description
        string owner_id FK
        datetime created_at
        datetime updated_at
        string status
    }
    
    DOCUMENT {
        string id PK
        string title
        text content
        string project_id FK
        string author_id FK
        datetime created_at
        datetime modified_at
        string version
    }
    
    PROJECT_MEMBER {
        string project_id FK
        string user_id FK
        string role
        datetime joined_at
    }
    
    DOCUMENT_VERSION {
        string id PK
        string document_id FK
        string author_id FK
        text content
        string change_summary
        datetime created_at
    }
    
    USER ||--o{ PROJECT : "owns"
    USER ||--o{ DOCUMENT : "authors"
    PROJECT ||--o{ DOCUMENT : "contains"
    USER }o--o{ PROJECT : "member of"
    DOCUMENT ||--o{ DOCUMENT_VERSION : "has versions"
    USER ||--o{ DOCUMENT_VERSION : "creates"
```

### Gantt Charts

#### Project Timeline
```mermaid
gantt
    title Demo Project Development Timeline
    dateFormat  YYYY-MM-DD
    section Planning
    Requirements Analysis    :done, req, 2024-01-01, 2024-01-15
    System Design          :done, design, 2024-01-10, 2024-01-30
    
    section Development
    Backend Development     :active, backend, 2024-01-20, 2024-03-15
    Frontend Development    :frontend, 2024-02-01, 2024-03-30
    Database Setup         :done, db, 2024-01-25, 2024-02-10
    
    section Testing
    Unit Testing           :testing, 2024-02-15, 2024-03-31
    Integration Testing    :integration, 2024-03-15, 2024-04-15
    User Acceptance        :uat, 2024-04-01, 2024-04-30
    
    section Deployment
    Production Setup       :deploy, 2024-04-15, 2024-04-30
    Go Live               :milestone, 2024-05-01, 0d
```

### Pie Charts

#### Resource Allocation
```mermaid
pie title Resource Allocation
    "Development" : 45
    "Testing" : 20
    "Documentation" : 15
    "DevOps" : 10
    "Management" : 10
```

#### Technology Stack Usage
```mermaid
pie title Technology Stack Distribution
    "Frontend (React)" : 30
    "Backend (Node.js)" : 25
    "Database (PostgreSQL)" : 15
    "Infrastructure (AWS)" : 12
    "Monitoring" : 8
    "Testing Tools" : 10
```

### Git Flow Diagram

#### Development Workflow
```mermaid
gitgraph
    commit id: "Initial"
    branch develop
    checkout develop
    commit id: "Setup"
    branch feature/auth
    checkout feature/auth
    commit id: "Add auth"
    commit id: "Auth tests"
    checkout develop
    merge feature/auth
    branch feature/api
    checkout feature/api
    commit id: "Add API"
    commit id: "API docs"
    checkout develop
    merge feature/api
    checkout main
    merge develop
    commit id: "Release v1.0"
    checkout develop
    commit id: "Hotfix prep"
    checkout main
    commit id: "Hotfix v1.0.1"
```

### User Journey Diagram

#### User Onboarding Experience
```mermaid
journey
    title User Onboarding Journey
    section Discovery
      Visit Website: 5: User
      Read About: 4: User
      Check Pricing: 3: User
    section Registration  
      Sign Up: 3: User
      Email Verification: 2: User
      Profile Setup: 4: User
    section First Use
      Tutorial: 4: User
      Create First Project: 5: User
      Invite Team Member: 3: User
    section Adoption
      Daily Usage: 5: User
      Advanced Features: 4: User
      Feedback: 5: User
```

### Requirement Diagrams

#### System Requirements
```mermaid
requirementDiagram
    requirement Authentication {
        id: 1
        text: "Users must authenticate before accessing the system"
        risk: high
        verifymethod: test
    }
    
    requirement DataSecurity {
        id: 2
        text: "All data must be encrypted in transit and at rest"
        risk: high
        verifymethod: inspection
    }
    
    requirement Performance {
        id: 3
        text: "System must respond within 200ms for 95% of requests"
        risk: medium
        verifymethod: test
    }
    
    requirement Scalability {
        id: 4
        text: "System must handle 10,000 concurrent users"
        risk: medium
        verifymethod: test
    }
    
    element WebApp {
        type: "Application"
    }
    
    element Database {
        type: "Storage"
    }
    
    element LoadBalancer {
        type: "Infrastructure"
    }
    
    WebApp - satisfies -> Authentication
    Database - satisfies -> DataSecurity
    LoadBalancer - satisfies -> Performance
    LoadBalancer - satisfies -> Scalability
```

### Mindmap

#### Project Structure Mindmap
```mermaid
mindmap
  root((Demo Project))
    Documentation
      User Guides
        Getting Started
        Advanced Usage
      Developer Guides
        Architecture
        Testing
    Examples
      Basic
        Hello World
      Advanced
        Complex Example
      Graphs
        Mermaid Diagrams
        Data Visualization
    API Reference
      Overview
      Endpoints
      Changelog
    Tutorials
      Tutorial 01
      Tutorial 02
    Guides
      Deployment
      Troubleshooting
```

### Quadrant Chart

#### Feature Prioritization
```mermaid
quadrantChart
    title Feature Prioritization Matrix
    x-axis Low Impact --> High Impact
    y-axis Low Effort --> High Effort
    
    quadrant-1 Quick Wins
    quadrant-2 Major Projects
    quadrant-3 Fill-ins
    quadrant-4 Thankless Tasks
    
    User Authentication: [0.8, 0.9]
    Dashboard: [0.7, 0.8]
    Mobile App: [0.9, 0.9]
    API Rate Limiting: [0.6, 0.3]
    Documentation: [0.4, 0.2]
    Dark Mode: [0.3, 0.1]
    Advanced Analytics: [0.8, 0.7]
    Bug Fixes: [0.2, 0.1]
```

### XY Chart

#### Performance Metrics
```mermaid
xychart-beta
    title "System Performance Over Time"
    x-axis [Jan, Feb, Mar, Apr, May, Jun]
    y-axis "Response Time (ms)" 0 --> 500
    line [120, 110, 95, 105, 90, 85]
    line [200, 180, 160, 150, 140, 130]
```

### Timeline

#### Project Milestones
```mermaid
timeline
    title Project Development Timeline
    
    Q1 2024 : Planning Phase
             : Requirements Gathering
             : System Design
             : Technology Selection
    
    Q2 2024 : Development Phase
             : Backend Implementation
             : Frontend Development
             : Database Schema
             
    Q3 2024 : Testing Phase
             : Unit Testing
             : Integration Testing
             : Performance Testing
             
    Q4 2024 : Deployment Phase
             : Production Deployment
             : User Training
             : Go-Live Support
```

## ASCII Art Graphs

### Simple Bar Chart
```
Project Progress
                              
Backend     ████████████████████ 100%
Frontend    ████████████████     80%
Testing     ██████████           50%
Docs        ████████             40%
Deployment  ██                   10%

0%    25%   50%   75%   100%
```

### Network Topology
```
                    Internet
                        │
                   [Router]
                   /   │   \
                  /    │    \
            [Switch] [Switch] [WiFi AP]
            /   │   \     │      │
           /    │    \    │      │
      [PC1] [PC2] [Server] [PC3] [Mobile]
```

### System Architecture
```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Load Balancer │────│   Web Server    │────│    Database     │
│                 │    │                 │    │                 │
│   nginx         │    │   Node.js       │    │   PostgreSQL    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│     Cache       │    │   File Storage  │    │   Monitoring    │
│                 │    │                 │    │                 │
│     Redis       │    │      S3         │    │   Prometheus    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## Mathematical Expressions

### Basic Mathematics
```
Linear Function: f(x) = mx + b

Quadratic Formula: x = (-b ± √(b² - 4ac)) / 2a

Exponential Growth: P(t) = P₀ × e^(rt)

Logarithmic Scale: log₁₀(x)
```

### Algorithm Complexity
```
Big O Notation Examples:

O(1)      - Constant Time
O(log n)  - Logarithmic Time
O(n)      - Linear Time
O(n log n)- Linearithmic Time  
O(n²)     - Quadratic Time
O(2ⁿ)     - Exponential Time

Graph: Time Complexity
   │
   │     O(2ⁿ)
   │    ╱
   │   ╱
   │  ╱ O(n²)
   │ ╱╱
   │╱╱ O(n log n)
   ├── O(n)
   ├── O(log n)
   ├── O(1)
   └──────────────── Input Size (n)
```

## Data Visualization

### Table with Trends
| Metric | Q1 | Q2 | Q3 | Q4 | Trend |
|--------|----|----|----|----|-------|
| Users | 1,000 | 2,500 | 4,200 | 6,800 | 📈 |
| Revenue | $10K | $28K | $52K | $85K | 📈 |
| Errors | 45 | 32 | 18 | 12 | 📉 |
| Uptime | 99.1% | 99.5% | 99.8% | 99.9% | 📈 |

### Status Dashboard
```
🟢 API Service: Operational (99.9% uptime)
🟢 Database: Healthy (12ms avg response)
🟡 Cache: Warning (85% memory usage)
🔴 Email Service: Down (investigating)
🟢 File Storage: Operational (99.8% uptime)

Current Load: ████████░░ 80%
```

### Process Flow with Metrics
```
┌─────────┐    ┌─────────┐    ┌─────────┐    ┌─────────┐
│ Request │───▶│ Auth    │───▶│Process  │───▶│Response │
│         │    │         │    │         │    │         │
│1000/sec │    │ 950/sec │    │ 920/sec │    │ 915/sec │
└─────────┘    └─────────┘    └─────────┘    └─────────┘
     ▼              ▼              ▼              ▼
  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐
  │Rate     │  │Auth     │  │Business │  │Success  │
  │Limited  │  │Failed   │  │Logic    │  │Rate     │
  │50/sec   │  │30/sec   │  │Error    │  │91.5%    │
  │         │  │         │  │5/sec    │  │         │
  └─────────┘  └─────────┘  └─────────┘  └─────────┘
```

## Graph Usage in Documentation

### When to Use Different Graph Types

#### Flowcharts
- **Use for**: Process flows, decision trees, algorithm logic
- **Example**: [System architecture](../docs/developer-guide/architecture.md)
- **Best practice**: Keep nodes concise and flows logical

#### Sequence Diagrams  
- **Use for**: API interactions, user workflows, system communications
- **Example**: [Authentication flow](../api/reference/api-overview.md#authentication-methods)
- **Best practice**: Show time progression clearly

#### Class Diagrams
- **Use for**: Object-oriented design, database schemas, system relationships
- **Example**: [Architecture patterns](../docs/developer-guide/architecture.md#design-patterns)
- **Best practice**: Focus on key relationships

#### State Diagrams
- **Use for**: Workflow states, user journeys, system states
- **Example**: [Testing procedures](../docs/developer-guide/testing.md#test-categories)
- **Best practice**: Define clear state transitions

#### Gantt Charts
- **Use for**: Project timelines, milestone tracking, resource planning
- **Example**: [Deployment planning](../guides/how-to/deployment.md#deployment-procedures)
- **Best practice**: Include dependencies and critical path

## Integration with Project Documentation

### Cross-References to Other Documents
These graph examples complement the project documentation:

- **Architecture diagrams** support [system design documentation](../docs/developer-guide/architecture.md)
- **Sequence diagrams** enhance [API documentation](../api/reference/api-overview.md)
- **Flowcharts** clarify [user guides](../docs/user-guide/getting-started.md)
- **State diagrams** illustrate [testing workflows](../docs/developer-guide/testing.md)

### Best Practices for Graph Integration

1. **Consistency**: Use similar styling across all diagrams
2. **Context**: Provide explanatory text before and after graphs
3. **Updates**: Keep graphs synchronized with code/system changes
4. **Accessibility**: Include alt text and descriptions
5. **Performance**: Consider diagram complexity and rendering time

## Testing Graph Rendering

To test these graphs:
1. **Open this file** in MD Tool
2. **Verify Mermaid rendering** - all diagrams should display properly
3. **Check ASCII art** - should maintain formatting
4. **Test navigation links** - all cross-references should work
5. **Review in different themes** - ensure readability in dark/light modes

## Related Documentation

### Examples
- [Hello World Example](basic/hello-world.md) - Simple markdown usage
- [Complex Example](advanced/complex-example.md) - Advanced navigation patterns

### User Guides  
- [Getting Started](../docs/user-guide/getting-started.md) - Basic concepts
- [Advanced Usage](../docs/user-guide/advanced-usage.md) - Power features

### Developer Resources
- [Architecture Overview](../docs/developer-guide/architecture.md) - System design
- [Testing Guide](../docs/developer-guide/testing.md) - Validation procedures

### API Documentation
- [API Overview](../api/reference/api-overview.md) - Complete API guide
- [API Endpoints](../api/reference/endpoints.md) - Endpoint reference

---

*Return to [Main Index](../../index.md) or [Native Graph Examples](native_graphs.md) for complete project navigation.*