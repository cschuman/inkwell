#pragma once

#import <Cocoa/Cocoa.h>
#include <vector>
#include <string>
#include <functional>

enum class CommandType {
    Document,      // Open recent document
    Heading,       // Jump to heading
    Action,        // Execute action (export, toggle theme, etc.)
    Search         // Search in document
};

struct CommandItem {
    CommandType type;
    NSString* title;
    NSString* subtitle;
    NSString* icon;
    NSString* shortcut;
    std::function<void()> action;
    double score;  // For fuzzy matching
};

@interface CommandPaletteView : NSView
@property (nonatomic, strong) NSVisualEffectView* backgroundView;
@property (nonatomic, strong) NSTextField* searchField;
@property (nonatomic, strong) NSTableView* resultsTable;
@property (nonatomic, strong) NSScrollView* scrollView;
@property (nonatomic, assign) NSInteger selectedIndex;

- (void)animateIn;
- (void)animateOut:(void(^)(void))completion;
- (void)updateResults:(NSArray<NSDictionary*>*)results;
@end

@interface CommandPaletteController : NSWindowController <NSTextFieldDelegate, NSTableViewDelegate, NSTableViewDataSource>

@property (nonatomic, strong) CommandPaletteView* paletteView;
@property (nonatomic, strong) NSMutableArray<NSDictionary*>* filteredCommands;
@property (nonatomic, strong) NSMutableArray<NSDictionary*>* allCommands;
@property (nonatomic, assign) id delegate;

// Public methods
- (void)show;
- (void)hide;
- (void)registerCommand:(CommandType)type 
                   title:(NSString*)title 
                subtitle:(NSString*)subtitle
                    icon:(NSString*)icon
                shortcut:(NSString*)shortcut
                  action:(dispatch_block_t)action;
- (void)clearCommands;
- (void)updateRecentDocuments:(NSArray<NSString*>*)documents;
- (void)updateHeadings:(NSArray<NSDictionary*>*)headings;

// Fuzzy search
- (double)fuzzyScore:(NSString*)query target:(NSString*)target;
- (void)filterCommands:(NSString*)query;

@end

// Protocol for command palette delegate
@protocol CommandPaletteDelegate <NSObject>
@optional
- (void)commandPaletteWillShow:(CommandPaletteController*)controller;
- (void)commandPaletteDidHide:(CommandPaletteController*)controller;
- (void)commandPalette:(CommandPaletteController*)controller didSelectCommand:(NSDictionary*)command;
@end