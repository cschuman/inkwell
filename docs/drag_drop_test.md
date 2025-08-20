# Drag & Drop Test Document

## Testing Instructions

This file is for testing the drag & drop functionality.

### How to Test:

1. **Drag this file onto the Inkwell window**
   - The window should briefly change color when you hover with the file
   - The file should open immediately when dropped

2. **Drag this file onto the Inkwell icon in the Dock**
   - The file should open in the existing window

3. **Try dragging multiple files**
   - Select this file and another markdown file
   - Drag them together onto the window
   - Should open the first file and show an alert about the others

### Features Working:

- ✅ Drag files onto window
- ✅ Drag files onto Dock icon  
- ✅ Visual feedback (window color change)
- ✅ Multiple file type support (.md, .markdown, .txt, etc.)
- ✅ Multiple file alert

### Sample Content

Here's some **bold text**, *italic text*, and `inline code`.

```python
# Code block test
def hello_world():
    print("Drag & Drop is working!")
```

> This is a blockquote to test rendering.

- List item 1
- List item 2
- List item 3

---

If you can read this after dragging the file, drag & drop is working! 🎉