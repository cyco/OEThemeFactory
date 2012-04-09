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
static const CGFloat OEMenuClickDelay      = 0.5;   // Amount of time before menu interprets a mouse down event between a click or drag operation

NSString * const OEMenuOptionsStyleKey           = @"OEMenuStyle";
NSString * const OEMenuOptionsArrowEdgeKey       = @"OEArrowEdge";
NSString * const OEMenuOptionsMaximumSizeKey     = @"OEMaximumSize";
NSString * const OEMenuOptionsMinimumSizeKey     = @"OEMinimumSize";
NSString * const OEMenuOptionsHighlightedItemKey = @"OEHighlightedItem";

@interface OEMenu ()

- (void)OE_updateFrameAttachedToPopupButton:(OEPopUpButton *)buton alignSelectedItemWithRect:(NSRect)titleRect;
- (void)OE_updateFrameAttachedToScreenRect:(NSRect)rect;
- (void)OE_updateFrameForSubmenu;

- (void)OE_applicationActivityNotification:(NSNotification *)notification;
- (void)OE_menuWillBeginTrackingNotification:(NSNotification *)notification;

- (void)OE_hideWindowWithFadeDuration:(CGFloat)duration completionHandler:(void (^)(void))completionHandler;
- (void)OE_showMenuAttachedToWindow:(NSWindow *)parentWindow;
- (void)OE_showMenuAttachedToWindow:(NSWindow *)parentWindow withEvent:(NSEvent *)initialEvent;

@end

static NSMutableArray *sharedMenuStack;

@implementation OEMenu

+ (OEMenu *)OE_popUpContextMenuWithMenu:(NSMenu *)menu options:(NSDictionary *)options
{
    OEMenu *result = [[self alloc] initWithContentRect:NSZeroRect styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:YES screen:[NSScreen mainScreen]];
    NSAssert(result != nil, @"Out of memory.");
    [result setMenu:menu];


    NSNumber *style             = [options objectForKey:OEMenuOptionsStyleKey];
    NSNumber *edge              = [options objectForKey:OEMenuOptionsArrowEdgeKey];
    NSValue  *maxSize           = [options objectForKey:OEMenuOptionsMaximumSizeKey];
    NSValue  *minSize           = [options objectForKey:OEMenuOptionsMinimumSizeKey];
    NSMenuItem *highlightedItem = [options objectForKey:OEMenuOptionsHighlightedItemKey];

    OEMenuView *menuView = [result OE_view];
    if(style)           [menuView setStyle:[style unsignedIntegerValue]];
    if(edge)            [menuView setEdge:[edge unsignedIntegerValue]];
    if(maxSize)         [menuView setMaximumSize:[maxSize sizeValue]];
    if(minSize)         [menuView setMinimumSize:[minSize sizeValue]];
    if(highlightedItem) [menuView setHighlightedItem:highlightedItem];
    [menuView display];

    return result;
}

+ (void)popUpContextMenuForPopUpButton:(OEPopUpButton *)button withEvent:(NSEvent *)event options:(NSDictionary *)options
{
    // Calculate the frame for the popup menu so that the popup menu's selected item hovers exactly over the popup button's title
    const NSRect titleRectInButton = [[button cell] titleRectForBounds:[button bounds]];
    const NSRect titleRectInScreen = [[button window] convertRectToScreen:[button convertRect:titleRectInButton toView:nil]];

    // Create a popup using the style specified by the button
    NSMutableDictionary *newOptions = (options ? [options mutableCopy] : [NSMutableDictionary dictionary]);
    [newOptions setValue:[NSNumber numberWithUnsignedInteger:OENoEdge] forKey:OEMenuOptionsArrowEdgeKey];
    [newOptions setValue:[button selectedItem] forKey:OEMenuOptionsHighlightedItemKey];

    OEMenu *result = [self OE_popUpContextMenuWithMenu:[button menu] options:newOptions];
    [result OE_updateFrameAttachedToPopupButton:button alignSelectedItemWithRect:titleRectInScreen];
    [result OE_showMenuAttachedToWindow:[button window] withEvent:event];
}

