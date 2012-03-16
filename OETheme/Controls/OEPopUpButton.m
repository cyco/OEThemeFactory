//
//  OEThemePopUpButton.m
//  OEThemeFactory
//
//  Created by Faustino Osuna on 3/10/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "OEPopUpButton.h"
#import "OEMenu.h"

@interface OEPopUpButton ()

- (void)OE_windowKeyChanged:(NSNotification *)notification;
- (void)OE_updateNotifications;

@end

@implementation OEPopUpButton

- (void)viewWillMoveToWindow:(NSWindow *)newWindow
{
    [super viewWillMoveToWindow:newWindow];

    if([self window])
    {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:NSWindowDidBecomeMainNotification object:[self window]];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:NSWindowDidResignMainNotification object:[self window]];
    }

    if(newWindow && _shouldTrackWindowActivity)
    {
        // Register with the default notification center for changes in the window's keyedness only if one of the themed elements (the state mask) is influenced by the window's activity
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
    if(_shouldTrackMouseActivity)
    {
        // Track mouse enter and exit (hover and off) events only if the one of the themed elements (the state mask) is influenced by the mouse
        _mouseTrackingArea = [[NSTrackingArea alloc] initWithRect:[self bounds] options:NSTrackingActiveInActiveApp | NSTrackingMouseEnteredAndExited owner:self userInfo:nil];
        [self addTrackingArea:_mouseTrackingArea];
    }
}

- (void)mouseEntered:(NSEvent *)theEvent
{
    // Mouse has entered / mouse hover, we want to redisplay the button with the new state...this is only fired when the mouse tracking is installed
    [self setNeedsDisplay];
}

- (void)mouseExited:(NSEvent *)theEvent
{
    // Mouse has exited / mouse off, we want to redisplay the button with the new state...this is only fired when the mouse tracking is installed
    [self setNeedsDisplay];
}

- (void)mouseDown:(NSEvent *)theEvent
{
    [OEMenu popUpContextMenuForPopUpButton:self withEvent:theEvent];
}

- (void)OE_windowKeyChanged:(NSNotification *)notification
{
    // The keyedness of the window has changed, we want to redisplay the button with the new state, this is only fired when NSWindowDidBecomeMainNotification and NSWindowDidResignMainNotification is registered.
    [self setNeedsDisplay];
}

- (void)OE_setShouldTrackWindowActivity:(BOOL)shouldTrackWindowActivity
{
    if(_shouldTrackWindowActivity != shouldTrackWindowActivity)
    {
        _shouldTrackWindowActivity = shouldTrackWindowActivity;
        [self viewWillMoveToWindow:[self window]];
        [self setNeedsDisplay:YES];
    }
}

- (void)OE_setShouldTrackMouseActivity:(BOOL)shouldTrackMouseActivity
{
    if(_shouldTrackMouseActivity != shouldTrackMouseActivity)
    {
        _shouldTrackMouseActivity = shouldTrackMouseActivity;
        [self updateTrackingAreas];
        [self setNeedsDisplay];
    }
}

- (void)OE_updateNotifications
{
    // This method determins if we need to register ourselves with the notification center and/or we need to add mouse tracking
    OEPopUpButtonCell *cell = [self cell];
    if([cell isKindOfClass:[OEPopUpButtonCell class]])
    {
        [self OE_setShouldTrackWindowActivity:[cell stateMask] & OEThemeStateAnyWindowActivity];
        [self OE_setShouldTrackMouseActivity:[cell stateMask] & OEThemeStateAnyMouse];
    }
}

- (void)setBackgroundThemeImageKey:(NSString *)key
{
    [self setBackgroundThemeImage:[[OETheme sharedTheme] themeImageForKey:key]];
}

- (void)setThemeImageKey:(NSString *)key
{
    [self setThemeImage:[[OETheme sharedTheme] themeImageForKey:key]];
}

- (void)setThemeTextAttributesKey:(NSString *)key
{
    [self setThemeTextAttributes:[[OETheme sharedTheme] themeTextAttributesForKey:key]];
}

- (void)setBackgroundThemeImage:(OEThemeImage *)backgroundThemeImage
{
    OEPopUpButtonCell *cell = [self cell];
    if([cell isKindOfClass:[OEPopUpButtonCell class]])
    {
        [cell setBackgroundThemeImage:backgroundThemeImage];
        [self OE_updateNotifications];
        [self setNeedsDisplay];
    }
}

- (OEThemeImage *)backgroundThemeImage
{
    OEPopUpButtonCell *cell = [self cell];
    return ([cell isKindOfClass:[OEPopUpButtonCell class]] ? [cell backgroundThemeImage] : nil);
}

- (void)setThemeImage:(OEThemeImage *)themeImage
{
    OEPopUpButtonCell *cell = [self cell];
    if([cell isKindOfClass:[OEPopUpButtonCell class]])
    {
        [cell setThemeImage:themeImage];
        [self OE_updateNotifications];
        [self setNeedsDisplay];
    }
}

- (OEThemeImage *)themeImage
{
    OEPopUpButtonCell *cell = [self cell];
    return ([cell isKindOfClass:[OEPopUpButtonCell class]] ? [cell themeImage] : nil);
}

- (void)setThemeTextAttributes:(OEThemeTextAttributes *)themeTextAttributes
{
    OEPopUpButtonCell *cell = [self cell];
    if([cell isKindOfClass:[OEPopUpButtonCell class]])
    {
        [cell setThemeTextAttributes:themeTextAttributes];
        [self OE_updateNotifications];
        [self setNeedsDisplay];
    }
}

- (OEThemeTextAttributes *)themeTextAttributes
{
    OEPopUpButtonCell *cell = [self cell];
    return ([cell isKindOfClass:[OEPopUpButtonCell class]] ? [cell themeTextAttributes] : nil);
}

- (void)setCell:(NSCell *)aCell
{
    [super setCell:aCell];
    [self updateTrackingAreas];
}

@end
