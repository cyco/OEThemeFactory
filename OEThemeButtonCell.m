//
//  OEThemeButtonCell.m
//  OEThemeFactory
//
//  Created by Faustino Osuna on 3/10/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "OEThemeButtonCell.h"
#import "OEThemeButton.h"

@implementation OEThemeButtonCell

@synthesize stateMask = _stateMask;

- (OEThemeState)OE_currentState
{
    // This is a convenience method that retrieves the current state of the button
    OEThemeButton *button = (OEThemeButton *)[self controlView];
    if(![button isKindOfClass:[OEThemeButton class]]) return OEThemeStateDefault;

    BOOL focused      = NO;
    BOOL windowActive = NO;
    BOOL hover        = NO;

    if((_stateMask & OEThemeStateAnyFocus) || (_stateMask & OEThemeStateAnyMouse) || (_stateMask & OEThemeStateAnyWindowActivity))
    {
        // Set the focused, windowActive, and hover properties only if the state mask is tracking the button's focus, mouse hover, and window activity properties
        NSWindow   *window       = [[self controlView] window];

        focused      = [window firstResponder] == [self controlView];
        windowActive = (_stateMask & OEThemeStateAnyWindowActivity) && ([window isMainWindow] || ([window parentWindow] && [[window parentWindow] isMainWindow]));

        if(_stateMask & OEThemeStateAnyMouse)
        {
            const NSPoint p = [[self controlView] convertPointFromBase:[window convertScreenToBase:[NSEvent mouseLocation]]];
            hover           = NSPointInRect(p, [[self controlView] bounds]);
        }
    }

    return [OEThemeObject themeStateWithWindowActive:windowActive buttonState:[self state] selected:[self isHighlighted] enabled:[self isEnabled] focused:focused houseHover:hover] & _stateMask;
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
    [image drawInRect:frame fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
}

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
    NSRect textRect  = [self titleRectForBounds:cellFrame];
    NSRect imageRect = [self imageRectForBounds:cellFrame];

    if(!NSIsEmptyRect(textRect))  [self drawTitle:[self attributedTitle] withFrame:textRect inView:controlView];
    if(!NSIsEmptyRect(imageRect)) [self drawImage:[self image] withFrame:imageRect inView:controlView];
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

- (void)OE_recomputeStateMask
{
    _stateMask = [_backgroundThemeImage stateMask] | [_themeImage stateMask] | [_themeTextAttributes stateMask];
}

- (void)setBackgroundThemeImage:(OEThemeImage *)backgroundThemeImage
{
    if(_backgroundThemeImage != backgroundThemeImage)
    {
        _backgroundThemeImage = backgroundThemeImage;
        [[self controlView] setNeedsDisplay:YES];
        [self OE_recomputeStateMask];
    }
}

- (OEThemeImage *)backgroundThemeImage
{
    return _backgroundThemeImage;
}

- (void)setThemeImage:(OEThemeImage *)themeImage
{
    if(_themeImage != themeImage)
    {
        _themeImage = themeImage;
        [[self controlView] setNeedsDisplay:YES];
        [self OE_recomputeStateMask];
    }
}

- (OEThemeImage *)themeImage
{
    return _themeImage;
}

- (void)setThemeTextAttributes:(OEThemeTextAttributes *)themeTextAttributes
{
    if(_themeTextAttributes != themeTextAttributes)
    {
        _themeTextAttributes = themeTextAttributes;
        [[self controlView] setNeedsDisplay:YES];
        [self OE_recomputeStateMask];
    }
}

- (OEThemeTextAttributes *)themeTextAttributes
{
    return _themeTextAttributes;
}

@end