//
//  OEMenuScrollView.m
//  OEThemeFactory
//
//  Created by Faustino Osuna on 4/10/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "OEMenuScrollView.h"
#import "OEMenuContentView.h"
#import "OEMenuContentView+OEMenuView.h"

@interface _OEMenuScroller : NSScroller
@end

@implementation OEMenuScrollView

- (id)initWithFrame:(NSRect)frame
{
    if((self = [super initWithFrame:frame]))
    {
        [self setDrawsBackground:NO];
        [self setBorderType:NSNoBorder];
        [self setHasVerticalScroller:YES];
        [self setVerticalScroller:[[_OEMenuScroller alloc] init]];
        [self setVerticalScrollElasticity:NSScrollElasticityNone];
        [self setDocumentView:[[OEMenuContentView alloc] initWithFrame:[self bounds]]];
    }
    return self;
}

- (void)OE_layoutIfNeeded
{
    [(OEMenuContentView *)[self documentView] OE_layoutIfNeeded];
}

- (void)setStyle:(OEMenuStyle)style
{
    [(OEMenuContentView *)[self documentView] setStyle:style];
}

- (OEMenuStyle)style
{
    return [(OEMenuContentView *)[self documentView] style];
}

- (NSSize)intrinsicSize
{
    return [(OEMenuContentView *)[self documentView] intrinsicSize];
}

- (void)setItemArray:(NSArray *)itemArray
{
    OEMenuContentView *contentView = (OEMenuContentView *)[self documentView];
    [contentView setItemArray:itemArray];
    [[self documentView] setFrameSize:[contentView intrinsicSize]];
}

- (void)setFrameSize:(NSSize)newSize
{
    OEMenuContentView *contentView = [self documentView];

    NSSize size = [contentView frame].size;
    size.width = newSize.width;
    [super setFrameSize:newSize];
    [contentView setFrameSize:size];

    if(size.height > newSize.height) [[self contentView] scrollToPoint:NSMakePoint(0.0, size.height - newSize.height)];
}

- (NSArray *)itemArray
{
    return [(OEMenuContentView *)[self documentView] itemArray];
}

- (void)setContainImages:(BOOL)containImages
{
    [(OEMenuContentView *)[self documentView] setContainImages:containImages];
}

- (BOOL)doesMenuContainImages
{
    return [(OEMenuContentView *)[self documentView] doesMenuContainImages];
}

@end

@implementation _OEMenuScroller

+ (BOOL)isCompatibleWithOverlayScrollers
{
    return YES;
}

- (void)drawKnob
{
}

- (void)drawKnobSlotInRect:(NSRect)slotRect highlight:(BOOL)flag
{
}

+ (CGFloat)scrollerWidthForControlSize:(NSControlSize)controlSize scrollerStyle:(NSScrollerStyle)scrollerStyle
{
    return 0.0;
}

+ (CGFloat)scrollerWidth
{
    return 0.0;
}

@end