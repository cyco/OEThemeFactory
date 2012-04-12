//
//  OEMenuScrollView.m
//  OEThemeFactory
//
//  Created by Faustino Osuna on 4/10/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "OEMenuScrollView.h"
#import "OEMenuDocumentView.h"
#import "OEMenuDocumentView+OEMenuView.h"
#import "OEMenu.h"
#import "OEMenu+OEMenuViewAdditions.h"

// Fake menu scroller (doesn't render anything)
@interface _OEMenuScroller : NSScroller
@end

@implementation OEMenuScrollView
@synthesize scrollable = _scrollable;

- (id)initWithFrame:(NSRect)frame
{
    if((self = [super initWithFrame:frame]))
    {
        [self setDrawsBackground:NO];
        [self setBorderType:NSNoBorder];
        [self setHasVerticalScroller:YES];
        [self setVerticalScroller:[[_OEMenuScroller alloc] init]];
        [self setVerticalScrollElasticity:NSScrollElasticityNone];

        // Add an observer to the frame and bounds of the document view as it will determine if / when / what scroll up and scroll down bottoms would be displayed and changes to the highlighted item
        OEMenuDocumentView *documentView = [[OEMenuDocumentView alloc] initWithFrame:[self bounds]];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(documentViewBoundsDidChange:) name:NSViewBoundsDidChangeNotification object:[self contentView]];

        [self setDocumentView:documentView];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)documentViewBoundsDidChange:(NSNotification *)notification
{
    if([[self window] isVisible])
    {
        // Update the highlighted item to be the item underneath the mouse
        OEMenuView *view = [(OEMenu *)[self window] OE_view];
        [view highlightItemAtPoint:[view convertPointFromBase:[[self window] convertScreenToBase:[NSEvent mouseLocation]]]];
    }
}

- (void)setStyle:(OEMenuStyle)style
{
    [(OEMenuDocumentView *)[self documentView] setStyle:style];
}

- (OEMenuStyle)style
{
    return [(OEMenuDocumentView *)[self documentView] style];
}

- (NSSize)intrinsicSize
{
    return [(OEMenuDocumentView *)[self documentView] intrinsicSize];
}

- (void)setItemArray:(NSArray *)itemArray
{
    OEMenuDocumentView *contentView = (OEMenuDocumentView *)[self documentView];
    [contentView setItemArray:itemArray];
    [[self documentView] setFrameSize:[contentView intrinsicSize]];
}

- (void)setFrameSize:(NSSize)newSize
{
    OEMenuDocumentView *documentView = [self documentView];

    NSSize contentSize = { newSize.width, [documentView frame].size.height };

    [super setFrameSize:newSize];
    [documentView setFrameSize:contentSize];
}

- (NSArray *)itemArray
{
    return [(OEMenuDocumentView *)[self documentView] itemArray];
}

- (void)setContainImages:(BOOL)containImages
{
    [(OEMenuDocumentView *)[self documentView] setContainImages:containImages];
}

- (BOOL)doesContainImages
{
    return [(OEMenuDocumentView *)[self documentView] doesContainImages];
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