+ (void)popUpContextMenu:(NSMenu *)menu forScreenRect:(NSRect)rect withEvent:(NSEvent *)event options:(NSDictionary *)options
{
    // Calculate the frame for the popup menu so that the menu appears to be attached to the specified view
    OEMenu *result = [self OE_popUpContextMenuWithMenu:menu options:options];
    [result OE_updateFrameAttachedToScreenRect:rect];
    [result OE_showMenuAttachedToWindow:[event window] withEvent:event];
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

- (NSRect)OE_confinementRectForScreen:(NSScreen *)screen
{
    NSRect results      = NSZeroRect;
    NSRect visibleFrame = [[self screen] visibleFrame];

    // Invoked to allow the delegate to specify a display location for the menu.
    id<NSMenuDelegate> delegate = [[self menu] delegate];
    if([delegate respondsToSelector:@selector(confinementRectForMenu:onScreen:)]) results = [delegate confinementRectForMenu:[self menu] onScreen:screen];

    // If delegate is not implemented or it returns NSZeroRect then return the screen's visible frame
    if(NSEqualRects(results, NSZeroRect)) results = [[self screen] visibleFrame];
    else                                  results = NSIntersectionRect(visibleFrame, results);

    return results;
}

// Updates the frame's position and dimensions as it relates to the provided pop up button, while aligning the selected item to the rect specified
- (void)OE_updateFrameAttachedToPopupButton:(OEPopUpButton *)button alignSelectedItemWithRect:(NSRect)rect
{
    const NSRect       screenFrame      = [self OE_confinementRectForScreen:([self screen] ?: [[button window] screen])];
    const NSEdgeInsets edgeInsets       = [_view backgroundEdgeInsets];
    const NSRect       buttonFrame      = [button bounds];
    const NSRect       selectedItemRect = [[[_view highlightedItem] extraData] frame];

    NSRect frame = { .origin = rect.origin, .size = [_view size] };

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

// Calculates the origin of the frame, this position is dependent on the edge that the arrow is visible on
- (NSPoint)OE_originAttachedToScreenRect:(NSRect)rect withArrowOnEdge:(OERectEdge)edge
{
    const NSRect       bounds     = { .size = [[self OE_view] size] };
    const NSEdgeInsets edgeInsets = [OEMenuView OE_backgroundEdgeInsetsForEdge:edge];
    switch(edge)
    {
        case OENoEdge:   return NSMakePoint(NSMinX(rect) - edgeInsets.left + 1.0,  NSMinY(rect) - NSHeight(bounds));
        case OEMinXEdge: return NSMakePoint(NSMaxX(rect) - edgeInsets.right + 1.0, NSMidY(rect) - NSMidY(bounds));
        case OEMaxXEdge: return NSMakePoint(NSMinX(rect) - NSWidth(bounds) + edgeInsets.left - 1.0, NSMidY(rect) - NSMidY(bounds));
        case OEMinYEdge: return NSMakePoint(NSMidX(rect) - NSMidX(bounds), NSMaxY(rect) - edgeInsets.top - 1.0);
        case OEMaxYEdge: return NSMakePoint(NSMidX(rect) - NSMidX(bounds), NSMinY(rect) - NSHeight(bounds) + edgeInsets.bottom + 1.0);
        default:         break;
    }
    return NSZeroPoint;
}

// Updates the frame's position and dimensions as it relates to the rect specified on the screen
- (void)OE_updateFrameAttachedToScreenRect:(NSRect)rect
{
    const NSRect screenFrame = [self OE_confinementRectForScreen:[self screen]];
    const NSSize size        = [_view size];

    // Figure out the size and position of the frame, as well as the anchor point.
    OERectEdge edge          = [_view edge];
    NSRect     frame         = NSIntegralRect((NSRect){.origin = [self OE_originAttachedToScreenRect:rect withArrowOnEdge:edge], .size = size });
    NSPoint    attachedPoint = NSZeroPoint;

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
                frame.origin = [self OE_originAttachedToScreenRect:rect withArrowOnEdge:newEdge];

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
                frame.origin = [self OE_originAttachedToScreenRect:rect withArrowOnEdge:newEdge];

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
    const NSRect       screenFrame  = [self OE_confinementRectForScreen:[self screen]];
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

    OERectEdge edge = ([_view edge] == OENoEdge ? OEMaxXEdge : [_view edge]);
    NSRect frame = { .origin = { .x = xForEdge(edge), .y = NSMaxY(rectInScreen) - size.height + OEMenuContentEdgeInsets.top + edgeInsets.top }, .size = size };

    // Adjust the frame's dimensions not to be bigger than the screen
    frame.size.height = MIN(NSHeight(frame), NSHeight(screenFrame));
    frame.size.width  = MIN(NSWidth(frame), NSWidth(screenFrame));

    // Adjust the frame's position to make the menu completely visible
    if(NSMinX(frame) < NSMinX(screenFrame))
    {
        // Flip to the other side
        frame.origin.x = xForEdge(OEMaxXEdge);
        edge = OEMaxXEdge;
    }
    else if(NSMaxX(frame) > NSMaxX(screenFrame))
    {
        // Flip to the other side
        frame.origin.x = xForEdge(OEMinXEdge);
        edge = OEMinXEdge;
    }
    [_submenu->_view setEdge:edge];

    frame.origin.y = MIN(MAX(NSMinY(frame), NSMinY(screenFrame)), NSMaxY(screenFrame) - NSHeight(frame));

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

- (void)removeChildWindow:(NSWindow *)childWin
{
    if(childWin == _submenu) _submenu = nil;
    [super removeChildWindow:childWin];
}

- (void)setMenu:(NSMenu *)menu
{
    [super setMenu:menu];
    [_view setMenu:menu];
    [self setContentSize:[_view size]];
}

- (void)OE_applicationActivityNotification:(NSNotification *)notification
{
    [self cancelTrackingWithoutAnimation];
}

- (void)OE_menuWillBeginTrackingNotification:(NSNotification *)notification
{
    if([notification object] != [self menu]) [self cancelTrackingWithoutAnimation];
}

- (void)OE_hideWindowWithFadeDuration:(CGFloat)duration completionHandler:(void (^)(void))completionHandler
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

    void (^fireCompletionHandler)(void) = ^{
        if(completionHandler) completionHandler();
        [[self parentWindow] removeChildWindow:self];

        // Invoked after a menu closed.
        id<NSMenuDelegate> delegate = [[self menu] delegate];
        if([delegate respondsToSelector:@selector(menuDidClose:)]) [delegate menuDidClose:[_view menu]];

        [sharedMenuStack removeObjectsInArray:menus];
    };

    [NSAnimationContext runAnimationGroup:changes completionHandler:fireCompletionHandler];
}

- (void)OE_cancelTrackingWithFadeDuration:(CGFloat)duration completionHandler:(void (^)(void))completionHandler
{
    if(_cancelTracking) return;
    _cancelTracking = YES;

    if(self != [sharedMenuStack objectAtIndex:0])
    {
        [[sharedMenuStack objectAtIndex:0] OE_cancelTrackingWithFadeDuration:duration completionHandler:completionHandler];
    }
    else
    {
        [self OE_hideWindowWithFadeDuration:duration completionHandler:completionHandler];
    }
}

- (void)cancelTracking
{
    [self OE_cancelTrackingWithFadeDuration:OEMenuFadeOutDuration completionHandler:nil];
}

- (void)cancelTrackingWithoutAnimation
{
    [self OE_cancelTrackingWithFadeDuration:0.0 completionHandler:nil];
}

- (void)OE_showMenuAttachedToWindow:(NSWindow *)parentWindow
{
    [sharedMenuStack addObject:self];
    if([sharedMenuStack count] == 1)
    {
        // We only need to register for these notifications once, so just do it to the first menu that becomes visible
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(OE_applicationActivityNotification:) name:NSApplicationDidResignActiveNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(OE_applicationActivityNotification:) name:NSApplicationDidHideNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(OE_menuWillBeginTrackingNotification:) name:NSMenuDidBeginTrackingNotification object:nil];
    }

#if 0
    // TODO: Track additions and subtractions from the menu
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(OE_menuDidAddItemNotification:) name:NSMenuDidAddItemNotification object:[self menu]];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(OE_menuDidRemoveItemNotification:) name:NSMenuDidRemoveItemNotification object:[self menu]];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(OE_menuDidChangeItemNotification:) name:NSMenuDidChangeItemNotification object:[self menu]];
#endif

    // Invoked when a menu is about to open.
    id<NSMenuDelegate> delegate = [[_view menu] delegate];
    if([delegate respondsToSelector:@selector(menuWillOpen:)]) [delegate menuWillOpen:[_view menu]];

