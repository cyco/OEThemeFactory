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

- (void)OE_applicationNotification:(NSNotification *)notification;
- (void)OE_showWindowForView:(NSView *)view withEvent:(NSEvent *)initialEvent;
- (OEMenuView *)OE_view;

@end

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

    const NSRect buttonFrame       = [window convertRectToScreen:[button convertRect:[button frame] toView:nil]];
    const NSRect titleRectInButton = [[button cell] titleRectForBounds:[button bounds]];
    const NSRect titleRectInScreen = [window convertRectToScreen:[button convertRect:titleRectInButton toView:nil]];

    OEMenu *result = [self popUpContextMenuWithMenu:[button menu] withRect:buttonFrame];
    if(result != nil)
    {
        // Make sure result is not nil we don't want to dereference a null pointer
        [result->_view setEdge:OENoEdge];
        [result setContentSize:[result->_view sizeThatFits:buttonFrame]];
        [result->_view setHighlightedItem:[button selectedItem]];
        [result setFrameTopLeftPoint:[result->_view topLeftPointWithRect:titleRectInScreen]];
        [result OE_showWindowForView:button withEvent:event];
    }
}

+ (void)popUpContextMenu:(NSMenu *)menu arrowOnEdge:(OERectEdge)edge forView:(NSView *)view withEvent:(NSEvent *)event
{
    const NSRect rectInWindow = [view convertRect:[view bounds] toView:nil];
    const NSRect rectInScreen = [[view window] convertRectToScreen:rectInWindow];

    OEMenu *result = [self popUpContextMenuWithMenu:menu withRect:rectInScreen];
    if(result)
    {
        [result->_view setEdge:edge];
        [result setContentSize:[result->_view sizeThatFits:NSZeroRect]];
        [result setFrameTopLeftPoint:[result->_view topLeftPointWithRect:rectInScreen]];
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
        [self makeFirstResponder:_view];

        [self setOpaque:NO];
        [self setBackgroundColor:[NSColor clearColor]];
        [self setLevel:NSTornOffMenuWindowLevel];
        [self setHasShadow:NO];
        [self setReleasedWhenClosed:YES];
        [self setCollectionBehavior:NSWindowCollectionBehaviorTransient | NSWindowCollectionBehaviorIgnoresCycle];

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(OE_applicationNotification:) name:NSApplicationDidResignActiveNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(OE_applicationNotification:) name:NSApplicationDidHideNotification object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self OE_removeEventMonitor];
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

- (void)OE_applicationNotification:(NSNotification *)notification
{
    [self cancelTrackingWithoutAnimation];
}

- (void)OE_createEventMonitorWithInitialEvent:(NSEvent *)initialEvent
{
    __block NSInteger mouseDragging = NSMixedState; // Determines if the mouse is being dragged or just clicked

    // Set up block used to dispatch events that we would like to forward to the OEMenuView
    NSEvent *(^dispatchEvent)(NSEvent *) =
    ^ NSEvent *(NSEvent *incomingEvent)
    {
        switch([incomingEvent type])
        {
            case NSAppKitDefined:
                // When an application gains and looses focus an event with NSAppKitDefined is received -- go ahead and forward that event to NSApp to follow the right responder chain
                return incomingEvent;
            case NSFlagsChanged:
                [_view flagsChanged:incomingEvent];
                break;
            case NSScrollWheel:
                // TODO: If we are in a scrollable part of the meu then we should react to this
                break;
            case NSMouseMoved:
                [_view mouseMoved:incomingEvent];
                break;
            case NSKeyDown:
                [_view keyDown:incomingEvent];
                break;
            case NSKeyUp:
                [_view keyUp:incomingEvent];
                break;
            case NSRightMouseDragged:
            case NSLeftMouseDragged:
            case NSOtherMouseDragged:
                mouseDragging = NSOnState;
                [_view mouseDragged:incomingEvent];
                break;
            case NSRightMouseUp:
            case NSLeftMouseUp:
            case NSOtherMouseUp:
                if(initialEvent != nil && mouseDragging == NSMixedState) mouseDragging = ([incomingEvent timestamp] - [initialEvent timestamp] > 1.0 ? NSOnState : NSOffState);
            default:
                if([[incomingEvent window] isKindOfClass:[self class]]) return incomingEvent;
                else                                                    [self cancelTracking];
                break;
        }
        return nil;
    };

    // Figure out what events we should monitor based on the initial event (if it is provided)
    NSUInteger        mouseButtonMask = NSMouseMovedMask | NSScrollWheelMask | NSFlagsChangedMask;
    const NSEventType type            = [initialEvent type];
    switch(type)
    {
        case NSRightMouseDown:
            mouseButtonMask |= NSRightMouseDraggedMask | NSRightMouseDownMask | NSRightMouseUpMask;
            break;
        case NSOtherMouseDown:
            mouseButtonMask |= NSOtherMouseDraggedMask | NSOtherMouseDownMask | NSOtherMouseUpMask;
            break;
        default:
        case NSLeftMouseDown:
            mouseButtonMask |= NSLeftMouseDraggedMask | NSLeftMouseDownMask | NSLeftMouseUpMask;
            break;
            break;
    }

    // If there was an initial event lets track the mouse until it is released
    if(initialEvent != nil)
    {
        [_view mouseDown:[self OE_convertEvent:initialEvent]];

        NSEvent *event = nil;
        while(!_cancelTracking && !_closing && (event = [self nextEventMatchingMask:mouseButtonMask | NSAppKitDefinedMask untilDate:[NSDate distantFuture] inMode:NSEventTrackingRunLoopMode dequeue:YES]))
        {
            if((event = dispatchEvent([self OE_convertEvent:event])))
            {
                NSEventType type = [event type];
                if(type == NSLeftMouseUp || type == NSRightMouseUp || type == NSOtherMouseUp)
                {
                    // Only forward the mouse up to the view if we are dragging the mouse around...if we are not dragging the mouse, then we are recoverring from a mouse click (momentary press)
                    if(initialEvent == nil || mouseDragging == NSOnState) [_view mouseUp:event];
                    break;
                }
                [NSApp sendEvent:event];
            }
        }
        [self discardEventsMatchingMask:NSAnyEventMask beforeEvent:event];
    }

    if(!_cancelTracking && !_closing)
    {
        // If we just finished recovering from a mouse click, lets install a local monitor to capture events that should be forwarded to the OEMenuView
        mouseDragging = NSOnState;
        _localMonitor = [NSEvent addLocalMonitorForEventsMatchingMask:mouseButtonMask | NSKeyUpMask | NSKeyDownMask handler:dispatchEvent];
    }
}

- (void)OE_removeEventMonitor
{
    if(_localMonitor != nil)
    {
        [NSEvent removeMonitor:_localMonitor];
        _localMonitor = nil;
    }
}

- (void)cancelTracking
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
     }];
}

