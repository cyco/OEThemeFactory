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

- (void)OE_updateFrameAttachedToView:(NSView *)view alignSelectedItemWithRect:(NSRect)titleRect;
- (void)OE_updateFrameAttachedToView:(NSView *)attachedView onEdge:(OERectEdge)edge;
- (void)OE_updateFrameForSubmenu;

- (void)OE_applicationNotification:(NSNotification *)notification;
- (void)OE_menuWillShow:(NSNotification *)notification;
- (void)OE_showWindowForView:(NSView *)view withEvent:(NSEvent *)initialEvent;
- (void)OE_hideWindowWithFadeDuration:(CGFloat)duration;

@end

static NSMutableArray *sharedMenuStack;

@implementation OEMenu

+ (OEMenu *)popUpContextMenuWithMenu:(NSMenu *)menu withRect:(NSRect)rect
{
    OEMenu *result = [[self alloc] initWithContentRect:rect styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:YES screen:[NSScreen mainScreen]];
    [result setMenu:menu];
    return result;
}

+ (void)popUpContextMenuForPopUpButton:(OEPopUpButton *)button withEvent:(NSEvent *)event
{
    NSWindow *window = [button window];

    const NSRect buttonFrame = [window convertRectToScreen:[button convertRect:[button frame] toView:nil]];
    OEMenu *result           = [self popUpContextMenuWithMenu:[button menu] withRect:buttonFrame];
    if(result != nil)
    {
        // Make sure result is not nil we don't want to dereference a null pointer
        OEMenuView *menuView = result->_view;
        [menuView setEdge:OENoEdge];
        [menuView display];
        [menuView setStyle:[button menuStyle]];
        [menuView setHighlightedItem:[button selectedItem]];

        // Calculate the frame for the popup menu so that the popup menu's selected item hovers exactly over the popup button's title
        const NSRect titleRectInButton = [[button cell] titleRectForBounds:[button bounds]];
        const NSRect titleRectInScreen = [window convertRectToScreen:[button convertRect:titleRectInButton toView:nil]];
        [result OE_updateFrameAttachedToView:button alignSelectedItemWithRect:titleRectInScreen];
        [result OE_showWindowForView:button withEvent:event];
    }
}

+ (void)popUpContextMenu:(NSMenu *)menu arrowOnEdge:(OERectEdge)edge forView:(NSView *)view withStyle:(OEMenuStyle)style withEvent:(NSEvent *)event
{
    const NSRect rectInWindow = [view convertRect:[view bounds] toView:nil];
    const NSRect rectInScreen = [[view window] convertRectToScreen:rectInWindow];

    OEMenu *result = [self popUpContextMenuWithMenu:menu withRect:rectInScreen];
    if(result != nil)
    {
        OEMenuView *menuView = result->_view;
        [menuView display];
        [menuView setStyle:style];
        [result OE_updateFrameAttachedToView:view onEdge:edge];
        [result OE_showWindowForView:view withEvent:event];
    }
}

- (id)initWithContentRect:(NSRect)contentRect styleMask:(NSUInteger)aStyle backing:(NSBackingStoreType)bufferingType defer:(BOOL)flag screen:(NSScreen *)screen
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMenuStack = [NSMutableArray array];
    });

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
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)OE_updateFrameAttachedToView:(NSView *)view alignSelectedItemWithRect:(NSRect)titleRect
{
    const NSRect       screenFrame      = [([self screen] ?: [[view window] screen]) visibleFrame];
    const NSEdgeInsets edgeInsets       = [_view backgroundEdgeInsets];
    const NSRect       buttonFrame      = [view bounds];
    const NSRect       selectedItemRect = [[[_view highlightedItem] extraData] frame];

    NSRect frame = { .origin = titleRect.origin, .size = [_view size] };

    // TODO: Adjust origin based on the button's and menu item's shadows
    frame.origin.x   -= edgeInsets.left + OEMenuItemTickMarkWidth - 1.0;
    frame.origin.y   -= NSMinY(selectedItemRect) + 2.0;
    frame.size.width  = buttonFrame.size.width + OEMenuContentEdgeInsets.left + OEMenuContentEdgeInsets.right + edgeInsets.left + edgeInsets.right;

    // Adjust the frame's dimensions not to be bigger than the screen
    frame.size.height = MIN(NSHeight(frame), NSHeight(screenFrame));
    frame.size.width  = MIN(NSWidth(frame), NSWidth(screenFrame));

    // Adjust the frame's position to make the menu completely visible
    frame.origin.x = MIN(MAX(NSMinX(frame), NSMinX(screenFrame)), NSMaxX(screenFrame) - NSWidth(frame));
    frame.origin.y = MIN(MAX(NSMinY(frame), NSMinY(screenFrame)), NSMaxY(screenFrame) - NSHeight(frame));

    [self setFrame:frame display:[self isVisible]];
}

