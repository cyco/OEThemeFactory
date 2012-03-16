//
//  OEMenu.m
//  OEThemeFactory
//
//  Created by Faustino Osuna on 3/14/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "OEMenu.h"
#import "OEPopUpButton.h"

@interface OEMenu ()

- (void)OE_showWindowForView:(NSView *)view;

@end

@implementation OEMenu

+ (OEMenu *)popUpContextMenuWithMenu:(NSMenu *)menu withRect:(NSRect)rect
{
    OEMenu *result = [[self alloc] initWithContentRect:rect styleMask:NSBorderlessWindowMask | NSNonactivatingPanelMask backing:NSBackingStoreBuffered defer:YES screen:[NSScreen mainScreen]];
    [result setMenu:menu];
    [result setContentSize:[result->_view sizeThatFits:rect]];

    return result;
}

+ (void)popUpContextMenuForPopUpButton:(OEPopUpButton *)button
{
    const NSRect buttonFrame  = [[button window] convertRectToScreen:[button frame]];
    OEMenu *result = [self popUpContextMenuWithMenu:[button menu] withRect:buttonFrame];
    [result->_view setEdge:OENoEdge];
    [result->_view setHighlightedItem:[button selectedItem]];

    const NSRect titleRectInButton = [[button cell] titleRectForBounds:[button bounds]];
    const NSRect titleRectInWindow = [button convertRect:titleRectInButton toView:nil];
    const NSRect titleRectInScreen = [[button window] convertRectToScreen:titleRectInWindow];

    [result setFrameTopLeftPoint:[result->_view topLeftPointWithSelectedItemRect:titleRectInScreen]];

    [result OE_showWindowForView:button];
}

+ (void)popUpContextMenu:(NSMenu *)menu arrowOnEdge:(OERectEdge)edge withRect:(NSRect)rect forView:(NSView *)view
{
    OEMenu *result = [self popUpContextMenuWithMenu:menu withRect:rect];
    [result->_view setEdge:edge];

    [result OE_showWindowForView:view];
}

- (id)initWithContentRect:(NSRect)contentRect styleMask:(NSUInteger)aStyle backing:(NSBackingStoreType)bufferingType defer:(BOOL)flag screen:(NSScreen *)screen
{
    if((self = [super initWithContentRect:contentRect styleMask:aStyle backing:bufferingType defer:flag screen:screen]))
    {
        _view = [[OEMenuView alloc] initWithFrame:[[self contentView] bounds]];
        [_view setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
        [[self contentView] addSubview:_view];
        [self makeFirstResponder:_view];

        [self setOpaque:NO];
        [self setBackgroundColor:[NSColor clearColor]];
        [self setLevel:NSTornOffMenuWindowLevel];
        [self setReleasedWhenClosed:YES];
    }
    return self;
}

- (void)setMenu:(NSMenu *)menu
{
    [super setMenu:menu];
    [_view setMenu:menu];
}

- (void)resignKeyWindow
{
    [self cancelTracking];
}


- (void)OE_createEventMonitor
{
    _localMonitor = [NSEvent addLocalMonitorForEventsMatchingMask:NSLeftMouseDownMask | NSRightMouseDownMask | NSOtherMouseDownMask | NSKeyUpMask | NSKeyDownMask | NSFlagsChangedMask | NSScrollWheelMask
                                                          handler:
                     ^ NSEvent *(NSEvent *incomingEvent)
                     {
                         if([incomingEvent type] == NSScrollWheel)
                         {
                             // TODO: If we are in a scrollable part of the meu then we should react to this
                             return nil;
                         }

                         if([incomingEvent type] == NSFlagsChanged)
                         {
                             [_view flagsChanged:incomingEvent];
                             return nil;
                         }

                         if([incomingEvent type] == NSKeyDown)
                         {
                             [_view keyDown:incomingEvent];
                             return nil;
                         }

                         if([incomingEvent type] == NSKeyUp)
                         {
                             [_view keyUp:incomingEvent];
                             return nil;
                         }

                         if([[incomingEvent window] isKindOfClass:[self class]])// mouse down in window, will be handle by content view
                         {
                             return incomingEvent;
                         }
                         else
                         {
                             // event is outside of window, close menu without changes and remove event
                             [self cancelTracking];
                         }

                         return nil;
                     }];
}

- (void)OE_removeEventMonitor
{
    if(_localMonitor != nil)
    {
        [NSEvent removeMonitor:_localMonitor];
        _localMonitor = nil;
    }
}

- (oneway void)cancelTracking
{
    if(_cancelTracking) return;
    _cancelTracking = YES;
    [self OE_removeEventMonitor];

    [NSAnimationContext runAnimationGroup:
     ^ (NSAnimationContext *context)
     {
         [[self animator] setAlphaValue:0.0];
     }
                        completionHandler:
     ^{
         [[self parentWindow] removeChildWindow:self];
         [self orderOut:nil];
     }];
}

- (void)OE_showWindowForView:(NSView *)view
{
    [self OE_createEventMonitor];
    [[view window] addChildWindow:self ordered:NSWindowAbove];
    [self orderFrontRegardless];
}

@end
