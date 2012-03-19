//
//  OEMenu.m
//  OEThemeFactory
//
//  Created by Faustino Osuna on 3/14/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "OEMenu.h"
#import "OEMenu+OEMenuViewAdditions.h"
#import "OEPopUpButton.h"
#import "NSMenuItem+OEMenuItemExtraDataAdditions.h"

// Animation duration to fade the menu out
static const CGFloat OEMenuFadeOutDuration = 0.075;

@interface OEMenu ()

- (void)OE_applicationNotification:(NSNotification *)notification;
- (void)OE_menuWillShow:(NSNotification *)notification;
- (void)OE_showWindowForView:(NSView *)view withEvent:(NSEvent *)initialEvent;
- (void)OE_hideWindowWithFadeDuration:(CGFloat)duration;
- (void)OE_calculateSubmenuOrigin;

@end

@implementation OEMenu

+ (OEMenu *)popUpContextMenuWithMenu:(NSMenu *)menu arrowOnEdge:(OERectEdge)edge withRect:(NSRect)rect
{
    OEMenu *result = [[self alloc] initWithContentRect:rect styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:YES screen:[NSScreen mainScreen]];
    [result setMenu:menu];
    [result->_view setEdge:edge];
    [result setContentSize:[result->_view size]];
    return result;
}

+ (void)popUpContextMenuForPopUpButton:(OEPopUpButton *)button withEvent:(NSEvent *)event
{
    NSWindow *window = [button window];

    const NSRect buttonFrame = [window convertRectToScreen:[button convertRect:[button frame] toView:nil]];
    OEMenu *result           = [self popUpContextMenuWithMenu:[button menu] arrowOnEdge:OENoEdge withRect:buttonFrame];
    if(result != nil)
    {
        // Make sure result is not nil we don't want to dereference a null pointer
        OEMenuView *menuView = result->_view;
        [menuView display];
        [menuView setStyle:[button menuStyle]];
        [menuView setHighlightedItem:[button selectedItem]];

        // Calculate the frame for the popup menu so that the popup menu's selected item hovers exactly over the popup button's title
        const NSRect titleRectInButton = [[button cell] titleRectForBounds:[button bounds]];
        const NSRect titleRectInScreen = [window convertRectToScreen:[button convertRect:titleRectInButton toView:nil]];

        const NSEdgeInsets edgeInsets = [menuView backgroundEdgeInsets];

        NSPoint origin = titleRectInScreen.origin;
        NSSize size    = [result frame].size;

        // TODO: Adjust origin based on the button's and menu item's shadows
        origin.x   -= edgeInsets.left + OEMenuItemTickMarkWidth - 1.0;              // Assumes 1px shadow + 1px border
        origin.y   -= NSMinY([[[menuView highlightedItem] extraData] frame]) + 2.0; // Assumes a 1px shadow + 1px border
        size.width  = buttonFrame.size.width + OEMenuContentEdgeInsets.left + OEMenuContentEdgeInsets.right + edgeInsets.left + edgeInsets.right;

        [result setFrame:(NSRect){ .origin = origin, .size = size } display:NO];
        [result OE_showWindowForView:button withEvent:event];
    }
}

+ (void)popUpContextMenu:(NSMenu *)menu arrowOnEdge:(OERectEdge)edge forView:(NSView *)view withStyle:(OEMenuStyle)style withEvent:(NSEvent *)event
{
    const NSRect rectInWindow = [view convertRect:[view bounds] toView:nil];
    const NSRect rectInScreen = [[view window] convertRectToScreen:rectInWindow];

    OEMenu *result = [self popUpContextMenuWithMenu:menu arrowOnEdge:edge withRect:rectInScreen];
    if(result != nil)
    {
        OEMenuView *menuView = result->_view;
        [menuView display];
        [menuView setStyle:style];

        // Calculate the top left point of the frame, this position is dependent on the edge that the arrow is visible on
        const NSEdgeInsets edgeInsets = [menuView backgroundEdgeInsets];

        NSPoint origin = rectInScreen.origin;
        if(edge == OENoEdge)
        {
            origin = NSMakePoint(NSMinX(rectInScreen) - edgeInsets.left + 1.0, NSMinY(rectInScreen));
        }
        else
        {
            const NSRect bounds = [result convertRectToScreen:[menuView frame]];
            switch(edge)
            {
                case OEMinXEdge:
                    origin = NSMakePoint(NSMaxX(rectInScreen) - edgeInsets.left, NSMaxY(rectInScreen) - (NSMidY(rectInScreen) - NSMidY(bounds)));
                    break;
                case OEMaxXEdge:
                    origin = NSMakePoint(NSMinX(rectInScreen) - NSWidth(bounds) + edgeInsets.right, NSMaxY(rectInScreen) - (NSMidY(rectInScreen) - NSMidY(bounds)));
                    break;
                case OEMinYEdge:
                    origin = NSMakePoint(NSMinX(rectInScreen) + NSMidX(rectInScreen) - NSMidX(bounds), NSMaxY(rectInScreen) + NSHeight(bounds) - edgeInsets.bottom);
                    break;
                case OEMaxYEdge:
                    origin = NSMakePoint(NSMinX(rectInScreen) + NSMidX(rectInScreen) - NSMidX(bounds), NSMinY(rectInScreen) - edgeInsets.top);
                    break;
                default:
                    break;
            }
        }

        [result setFrameTopLeftPoint:origin];
        [result OE_showWindowForView:view withEvent:event];
    }
}

