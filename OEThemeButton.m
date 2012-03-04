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
    if([cell isKindOfClass:[OEThemeButtonCell class]] && newWindow && [[cell backgroundThemeImage] stateMask] & OEThemeStateAnyWindowActivityMask)
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
    OEThemeButtonCell *cell = [self cell];
    if([cell isKindOfClass:[OEThemeButtonCell class]] && [[cell backgroundThemeImage] stateMask] & OEThemeStateAnyMouseMask)
    {
        _mouseTrackingArea = [[NSTrackingArea alloc] initWithRect:[self bounds] options:NSTrackingActiveInActiveApp | NSTrackingMouseEnteredAndExited owner:self userInfo:nil];
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
    OEThemeButtonCell *cell = [self cell];
    if([cell isKindOfClass:[OEThemeButtonCell class]])
    {
        OEThemeImage          *backgroundThemeImage = [cell backgroundThemeImage];
        OEThemeTextAttributes *themeTextAttributes  = [cell themeTextAttributes];

        NSUInteger stateMask = [backgroundThemeImage stateMask] | [themeTextAttributes stateMask];

        BOOL updateWindowActivity = (_cachedStateMask & OEThemeStateAnyWindowActivityMask) != (stateMask & OEThemeStateAnyWindowActivityMask);
        BOOL updateMouseActivity  = (_cachedStateMask & OEThemeStateAnyMouseMask)          != (stateMask & OEThemeStateAnyMouseMask);

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
@synthesize themeTextAttributes = _themeTextAttributes;

- (OEThemeState)OE_currentState
{
    OEThemeButton *button = (OEThemeButton *)[self controlView];
    if(![button isKindOfClass:[OEThemeButton class]]) return OEThemeStateDefault;

    NSWindow   *window       = [[self controlView] window];
    const BOOL  focused      = [window firstResponder] == [self controlView];
    const BOOL  windowActive = (button->_cachedStateMask & OEThemeStateAnyWindowActivityMask) && ([window isMainWindow] || ([window parentWindow] && [[window parentWindow] isMainWindow]));
    BOOL        hover        = NO;

    if(button->_cachedStateMask & OEThemeStateAnyMouseMask)
    {
        const NSPoint p = [[self controlView] convertPointFromBase:[window convertScreenToBase:[NSEvent mouseLocation]]];
        hover           = NSPointInRect(p, [[self controlView] bounds]);
    }

    return [OEThemeObject themeStateWithWindowActive:windowActive buttonState:[self state] selected:[self isHighlighted] enabled:[self isEnabled] focused:focused houseHover:hover];
}

- (NSDictionary *)OE_attributesForState:(OEThemeState)state
{
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

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
    if(_backgroundThemeImage == nil)
    {
        [super drawWithFrame:cellFrame inView:controlView];
    }
    else
    {
        const OEThemeState state      = [self OE_currentState];
        const NSRect       targetRect = cellFrame;

        [[_backgroundThemeImage imageForState:state] drawInRect:targetRect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
        [self drawInteriorWithFrame:[self drawingRectForBounds:cellFrame] inView:controlView];
    }
}

- (NSAttributedString *)attributedTitle
{
    if(_themeTextAttributes == nil)
    {
        return [super attributedTitle];
    }
    else
    {
        NSDictionary *attributes = [self OE_attributesForState:[self OE_currentState]];
        return (!attributes ? [super attributedTitle] : [[NSAttributedString alloc] initWithString:[self title] attributes:attributes]);
    }
}

@end