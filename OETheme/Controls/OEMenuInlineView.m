//
//  OEMenuInlineView.m
//  OEThemeFactory
//
//  Created by Faustino Osuna on 4/10/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "OEMenuInlineView.h"
#import "OEMenuDocumentView.h"
#import "OEMenuDocumentView+OEMenuView.h"
#import "OEMenu.h"
#import "OEMenu+OEMenuViewAdditions.h"
#import "NSMenuItem+OEMenuItemExtraDataAdditions.h"

static const CGFloat OEMenuScrollArrowHeight = 19.0;
static const CGFloat OEMenuScrollAutoStep    = 8.0;
static const CGFloat OEMenuScrollAutoDelay   = 0.1;

// Fake menu scroller (doesn't render anything)
@interface _OEMenuScroller : NSScroller
@end

@interface _OEMenuScrollArrowView : NSView
@property(nonatomic, retain) NSImage *arrow;
@end

@implementation OEMenuInlineView
@synthesize scrollable = _scrollable;
@synthesize documentView = _documentView;
@synthesize clippingRect = _clippingRect;

- (id)initWithFrame:(NSRect)frame
{
    if((self = [super initWithFrame:frame]))
    {
        // Create subclass of clip view so that we can track scroll positional offset changes...plus! we can create a scroll up and down overlay.
        _scrollView = [[NSScrollView alloc] initWithFrame:[self bounds]];
        [_scrollView setDrawsBackground:NO];
        [_scrollView setBorderType:NSNoBorder];
        [_scrollView setHasVerticalScroller:YES];
        [_scrollView setVerticalScroller:[[_OEMenuScroller alloc] init]];
        [_scrollView setVerticalScrollElasticity:NSScrollElasticityNone];

        // Add an observer to the  bounds of the scroller's content view as it will determine if / when the view has been scrolled
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(documentViewBoundsDidChange:) name:NSViewBoundsDidChangeNotification object:[_scrollView contentView]];

        _documentView = [[OEMenuDocumentView alloc] initWithFrame:[self bounds]];
        [_scrollView setDocumentView:_documentView];

        _scrollUpButton = [[_OEMenuScrollArrowView alloc] initWithFrame:NSZeroRect];
        _scrollDownButton = [[_OEMenuScrollArrowView alloc] initWithFrame:NSZeroRect];

        [self addSubview:_scrollView];
        [self addSubview:_scrollUpButton];
        [self addSubview:_scrollDownButton];

        [self OE_updateTheme];
    }
    return self;
}

- (void)dealloc
{
    // -invalidate appears to have no affect
    [_automaticScrollTimer invalidate];
    _automaticScrollTimer = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)updateTrackingAreas
{
    [[self trackingAreas] enumerateObjectsUsingBlock:
     ^ (NSTrackingArea *obj, NSUInteger idx, BOOL *stop)
     {
         [self removeTrackingArea:obj];
     }];

    if(![_scrollUpButton isHidden])   [self addTrackingArea:[[NSTrackingArea alloc] initWithRect:[_scrollUpButton frame] options:NSTrackingMouseEnteredAndExited | NSTrackingActiveInActiveApp owner:self userInfo:nil]];
    if(![_scrollDownButton isHidden]) [self addTrackingArea:[[NSTrackingArea alloc] initWithRect:[_scrollDownButton frame] options:NSTrackingMouseEnteredAndExited | NSTrackingActiveInActiveApp owner:self userInfo:nil]];
}

- (void)mouseEntered:(NSEvent *)theEvent
{
    [_automaticScrollTimer invalidate];

    const NSPoint locationInView = [self convertPoint:[theEvent locationInWindow] fromView:nil];
    SEL scrollSelector           = NSPointInRect(locationInView, [_scrollUpButton frame]) ? @selector(OE_autoScrollUp:) : @selector(OE_autoScrollDown:);
    _automaticScrollTimer        = [NSTimer scheduledTimerWithTimeInterval:OEMenuScrollAutoDelay target:self selector:scrollSelector userInfo:nil repeats:YES];

    [(OEMenu *)[self window] setHighlightedItem:nil];
}

- (void)mouseExited:(NSEvent *)theEvent
{
    [_automaticScrollTimer invalidate];
    _automaticScrollTimer = nil;
}

