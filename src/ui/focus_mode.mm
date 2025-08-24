//
//  focus_mode.mm
//  Inkwell
//
//  Real focus mode implementation with paragraph-level highlighting
//

#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>
#include <vector>
#include <optional>

@interface MDFocusMode : NSObject {
    NSTextView* _textView;
    NSScrollView* _scrollView;
    BOOL _enabled;
    NSRange _currentFocusRange;
    NSRange _previousFocusRange;
    NSTimer* _animationTimer;
    CGFloat _animationProgress;
    
    // Paragraph tracking
    std::vector<NSRange> _paragraphRanges;
    NSInteger _currentParagraphIndex;
    
    // Visual settings
    CGFloat _focusedOpacity;
    CGFloat _nearOpacity;
    CGFloat _farOpacity;
    CGFloat _animationDuration;
    
    // Original attributes backup
    NSAttributedString* _originalContent;
}

- (instancetype)initWithTextView:(NSTextView*)textView scrollView:(NSScrollView*)scrollView;
- (void)setEnabled:(BOOL)enabled;
- (BOOL)isEnabled;
- (void)updateFocus;
- (void)moveFocusUp;
- (void)moveFocusDown;
- (void)moveFocusToLocation:(NSPoint)location;
- (void)moveFocusToParagraphIndex:(NSInteger)index;

@end

@implementation MDFocusMode

- (instancetype)initWithTextView:(NSTextView*)textView scrollView:(NSScrollView*)scrollView {
    self = [super init];
    if (self) {
        _textView = textView;
        _scrollView = scrollView;
        _enabled = NO;
        _currentFocusRange = NSMakeRange(0, 0);
        _previousFocusRange = NSMakeRange(0, 0);
        _currentParagraphIndex = 0;
        _animationProgress = 1.0;
        
        // Visual settings
        _focusedOpacity = 1.0;
        _nearOpacity = 0.6;
        _farOpacity = 0.25;
        _animationDuration = 0.25; // 250ms animations
        
        // Listen for text changes
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(textDidChange:)
                                                     name:NSTextDidChangeNotification
                                                   object:_textView];
        
        // Listen for scroll changes
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(scrollViewDidScroll:)
                                                     name:NSViewBoundsDidChangeNotification
                                                   object:_scrollView.contentView];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    if (_animationTimer) {
        [_animationTimer invalidate];
    }
}

- (void)setEnabled:(BOOL)enabled {
    if (_enabled == enabled) return;
    
    _enabled = enabled;
    
    if (_enabled) {
        // Store original content
        _originalContent = [[NSAttributedString alloc] initWithAttributedString:_textView.textStorage];
        
        // Parse paragraphs
        [self parseParagraphs];
        
        // Find current paragraph based on cursor or visible area
        [self findCurrentParagraph];
        
        // Apply focus effect
        [self updateFocus];
        
        // Animate in
        [self animateFocusTransition];
    } else {
        // Restore original content
        if (_originalContent) {
            [_textView.textStorage setAttributedString:_originalContent];
            _originalContent = nil;
        }
    }
}

- (BOOL)isEnabled {
    return _enabled;
}

