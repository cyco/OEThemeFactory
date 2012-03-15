//
//  OEMenu.m
//  OEThemeFactory
//
//  Created by Faustino Osuna on 3/14/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "OEMenu.h"
#import "OEPopUpButton.h"

@implementation OEMenu

+ (OEMenu *)menuWithMenu:(NSMenu *)menu withRect:(NSRect)rect
{
    OEMenu *result = [[self alloc] initWithContentRect:rect styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:YES screen:[NSScreen mainScreen]];
    [result setOpaque:NO];
    [result setBackgroundColor:[NSColor clearColor]];
    [result setMenu:menu];
    [result setLevel:NSPopUpMenuWindowLevel];
    return result;
}

+ (OEMenu *)openMenuForPopUpButton:(OEPopUpButton *)button
{
    NSRect  buttonFrame  = [[button window] convertRectToScreen:[button frame]];
    OEMenu *result = [self menuWithMenu:[button menu] withRect:buttonFrame];
    [result->_view setEdge:OENoEdge];
    [result->_view setHighlightedItem:[button selectedItem]];

    NSRect titleRectInButton = [[button cell] titleRectForBounds:[button bounds]];
    NSRect titleRectInWindow = [button convertRect:titleRectInButton toView:nil];
    NSRect titleRectInScreen = [[button window] convertRectToScreen:titleRectInWindow];

    [result setFrameTopLeftPoint:[result->_view topLeftPointWithSelectedItemRect:titleRectInScreen]];
    NSRect frame = [result frame];
    frame = [result frame];
    frame.size.width += NSMaxX(buttonFrame) - NSMaxX(frame);
    [result setFrame:frame display:NO];
    [result orderFrontRegardless];

    return result;
}

+ (OEMenu *)openMenu:(NSMenu *)menu arrowOnEdge:(OERectEdge)edge withRect:(NSRect)rect
{
    OEMenu *result = [self menuWithMenu:menu withRect:rect];
    [result->_view setEdge:edge];
    [result orderFrontRegardless];

    return result;
}

- (id)initWithContentRect:(NSRect)contentRect styleMask:(NSUInteger)aStyle backing:(NSBackingStoreType)bufferingType defer:(BOOL)flag screen:(NSScreen *)screen
{
    if((self = [super initWithContentRect:contentRect styleMask:aStyle backing:bufferingType defer:flag screen:screen]))
    {
        _view = [[OEMenuView alloc] initWithFrame:[[self contentView] bounds]];
        [_view setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
        [[self contentView] addSubview:_view];
    }
    return self;
}

- (void)OE_resizeToFit
{
    [self setContentSize:[_view sizeThatFits:[self frame]]];
}

- (void)setMenu:(NSMenu *)menu
{
    if([_view menu]) NSLog(@"Menu already set, you must create a new instatiation.");
    else
    {
        [_view setMenu:menu];
        [self OE_resizeToFit];
    }
    [super setMenu:menu];
}

- (NSMenu *)menu
{
    return [_view menu];
}
@end