#if 0
    // TODO: -numberOfItemsInMenu:
    // Invoked when a menu is about to be displayed at the start of a tracking session so the delegate can specify the number of items in the menu.
    if([delegate respondsToSelector:@selector(numberOfItemsInMenu:)] && [delegate respondsToSelector:@selector(menu:updateItem:atIndex:shouldCancel:)])
    {
        NSInteger numberOfMenuItems = [delegate numberOfItemsInMenu:[self menu]];
        if(numberOfMenuItems > 0)
        {
            // Resize the menu
            NSArray *itemArray = [[self menu] itemArray];
            for(NSInteger i = 0; i < numberOfMenuItems; i++)
            {
                if([delegate menu:[self menu] updateItem:[itemArray objectAtIndex:i] atIndex:i shouldCancel:([OEMenu OE_closing] || _cancelTracking)]) break;
            }
        }
    }
#endif

    [parentWindow addChildWindow:self ordered:NSWindowAbove];
    if(![parentWindow isKindOfClass:[OEMenu class]] || [parentWindow isVisible]) [self orderFrontRegardless];
}

+ (NSPoint)OE_locationInScreenForEvent:(NSEvent *)event
{
    const NSPoint locationInWindow = [event locationInWindow];
    NSWindow *window               = [event window];
    return window == nil ? locationInWindow : [window convertBaseToScreen:locationInWindow];
}

