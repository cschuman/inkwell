# Focus Mode Test Document

This is the first paragraph of our test document. It contains enough text to properly test the focus mode functionality. When focus mode is activated, this paragraph should be highlighted when selected.

## Section One: Introduction

The introduction section provides context for the document. In focus mode, each paragraph should be individually selectable and highlightable. The surrounding paragraphs should gradually fade based on their distance from the focused content.

Here's another paragraph with different content. Focus mode should allow smooth navigation between paragraphs using the arrow keys. The transition animations should be smooth and pleasant.

## Section Two: Features

Focus mode includes several key features:
- Paragraph-level highlighting
- Keyboard navigation with arrow keys
- Click to focus on specific paragraphs
- Smooth scroll animations
- Gradual opacity fading for context

### Subsection: Navigation

You can navigate through the document in multiple ways. The up and down arrow keys move between paragraphs sequentially. Clicking on any paragraph immediately moves focus to that location.

The ESC key exits focus mode, returning the document to its normal viewing state. This provides a quick way to toggle between focused reading and regular browsing.

## Section Three: Technical Details

The implementation uses native Cocoa APIs for text manipulation. Each paragraph is detected and tracked independently. The opacity changes are applied using NSAttributedString attributes.

Animation timing follows standard Material Design curves for smooth, natural motion. The duration is set to 250ms for most transitions, providing responsive feedback without feeling sluggish.

### Performance Considerations

Focus mode is designed to be lightweight and performant. The paragraph detection happens once when entering focus mode, and updates only when the document changes. The rendering uses native text view capabilities without additional overhead.

## Conclusion

This test document demonstrates the focus mode functionality. Each paragraph should be clearly distinguishable when focused, with smooth transitions between selections. The visual hierarchy helps guide reading through longer documents.

The final paragraph wraps up our test. Focus mode should enhance the reading experience by reducing distractions and guiding attention to the current content.