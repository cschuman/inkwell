#import <Cocoa/Cocoa.h>

@interface SimpleCommandPalette : NSWindowController <NSTableViewDelegate, NSTableViewDataSource, NSTextFieldDelegate>
@property (nonatomic, strong) NSTextField* searchField;
@property (nonatomic, strong) NSTableView* resultsTable;
@property (nonatomic, strong) NSMutableArray* commands;
@property (nonatomic, strong) NSMutableArray* filteredCommands;
@end

@implementation SimpleCommandPalette

- (instancetype)init {
    // Create a simple window
    NSRect frame = NSMakeRect(0, 0, 500, 300);
    NSWindow* window = [[NSWindow alloc] initWithContentRect:frame
                                                    styleMask:NSWindowStyleMaskTitled | NSWindowStyleMaskClosable
                                                      backing:NSBackingStoreBuffered
                                                        defer:NO];
    
    self = [super initWithWindow:window];
    if (self) {
        [self setupUI];
        [self loadCommands];
    }
    return self;
}

- (void)setupUI {
    NSView* contentView = self.window.contentView;
    
    // Search field at top
    self.searchField = [[NSTextField alloc] initWithFrame:NSMakeRect(10, 260, 480, 30)];
    self.searchField.placeholderString = @"Type to search...";
    self.searchField.delegate = self;
    [contentView addSubview:self.searchField];
    
    // Results table below
    NSScrollView* scrollView = [[NSScrollView alloc] initWithFrame:NSMakeRect(10, 10, 480, 240)];
    self.resultsTable = [[NSTableView alloc] initWithFrame:scrollView.bounds];
    
    NSTableColumn* column = [[NSTableColumn alloc] initWithIdentifier:@"command"];
    column.title = @"Commands";
    column.width = 460;
    [self.resultsTable addTableColumn:column];
    
    self.resultsTable.delegate = self;
    self.resultsTable.dataSource = self;
    
    scrollView.documentView = self.resultsTable;
    scrollView.hasVerticalScroller = YES;
    [contentView addSubview:scrollView];
}

- (void)loadCommands {
    self.commands = [NSMutableArray arrayWithObjects:
        @{@"name": @"Toggle Theme", @"action": @"toggleTheme"},
        @{@"name": @"Export as PDF", @"action": @"exportPDF"},
        @{@"name": @"Toggle Table of Contents", @"action": @"toggleTOC"},
        @{@"name": @"Toggle File Browser", @"action": @"toggleFiles"},
        @{@"name": @"Refresh File Browser", @"action": @"refreshFiles"},
        @{@"name": @"Search in Document", @"action": @"search"},
        @{@"name": @"Open Recent Files", @"action": @"openRecent"},
        nil];
    
    self.filteredCommands = [self.commands mutableCopy];
    [self.resultsTable reloadData];
}

- (void)show {
    [self.window center];
    [self.window makeKeyAndOrderFront:nil];
    [self.searchField becomeFirstResponder];
}

#pragma mark - NSTextFieldDelegate

- (void)controlTextDidChange:(NSNotification*)notification {
    NSString* searchText = self.searchField.stringValue.lowercaseString;
    
    if (searchText.length == 0) {
        self.filteredCommands = [self.commands mutableCopy];
    } else {
        self.filteredCommands = [NSMutableArray array];
        for (NSDictionary* cmd in self.commands) {
            if ([[cmd[@"name"] lowercaseString] rangeOfString:searchText].location != NSNotFound) {
                [self.filteredCommands addObject:cmd];
            }
        }
    }
    
    [self.resultsTable reloadData];
}

#pragma mark - NSTableViewDataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView*)tableView {
    return self.filteredCommands.count;
}

#pragma mark - NSTableViewDelegate

- (NSView*)tableView:(NSTableView*)tableView viewForTableColumn:(NSTableColumn*)tableColumn row:(NSInteger)row {
    NSTextField* cell = [[NSTextField alloc] init];
    cell.stringValue = self.filteredCommands[row][@"name"];
    cell.bordered = NO;
    cell.editable = NO;
    cell.backgroundColor = [NSColor clearColor];
    return cell;
}

- (void)tableViewSelectionDidChange:(NSNotification*)notification {
    NSInteger row = self.resultsTable.selectedRow;
    if (row >= 0 && row < self.filteredCommands.count) {
        NSDictionary* command = self.filteredCommands[row];
        NSLog(@"Selected command: %@", command[@"name"]);
        
        // Execute the action
        NSString* action = command[@"action"];
        if ([action isEqualToString:@"toggleTheme"]) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"ToggleTheme" object:nil];
        } else if ([action isEqualToString:@"exportPDF"]) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"ExportPDF" object:nil];
        } else if ([action isEqualToString:@"toggleTOC"]) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"ToggleTOC" object:nil];
        } else if ([action isEqualToString:@"toggleFiles"]) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"ToggleFiles" object:nil];
        } else if ([action isEqualToString:@"refreshFiles"]) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"RefreshFiles" object:nil];
        } else if ([action isEqualToString:@"search"]) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"ShowSearch" object:nil];
        }
        
        // Close the palette
        [self.window close];
    }
}

@end

// Export a simple C function to create and show the palette
extern "C" void showSimpleCommandPalette() {
    static SimpleCommandPalette* palette = nil;
    if (!palette) {
        palette = [[SimpleCommandPalette alloc] init];
    }
    [palette show];
}