- (void)OE_updateFrameAttachedToView:(NSView *)attachedView onEdge:(OERectEdge)edge
{
    // Calculate the top left point of the frame, this position is dependent on the edge that the arrow is visible on
    NSWindow *attachedWindow = [attachedView window];
    const NSRect screenFrame = [[self screen] visibleFrame];
    const NSRect rect        = [attachedWindow convertRectToScreen:[attachedView convertRect:[attachedView bounds] toView:nil]];

    [_view setEdge:edge];             // Edge must be set first for -[OEMenuView size] to produce an accurate result
    const NSSize size = [_view size];

    // Calculates the origin for the specified edge
    NSPoint (^originForEdge)(OERectEdge edge) =
    ^ (OERectEdge edge)
    {
        const NSRect       bounds     = { .size = size };
        const NSEdgeInsets edgeInsets = [OEMenuView OE_backgroundEdgeInsetsForEdge:edge];
        switch(edge)
        {
            case OENoEdge:   return NSMakePoint(NSMinX(rect) - edgeInsets.left + 1.0,  NSMinY(rect) - size.height);
            case OEMinXEdge: return NSMakePoint(NSMaxX(rect) - edgeInsets.right + 1.0, NSMidY(rect) - NSMidY(bounds));
            case OEMaxXEdge: return NSMakePoint(NSMinX(rect) - NSWidth(bounds) + edgeInsets.left - 1.0, NSMidY(rect) - NSMidY(bounds));
            case OEMinYEdge: return NSMakePoint(NSMidX(rect) - NSMidX(bounds), NSMaxY(rect) - edgeInsets.top - 1.0);
            case OEMaxYEdge: return NSMakePoint(NSMidX(rect) - NSMidX(bounds), NSMinY(rect) - NSHeight(bounds) + edgeInsets.bottom + 1.0);
            default:         break;
        }
        return NSZeroPoint;
    };

    // Figure out the size and position of the frame, as well as the anchor point.
    NSRect  frame         = NSIntegralRect((NSRect){.origin = originForEdge(edge), .size = size });
    NSPoint attachedPoint = NSZeroPoint;

    // Adjust the frame's dimensions not to be bigger than the screen
    frame.size.height = MIN(NSHeight(frame), NSHeight(screenFrame));
    frame.size.width  = MIN(NSWidth(frame), NSWidth(screenFrame));

    switch(edge)
    {
        case OEMinXEdge:
        case OEMaxXEdge:
            if(NSMinX(frame) < NSMinX(screenFrame) || NSMaxX(frame) > NSMaxX(screenFrame))
            {
                NSLog(@"Flip to the other side.");
                OERectEdge newEdge = edge == OEMinXEdge ? OEMaxXEdge : OEMinXEdge;
                frame.origin = originForEdge(newEdge);

                if(NSMinX(frame) < NSMinX(screenFrame) || NSMaxX(frame) > NSMaxX(screenFrame))
                {
                    // TODO: Make view smaller
                    NSLog(@"Make view smaller");
                }
                else
                {
                    // Flip successful
                    [_view setEdge:newEdge];
                }
            }

            // Adjust the frame's position to make the menu completely visible
            frame.origin.x = MIN(MAX(NSMinX(frame), NSMinX(screenFrame)), NSMaxX(screenFrame) - NSWidth(frame));
            frame.origin.y = MIN(MAX(NSMinY(frame), NSMinY(screenFrame)), NSMaxY(screenFrame) - NSHeight(frame));

            attachedPoint.x = ([_view edge] == OEMinXEdge ? NSMinX(frame) : NSMaxX(frame));
            attachedPoint.y = NSMidY(rect);
            break;
        case OEMinYEdge:
        case OEMaxYEdge:
            if(NSMinY(frame) < NSMinY(screenFrame) || NSMaxY(frame) > NSMaxY(screenFrame))
            {
                NSLog(@"Flip to the other side.");
                OERectEdge newEdge = edge == OEMinYEdge ? OEMaxYEdge : OEMinYEdge;
                frame.origin = originForEdge(newEdge);

                if(NSMinY(frame) < NSMinY(screenFrame) || NSMaxY(frame) > NSMaxY(screenFrame))
                {
                    // TODO: Make view smaller
                    NSLog(@"Make view smaller");
                }
                else
                {
                    // Flip successful
                    [_view setEdge:newEdge];
                }
            }

            // Adjust the frame's position to make the menu completely visible
            frame.origin.x = MIN(MAX(NSMinX(frame), NSMinX(screenFrame)), NSMaxX(screenFrame) - NSWidth(frame));
            frame.origin.y = MIN(MAX(NSMinY(frame), NSMinY(screenFrame)), NSMaxY(screenFrame) - NSHeight(frame));

            attachedPoint.x = NSMidX(rect);
            attachedPoint.y = ([_view edge] == OEMinYEdge ? NSMinY(frame) : NSMaxY(frame));
            break;
        case OENoEdge:
        default:
            // Adjust the frame's position to make the menu completely visible
            frame.origin.x = MIN(MAX(NSMinX(frame), NSMinX(screenFrame)), NSMaxX(screenFrame) - NSWidth(frame));
            frame.origin.y = MIN(MAX(NSMinY(frame), NSMinY(screenFrame)), NSMaxY(screenFrame) - NSHeight(frame));
            break;
    }
    [self setFrame:frame display:[self isVisible]];
    if(!NSEqualPoints(attachedPoint, NSZeroPoint))
    {
        attachedPoint = [_view convertPoint:[self convertScreenToBase:attachedPoint] fromView:nil];
        [_view setAttachedPoint:attachedPoint];
    }
}

