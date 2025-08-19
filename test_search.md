# Search Test Document

This document contains various **search** terms to test the search functionality.

## Testing Search Crashes

The word search appears multiple times in this document. We need to test:

1. Opening search with Cmd+F
2. Typing a search term
3. Navigating through results with Cmd+G
4. Closing search with ESC
5. Reopening search immediately after

### Code Blocks

```javascript
// The word search in a code block
function searchDatabase() {
    return "search results";
}
```

### More Search Terms

- Search term one
- Search term two  
- Search term three

The goal is to ensure that rapidly opening and closing search doesn't cause a crash.

**Search** should be highlighted when found.

