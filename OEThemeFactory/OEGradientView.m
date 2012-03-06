//
//  OEGradientView.m
//  OEThemeFactory
//
//  Created by Faustino Osuna on 3/4/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "OEGradientView.h"
#import "OEThemeGradient.h"

@implementation OEGradientView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }

    return self;
}

- (OEThemeState)OE_currentState
{
    NSWindow   *window       = [self window];
    const BOOL  focused      = [window firstResponder] == self;
    const BOOL  windowActive = (_cachedStateMask & OEThemeStateAnyWindowActivity) && ([window isMainWindow] || ([window parentWindow] && [[window parentWindow] isMainWindow]));
    BOOL        hover        = NO;

    if(_cachedStateMask & OEThemeStateAnyMouse)
    {
        const NSPoint p = [self convertPointFromBase:[window convertScreenToBase:[NSEvent mouseLocation]]];
        hover           = NSPointInRect(p, [self bounds]);
    }

    return [OEThemeObject themeStateWithWindowActive:windowActive buttonState:NSOffState selected:NO enabled:YES focused:focused houseHover:hover];
}

- (void)drawRect:(NSRect)dirtyRect
{
    NSGradient *gradient = [_themeGradient gradientForState:[self OE_currentState]];
    [gradient drawInRect:[self bounds] angle:0.0];
}

- (void)viewWillMoveToWindow:(NSWindow *)newWindow
{
    [super viewWillMoveToWindow:newWindow];

    if([self window])
    {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:NSWindowDidBecomeMainNotification object:[self window]];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:NSWindowDidResignMainNotification object:[self window]];
    }

    if(newWindow && (_cachedStateMask & OEThemeStateAnyWindowActivity))
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
    if(_cachedStateMask & OEThemeStateAnyMouse)
    {
        _mouseTrackingArea = [[NSTrackingArea alloc] initWithRect:[self bounds] options:NSTrackingActiveInActiveApp | NSTrackingMouseEnteredAndExited owner:self userInfo:nil];
        [self addTrackingArea:_mouseTrackingArea];
    }
}

- (void)mouseEntered:(NSEvent *)theEvent
{
    [self setNeedsDisplay:YES];
}

- (void)mouseExited:(NSEvent *)theEvent
{
    [self setNeedsDisplay:YES];
}

- (void)OE_windowKeyChanged:(NSNotification *)notification
{
    [self setNeedsDisplay:YES];
}

- (void)OE_updateNotifications
{
    NSUInteger stateMask = [_themeGradient stateMask];

    BOOL updateWindowActivity = (_cachedStateMask & OEThemeStateAnyWindowActivity) != (stateMask & OEThemeStateAnyWindowActivity);
    BOOL updateMouseActivity  = (_cachedStateMask & OEThemeStateAnyMouse)          != (stateMask & OEThemeStateAnyMouse);

    _cachedStateMask = stateMask;
    if(updateWindowActivity)
    {
        [self viewWillMoveToWindow:[self window]];
        [self setNeedsDisplay:YES];
    }

    if(updateMouseActivity)
    {
        [self updateTrackingAreas];
        [self setNeedsDisplay:YES];
    }
}

- (void)setThemeGradientKey:(NSString *)key
{
    [self setThemeGradient:[[OETheme sharedTheme] themeGradientForKey:key]];
}

- (void)setThemeGradient:(OEThemeGradient *)themeGradient
{
    if(_themeGradient != themeGradient)
    {
        _themeGradient = themeGradient;
        [self OE_updateNotifications];
        [self setNeedsDisplay:YES];
    }
}

- (OEThemeGradient *)themeGradient
{
    return _themeGradient;
}

@end