- (void)cancelTrackingWithoutAnimation
{
    if(_cancelTracking) return;
    _cancelTracking = YES;
    [self OE_removeEventMonitor];
    [[self parentWindow] removeChildWindow:self];
}

- (NSEvent *)OE_convertEvent:(NSEvent *)event
{
    NSEventType type = [event type];
    if([event window] != self && (type == NSLeftMouseDown || type == NSLeftMouseUp || type == NSLeftMouseDragged || type == NSRightMouseDown || type == NSRightMouseUp || type == NSRightMouseDragged || type == NSOtherMouseDown || type == NSOtherMouseUp || type == NSOtherMouseDragged))
    {
        const NSPoint location = [self convertScreenToBase:[[event window] convertBaseToScreen:[event locationInWindow]]];
        return [NSEvent mouseEventWithType:[event type] location:location modifierFlags:[event modifierFlags] timestamp:[event timestamp] windowNumber:[self windowNumber] context:[event context] eventNumber:[event eventNumber] clickCount:[event clickCount] pressure:[event pressure]];
    }
    return event;
}

- (void)OE_showWindowForView:(NSView *)view withEvent:(NSEvent *)initialEvent
{
    [[view window] addChildWindow:self ordered:NSWindowAbove];
    [self orderFrontRegardless];
    [self OE_createEventMonitorWithInitialEvent:initialEvent];
}

- (OEMenuView *)OE_view
{
    return _view;
}

@end