- (id)initWithContentRect:(NSRect)contentRect styleMask:(NSUInteger)aStyle backing:(NSBackingStoreType)bufferingType defer:(BOOL)flag screen:(NSScreen *)screen
{
    if((self = [super initWithContentRect:contentRect styleMask:aStyle backing:bufferingType defer:flag screen:screen]))
    {
        _view = [[OEMenuView alloc] initWithFrame:[[self contentView] bounds]];
        [_view setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
        [[self contentView] addSubview:_view];

        [self setOpaque:NO];
        [self setBackgroundColor:[NSColor clearColor]];
        [self setLevel:NSTornOffMenuWindowLevel];
        [self setHasShadow:NO];
        [self setReleasedWhenClosed:YES];
        [self setCollectionBehavior:NSWindowCollectionBehaviorTransient | NSWindowCollectionBehaviorIgnoresCycle];

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(OE_applicationNotification:) name:NSApplicationDidResignActiveNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(OE_applicationNotification:) name:NSApplicationDidHideNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(OE_menuWillShow:) name:NSMenuDidBeginTrackingNotification object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)orderWindow:(NSWindowOrderingMode)place relativeTo:(NSInteger)otherWin
{
    [super orderWindow:place relativeTo:otherWin];
    if(_submenu)
    {
        [self OE_calculateSubmenuOrigin];
        [_submenu orderFrontRegardless];
    }
}

- (void)removeChildWindow:(NSWindow *)childWin
{
    if(childWin == _submenu) _submenu = nil;
    [super removeChildWindow:childWin];
}

- (void)setMenu:(NSMenu *)menu
{
    [super setMenu:menu];
    [_view setMenu:menu];
}

- (void)OE_applicationNotification:(NSNotification *)notification
{
    [self cancelTrackingWithoutAnimation];
}

- (void)OE_menuWillShow:(NSNotification *)notification
{
    [self cancelTracking];
}

- (void)OE_cancelTrackingWithFadeDuration:(CGFloat)duration
{
    if(_cancelTracking) return;
    _cancelTracking = YES;

    [_submenu OE_cancelTrackingWithFadeDuration:duration];
    [_supermenu OE_cancelTrackingWithFadeDuration:duration];
    [self OE_hideWindowWithFadeDuration:duration];
}

- (void)cancelTracking
{
    [self OE_cancelTrackingWithFadeDuration:OEMenuFadeOutDuration];
}

- (void)cancelTrackingWithoutAnimation
{
    [self OE_cancelTrackingWithFadeDuration:0.0];
}

- (void)OE_showWindowForView:(NSView *)view
{
    NSWindow *parentWindow = [view window];
    [parentWindow addChildWindow:self ordered:NSWindowAbove];
    if(![parentWindow isKindOfClass:[OEMenu class]] || [parentWindow isVisible]) [self orderFrontRegardless];
}

- (void)OE_showWindowForView:(NSView *)view withEvent:(NSEvent *)initialEvent
{
    id<NSMenuDelegate> delegate = [[_view menu] delegate];
    if([delegate respondsToSelector:@selector(menuWillOpen:)]) [delegate menuWillOpen:[_view menu]];

    [self OE_showWindowForView:view];

    const NSEventType type               = [initialEvent type];
    NSEventType       oppositeMouseEvent = 0;
    switch(type)
    {
        case NSLeftMouseDown:
            oppositeMouseEvent = NSLeftMouseUp;
            break;
        case NSRightMouseDown:
            oppositeMouseEvent = NSRightMouseDown;
            break;
        case NSOtherMouseDown:
            oppositeMouseEvent = NSOtherMouseDown;
            break;
        default:
            break;
    }

    NSEvent *event;
    while(!_closing && !_cancelTracking && (event = [NSApp nextEventMatchingMask:NSAnyEventMask untilDate:[NSDate distantFuture] inMode:NSDefaultRunLoopMode dequeue:YES]))
    {
        const NSEventType type = [event type];
        if(type == oppositeMouseEvent && [event timestamp] - [initialEvent timestamp] > 1.0)
        {
            const NSPoint locationInWindow = [event locationInWindow];
            const NSPoint location = [self convertScreenToBase:[event window] == nil ? locationInWindow : [[event window] convertBaseToScreen:locationInWindow]];
            NSEvent *mockEvent = [NSEvent mouseEventWithType:[event type] location:location modifierFlags:[event modifierFlags] timestamp:[event timestamp] windowNumber:[self windowNumber] context:[event context] eventNumber:[event eventNumber] clickCount:[event clickCount] pressure:[event pressure]];
            [_view mouseUp:mockEvent];
        }
        else if((type == NSLeftMouseDown || type == NSRightMouseDown || type == NSOtherMouseDown) && ![[event window] isKindOfClass:isa])
        {
            [self cancelTracking];
        }
        else if((type == NSKeyDown) || (type == NSKeyUp))
        {
            OEMenu *submenu = self;
            while(submenu->_submenu) submenu = submenu->_submenu;
            [submenu sendEvent:event];
            continue;
        }
        else if(type == NSFlagsChanged)
        {
            OEMenu *submenu = self;
            while(submenu)
            {
                [submenu sendEvent:event];
                submenu = submenu->_submenu;
            }
        }
        [NSApp sendEvent:event];
    }
    [NSApp discardEventsMatchingMask:NSAnyEventMask beforeEvent:event];
    if([delegate respondsToSelector:@selector(menuDidClose:)]) [delegate menuDidClose:[_view menu]];
}

- (void)OE_hideWindowWithFadeDuration:(CGFloat)duration
{
    void (^changes)(NSAnimationContext *context) =
    ^ (NSAnimationContext *context)
    {
        [context setDuration:duration];
        [[self animator] setAlphaValue:0.0];
    };

    void (^completionHandler)(void) = ^{
        [[self parentWindow] removeChildWindow:self];
    };

    [NSAnimationContext runAnimationGroup:changes completionHandler:completionHandler];
}

- (void)OE_calculateSubmenuOrigin
{
    const NSRect        rectInScreen = [self convertRectToScreen:[_view convertRect:[[[_view highlightedItem] extraData] frame] toView:nil]];
    const NSEdgeInsets  edgeInsets   = [_view backgroundEdgeInsets];
    [_submenu setFrameTopLeftPoint:NSMakePoint(NSMaxX(rectInScreen) - edgeInsets.right - OEMenuContentEdgeInsets.left, NSMaxY(rectInScreen) + edgeInsets.top + OEMenuContentEdgeInsets.top)];
}

@end

@implementation OEMenu (OEMenuViewAdditions)

- (void)OE_setClosing:(BOOL)closing
{
    _closing = YES;
}

- (void)OE_setSubmenu:(NSMenu *)submenu
{
    if([_submenu menu] == submenu) return;
    if(submenu == nil)
    {
        [_submenu OE_hideWindowWithFadeDuration:OEMenuFadeOutDuration];
        _submenu = nil;
        return;
    }

    const NSRect rectInScreen = [self convertRectToScreen:[_view convertRect:[[[_view highlightedItem] extraData] frame] toView:nil]];
    _submenu = [isa popUpContextMenuWithMenu:submenu arrowOnEdge:OENoEdge withRect:rectInScreen];
    if(_submenu != nil)
    {
        _submenu->_supermenu = self;
        [_submenu->_view setStyle:[_view style]];
        [self OE_calculateSubmenuOrigin];
        [_submenu OE_showWindowForView:_view];
    }
}

- (OEMenu *)OE_submenu
{
    return _submenu;
}

- (OEMenuView *)OE_view
{
    return _view;
}

- (void)OE_hideWindowWithoutAnimation
{
    [self OE_hideWindowWithFadeDuration:0.0];
}

@end
