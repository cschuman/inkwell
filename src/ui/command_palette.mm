#import "ui/command_palette.h"
#import <QuartzCore/QuartzCore.h>

static const CGFloat kPaletteWidth = 600.0;
static const CGFloat kPaletteMaxHeight = 400.0;
static const CGFloat kRowHeight = 56.0;
static const CGFloat kSearchFieldHeight = 48.0;
static const CGFloat kCornerRadius = 12.0;
static const CGFloat kAnimationDuration = 0.25;
static const NSInteger kMaxVisibleResults = 7;

@implementation CommandPaletteView

- (instancetype)initWithFrame:(NSRect)frameRect {
    self = [super initWithFrame:frameRect];
    if (self) {
        [self setupViews];
    }
    return self;
}

- (void)setupViews {
    self.wantsLayer = YES;
    self.layer.cornerRadius = kCornerRadius;
    self.layer.masksToBounds = YES;
    
    // Glass morphism background
    self.backgroundView = [[NSVisualEffectView alloc] initWithFrame:self.bounds];
    self.backgroundView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    self.backgroundView.material = NSVisualEffectMaterialHUDWindow;
    self.backgroundView.blendingMode = NSVisualEffectBlendingModeBehindWindow;
    self.backgroundView.state = NSVisualEffectStateActive;
    self.backgroundView.wantsLayer = YES;
    [self addSubview:self.backgroundView];
    
    // Add subtle border
    self.layer.borderWidth = 0.5;
    self.layer.borderColor = [[NSColor whiteColor] colorWithAlphaComponent:0.1].CGColor;
    
    // Shadow for depth
    NSShadow* shadow = [[NSShadow alloc] init];
    shadow.shadowColor = [[NSColor blackColor] colorWithAlphaComponent:0.3];
    shadow.shadowOffset = NSMakeSize(0, -10);
    shadow.shadowBlurRadius = 30;
    self.shadow = shadow;
    
    // Search field with custom styling
    self.searchField = [[NSTextField alloc] initWithFrame:NSMakeRect(20, self.bounds.size.height - kSearchFieldHeight - 20, 
                                                                      self.bounds.size.width - 40, kSearchFieldHeight)];
    self.searchField.autoresizingMask = NSViewWidthSizable | NSViewMinYMargin;
    self.searchField.bordered = NO;
    self.searchField.focusRingType = NSFocusRingTypeNone;
    self.searchField.backgroundColor = [NSColor clearColor];
    self.searchField.font = [NSFont systemFontOfSize:18 weight:NSFontWeightLight];
    self.searchField.textColor = [NSColor labelColor];
    self.searchField.placeholderString = @"Type to search documents, headings, or actions...";
    self.searchField.wantsLayer = YES;
    
    // Custom search field background
    CALayer* searchBackground = [CALayer layer];
    searchBackground.frame = self.searchField.bounds;
    searchBackground.backgroundColor = [[NSColor blackColor] colorWithAlphaComponent:0.2].CGColor;
    searchBackground.cornerRadius = 8;
    [self.searchField.layer addSublayer:searchBackground];
    
    [self.backgroundView addSubview:self.searchField];
    
    // Results table
    self.scrollView = [[NSScrollView alloc] initWithFrame:NSMakeRect(0, 0, 
                                                                      self.bounds.size.width, 
                                                                      self.bounds.size.height - kSearchFieldHeight - 30)];
    self.scrollView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    self.scrollView.hasVerticalScroller = NO;
    self.scrollView.hasHorizontalScroller = NO;
    self.scrollView.borderType = NSNoBorder;
    self.scrollView.backgroundColor = [NSColor clearColor];
    
    self.resultsTable = [[NSTableView alloc] initWithFrame:self.scrollView.bounds];
    self.resultsTable.backgroundColor = [NSColor clearColor];
    self.resultsTable.rowHeight = kRowHeight;
    self.resultsTable.intercellSpacing = NSMakeSize(0, 0);
    self.resultsTable.headerView = nil;
    self.resultsTable.gridStyleMask = NSTableViewGridNone;
    
    NSTableColumn* column = [[NSTableColumn alloc] initWithIdentifier:@"CommandColumn"];
    column.width = self.bounds.size.width;
    [self.resultsTable addTableColumn:column];
    
    self.scrollView.documentView = self.resultsTable;
    [self.backgroundView addSubview:self.scrollView];
}