- (NSEvent *)OE_mockMouseEvent:(NSEvent *)event
{
    if([event window] == self || [[event window] isKindOfClass:[OEMenu class]]) return event;

    const NSPoint location = [self convertScreenToBase:[isa OE_locationInScreenForEvent:event]];
    return [NSEvent mouseEventWithType:[event type] location:location modifierFlags:[event modifierFlags] timestamp:[event timestamp] windowNumber:[self windowNumber] context:[event context] eventNumber:[event eventNumber] clickCount:[event clickCount] pressure:[event pressure]];
}

- (void)OE_showMenuAttachedToWindow:(NSWindow *)parentWindow withEvent:(NSEvent *)initialEvent
{
    [self OE_showMenuAttachedToWindow:parentWindow];

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

    // Invoked when a menu is about to be displayed at the start of a tracking session so the delegate can modify the menu.
    id<NSMenuDelegate> delegate = [[self menu] delegate];
    if([delegate respondsToSelector:@selector(menuNeedsUpdate:)]) [delegate menuNeedsUpdate:[self menu]];

    // Posted when menu tracking begins.
    [[NSNotificationCenter defaultCenter] postNotificationName:NSMenuDidBeginTrackingNotification object:[self menu]];

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
                // not have the information we really need.
                const NSPoint  locationInScreen = [isa OE_locationInScreenForEvent:event];
                OEMenu        *newMenuFocus     = [isa OE_menuAtPoint:locationInScreen];
                if(menuWithMouseFocus != newMenuFocus)
                {
                    // If the menu with the focus has changed, let the old menu know that the mouse has exited it's view
                    if(menuWithMouseFocus) [menuWithMouseFocus->_view mouseExited:[menuWithMouseFocus OE_mockMouseEvent:event]];
                    if([newMenuFocus isKindOfClass:[OEMenu class]])
                    {
                        // Let the new menu know that the mouse has enterd it's view
                        menuWithMouseFocus = newMenuFocus;
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
                // TODO: -performKeyEquivalent:

                // Key down messages should be sent to the deepest submenu that is open
                [[sharedMenuStack lastObject] sendEvent:event];
                continue;  // There is no need to forward this message to NSApp, go back to the start of the loop.
            }
            else if(type == NSFlagsChanged)
            {
                // Flags changes should be sent to all submenu's so that they can be updated appropriately
                [sharedMenuStack makeObjectsPerformSelector:@selector(sendEvent:) withObject:event];
                continue;  // There is no need to forward this message to NSApp, go back to the start of the loop.
            }

            // If we've gotten this far, then we need to forward the event to NSApp for additional / further processing
            [NSApp sendEvent:event];
        }
    }
    [NSApp discardEventsMatchingMask:NSAnyEventMask beforeEvent:event];

    // Posted when menu tracking ends, even if no action is sent.
    [[NSNotificationCenter defaultCenter] postNotificationName:NSMenuDidEndTrackingNotification object:[self menu]];
}

@end

@implementation OEMenu (OEMenuViewAdditions)

+ (OEMenu *)OE_menuAtPoint:(NSPoint)point
{
    __block OEMenu *result = nil;
    [sharedMenuStack enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:
     ^ (OEMenu *obj, NSUInteger idx, BOOL *stop)
     {
         if(NSPointInRect(point, [obj frame]))
         {
             result = obj;
             *stop = YES;
         }
     }];
    return result;
}

- (void)OE_setClosing:(BOOL)closing
{
    if([sharedMenuStack objectAtIndex:0] != self) [[sharedMenuStack objectAtIndex:0] OE_setClosing:closing];
    else                                          _closing = closing;
}

- (BOOL)OE_closing
{
    if([sharedMenuStack objectAtIndex:0] != self) return [[sharedMenuStack objectAtIndex:0] OE_closing];
    return _closing;
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

    _submenu = [isa OE_popUpContextMenuWithMenu:submenu options:[NSDictionary dictionaryWithObject:[NSNumber numberWithUnsignedInteger:[_view style]] forKey:OEMenuOptionsStyleKey]];
    _submenu->_supermenu = self;
//
//    [_submenu setContentSize:[_submenu->_view size]];
//    [_submenu->_view setStyle:[_view style]];

    [self OE_updateFrameForSubmenu];
    [_submenu OE_showMenuAttachedToWindow:[_view window]];
}

- (OEMenu *)OE_submenu
{
    return _submenu;
}

- (OEMenu *)OE_supermenu
{
    return _supermenu;
}

- (OEMenuView *)OE_view
{
    return _view;
}

- (void)OE_hideWindowWithoutAnimation
{
    [self OE_hideWindowWithFadeDuration:0.0 completionHandler:nil];
}

- (void)OE_cancelTrackingWithCompletionHandler:(void (^)(void))completionHandler
{
    [self OE_cancelTrackingWithFadeDuration:OEMenuFadeOutDuration completionHandler:completionHandler];
}

@end