- (void)OE_updateFrameForSubmenu
{
    const NSRect       rectInScreen = [self convertRectToScreen:[_view convertRect:[[[_view highlightedItem] extraData] frame] toView:nil]];
    const NSRect       screenFrame  = [[self screen] visibleFrame];
    const NSEdgeInsets edgeInsets   = [_view backgroundEdgeInsets];
    const NSSize       size         = [_submenu->_view size];

    // Calculates the origin for the specified edge
    CGFloat (^xForEdge)(OERectEdge edge) =
    ^ (OERectEdge edge)
    {
        switch(edge)
        {
            case OEMinXEdge: return NSMinX(rectInScreen) - size.width + edgeInsets.left + OEMenuContentEdgeInsets.right;
            case OEMaxXEdge: return NSMaxX(rectInScreen) - edgeInsets.right - OEMenuContentEdgeInsets.left;
            default:         break;
        }
        return 0.0;
    };

    NSRect frame = { .origin = { .x = xForEdge(_submenuOnAlternateSide ? OEMinXEdge : OEMaxXEdge), .y = NSMaxY(rectInScreen) - size.height + OEMenuContentEdgeInsets.top + edgeInsets.top }, .size = size };

    // Adjust the frame's dimensions not to be bigger than the screen
    frame.size.height = MIN(NSHeight(frame), NSHeight(screenFrame));
    frame.size.width  = MIN(NSWidth(frame), NSWidth(screenFrame));

    // Adjust the frame's position to make the menu completely visible
    if(NSMinX(frame) < NSMinX(screenFrame))
    {
        // Flip to the other side
        frame.origin.x = xForEdge(OEMaxXEdge);
        _submenuOnAlternateSide = NO;
    }
    else if(NSMaxX(frame) > NSMaxX(screenFrame))
    {
        // Flip to the other side
        frame.origin.x = xForEdge(OEMinXEdge);
        _submenuOnAlternateSide = YES;
    }

    frame.origin.y = MIN(MAX(NSMinY(frame), NSMinY(screenFrame)), NSMaxY(screenFrame) - NSHeight(frame));

    _submenu->_submenuOnAlternateSide = _submenuOnAlternateSide;
    [_submenu setFrame:frame display:[self isVisible]];
}

