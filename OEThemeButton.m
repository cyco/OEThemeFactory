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
    if([cell isKindOfClass:[OEImageButtonCell class]] && newWindow && [[cell backgroundThemeImage] stateMask] & OEThemeStateAnyWindowActivityMask)
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
    if([cell isKindOfClass:[OEImageButtonCell class]] && [[cell backgroundThemeImage] stateMask] & OEThemeStateAnyMouseMask)
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
        OEThemeImage *backgroundThemeImage = [cell backgroundThemeImage];
        NSUInteger stateMask = [backgroundThemeImage stateMask];

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

- (void)setBackgroundThemeImageKey:(NSString *)key
{
    [self setBackgroundThemeImage:[[OETheme sharedTheme] themeImageForKey:key]];
}

- (void)setBackgroundThemeImage:(OEThemeImage *)backgroundThemeImage
{
    OEImageButtonCell *cell = [self cell];
    if([cell isKindOfClass:[OEImageButtonCell class]])
    {
        [cell setBackgroundThemeImage:backgroundThemeImage];
        [self OE_updateNotifications];
        [self setNeedsDisplay];
    }
}

- (OEThemeImage *)backgroundThemeImage
{
    OEImageButtonCell *cell = [self cell];
    return ([cell isKindOfClass:[OEImageButtonCell class]] ? [cell backgroundThemeImage] : nil);
}

- (void)setCell:(NSCell *)aCell
{
    [super setCell:aCell];
    [self updateTrackingAreas];
}

@end

#pragma mark -

@implementation OEImageButtonCell

@synthesize backgroundThemeImage = _backgroundThemeImage;

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
    if(_backgroundThemeImage == nil) return;

    const OEThemeState state      = [self currentState];
    const NSRect       sourceRect = [self imageRectForButtonState:state];
    const NSRect       targetRect = cellFrame;

    [[_backgroundThemeImage imageForState:state] drawInRect:targetRect fromRect:sourceRect operation:NSCompositeSourceOver fraction:1.0];
}

- (OEThemeState)currentState
{
    OEThemeButton *button = (OEThemeButton *)[self controlView];
    if(![button isKindOfClass:[OEThemeButton class]]) return OEThemeStateDefault;

    NSWindow   *window       = [[self controlView] window];
    const BOOL  focused      = [window firstResponder] == [self controlView];
    const BOOL  windowActive = (button->_stateMask & OEThemeStateAnyWindowActivityMask) && ([window isMainWindow] || ([window parentWindow] && [[window parentWindow] isMainWindow]));
    BOOL        hover        = NO;

    if(button->_stateMask & OEThemeStateAnyMouseMask)
    {
        const NSPoint p = [[self controlView] convertPointFromBase:[window convertScreenToBase:[NSEvent mouseLocation]]];
        hover           = NSPointInRect(p, [[self controlView] bounds]);
    }

    return [OEThemeObject themeStateWithWindowActive:windowActive buttonState:[self state] selected:[self isHighlighted] enabled:[self isEnabled] focused:focused houseHover:hover] & [_backgroundThemeImage stateMask];;
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