- (void)animateIn {
    // Start with scale and opacity animation (Things 3 style)
    self.alphaValue = 0;
    self.layer.transform = CATransform3DMakeScale(0.95, 0.95, 1.0);
    
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext* context) {
        context.duration = kAnimationDuration;
        context.timingFunction = [CAMediaTimingFunction functionWithControlPoints:0.4 :0.0 :0.2 :1.0]; // Stripe's signature curve
        
        self.animator.alphaValue = 1.0;
        self.layer.transform = CATransform3DIdentity;
    } completionHandler:^{
        // Add subtle bounce at end
        [NSAnimationContext runAnimationGroup:^(NSAnimationContext* context) {
            context.duration = 0.1;
            context.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
            self.layer.transform = CATransform3DMakeScale(1.02, 1.02, 1.0);
        } completionHandler:^{
            [NSAnimationContext runAnimationGroup:^(NSAnimationContext* context) {
                context.duration = 0.1;
                self.layer.transform = CATransform3DIdentity;
            }];
        }];
    }];
}

- (void)animateOut:(void(^)(void))completion {
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext* context) {
        context.duration = kAnimationDuration * 0.8; // Faster out
        context.timingFunction = [CAMediaTimingFunction functionWithControlPoints:0.4 :0.0 :1.0 :1.0];
        
        self.animator.alphaValue = 0;
        self.layer.transform = CATransform3DMakeScale(0.97, 0.97, 1.0);
    } completionHandler:completion];
}

- (void)updateResults:(NSArray<NSDictionary*>*)results {
    // This method is called to update the visible results
    // The table view will be reloaded by the controller
}

@end

@implementation CommandPaletteController

- (instancetype)init {
    NSRect frame = NSMakeRect(0, 0, kPaletteWidth, kPaletteMaxHeight);
    NSWindow* window = [[NSWindow alloc] initWithContentRect:frame
                                                    styleMask:NSWindowStyleMaskBorderless
                                                      backing:NSBackingStoreBuffered
                                                        defer:NO];
    window.level = NSFloatingWindowLevel;
    window.backgroundColor = [NSColor clearColor];
    window.opaque = NO;
    window.hasShadow = NO;
    
    self = [super initWithWindow:window];
    if (self) {
        [self setupPalette];
        [self registerDefaultCommands];
    }
    return self;
}

- (void)setupPalette {
    self.filteredCommands = [NSMutableArray array];
    self.allCommands = [NSMutableArray array];
    
    NSRect frame = NSMakeRect(0, 0, kPaletteWidth, kPaletteMaxHeight);
    self.paletteView = [[CommandPaletteView alloc] initWithFrame:frame];
    self.window.contentView = self.paletteView;
    
    self.paletteView.searchField.delegate = self;
    self.paletteView.resultsTable.delegate = self;
    self.paletteView.resultsTable.dataSource = self;
    
    // Setup keyboard navigation
    NSClickGestureRecognizer* click = [[NSClickGestureRecognizer alloc] initWithTarget:self action:@selector(handleClick:)];
    [self.paletteView.resultsTable addGestureRecognizer:click];
}

- (void)registerDefaultCommands {
    // Core actions with keyboard shortcuts
    [self registerCommand:CommandType::Action 
                    title:@"Toggle Theme" 
                 subtitle:@"Switch between light and dark mode"
                     icon:@"🌓"
                 shortcut:@"⌘T"
                   action:^{ [self toggleTheme]; }];
    
    [self registerCommand:CommandType::Action 
                    title:@"Export as PDF" 
                 subtitle:@"Save the current document as PDF"
                     icon:@"📄"
                 shortcut:@"⌘E"
                   action:^{ [self exportPDF]; }];
    
    [self registerCommand:CommandType::Action 
                    title:@"Toggle Focus Mode" 
                 subtitle:@"Hide all distractions"
                     icon:@"🎯"
                 shortcut:@"⌘."
                   action:^{ [self toggleFocusMode]; }];
    
    [self registerCommand:CommandType::Action 
                    title:@"Toggle Table of Contents" 
                 subtitle:@"Show or hide the document outline"
                     icon:@"📑"
                 shortcut:@"⌘\\"
                   action:^{ [self toggleTOC]; }];
    
    [self registerCommand:CommandType::Search 
                    title:@"Search in Document" 
                 subtitle:@"Find text in the current document"
                     icon:@"🔍"
                 shortcut:@"⌘F"
                   action:^{ [self showSearch]; }];
}