- (void)parseParagraphs {
    _paragraphRanges.clear();
    
    NSString* text = _textView.string;
    NSUInteger length = text.length;
    NSUInteger location = 0;
    
    while (location < length) {
        NSRange paragraphRange = [text paragraphRangeForRange:NSMakeRange(location, 0)];
        
        // Skip empty paragraphs
        NSString* paragraphText = [text substringWithRange:paragraphRange];
        NSString* trimmed = [paragraphText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        
        if (trimmed.length > 0) {
            _paragraphRanges.push_back(paragraphRange);
        }
        
        location = NSMaxRange(paragraphRange);
    }
}

- (void)findCurrentParagraph {
    // Focus follows the reading position (upper third of viewport for natural reading)
    NSRect visibleRect = _scrollView.contentView.visibleRect;
    
    // Use a point in the upper third of the viewport (natural reading position)
    CGFloat readingPositionY = visibleRect.origin.y + (visibleRect.size.height * 0.33);
    NSPoint readingPoint = NSMakePoint(NSMidX(visibleRect), readingPositionY);
    
    // Convert the point to text coordinates
    NSPoint pointInTextView = [_textView convertPoint:readingPoint fromView:_scrollView.contentView];
    
    // Find which character is at this point
    NSUInteger glyphIndex = [_textView.layoutManager glyphIndexForPoint:pointInTextView
                                                        inTextContainer:_textView.textContainer];
    NSUInteger charIndex = [_textView.layoutManager characterIndexForGlyphAtIndex:glyphIndex];
    
    // Find which paragraph contains this character
    NSInteger newParagraphIndex = -1;
    for (size_t i = 0; i < _paragraphRanges.size(); i++) {
        if (NSLocationInRange(charIndex, _paragraphRanges[i])) {
            newParagraphIndex = i;
            break;
        }
    }
    
    // Only update if we found a valid paragraph and it's different from current
    if (newParagraphIndex >= 0 && newParagraphIndex != _currentParagraphIndex) {
        _previousFocusRange = _currentFocusRange;
        _currentParagraphIndex = newParagraphIndex;
        _currentFocusRange = _paragraphRanges[newParagraphIndex];
        
        NSLog(@"Focus moved to paragraph %ld based on scroll", (long)_currentParagraphIndex);
    }
    
    // Fallback: if we couldn't find a paragraph, keep the current one
    if (newParagraphIndex < 0 && !_paragraphRanges.empty() && _currentParagraphIndex < 0) {
        _currentParagraphIndex = 0;
        _currentFocusRange = _paragraphRanges[0];
    }
}

- (void)updateFocus {
    if (!_enabled || _paragraphRanges.empty()) return;
    
    // Work directly with the text storage to preserve fonts and other attributes
    NSTextStorage* textStorage = _textView.textStorage;
    
    // Begin editing
    [textStorage beginEditing];
    
    // First, restore original colors from the backup (preserving fonts)
    if (_originalContent) {
        [_originalContent enumerateAttributesInRange:NSMakeRange(0, _originalContent.length)
                                              options:0
                                           usingBlock:^(NSDictionary *attrs, NSRange range, BOOL *stop) {
            // Only restore color attributes, preserve everything else
            NSColor* originalColor = attrs[NSForegroundColorAttributeName];
            if (originalColor) {
                [textStorage addAttribute:NSForegroundColorAttributeName
                                    value:originalColor
                                    range:range];
            }
            // Remove any background colors we might have added
            [textStorage removeAttribute:NSBackgroundColorAttributeName range:range];
        }];
    }
    
    // Calculate opacity for each paragraph based on distance from focus
    for (size_t i = 0; i < _paragraphRanges.size(); i++) {
        NSRange range = _paragraphRanges[i];
        CGFloat opacity = [self opacityForParagraphAtIndex:i];
        
        // Get the existing color at this range
        NSColor* existingColor = [textStorage attribute:NSForegroundColorAttributeName
                                                atIndex:range.location
                                         effectiveRange:NULL];
        if (!existingColor) {
            existingColor = [NSColor labelColor];
        }
        
        // Apply opacity to the existing color
        NSColor* dimmedColor = [existingColor colorWithAlphaComponent:opacity];
        
        [textStorage addAttribute:NSForegroundColorAttributeName
                            value:dimmedColor
                            range:range];
        
        // Add subtle background highlight for focused paragraph
        if (i == _currentParagraphIndex) {
            NSColor* highlightColor = [NSColor colorWithWhite:0.0 alpha:0.03];
            if (@available(macOS 10.14, *)) {
                // Adjust for dark mode
                NSAppearance* appearance = [NSApp effectiveAppearance];
                NSString* appearanceName = [appearance bestMatchFromAppearancesWithNames:@[NSAppearanceNameAqua, NSAppearanceNameDarkAqua]];
                if ([appearanceName isEqualToString:NSAppearanceNameDarkAqua]) {
                    highlightColor = [NSColor colorWithWhite:1.0 alpha:0.05];
                }
            }
            
            [textStorage addAttribute:NSBackgroundColorAttributeName
                                value:highlightColor
                                range:range];
        }
    }
    
    // End editing
    [textStorage endEditing];
}

- (CGFloat)opacityForParagraphAtIndex:(NSInteger)index {
    if (!_enabled) return 1.0;
    
    NSInteger distance = labs(index - _currentParagraphIndex);
    
    // Smooth gradient based on distance
    if (distance == 0) {
        return _focusedOpacity;
    } else if (distance == 1) {
        return _nearOpacity;
    } else if (distance == 2) {
        return (_nearOpacity + _farOpacity) / 2.0;
    } else {
        return _farOpacity;
    }
}

- (void)animateFocusTransition {
    if (_animationTimer) {
        [_animationTimer invalidate];
    }
    
    _animationProgress = 0.0;
    _animationTimer = [NSTimer scheduledTimerWithTimeInterval:1.0/60.0 // 60 FPS
                                                        target:self
                                                      selector:@selector(animationTick:)
                                                      userInfo:nil
                                                       repeats:YES];
}

- (void)animationTick:(NSTimer*)timer {
    _animationProgress += (1.0/60.0) / _animationDuration;
    
    if (_animationProgress >= 1.0) {
        _animationProgress = 1.0;
        [_animationTimer invalidate];
        _animationTimer = nil;
    }
    
    // Ease-out cubic animation curve
    CGFloat easedProgress = 1.0 - pow(1.0 - _animationProgress, 3.0);
    
    // Update focus with eased progress
    [self updateFocus];
}

- (void)moveFocusUp {
    if (!_enabled || _paragraphRanges.empty()) return;
    
    NSLog(@"MDFocusMode: Moving focus up from paragraph %ld", (long)_currentParagraphIndex);
    
    if (_currentParagraphIndex > 0) {
        _previousFocusRange = _currentFocusRange;
        _currentParagraphIndex--;
        _currentFocusRange = _paragraphRanges[_currentParagraphIndex];
        
        NSLog(@"MDFocusMode: New focus on paragraph %ld", (long)_currentParagraphIndex);
        
        [self updateFocus];
        [self scrollToFocusedParagraph];
        [self animateFocusTransition];
    }
}

- (void)moveFocusDown {
    if (!_enabled || _paragraphRanges.empty()) return;
    
    NSLog(@"MDFocusMode: Moving focus down from paragraph %ld", (long)_currentParagraphIndex);
    
    if (_currentParagraphIndex < _paragraphRanges.size() - 1) {
        _previousFocusRange = _currentFocusRange;
        _currentParagraphIndex++;
        _currentFocusRange = _paragraphRanges[_currentParagraphIndex];
        
        NSLog(@"MDFocusMode: New focus on paragraph %ld", (long)_currentParagraphIndex);
        
        [self updateFocus];
        [self scrollToFocusedParagraph];
        [self animateFocusTransition];
    }
}

- (void)moveFocusToLocation:(NSPoint)location {
    if (!_enabled || _paragraphRanges.empty()) return;
    
    NSUInteger glyphIndex = [_textView.layoutManager glyphIndexForPoint:location
                                                        inTextContainer:_textView.textContainer];
    NSUInteger charIndex = [_textView.layoutManager characterIndexForGlyphAtIndex:glyphIndex];
    
    for (size_t i = 0; i < _paragraphRanges.size(); i++) {
        if (NSLocationInRange(charIndex, _paragraphRanges[i])) {
            if (i != _currentParagraphIndex) {
                _previousFocusRange = _currentFocusRange;
                _currentParagraphIndex = i;
                _currentFocusRange = _paragraphRanges[i];
                
                [self updateFocus];
                [self animateFocusTransition];
            }
            break;
        }
    }
}

- (void)moveFocusToParagraphIndex:(NSInteger)index {
    if (!_enabled || _paragraphRanges.empty()) return;
    if (index < 0 || index >= _paragraphRanges.size()) return;
    
    if (index != _currentParagraphIndex) {
        _previousFocusRange = _currentFocusRange;
        _currentParagraphIndex = index;
        _currentFocusRange = _paragraphRanges[index];
        
        [self updateFocus];
        [self scrollToFocusedParagraph];
        [self animateFocusTransition];
    }
}

- (void)scrollToFocusedParagraph {
    if (!_enabled || NSEqualRanges(_currentFocusRange, NSMakeRange(0, 0))) return;
    
    // Get the rect for the focused paragraph
    NSRange glyphRange = [_textView.layoutManager glyphRangeForCharacterRange:_currentFocusRange
                                                          actualCharacterRange:NULL];
    NSRect paragraphRect = [_textView.layoutManager boundingRectForGlyphRange:glyphRange
                                                               inTextContainer:_textView.textContainer];
    
    // Calculate center position (typewriter mode)
    NSRect visibleRect = _scrollView.contentView.visibleRect;
    CGFloat targetY = paragraphRect.origin.y + (paragraphRect.size.height / 2.0) - (visibleRect.size.height / 2.0);
    targetY = MAX(0, MIN(targetY, _textView.frame.size.height - visibleRect.size.height));
    
    // Smooth scroll animation
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext* context) {
        context.duration = _animationDuration;
        context.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        
        NSPoint targetPoint = NSMakePoint(visibleRect.origin.x, targetY);
        [_scrollView.contentView.animator setBoundsOrigin:targetPoint];
    }];
}

#pragma mark - Notifications

- (void)textDidChange:(NSNotification*)notification {
    if (_enabled) {
        [self parseParagraphs];
        [self findCurrentParagraph];
        [self updateFocus];
    }
}

- (void)scrollViewDidScroll:(NSNotification*)notification {
    if (_enabled) {
        // Update focus based on scroll position - focus follows viewport
        // No animation for scroll-based updates (immediate feedback)
        [self findCurrentParagraph];
        [self updateFocus];
    }
}

@end