#pragma once

#import <Cocoa/Cocoa.h>

@interface MDSmoothScrollView : NSScrollView

@property (nonatomic) BOOL enableMomentum;
@property (nonatomic) BOOL enableRubberBand;
@property (nonatomic) CGFloat scrollSensitivity;

@end