- (void)show {
    NSLog(@"CommandPaletteController: show called");
    
    // Check if window exists
    if (!self.window) {
        NSLog(@"ERROR: Command palette window is nil!");
        return;
    }
    
    // Check if palette view exists
    if (!self.paletteView) {
        NSLog(@"ERROR: Command palette view is nil!");
        return;
    }
    
    if ([self.delegate respondsToSelector:@selector(commandPaletteWillShow:)]) {
        [self.delegate commandPaletteWillShow:self];
    }
    
    // Position in center of parent window
    NSWindow* parentWindow = [NSApp mainWindow];
    if (parentWindow) {
        NSRect parentFrame = parentWindow.frame;
        NSRect paletteFrame = self.window.frame;
        
        CGFloat x = NSMidX(parentFrame) - (paletteFrame.size.width / 2);
        CGFloat y = NSMaxY(parentFrame) - 150; // Near top, Linear style
        
        [self.window setFrameOrigin:NSMakePoint(x, y)];
        NSLog(@"Positioned palette at: %.0f, %.0f", x, y);
    } else {
        NSLog(@"WARNING: No main window, centering on screen");
        [self.window center];
    }
    
    NSLog(@"Making palette window key and visible");
    [self.window makeKeyAndOrderFront:nil];
    
    if (self.paletteView) {
        [self.paletteView animateIn];
        
        if (self.paletteView.searchField) {
            [self.paletteView.searchField becomeFirstResponder];
            // Reset search
            self.paletteView.searchField.stringValue = @"";
        }
    }
    
    [self filterCommands:@""];
    NSLog(@"Command palette should now be visible");
}

- (void)hide {
    [self.paletteView animateOut:^{
        [self.window orderOut:nil];
        
        if ([self.delegate respondsToSelector:@selector(commandPaletteDidHide:)]) {
            [self.delegate commandPaletteDidHide:self];
        }
    }];
}

- (void)registerCommand:(CommandType)type 
                   title:(NSString*)title 
                subtitle:(NSString*)subtitle
                    icon:(NSString*)icon
                shortcut:(NSString*)shortcut
                  action:(dispatch_block_t)action {
    NSDictionary* command = @{
        @"type": @((int)type),
        @"title": title ?: @"",
        @"subtitle": subtitle ?: @"",
        @"icon": icon ?: @"",
        @"shortcut": shortcut ?: @"",
        @"action": action ?: ^{}
    };
    
    [self.allCommands addObject:command];
}

- (void)clearCommands {
    [self.allCommands removeAllObjects];
    [self.filteredCommands removeAllObjects];
    [self registerDefaultCommands];
}

- (void)updateRecentDocuments:(NSArray<NSString*>*)documents {
    // Remove old document commands
    NSMutableArray* toRemove = [NSMutableArray array];
    for (NSDictionary* cmd in self.allCommands) {
        if ([cmd[@"type"] intValue] == (int)CommandType::Document) {
            [toRemove addObject:cmd];
        }
    }
    [self.allCommands removeObjectsInArray:toRemove];
    
    // Add new document commands
    for (NSString* path in documents) {
        NSString* filename = [path lastPathComponent];
        NSString* directory = [[path stringByDeletingLastPathComponent] lastPathComponent];
        
        [self registerCommand:CommandType::Document
                        title:filename
                     subtitle:[NSString stringWithFormat:@"in %@", directory]
                         icon:@"📝"
                     shortcut:nil
                       action:^{ [self openDocument:path]; }];
    }
}

- (void)updateHeadings:(NSArray<NSDictionary*>*)headings {
    // Remove old heading commands
    NSMutableArray* toRemove = [NSMutableArray array];
    for (NSDictionary* cmd in self.allCommands) {
        if ([cmd[@"type"] intValue] == (int)CommandType::Heading) {
            [toRemove addObject:cmd];
        }
    }
    [self.allCommands removeObjectsInArray:toRemove];
    
    // Add heading commands with level indicators
    for (NSDictionary* heading in headings) {
        NSString* title = heading[@"title"];
        NSInteger level = [heading[@"level"] integerValue];
        NSString* icon = (level == 1) ? @"#" : (level == 2) ? @"##" : @"###";
        
        [self registerCommand:CommandType::Heading
                        title:title
                     subtitle:[NSString stringWithFormat:@"Level %ld heading", level]
                         icon:icon
                     shortcut:nil
                       action:^{ [self jumpToHeading:heading]; }];
    }
}

#pragma mark - Fuzzy Search

