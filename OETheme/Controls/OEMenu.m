//
//  OEMenu.m
//  OEThemeFactory
//
//  Created by Faustino Osuna on 3/14/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "OEMenu.h"
#import "OEMenu+OEMenuViewAdditions.h"
#import "OEMenuView+OEMenuAdditions.h"
#import "OEPopUpButton.h"
#import "NSMenuItem+OEMenuItemExtraDataAdditions.h"

static const CGFloat OEMenuFadeOutDuration = 0.075; // Animation duration to fade the menu out
static const CGFloat OEMenuClickDelay      = 0.5;   // Amount of time before menu interprets a click to mean a drag operation

@interface OEMenu ()

- (void)OE_setEdge:(OERectEdge)edge;
- (void)OE_applicationNotification:(NSNotification *)notification;
- (void)OE_menuWillShow:(NSNotification *)notification;
- (void)OE_showWindowForView:(NSView *)view withEvent:(NSEvent *)initialEvent;
- (void)OE_hideWindowWithFadeDuration:(CGFloat)duration;
- (void)OE_calculateOriginInRelationshipToRect:(NSRect)rect;
- (void)OE_calculateSubmenuOrigin;

@end

@implementation OEMenu

+ (OEMenu *)popUpContextMenuWithMenu:(NSMenu *)menu arrowOnEdge:(OERectEdge)edge withRect:(NSRect)rect
{
    OEMenu *result = [[self alloc] initWithContentRect:rect styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:YES screen:[NSScreen mainScreen]];
    [result setMenu:menu];
    [result OE_setEdge:edge];

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

        NSPoint origin     = titleRectInScreen.origin;
        NSSize  size        = [result frame].size;
//        NSRect  screenFrame = [[result screen] visibleFrame];

        // TODO: Adjust origin based on the button's and menu item's shadows
        origin.x   -= edgeInsets.left + OEMenuItemTickMarkWidth - 1.0;              // Assumes 1px shadow + 1px border
        origin.y   -= NSMinY([[[menuView highlightedItem] extraData] frame]) + 2.0; // Assumes a 1px shadow + 1px border
        size.width  = buttonFrame.size.width + OEMenuContentEdgeInsets.left + OEMenuContentEdgeInsets.right + edgeInsets.left + edgeInsets.right;

        NSRect frame = (NSRect){ .origin = origin, .size = size };
        // TODO: Adjust the frame so that no portion is hidden by the screen's visible frame
        [result setFrame:frame display:NO];
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
        [result OE_calculateOriginInRelationshipToRect:rectInScreen];
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

- (void)OE_setEdge:(OERectEdge)edge
{
    [_view setEdge:edge];
    [self setContentSize:[_view size]];
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

+ (NSPoint)OE_locationInScreenForEvent:(NSEvent *)event
{
    const NSPoint locationInWindow = [event locationInWindow];
    NSWindow *window               = [event window];
    return window == nil ? locationInWindow : [window convertBaseToScreen:locationInWindow];
}

+ (NSWindow *)OE_windowAtPoint:(NSPoint)point
{
    for(NSWindow *window in [NSApp orderedWindows])
    {
        if(NSPointInRect(point, [window frame])) return window;
    }
    return nil;
}

- (NSEvent *)OE_mockMouseEvent:(NSEvent *)event
{
    if([event window] == self || [[event window] isKindOfClass:[OEMenu class]]) return event;

    const NSPoint location = [self convertScreenToBase:[isa OE_locationInScreenForEvent:event]];
    return [NSEvent mouseEventWithType:[event type] location:location modifierFlags:[event modifierFlags] timestamp:[event timestamp] windowNumber:[self windowNumber] context:[event context] eventNumber:[event eventNumber] clickCount:[event clickCount] pressure:[event pressure]];
}

- (void)OE_showWindowForView:(NSView *)view withEvent:(NSEvent *)initialEvent
{
    id<NSMenuDelegate> delegate = [[_view menu] delegate];
    if([delegate respondsToSelector:@selector(menuWillOpen:)]) [delegate menuWillOpen:[_view menu]];

    [self OE_showWindowForView:view];

    const NSEventType type         = [initialEvent type];
    NSEventType       mouseUpEvent = 0;
    switch(type)
    {
        case NSLeftMouseDown:
            mouseUpEvent = NSLeftMouseUp;
            break;
        case NSRightMouseDown:
            mouseUpEvent = NSRightMouseDown;
            break;
        case NSOtherMouseDown:
            mouseUpEvent = NSOtherMouseDown;
            break;
        default:
            break;
    }

    OEMenu *menuWithMouseFocus = self; // Tracks menu that is currently under the cursor
    BOOL    dragged            = NO;   // Identifies if the mouse has seen a drag operation

    NSEvent *event;
    while(!_closing && !_cancelTracking && (event = [NSApp nextEventMatchingMask:NSAnyEventMask untilDate:[NSDate distantFuture] inMode:NSDefaultRunLoopMode dequeue:YES]))
    {
        const NSEventType type = [event type];
        if(type == mouseUpEvent && (dragged || [event timestamp] - [initialEvent timestamp] > OEMenuClickDelay))
        {
            // Forward the mouse up message to the menu with the current focus
            [menuWithMouseFocus->_view mouseUp:[self OE_mockMouseEvent:event]];
            continue;  // There is no need to forward this message to NSApp, go back to the start of the loop.
        }
        else if((type == NSLeftMouseDragged) || (type == NSRightMouseDragged) || (type == NSOtherMouseDragged))
        {
            // Notify mouse up event that we've seen a mouse drag event
            dragged = YES;

            // Lets to figure which window is under the cursor. You would expect that [event window] would contain this information, when a mouse down
            // operation is encountered, the windowing system will send all the events to the window that initiated the mouse down event until a mouse
            // up event is reached.  Mouse drag events are only sent in between a mouse down and mouse up operation, therefore, [event window] does
            // not have the information we really need.  We need to know which menu (or submenu) has the current focus.
            const NSPoint  locationInScreen = [isa OE_locationInScreenForEvent:event];
            NSWindow      *newWindowFocus   = [isa OE_windowAtPoint:locationInScreen];
            if(menuWithMouseFocus != newWindowFocus)
            {
                // If the menu with the focus has changed, let the old menu know that the mouse has exited it's view
                if(menuWithMouseFocus) [menuWithMouseFocus->_view mouseExited:[menuWithMouseFocus OE_mockMouseEvent:event]];
                if([newWindowFocus isKindOfClass:[OEMenu class]])
                {
                    // Let the new menu know that the mouse has enterd it's view
                    menuWithMouseFocus = (OEMenu *)newWindowFocus;
                    [menuWithMouseFocus->_view mouseEntered:[menuWithMouseFocus OE_mockMouseEvent:event]];
                }
            }
            else
            {
                // If there has been no change, then let the current menu know that the mouse has been dragged
                [menuWithMouseFocus->_view mouseDragged:[menuWithMouseFocus OE_mockMouseEvent:event]];
            }
            continue;  // There is no need to forward this message to NSApp, go back to the start of the loop.
        }
        else if((type == NSMouseMoved) || (type == NSMouseEntered))
        {
            // Lets keep track of which menu has the current focus. After the windowing system receives a mouse up event,
            // it will forward any mouse position changes as mouse moved, entered, and exited messages, now [event window]
            // communicates the correct menu (or submenu) that is under that is under the cursor.
            if([[event window] isKindOfClass:[OEMenu class]]) menuWithMouseFocus = (OEMenu *)[event window];
        }
        else if((type == NSLeftMouseDown || type == NSRightMouseDown || type == NSOtherMouseDown) && ![[event window] isKindOfClass:isa])
        {
            // If we are tracking the mouse after a mouse up operation and we detect
            [self cancelTracking];
            continue;  // There is no need to forward this message to NSApp, go back to the start of the loop.
        }
        else if((type == NSKeyDown) || (type == NSKeyUp))
        {
            // Key down messages should be sent to the deepest submenu that is open
            OEMenu *submenu = self;
            while(submenu->_submenu) submenu = submenu->_submenu;
            [submenu sendEvent:event];
            continue;  // There is no need to forward this message to NSApp, go back to the start of the loop.
        }
        else if(type == NSFlagsChanged)
        {
            // Flags changes should be sent to all submenu's so that they can be updated appropriately
            OEMenu *submenu = self;
            while(submenu)
            {
                [submenu sendEvent:event];
                submenu = submenu->_submenu;
            }
        }
        // If we've gotten this far, then we need to forward the event to NSApp for additional / further processing
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

- (void)OE_calculateOriginInRelationshipToRect:(NSRect)rect
{
    // Calculate the top left point of the frame, this position is dependent on the edge that the arrow is visible on
    const OERectEdge   edge        = [_view edge];
    const NSRect       screenFrame = [[self screen] visibleFrame];

    NSPoint origin = NSZeroPoint;
    NSSize  size   = [self frame].size;

    // Calculates the origin for the specified edge
    NSPoint (^originForEdge)(OERectEdge edge) =
    ^ (OERectEdge edge)
    {
        const NSRect       bounds     = [self convertRectToScreen:[_view frame]];
        const NSEdgeInsets edgeInsets = [OEMenuView OE_backgroundEdgeInsetsForEdge:edge];
        switch(edge)
        {
            case OENoEdge:   return NSMakePoint(NSMinX(rect) - edgeInsets.left + 1.0, NSMinY(rect) - size.height);
            case OEMinXEdge: return NSMakePoint(NSMaxX(rect) - edgeInsets.right + 1.0, NSMaxY(rect) - (NSMidY(rect) - NSMidY(bounds)));
            case OEMaxXEdge: return NSMakePoint(NSMinX(rect) - NSWidth(bounds) + edgeInsets.left - 1.0, NSMaxY(rect) - (NSMidY(rect) - NSMidY(bounds)));
            case OEMinYEdge: return NSMakePoint(NSMinX(rect) + NSMidX(rect) - NSMidX(bounds), NSMaxY(rect) + NSHeight(bounds) - edgeInsets.top - 1.0);
            case OEMaxYEdge: return NSMakePoint(NSMinX(rect) + NSMidX(rect) - NSMidX(bounds), NSMinY(rect) + edgeInsets.bottom + 1.0);
            default:         break;
        }
        return NSZeroPoint;
    };

    origin = originForEdge(edge);
    if(edge == OENoEdge)
    {
        if(origin.x < NSMinX(screenFrame))                   origin.x  = 0.0;
        else if(origin.x + size.width > NSMaxX(screenFrame)) origin.x -= size.width;

        if(origin.y < NSMinY(screenFrame))                    origin.y = 0.0;
        else if(origin.y + size.height > NSMaxY(screenFrame)) origin.y = NSMaxY(screenFrame) - size.height;
    }
    else
    {
        switch(edge)
        {
            case OEMinXEdge:
            case OEMaxXEdge:
                if(origin.x < NSMinX(screenFrame) || (origin.x + size.width > NSMaxX(screenFrame)))
                {
                    NSLog(@"Flip to the other side.");
                    OERectEdge newEdge = edge == OEMinXEdge ? OEMaxXEdge : OEMinXEdge;
                    origin = originForEdge(newEdge);

                    if(origin.x < NSMinX(screenFrame) || origin.x + size.width > NSMaxX(screenFrame))
                    {
                        // TODO: Make view smaller
                        NSLog(@"Make view smaller");
                    }
                    else
                    {
                        // Flip successful
                        [self OE_setEdge:newEdge];
                    }
                }
                if(origin.y < NSMinY(screenFrame) || origin.y > NSMaxY(screenFrame))
                {
                    // TODO: Adjust arrow's position
                    if(origin.y < NSMinY(screenFrame) || origin.y > NSMaxY(screenFrame))
                    {
                        // TODO: Make view smaller
                        NSLog(@"Mak view smaller");
                    }
                }
                break;
            case OEMinYEdge:
            case OEMaxYEdge:
                if(origin.x < NSMinX(screenFrame) || (origin.x + size.width > NSMaxX(screenFrame)))
                {
                    // TODO: Adjust arrow's position
                    if(origin.x < NSMinX(screenFrame) || origin.x + size.width > NSMaxX(screenFrame))
                    {
                        // TODO: Make view smaller
                        NSLog(@"Make view smaller");
                    }
                }
                if(origin.y < NSMinY(screenFrame) || origin.y > NSMaxY(screenFrame))
                {
                    NSLog(@"Flip to the other side.");
                    OERectEdge newEdge = edge == OEMinYEdge ? OEMaxYEdge : OEMinYEdge;
                    origin = originForEdge(newEdge);

                    if(origin.y < NSMinY(screenFrame) || origin.y > NSMaxY(screenFrame))
                    {
                        // TODO: Make view smaller
                        NSLog(@"Make view smaller");
                    }
                    else
                    {
                        // Flip successful
                        [self OE_setEdge:newEdge];
                    }
                }
                break;
            default:
                break;
        }
    }
    [self setFrameTopLeftPoint:origin];
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
    OEMenu *supermenu = self;
    while(supermenu->_supermenu) supermenu = supermenu->_supermenu;
    supermenu->_closing = closing;
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
