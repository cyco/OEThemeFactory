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

- (void)viewWillMoveToWindow:(NSWindow *)newWindow
{
    [super viewWillMoveToWindow:newWindow];

    if([self window])
    {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:NSWindowDidBecomeMainNotification object:[self window]];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:NSWindowDidResignMainNotification object:[self window]];
    }

    OEThemeButtonCell *cell = [self cell];
    if([cell isKindOfClass:[OEThemeButtonCell class]] && newWindow && (_cachedStateMask & OEThemeStateAnyWindowActivity))
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
    OEThemeButtonCell *cell = [self cell];
    if([cell isKindOfClass:[OEThemeButtonCell class]] && (_cachedStateMask & OEThemeStateAnyMouse))
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

- (void)OE_windowKeyChanged:(NSNotification *)notification
{
    // The keyedness of the window has changed, we want to redisplay the button with the new state, this is only fired when NSWindowDidBecomeMainNotification and NSWindowDidResignMainNotification is registered.
    [self setNeedsDisplay];
}

- (void)OE_updateNotifications
{
    // This method determins if we need to register ourselves with the notification center and/or we need to add mouse tracking
    OEThemeButtonCell *cell = [self cell];
    if([cell isKindOfClass:[OEThemeButtonCell class]])
    {
        OEThemeImage          *backgroundThemeImage = [cell backgroundThemeImage];
        OEThemeImage          *themeImage           = [cell themeImage];
        OEThemeTextAttributes *themeTextAttributes  = [cell themeTextAttributes];

        // Create a new stateMask that is an aggregate of all the themed elements
        NSUInteger stateMask = [backgroundThemeImage stateMask] | [themeImage stateMask] | [themeTextAttributes stateMask];

        // Check to see if there are any changes to the window activity and mouse components of the state mask
        BOOL updateWindowActivity = (_cachedStateMask & OEThemeStateAnyWindowActivity) != (stateMask & OEThemeStateAnyWindowActivity);
        BOOL updateMouseActivity  = (_cachedStateMask & OEThemeStateAnyMouse)          != (stateMask & OEThemeStateAnyMouse);

        // Update the state mask and register for notifications as necessary
        _cachedStateMask = stateMask;
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
    OEThemeButtonCell *cell = [self cell];
    if([cell isKindOfClass:[OEThemeButtonCell class]])
    {
        [cell setBackgroundThemeImage:backgroundThemeImage];
        [self OE_updateNotifications];
        [self setNeedsDisplay];
    }
}

- (OEThemeImage *)backgroundThemeImage
{
    OEThemeButtonCell *cell = [self cell];
    return ([cell isKindOfClass:[OEThemeButtonCell class]] ? [cell backgroundThemeImage] : nil);
}

- (void)setThemeImage:(OEThemeImage *)themeImage
{
    OEThemeButtonCell *cell = [self cell];
    if([cell isKindOfClass:[OEThemeButtonCell class]])
    {
        [cell setThemeImage:themeImage];
        [self OE_updateNotifications];
        [self setNeedsDisplay];
    }
}

- (OEThemeImage *)themeImage
{
    OEThemeButtonCell *cell = [self cell];
    return ([cell isKindOfClass:[OEThemeButtonCell class]] ? [cell themeImage] : nil);
}

- (void)setThemeTextAttributes:(OEThemeTextAttributes *)themeTextAttributes
{
    OEThemeButtonCell *cell = [self cell];
    if([cell isKindOfClass:[OEThemeButtonCell class]])
    {
        [cell setThemeTextAttributes:themeTextAttributes];
        [self OE_updateNotifications];
        [self setNeedsDisplay];
    }
}

- (OEThemeTextAttributes *)themeTextAttributes
{
    OEThemeButtonCell *cell = [self cell];
    return ([cell isKindOfClass:[OEThemeButtonCell class]] ? [cell themeTextAttributes] : nil);
}

- (void)setCell:(NSCell *)aCell
{
    [super setCell:aCell];
    [self updateTrackingAreas];
}

@end

#pragma mark -

@implementation OEThemeButtonCell

@synthesize backgroundThemeImage = _backgroundThemeImage;
@synthesize themeImage = _themeImage;
@synthesize themeTextAttributes = _themeTextAttributes;

- (OEThemeState)OE_currentState
{
    // This is a convenience method that retrieves the current state of the button
    OEThemeButton *button = (OEThemeButton *)[self controlView];
    if(![button isKindOfClass:[OEThemeButton class]]) return OEThemeStateDefault;

    NSUInteger stateMask = button->_cachedStateMask;

    BOOL focused      = NO;
    BOOL windowActive = NO;
    BOOL hover        = NO;

    if((stateMask & OEThemeStateAnyFocus) || (stateMask & OEThemeStateAnyMouse) || (stateMask & OEThemeStateAnyWindowActivity))
    {
        // Set the focused, windowActive, and hover properties only if the state mask is tracking the button's focus, mouse hover, and window activity properties
        NSWindow   *window       = [[self controlView] window];

        focused      = [window firstResponder] == [self controlView];
        windowActive = (stateMask & OEThemeStateAnyWindowActivity) && ([window isMainWindow] || ([window parentWindow] && [[window parentWindow] isMainWindow]));

        if(button->_cachedStateMask & OEThemeStateAnyMouse)
        {
            const NSPoint p = [[self controlView] convertPointFromBase:[window convertScreenToBase:[NSEvent mouseLocation]]];
            hover           = NSPointInRect(p, [[self controlView] bounds]);
        }
    }

    return [OEThemeObject themeStateWithWindowActive:windowActive buttonState:[self state] selected:[self isHighlighted] enabled:[self isEnabled] focused:focused houseHover:hover];
}

- (NSDictionary *)OE_attributesForState:(OEThemeState)state
{
    // This is a convenience method for creating the attributes for an NSAttributedString
    if(!_themeTextAttributes) return nil;
    if(!_style) _style = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];

    NSDictionary *attributes = [_themeTextAttributes textAttributesForState:state];
    if(![attributes objectForKey:NSParagraphStyleAttributeName])
    {
        [_style setLineBreakMode:([self wraps] ? NSLineBreakByWordWrapping : NSLineBreakByClipping)];
        [_style setAlignment:[self alignment]];

        NSMutableDictionary *newAttributes = [attributes mutableCopy];
        [newAttributes setValue:_style forKey:NSParagraphStyleAttributeName];
        attributes = [newAttributes copy];
    }

    return attributes;
}