- (double)fuzzyScore:(NSString*)query target:(NSString*)target {
    if (query.length == 0) return 1.0;
    if (target.length == 0) return 0.0;
    
    query = [query lowercaseString];
    target = [target lowercaseString];
    
    // Exact match
    if ([target isEqualToString:query]) return 2.0;
    
    // Starts with query
    if ([target hasPrefix:query]) return 1.5;
    
    // Contains query
    if ([target containsString:query]) return 1.0;
    
    // Fuzzy match (character by character)
    NSInteger queryIndex = 0;
    NSInteger targetIndex = 0;
    double score = 0;
    double consecutiveBonus = 0;
    
    while (queryIndex < query.length && targetIndex < target.length) {
        if ([query characterAtIndex:queryIndex] == [target characterAtIndex:targetIndex]) {
            score += 1.0 + consecutiveBonus;
            consecutiveBonus += 0.5; // Bonus for consecutive matches
            queryIndex++;
        } else {
            consecutiveBonus = 0;
        }
        targetIndex++;
    }
    
    // All query characters found
    if (queryIndex == query.length) {
        return score / query.length;
    }
    
    return 0;
}

- (void)filterCommands:(NSString*)query {
    [self.filteredCommands removeAllObjects];
    
    if (query.length == 0) {
        // Show recent/frequent commands when empty
        NSInteger count = MIN(kMaxVisibleResults, self.allCommands.count);
        for (NSInteger i = 0; i < count; i++) {
            [self.filteredCommands addObject:self.allCommands[i]];
        }
    } else {
        // Score and sort all commands
        NSMutableArray* scoredCommands = [NSMutableArray array];
        
        for (NSDictionary* cmd in self.allCommands) {
            double titleScore = [self fuzzyScore:query target:cmd[@"title"]];
            double subtitleScore = [self fuzzyScore:query target:cmd[@"subtitle"]] * 0.5;
            double totalScore = titleScore + subtitleScore;
            
            if (totalScore > 0) {
                NSMutableDictionary* scoredCmd = [cmd mutableCopy];
                scoredCmd[@"score"] = @(totalScore);
                [scoredCommands addObject:scoredCmd];
            }
        }
        
        // Sort by score
        [scoredCommands sortUsingComparator:^NSComparisonResult(NSDictionary* a, NSDictionary* b) {
            return [b[@"score"] compare:a[@"score"]];
        }];
        
        // Take top results
        NSInteger count = MIN(kMaxVisibleResults, scoredCommands.count);
        for (NSInteger i = 0; i < count; i++) {
            [self.filteredCommands addObject:scoredCommands[i]];
        }
    }
    
    [self.paletteView.resultsTable reloadData];
    
    // Auto-select first result
    if (self.filteredCommands.count > 0) {
        [self.paletteView.resultsTable selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
    }
}

#pragma mark - NSTextFieldDelegate

- (void)controlTextDidChange:(NSNotification*)notification {
    NSTextField* searchField = notification.object;
    [self filterCommands:searchField.stringValue];
}

- (BOOL)control:(NSControl*)control textView:(NSTextView*)textView doCommandBySelector:(SEL)commandSelector {
    if (commandSelector == @selector(moveUp:)) {
        NSInteger selectedRow = self.paletteView.resultsTable.selectedRow;
        if (selectedRow > 0) {
            [self.paletteView.resultsTable selectRowIndexes:[NSIndexSet indexSetWithIndex:selectedRow - 1] byExtendingSelection:NO];
            [self.paletteView.resultsTable scrollRowToVisible:selectedRow - 1];
        }
        return YES;
    } else if (commandSelector == @selector(moveDown:)) {
        NSInteger selectedRow = self.paletteView.resultsTable.selectedRow;
        if (selectedRow < self.filteredCommands.count - 1) {
            [self.paletteView.resultsTable selectRowIndexes:[NSIndexSet indexSetWithIndex:selectedRow + 1] byExtendingSelection:NO];
            [self.paletteView.resultsTable scrollRowToVisible:selectedRow + 1];
        }
        return YES;
    } else if (commandSelector == @selector(insertNewline:)) {
        [self executeSelectedCommand];
        return YES;
    } else if (commandSelector == @selector(cancelOperation:)) {
        [self hide];
        return YES;
    }
    
    return NO;
}

#pragma mark - NSTableViewDataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView*)tableView {
    return self.filteredCommands.count;
}

#pragma mark - NSTableViewDelegate