- (void)OE_scrollToPoint:(NSPoint)point
{
    const CGFloat minY                 = 0.0;
    const CGFloat maxY                 = NSHeight([[_scrollView documentView] frame]) - NSHeight([_scrollView frame]);

    if(point.y <= minY)
    {
        point.y              = minY;
    }

    if(point.y >= maxY)
    {
        point.y              = maxY;
    }

    [[_scrollView contentView] scrollToPoint:point];
}

- (void)scrollItemToVisible:(NSMenuItem *)item
{
    if(!item || ![[_documentView itemArray] containsObject:item]) return;

    const NSRect visibleRect   = [self convertRect:_clippingRect toView:_documentView];
    const NSRect menuItemFrame = [[item extraData] frame];

    if(NSMaxY(menuItemFrame) > NSMaxY(visibleRect))
    {
        [self OE_scrollToPoint:NSMakePoint(0.0, NSMaxY(menuItemFrame) - NSHeight(visibleRect) - OEMenuScrollArrowHeight)];
    }
    else if(NSMinY(menuItemFrame) < NSMinY(visibleRect))
    {
        [self OE_scrollToPoint:NSMakePoint(0.0, NSMinY(menuItemFrame) - OEMenuScrollArrowHeight)];
    }
}

- (BOOL)shouldKeepAutoscroll:(NSEvent *)theEvent
{
    const NSPoint locationInView = [self convertPoint:[theEvent locationInWindow] fromView:nil];
    if(![_scrollUpButton isHidden]   && NSPointInRect(locationInView, [_scrollUpButton frame]))
    {
        [self OE_autoScrollUp:nil];
        return ![_scrollUpButton isHidden];
    }
    else if(![_scrollDownButton isHidden] && NSPointInRect(locationInView, [_scrollDownButton frame]))
    {
        [self OE_autoScrollDown:nil];
        return ![_scrollDownButton isHidden];
    }

    if([[_scrollView contentView] autoscroll:theEvent])
    {
        if (locationInView.y < NSMinY([self bounds])) return ![_scrollDownButton isHidden];
        if (locationInView.y > NSMaxY([self bounds])) return ![_scrollUpButton isHidden];
    }

    return YES;
}

- (void)scrollToBeginningOfDocument:(id)sender
{
    [self OE_scrollToPoint:NSMakePoint(0.0, NSMaxY([_documentView frame]))];
}

- (void)scrollToEndOfDocument:(id)sender
{
    [self OE_scrollToPoint:NSZeroPoint];
}

- (void)OE_highlightItemUnderMouse
{
    // Update the highlighted item to be the item underneath the mouse (only if the last event was the scroll wheel)
    OEMenuView *view = [(OEMenu *)[self window] OE_view];
    [view highlightItemAtPoint:[view convertPointFromBase:[[self window] convertScreenToBase:[NSEvent mouseLocation]]]];
}

- (void)OE_autoScrollUp:(NSTimer *)timer
{
    if(!_automaticScrollTimer && timer)
    {
        [timer invalidate];
        return;
    }

    [self OE_scrollToPoint:NSMakePoint(0.0, NSMinY([[_scrollView contentView] bounds]) + OEMenuScrollAutoStep)];

    if([_scrollUpButton isHidden])
    {
        [_automaticScrollTimer invalidate];
        _automaticScrollTimer = nil;
        [self OE_highlightItemUnderMouse];
    }
}

- (void)OE_autoScrollDown:(NSTimer *)timer
{
    if(!_automaticScrollTimer && timer)
    {
        [timer invalidate];
        return;
    }

    [self OE_scrollToPoint:NSMakePoint(0.0, NSMinY([[_scrollView contentView] bounds]) - OEMenuScrollAutoStep)];

    if([_scrollDownButton isHidden])
    {
        [_automaticScrollTimer invalidate];
        _automaticScrollTimer = nil;
        [self OE_highlightItemUnderMouse];
    }
}

- (void)OE_updateTheme
{
    [(_OEMenuScrollArrowView *)_scrollUpButton setArrow:[[OETheme sharedTheme] imageForKey:@"dark_menu_scroll_up_arrow" forState:OEThemeStateDefault]];
    [(_OEMenuScrollArrowView *)_scrollDownButton setArrow:[[OETheme sharedTheme] imageForKey:@"dark_menu_scroll_down_arrow" forState:OEThemeStateDefault]];
    [self setNeedsDisplay:YES];
}

