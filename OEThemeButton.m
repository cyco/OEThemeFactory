//
//  OEImageButton.m
//  OEThemeFactory
//
//  Created by Faustino Osuna on 3/3/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "OEThemeButton.h"

@interface OEThemeButton ()

- (void)OE_windowKeyChanged:(NSNotification *)notification;
- (void)OE_updateNotifications;

@end

@implementation OEThemeButton

- (BOOL)isFlipped
{
    return YES;
}

- (void)viewWillMoveToWindow:(NSWindow *)newWindow
{
    [super viewWillMoveToWindow:newWindow];

    if([self window])
    {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:NSWindowDidBecomeMainNotification object:[self window]];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:NSWindowDidResignMainNotification object:[self window]];
    }

    OEImageButtonCell *cell = [self cell];
    if([cell isKindOfClass:[OEImageButtonCell class]] && newWindow && [[cell imageStates] stateMask] & OEThemeStateAnyWindowActivityMask)
    {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(OE_windowKeyChanged:) name:NSWindowDidBecomeMainNotification object:newWindow];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(OE_windowKeyChanged:) name:NSWindowDidResignMainNotification object:newWindow];
    }
}

- (void)viewDidMoveToWindow
{
    [super viewDidMoveToWindow];
    [self updateTrackingAreas];
}

- (void)updateTrackingAreas
{
    if(_mouseTrackingArea) [self removeTrackingArea:_mouseTrackingArea];
    OEImageButtonCell *cell = [self cell];
    if([cell isKindOfClass:[OEImageButtonCell class]] && [[cell imageStates] stateMask] & OEThemeStateAnyMouseMask)
    {
        _mouseTrackingArea = [[NSTrackingArea alloc] initWithRect:[self bounds] options:NSTrackingActiveInActiveApp|NSTrackingMouseEnteredAndExited owner:self userInfo:nil];
        [self addTrackingArea:_mouseTrackingArea];
    }
}

- (void)mouseEntered:(NSEvent *)theEvent
{
    [self setNeedsDisplay];
}

- (void)mouseExited:(NSEvent *)theEvent
{
    [self setNeedsDisplay];
}

- (void)OE_windowKeyChanged:(NSNotification *)notification
{
    [self setNeedsDisplay];
}

- (void)OE_updateNotifications
{
    OEImageButtonCell *cell = [self cell];
    if([cell isKindOfClass:[OEImageButtonCell class]])
    {
        OEThemeImageStates *imageStates = [cell imageStates];
        NSUInteger stateMask = [imageStates stateMask];

        BOOL updateWindowActivity = (_stateMask & OEThemeStateAnyWindowActivityMask) != (stateMask & OEThemeStateAnyWindowActivityMask);
        BOOL updateMouseActivity  = (_stateMask & OEThemeStateAnyMouseMask)          != (stateMask & OEThemeStateAnyMouseMask);

        _stateMask = stateMask;
        if(updateWindowActivity)
        {
            [self viewWillMoveToWindow:[self window]];
            [self setNeedsDisplay];
        }

        if(updateMouseActivity)
        {
            [self updateTrackingAreas];
            [self setNeedsDisplay];
        }
    }
}

- (void)setImageStates:(OEThemeImageStates *)imageStates
{
    OEImageButtonCell *cell = [self cell];
    if([cell isKindOfClass:[OEImageButtonCell class]])
    {
        [cell setImageStates:imageStates];
        [self OE_updateNotifications];
        [self setNeedsDisplay];
    }
}

- (void)setImageStatesThemeKey:(NSString *)key
{
    [self setImageStates:[[OETheme sharedTheme] imageStatesForKey:key]];
}

- (OEThemeImageStates *)imageStates
{
    OEImageButtonCell *cell = [self cell];
    return ([cell isKindOfClass:[OEImageButtonCell class]] ? [cell imageStates] : nil);
}

- (void)setCell:(NSCell *)aCell
{
    [super setCell:aCell];
    [self updateTrackingAreas];
}

@end

#pragma mark -

@implementation OEImageButtonCell

@synthesize imageStates = _imageStates;

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
    if(_imageStates == nil) return;

    OEThemeButton *button = (OEThemeButton *)controlView;
    if(![button isKindOfClass:[OEThemeButton class]]) return;

    const BOOL focused      = [[controlView window] firstResponder] == controlView;
    const BOOL windowActive = (button->_stateMask & OEThemeStateAnyWindowActivityMask) && ([[controlView window] isMainWindow] || ([[controlView window] parentWindow] && [[[controlView window] parentWindow] isMainWindow]));
    BOOL hover              = NO;

    if(button->_stateMask & OEThemeStateAnyMouseMask)
    {
        const NSPoint p = [controlView convertPointFromBase:[[controlView window] convertScreenToBase:[NSEvent mouseLocation]]];
        hover           = NSPointInRect(p, [controlView bounds]);
    }

    OEThemeState state = [OEThemeItemStates themeStateWithWindowActive:windowActive buttonState:[self state] selected:[self isHighlighted] enabled:[self isEnabled] focused:focused houseHover:hover] & [_imageStates stateMask];;

    NSRect sourceRect = [self imageRectForButtonState:state];
    NSRect targetRect = cellFrame;

    [[_imageStates imageForState:state] drawInRect:targetRect fromRect:sourceRect operation:NSCompositeSourceOver fraction:1.0];
}

- (NSRect)imageRectForButtonState:(OEThemeState)state
{
    return NSZeroRect;
}

- (BOOL)respondsToStateChangesForMask:(OEThemeState)mask
{
    return YES;
}

@end