- (NSView*)tableView:(NSTableView*)tableView viewForTableColumn:(NSTableColumn*)tableColumn row:(NSInteger)row {
    NSDictionary* command = self.filteredCommands[row];
    
    NSView* cellView = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, tableView.bounds.size.width, kRowHeight)];
    cellView.wantsLayer = YES;
    
    // Hover effect
    if (row == tableView.selectedRow) {
        cellView.layer.backgroundColor = [[NSColor selectedControlColor] colorWithAlphaComponent:0.1].CGColor;
    }
    
    // Icon
    NSTextField* iconField = [[NSTextField alloc] initWithFrame:NSMakeRect(16, 14, 28, 28)];
    iconField.stringValue = command[@"icon"];
    iconField.font = [NSFont systemFontOfSize:20];
    iconField.bordered = NO;
    iconField.editable = NO;
    iconField.backgroundColor = [NSColor clearColor];
    [cellView addSubview:iconField];
    
    // Title
    NSTextField* titleField = [[NSTextField alloc] initWithFrame:NSMakeRect(56, 28, 400, 20)];
    titleField.stringValue = command[@"title"];
    titleField.font = [NSFont systemFontOfSize:14 weight:NSFontWeightMedium];
    titleField.bordered = NO;
    titleField.editable = NO;
    titleField.backgroundColor = [NSColor clearColor];
    titleField.textColor = [NSColor labelColor];
    [cellView addSubview:titleField];
    
    // Subtitle
    NSTextField* subtitleField = [[NSTextField alloc] initWithFrame:NSMakeRect(56, 8, 400, 16)];
    subtitleField.stringValue = command[@"subtitle"];
    subtitleField.font = [NSFont systemFontOfSize:11];
    subtitleField.bordered = NO;
    subtitleField.editable = NO;
    subtitleField.backgroundColor = [NSColor clearColor];
    subtitleField.textColor = [NSColor secondaryLabelColor];
    [cellView addSubview:subtitleField];
    
    // Shortcut (if present)
    if ([command[@"shortcut"] length] > 0) {
        NSTextField* shortcutField = [[NSTextField alloc] initWithFrame:NSMakeRect(tableView.bounds.size.width - 80, 18, 60, 20)];
        shortcutField.stringValue = command[@"shortcut"];
        shortcutField.font = [NSFont monospacedSystemFontOfSize:11 weight:NSFontWeightRegular];
        shortcutField.alignment = NSTextAlignmentRight;
        shortcutField.bordered = NO;
        shortcutField.editable = NO;
        shortcutField.backgroundColor = [NSColor clearColor];
        shortcutField.textColor = [NSColor tertiaryLabelColor];
        [cellView addSubview:shortcutField];
    }
    
    return cellView;
}

- (void)tableViewSelectionDidChange:(NSNotification*)notification {
    // Add subtle selection animation
    NSInteger selectedRow = self.paletteView.resultsTable.selectedRow;
    if (selectedRow >= 0) {
        NSView* rowView = [self.paletteView.resultsTable viewAtColumn:0 row:selectedRow makeIfNecessary:YES];
        
        CABasicAnimation* pulse = [CABasicAnimation animationWithKeyPath:@"backgroundColor"];
        pulse.fromValue = (id)[NSColor clearColor].CGColor;
        pulse.toValue = (id)[[NSColor selectedControlColor] colorWithAlphaComponent:0.1].CGColor;
        pulse.duration = 0.15;
        pulse.fillMode = kCAFillModeForwards;
        pulse.removedOnCompletion = NO;
        
        [rowView.layer addAnimation:pulse forKey:@"selectionPulse"];
    }
}

#pragma mark - Actions

- (void)executeSelectedCommand {
    NSInteger selectedRow = self.paletteView.resultsTable.selectedRow;
    if (selectedRow >= 0 && selectedRow < self.filteredCommands.count) {
        NSDictionary* command = self.filteredCommands[selectedRow];
        
        // Hide palette first for smooth transition
        [self hide];
        
        // Execute action after a brief delay for animation
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            dispatch_block_t action = command[@"action"];
            if (action) {
                action();
            }
            
            if ([self.delegate respondsToSelector:@selector(commandPalette:didSelectCommand:)]) {
                [self.delegate commandPalette:self didSelectCommand:command];
            }
        });
    }
}

- (void)handleClick:(NSClickGestureRecognizer*)recognizer {
    NSPoint clickPoint = [recognizer locationInView:self.paletteView.resultsTable];
    NSInteger row = [self.paletteView.resultsTable rowAtPoint:clickPoint];
    
    if (row >= 0) {
        [self.paletteView.resultsTable selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
        [self executeSelectedCommand];
    }
}

#pragma mark - Command Actions (Delegates to main controller)

- (void)toggleTheme {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ToggleTheme" object:nil];
}

- (void)exportPDF {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ExportPDF" object:nil];
}

- (void)toggleFocusMode {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ToggleFocusMode" object:nil];
}

- (void)toggleTOC {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ToggleTOC" object:nil];
}

- (void)showSearch {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ShowSearch" object:nil];
}

- (void)openDocument:(NSString*)path {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"OpenDocument" object:path];
}

- (void)jumpToHeading:(NSDictionary*)heading {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"JumpToHeading" object:heading];
}

@end