# Mermaid Diagram Test

This document contains various Mermaid diagrams to test the rendering functionality.

## Basic Flowchart

```mermaid
graph TD
    A[Start] --> B{Is it working?}
    B -->|Yes| C[Great!]
    B -->|No| D[Fix it]
    D --> B
    C --> E[End]
```

## Sequence Diagram

```mermaid
sequenceDiagram
    participant User
    participant App
    participant Server
    
    User->>App: Click button
    App->>Server: Request data
    Server-->>App: Return data
    App-->>User: Display result
```

## Class Diagram

```mermaid
classDiagram
    class Animal {
        +String name
        +int age
        +void eat()
        +void sleep()
    }
    class Dog {
        +void bark()
    }
    class Cat {
        +void meow()
    }
    Animal <|-- Dog
    Animal <|-- Cat
```

## Gantt Chart

```mermaid
gantt
    title Project Schedule
    dateFormat  YYYY-MM-DD
    section Phase 1
    Task 1           :a1, 2024-01-01, 30d
    Task 2           :after a1, 20d
    section Phase 2
    Task 3           :2024-02-01, 12d
    Task 4           :24d
```

## Regular Code Block

This is a regular code block that should not be treated as a Mermaid diagram:

```javascript
function hello() {
    console.log("Hello, World!");
}
```

## State Diagram

```mermaid
stateDiagram-v2
    [*] --> Idle
    Idle --> Processing : Start
    Processing --> Success : Complete
    Processing --> Error : Fail
    Success --> [*]
    Error --> Idle : Retry
```

## End of Document

That's all for the Mermaid diagram test!