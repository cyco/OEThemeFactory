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
    [result setContentSize:[result->_view sizeThatFits:rect]];
    return result;
}

+ (OEMenu *)openMenuForPopUpButton:(OEPopUpButton *)button
{
    const NSRect  buttonFrame  = [[button window] convertRectToScreen:[button frame]];
    OEMenu *result = [self menuWithMenu:[button menu] withRect:buttonFrame];
    [result->_view setEdge:OENoEdge];
    [result->_view setHighlightedItem:[button selectedItem]];

    const NSRect titleRectInButton = [[button cell] titleRectForBounds:[button bounds]];
    const NSRect titleRectInWindow = [button convertRect:titleRectInButton toView:nil];
    const NSRect titleRectInScreen = [[button window] convertRectToScreen:titleRectInWindow];

    [result setFrameTopLeftPoint:[result->_view topLeftPointWithSelectedItemRect:titleRectInScreen]];
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

- (void)setMenu:(NSMenu *)menu
{
    [super setMenu:menu];
    [_view setMenu:menu];
}

@end
