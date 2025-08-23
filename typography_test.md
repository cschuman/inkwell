# Typography Refinement Test

## Lists with Golden Ratio Spacing

### Unordered Lists

- **First principle** — Form follows function
- **Second principle** — Less is more
- **Third principle** — Unity of art and technology
  - Nested item with subtle indentation
  - Another nested item showcasing hierarchy
    - Deep nesting maintains readability
    - Golden ratio spacing throughout

### Ordered Lists

1. Start with clear hierarchy
2. Continue with consistent spacing
3. Maintain visual rhythm
   1. Sub-items align perfectly
   2. Numbers are elegantly styled
   3. Each level has its own weight

## Code Blocks with Refined Design

### JavaScript Example

```javascript
// Fibonacci sequence with golden ratio
function goldenFibonacci(n) {
    const phi = 1.618033988749895;
    
    if (n <= 1) return n;
    
    // Calculate using Binet's formula
    const sqrt5 = Math.sqrt(5);
    const result = (Math.pow(phi, n) - Math.pow(-phi, -n)) / sqrt5;
    
    return Math.round(result);
}
```

### Python Example

```python
# Typography scale generator
def generate_scale(base_size=16, ratio=1.618):
    """Generate a typographic scale using golden ratio"""
    scale = []
    size = base_size
    
    for i in range(8):
        scale.append(round(size, 2))
        size *= ratio
    
    return scale
```

### CSS Example

```css
/* Bauhaus-inspired design tokens */
:root {
    --spacing-xs: 2px;
    --spacing-sm: 5px;
    --spacing-md: 8px;
    --spacing-lg: 13px;
    --spacing-xl: 21px;
    --spacing-xxl: 34px;
    --spacing-xxxl: 55px;
    --spacing-huge: 89px;
}
```

## Mixed Content Test

The following list combines various elements to test alignment:

- **Typography** is the foundation of design
  - Serif fonts for body text provide elegance
  - Sans-serif for headings creates contrast
- **Code** can be inline like `const phi = 1.618` or in blocks
- **Spacing** follows mathematical principles:
  1. Golden ratio (φ = 1.618...)
  2. Fibonacci sequence
  3. Modular scales

### Complex Nested Structure

1. **Primary Level**
   - Secondary point A
   - Secondary point B
     1. Tertiary numbered item
     2. Another numbered item
        - Quaternary bullet
        - Final depth level
   - Back to secondary
2. **Another Primary**
   - Clean hierarchy maintained
   - Visual rhythm preserved

## Inline Code Test

Working with `monospace` fonts requires careful attention to `letter-spacing` and `line-height`. The golden ratio helps us achieve `1.618` times the base size for optimal readability.

---

*Design is not just what it looks like and feels like. Design is how it works.*  
— Steve Jobs