- (void)orderWindow:(NSWindowOrderingMode)place relativeTo:(NSInteger)otherWin
{
    [super orderWindow:place relativeTo:otherWin];
    if(_submenu)
    {
        [self OE_updateFrameForSubmenu];
        [_submenu orderFrontRegardless];
    }
}

- (void)setMenu:(NSMenu *)menu
{
    [super setMenu:menu];
    [_view setMenu:menu];
    [self setContentSize:[_view size]];
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

    if(self != [sharedMenuStack objectAtIndex:0])
    {
        [[sharedMenuStack objectAtIndex:0] OE_cancelTrackingWithFadeDuration:duration];
    }
    else
    {
        [self OE_hideWindowWithFadeDuration:duration];
    }
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
    [sharedMenuStack addObject:self];
    if([sharedMenuStack count] == 1)
    {
        // We only need to register for these notifications once, so just do it to the first menu that becomes visible
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(OE_applicationNotification:) name:NSApplicationDidResignActiveNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(OE_applicationNotification:) name:NSApplicationDidHideNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(OE_menuWillShow:) name:NSMenuDidBeginTrackingNotification object:nil];
    }

    NSWindow *parentWindow = [view window];
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
        @autoreleasepool
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
                [[sharedMenuStack lastObject] sendEvent:event];
                continue;  // There is no need to forward this message to NSApp, go back to the start of the loop.
            }
            else if(type == NSFlagsChanged)
            {
                // Flags changes should be sent to all submenu's so that they can be updated appropriately
                [sharedMenuStack makeObjectsPerformSelector:@selector(sendEvent:) withObject:event];
            }
            // If we've gotten this far, then we need to forward the event to NSApp for additional / further processing
            [NSApp sendEvent:event];
        }
    }
    [NSApp discardEventsMatchingMask:NSAnyEventMask beforeEvent:event];
    if([delegate respondsToSelector:@selector(menuDidClose:)]) [delegate menuDidClose:[_view menu]];
}

- (void)OE_hideWindowWithFadeDuration:(CGFloat)duration
{
    if(![self isVisible] || [self alphaValue] == 0.0) return;

    NSUInteger  index = [sharedMenuStack indexOfObject:self];
    NSUInteger  len   = [sharedMenuStack count] - index;
    NSArray    *menus = [sharedMenuStack objectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(index, len)]];

    void (^changes)(NSAnimationContext *context) =
    ^ (NSAnimationContext *context)
    {
        [context setDuration:duration];
        [menus enumerateObjectsUsingBlock:
         ^ (OEMenu *obj, NSUInteger idx, BOOL *stop)
         {
             [[obj animator] setAlphaValue:0.0];
         }];
    };

    void (^completionHandler)(void) = ^{
        [sharedMenuStack removeObjectsInArray:menus];
    };

    [NSAnimationContext runAnimationGroup:changes completionHandler:completionHandler];
}

@end

@implementation OEMenu (OEMenuViewAdditions)

- (void)OE_setClosing:(BOOL)closing
{
    OEMenu *topMenu = [sharedMenuStack objectAtIndex:0];
    if(topMenu) topMenu->_closing = closing;
}

- (void)OE_setSubmenu:(NSMenu *)submenu
{
    if([_submenu menu] == submenu) return;
    [_submenu OE_hideWindowWithoutAnimation];

    if(submenu == nil)
    {
        _submenu = nil;
        return;
    }

    const NSRect rectInScreen = [self convertRectToScreen:[_view convertRect:[[[_view highlightedItem] extraData] frame] toView:nil]];
    _submenu = [isa popUpContextMenuWithMenu:submenu withRect:rectInScreen];
    if(_submenu != nil)
    {
        [_submenu setContentSize:[_submenu->_view size]];
        _submenu->_supermenu = self;
        [_submenu->_view setStyle:[_view style]];
        [self OE_updateFrameForSubmenu];
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