- (void)drawBezelWithFrame:(NSRect)frame inView:(NSView*)controlView
{
    if(_backgroundThemeImage == nil) return;

    const OEThemeState state      = [self OE_currentState];
    const NSRect       targetRect = frame;

    [[_backgroundThemeImage imageForState:state] drawInRect:targetRect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
}

- (void)drawImage:(NSImage *)image withFrame:(NSRect)frame inView:(NSView *)controlView
{
    [super drawImage:[self image] withFrame:frame inView:controlView];
}

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
    NSRect textRect  = [self titleRectForBounds:cellFrame];
    NSRect imageRect = [self imageRectForBounds:cellFrame];

    if(!NSIsEmptyRect(textRect))  [super drawTitle:[self attributedTitle] withFrame:textRect inView:controlView];
    if(!NSIsEmptyRect(imageRect)) [super drawImage:[self image] withFrame:imageRect inView:controlView];
}

- (NSImage *)image
{
    return (_themeImage == nil ? [super image] : [_themeImage imageForState:[self OE_currentState]]);
}

- (NSAttributedString *)attributedTitle
{
    NSDictionary *attributes = [self OE_attributesForState:[self OE_currentState]];
    return (!attributes ? [super attributedTitle] : [[NSAttributedString alloc] initWithString:[self title] attributes:attributes]);
}

@end