- (void)setStyle:(OEMenuStyle)style
{
    [_documentView setStyle:style];
    [self OE_updateTheme];
}

- (OEMenuStyle)style
{
    return [_documentView style];
}

- (NSSize)intrinsicSize
{
    return [_documentView intrinsicSize];
}

- (void)setItemArray:(NSArray *)itemArray
{
    [_documentView setItemArray:itemArray];
    [_documentView setFrameSize:NSMakeSize(NSWidth([self bounds]), [_documentView intrinsicSize].height)];
}

- (void)OE_layout
{
    if(NSIsEmptyRect([self bounds])) return;

    const NSRect bounds = [self bounds];
    if(NSHeight(bounds) < NSHeight([_documentView frame]))
    {
        NSRect contentFrame = [self bounds];
        NSRect upFrame;
        NSRect downFrame;

        NSDivideRect(contentFrame, &upFrame,   &contentFrame, OEMenuScrollArrowHeight, NSMaxYEdge);
        NSDivideRect(contentFrame, &downFrame, &contentFrame, OEMenuScrollArrowHeight, NSMinYEdge);

        [_scrollUpButton setFrame:upFrame];
        [_scrollDownButton setFrame:downFrame];
    }
    [self OE_updateScrollerVisibility];
}

- (void)OE_updateScrollerVisibility
{
    if(NSIsEmptyRect([self bounds])) return;

    const NSRect bounds  = [self bounds];
    NSRect documentFrame = [_documentView frame];
    _clippingRect        = bounds;

    if(NSHeight(bounds) < NSHeight(documentFrame))
    {
        const NSRect contentBounds    = [[_scrollView contentView] bounds];
        const BOOL   hideDown         = NSMinY(contentBounds) <= 0.0;
        const BOOL   hideUp           = NSMaxY(contentBounds) >= NSHeight(documentFrame);
        const BOOL   updateVisibility = ([_scrollUpButton isHidden] != hideUp) || ([_scrollDownButton isHidden] != hideDown);

        [_scrollUpButton setHidden:hideUp];
        [_scrollDownButton setHidden:hideDown];

        if(!hideDown) _clippingRect.origin.y = NSMaxY([_scrollDownButton frame]);
        _clippingRect.size.height            = (hideUp ? NSHeight(bounds) : NSMinY([_scrollUpButton frame])) - NSMinY(_clippingRect);

        if(updateVisibility) [self updateTrackingAreas];
    }
    [_scrollView setFrame:bounds];
}

- (void)documentViewBoundsDidChange:(NSNotification *)notification
{
    if(NSIsEmptyRect([self bounds])) return;

    [self OE_updateScrollerVisibility];

    if([[[self window] currentEvent] type] == NSScrollWheel) [self OE_highlightItemUnderMouse];
}

- (void)setFrameSize:(NSSize)newSize
{
    [super setFrameSize:newSize];
    [self OE_layout];
    [_documentView setFrameSize:NSMakeSize(NSWidth([_scrollView bounds]), NSHeight([_documentView frame]))];
}

- (NSArray *)itemArray
{
    return [_documentView itemArray];
}

- (void)setContainImages:(BOOL)containImages
{
    [_documentView setContainImages:containImages];
}

- (BOOL)doesContainImages
{
    return [_documentView doesContainImages];
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

@implementation _OEMenuScrollArrowView
@synthesize arrow = _arrow;

- (void)drawRect:(NSRect)dirtyRect
{
    // TODO: Should be a themed view that draws based on state changes (if various states are provided)
    const NSSize arrowSize = [_arrow size];
    const NSPoint point = { ceil(NSMidX([self bounds]) - (arrowSize.width / 2.0)), ceil(NSMidY([self bounds]) - (arrowSize.height / 2.0))};
    [_arrow drawAtPoint:point fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
}

- (void)setArrow:(NSImage *)arrow
{
    if(_arrow != arrow)
    {
        _arrow = arrow;
        [self setNeedsDisplay:YES];
    }
}

@end
