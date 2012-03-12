//
//  OEMenuView.m
//  OEThemeFactory
//
//  Created by Faustino Osuna on 3/10/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "OEMenuView.h"
#import "NSImage+OEDrawingAdditions.h"

#pragma mark Item Spaces
const static CGFloat OEMenuItemTickMarkWidth      = 19.0;
const static CGFloat OEMenuItemImageWidth         = 22.0;
const static CGFloat OEMenuItemSubmenuArrowWidth  = 10.0;

const static CGFloat OEMenuItemHeightWithImage    = 20.0;
const static CGFloat OEMenuItemHeightWithoutImage = 17.0;
const static CGFloat OEMenuItemSeparatorHeight    =  7.0;
const static CGFloat OEMenuItemSeparatorOffset    =  3.0;


#pragma mark -
#pragma mark Content Insets
const static NSEdgeInsets OENoEdgeContentInset   = { 4.0,  4.0,  4.0,  4.0};
const static NSEdgeInsets OEMinXEdgeContentInset = { 4.0,  4.0,  4.0,  4.0};
const static NSEdgeInsets OEMaxXEdgeContentInset = { 4.0,  4.0,  4.0,  4.0};
const static NSEdgeInsets OEMinYEdgeContentInset = { 4.0,  4.0,  4.0,  4.0};
const static NSEdgeInsets OEMaxYEdgeContentInset = { 4.0,  4.0,  4.0,  4.0};

#pragma mark -
#pragma mark Background Gradient Sizes
const static NSEdgeInsets OEBackgroundNoEdgeInset = { 5.0,  5.0,  5.0,  5.0};
const static NSEdgeInsets OEBackgroundEdgeInset   = {14.0, 14.0, 14.0, 14.0};

#pragma mark -
#pragma mark Edge Sizes
const static NSSize OEMinXEdgeArrowSize = (NSSize){10.0, 15.0};
const static NSSize OEMaxXEdgeArrowSize = (NSSize){10.0, 15.0};
const static NSSize OEMinYEdgeArrowSize = (NSSize){15.0, 10.0};
const static NSSize OEMaxYEdgeArrowSize = (NSSize){15.0, 10.0};

static inline NSString *NSStringFromOEMenuStyle(OEMenuStyle style, NSString *component)
{
    return [(style == OEMenuStyleDark ? @"dark_menu_" : @"light_menu_") stringByAppendingString:component];
}

static inline NSRect NSInsetRectWithEdgeInsets(NSRect rect, NSEdgeInsets inset)
{
    return NSMakeRect(NSMinX(rect) + inset.left, NSMinY(rect) + inset.bottom, NSWidth(rect) - inset.left - inset.right, NSHeight(rect) - inset.bottom - inset.top);
}

@implementation OEMenuView

- (void)updateTrackingAreas
{
    if(_trackingArea) [self removeTrackingArea:_trackingArea];

    _trackingArea = [[NSTrackingArea alloc] initWithRect:[self bounds] options:NSTrackingMouseMoved | NSTrackingMouseEnteredAndExited | NSTrackingActiveInActiveApp owner:self userInfo:nil];
    [self addTrackingArea:_trackingArea];
}

- (void)mouseEntered:(NSEvent *)theEvent
{
    [self highlightItemAtPoint:[self convertPoint:[theEvent locationInWindow] fromView:nil]];
}

- (void)mouseMoved:(NSEvent *)theEvent
{
    [self highlightItemAtPoint:[self convertPoint:[theEvent locationInWindow] fromView:nil]];
}

- (void)mouseExited:(NSEvent *)theEvent
{
    [self setHighlightedItem:nil];
}

- (void)setFrameSize:(NSSize)newSize
{
    _borderPath = nil;
    [super setFrameSize:newSize];
}

- (BOOL)OE_isSubmenu
{
    return [[self menu] supermenu] != nil;
}

- (NSImage *)OE_menuItemSeparator
{
    return [[OETheme sharedTheme] imageForKey:NSStringFromOEMenuStyle(_style, @"separator_item") forState:OEThemeStateDefault];
}

- (NSImage *)OE_backgroundImage
{
    return [[OETheme sharedTheme] imageForKey:NSStringFromOEMenuStyle(_style, @"body") forState:OEThemeStateDefault];
}

- (NSColor *)OE_backgroundColor
{
    return [[OETheme sharedTheme] colorForKey:NSStringFromOEMenuStyle(_style, @"body") forState:OEThemeStateDefault];
}

- (NSGradient *)OE_backgroundGradient
{
    return [[OETheme sharedTheme] gradientForKey:NSStringFromOEMenuStyle(_style, @"body") forState:OEThemeStateDefault];
}

- (NSRect)OE_backgroundRect
{
    NSRect rect = [self bounds];
    if([self OE_isSubmenu] || _edge == OENoEdge) return NSInsetRect(rect, 4, 4);

    switch(_edge)
    {
        case OEMinXEdge:
        case OEMaxXEdge:
            rect.origin.y    += OEBackgroundNoEdgeInset.top;
            rect.size.height -= OEBackgroundNoEdgeInset.top + OEBackgroundNoEdgeInset.bottom;
            break;
        case OEMinYEdge:
        case OEMaxYEdge:
            rect.origin.x   += OEBackgroundNoEdgeInset.left;
            rect.size.width -= OEBackgroundNoEdgeInset.left + OEBackgroundNoEdgeInset.right;
            break;
        default: break;
    }

    switch(_edge)
    {
        case OEMinXEdge:
            rect.origin.x   += OEBackgroundEdgeInset.left;
            rect.size.width -= OEBackgroundEdgeInset.left + OEBackgroundNoEdgeInset.right;
            break;
        case OEMaxXEdge:
            rect.origin.x   += OEBackgroundNoEdgeInset.left;
            rect.size.width -= OEBackgroundNoEdgeInset.left + OEBackgroundEdgeInset.right;
            break;
        case OEMinYEdge:
            rect.origin.y    += OEBackgroundEdgeInset.top;
            rect.size.height -= OEBackgroundEdgeInset.top + OEBackgroundNoEdgeInset.bottom;
            break;
        case OEMaxYEdge:
            rect.origin.y    += OEBackgroundNoEdgeInset.top;
            rect.size.height -= OEBackgroundNoEdgeInset.top + OEBackgroundEdgeInset.bottom;
            break;
        default: break;
    }

    return rect;
}

- (NSBezierPath *)OE_borderPath:(NSRect)rect
{
    if(_borderPath) return _borderPath;

    const BOOL isSubmenu = [self OE_isSubmenu];
    if(isSubmenu || _edge == OENoEdge)
    {
        _borderPath = [NSBezierPath bezierPathWithRoundedRect:rect xRadius:(isSubmenu ? 0 : 2) yRadius:2];
    }
    else
    {
        _borderPath = [NSBezierPath bezierPath];

        switch(_edge)
        {
            case OEMinXEdge:
                [_borderPath moveToPoint:NSMakePoint(NSMinX(rect),                             NSMidY(rect) + OEMaxXEdgeArrowSize.height / 2)];
                [_borderPath lineToPoint:NSMakePoint(NSMinX(rect) - OEMaxXEdgeArrowSize.width, NSMidY(rect))];
                [_borderPath lineToPoint:NSMakePoint(NSMinX(rect),                             NSMidY(rect) - OEMaxXEdgeArrowSize.height / 2)];
                [_borderPath lineToPoint:NSMakePoint(NSMinX(rect),                             NSMidY(rect) + OEMaxXEdgeArrowSize.height)];
                break;
            case OEMaxXEdge:
                [_borderPath moveToPoint:NSMakePoint(NSMaxX(rect),                             NSMidY(rect) + OEMinXEdgeArrowSize.height / 2)];
                [_borderPath lineToPoint:NSMakePoint(NSMaxX(rect) + OEMinXEdgeArrowSize.width, NSMidY(rect))];
                [_borderPath lineToPoint:NSMakePoint(NSMaxX(rect),                             NSMidY(rect) - OEMinXEdgeArrowSize.height / 2)];
                [_borderPath lineToPoint:NSMakePoint(NSMaxX(rect),                             NSMidY(rect) + OEMinXEdgeArrowSize.height)];
                break;
            case OEMinYEdge:
                [_borderPath moveToPoint:NSMakePoint(NSMidX(rect) - OEMaxYEdgeArrowSize.width / 2, NSMinY(rect))];
                [_borderPath lineToPoint:NSMakePoint(NSMidX(rect),                                 NSMinY(rect) - OEMaxYEdgeArrowSize.height)];
                [_borderPath lineToPoint:NSMakePoint(NSMidX(rect) + OEMaxYEdgeArrowSize.width / 2, NSMinY(rect))];
                [_borderPath lineToPoint:NSMakePoint(NSMidX(rect) - OEMaxYEdgeArrowSize.width / 2, NSMinY(rect))];
                break;
            case OEMaxYEdge:
                [_borderPath moveToPoint:NSMakePoint(NSMidX(rect) - OEMinYEdgeArrowSize.width / 2, NSMaxY(rect))];
                [_borderPath lineToPoint:NSMakePoint(NSMidX(rect),                                 NSMaxY(rect) + OEMinYEdgeArrowSize.height)];
                [_borderPath lineToPoint:NSMakePoint(NSMidX(rect) + OEMinYEdgeArrowSize.width / 2, NSMaxY(rect))];
                [_borderPath lineToPoint:NSMakePoint(NSMidX(rect) - OEMinYEdgeArrowSize.width / 2, NSMaxY(rect))];
                break;
            default: break;
        }

        [_borderPath appendBezierPathWithRoundedRect:rect xRadius:2 yRadius:2];
    }

    return _borderPath;
}

- (NSImage *)OE_arrowImageForEdge:(OERectEdge)edge
{
    if(edge == OENoEdge) return nil;

    NSString *component = nil;
    if(edge == OEMaxXEdge)      component = @"maxx_arrow_body";
    else if(edge == OEMinXEdge) component = @"minx_arrow_body";
    else if(edge == OEMaxYEdge) component = @"maxy_arrow_body";
    else if(edge == OEMinYEdge) component = @"miny_arrow_body";

    return [[OETheme sharedTheme] imageForKey:NSStringFromOEMenuStyle(_style, component) forState:OEThemeStateDefault];
}

- (NSRect)drawBackground
{
    const NSRect bounds = [self bounds];
    const NSRect rect   = [self OE_backgroundRect];

    NSBezierPath *borderPath         = [self OE_borderPath:rect];
    NSColor      *backgroundColor    = [self OE_backgroundColor];
    NSGradient   *backgroundGradient = [self OE_backgroundGradient];

    // Draw Background
    if(backgroundColor != nil && backgroundColor != [NSColor clearColor])
    {
        [backgroundColor setFill];
        [borderPath fill];
    }
    [backgroundGradient drawInBezierPath:borderPath angle:90];

    if([self OE_isSubmenu] || _edge == OENoEdge)
    {
        [[self OE_backgroundImage] drawInRect:bounds fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
    }
    else
    {
        NSImage *arrow    = [self OE_arrowImageForEdge:_edge];
        NSRect arrowRect  = {.size = [arrow size]};
        NSRect borderRect = bounds;

        switch(_edge)
        {
            case OEMaxXEdge:
                arrowRect.origin.x     = NSWidth(bounds) - NSWidth(arrowRect);
                arrowRect.origin.y     = NSMidY(bounds) - NSMidY(arrowRect);
                borderRect.size.width -= OEMinXEdgeArrowSize.width - 1.0;
                break;
            case OEMinXEdge:
                arrowRect.origin.y     = NSMidY(bounds) - NSMidY(arrowRect);
                borderRect.origin.x   += OEMaxXEdgeArrowSize.width - 1.0;
                borderRect.size.width -= OEMaxXEdgeArrowSize.width - 1.0;
                break;
            case OEMaxYEdge:
                arrowRect.origin.y      = NSHeight(bounds) - NSHeight(arrowRect);
                arrowRect.origin.x      = NSMidX(bounds) - NSMidX(arrowRect);
                borderRect.size.height -= OEMinYEdgeArrowSize.height - 1.0;
                break;
            case OEMinYEdge:
                arrowRect.origin.x      = NSMidX(bounds) - NSMidX(arrowRect);
                borderRect.origin.y    += OEMaxYEdgeArrowSize.height - 1.0;
                borderRect.size.height -= OEMaxYEdgeArrowSize.height - 1.0;
                break;
            default:
                break;
        }

        arrowRect = NSIntegralRect(arrowRect);
        [arrow drawInRect:arrowRect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0 respectFlipped:YES hints:nil];

        [NSGraphicsContext saveGraphicsState];
        NSBezierPath* clipPath = [NSBezierPath bezierPathWithRect:bounds];
        [clipPath appendBezierPathWithRect:arrowRect];
        [clipPath setWindingRule:NSEvenOddWindingRule];
        [clipPath addClip];

        [[self OE_backgroundImage] drawInRect:borderRect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
        [NSGraphicsContext restoreGraphicsState];
    }

    return rect;
}

- (OEThemeState)OE_currentStateFromMenuItem:(NSMenuItem *)item
{
    static const OEThemeState OEMenuItemStateMask = OEThemeStateDefault & ~OEThemeStateAnyWindowActivity & ~OEThemeStateAnyMouse;
    return [OEThemeObject themeStateWithWindowActive:NO buttonState:[item state] selected:(_highlightedItem == item) enabled:[item isEnabled] focused:[item isAlternate] houseHover:NO] & OEMenuItemStateMask;
}

- (NSDictionary *)OE_textAttributes:(OEThemeTextAttributes *)themeTextAttributes forState:(OEThemeState)state
{
    if(!themeTextAttributes) return nil;

    // This is a convenience method for creating the attributes for an NSAttributedString
    if(!_paragraphStyle)
    {
        NSMutableParagraphStyle *ps = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
        [ps setLineBreakMode:NSLineBreakByTruncatingTail];

        _paragraphStyle = [ps copy];
    }

    NSDictionary *attributes = [themeTextAttributes textAttributesForState:state];
    if(![attributes objectForKey:NSParagraphStyleAttributeName])
    {
        NSMutableDictionary *newAttributes = [attributes mutableCopy];
        [newAttributes setValue:_paragraphStyle forKey:NSParagraphStyleAttributeName];
        attributes = [newAttributes copy];
    }

    return attributes;
}

- (void)drawRect:(NSRect)dirtyRect
{
    const NSRect bounds      = [self drawBackground];
    const NSRect contentRect = NSInsetRectWithEdgeInsets(bounds, _edgeInsets);

    // Draw Items
    NSArray      *items         = [[self menu] itemArray];
    if([items count] > 0)
    {
        // Check to see if one of the items has an image
        __block BOOL  containsImage = NO;
        [items enumerateObjectsUsingBlock:
         ^ (NSMenuItem *obj, NSUInteger idx, BOOL *stop) {
             if (![obj isHidden] && [obj image] != nil)
             {
                 *stop         = YES;
                 containsImage = YES;
             }
         }];

        OEThemeGradient       *menuItemGradient   = [[OETheme sharedTheme] themeGradientForKey:@"dark_menu_item_background"];
        OEThemeImage          *menuItemTick       = [[OETheme sharedTheme] themeImageForKey:@"dark_menu_item_tick"];
        OEThemeTextAttributes *menuItemAttributes = [[OETheme sharedTheme] themeTextAttributesForKey:@"dark_menu_item"];
        OEThemeImage          *submenuArrow       = [[OETheme sharedTheme] themeImageForKey:@"dark_menu_submenu_arrow"];

        const CGFloat itemHeight    = containsImage ? OEMenuItemHeightWithImage : OEMenuItemHeightWithoutImage;
        NSRect        menuItemFrame = NSMakeRect(NSMinX(bounds), NSMaxY(contentRect), NSWidth(bounds), itemHeight);
        NSRect        tickMarkFrame = menuItemFrame;
        NSRect        imageFrame;
        NSRect        textFrame;
        NSRect        submenuArrowFrame;

        NSDivideRect(tickMarkFrame, &tickMarkFrame,     &imageFrame, OEMenuItemTickMarkWidth,                    NSMinXEdge);
        NSDivideRect(imageFrame,    &imageFrame,        &textFrame,  (containsImage ? OEMenuItemImageWidth : 0), NSMinXEdge);
        NSDivideRect(textFrame,     &submenuArrowFrame, &textFrame,  OEMenuItemSubmenuArrowWidth,                NSMaxXEdge);

        NSImage      *separatorImage = [self OE_menuItemSeparator];
        NSSize        separatorSize  = [separatorImage size];
        OEThemeState  menuItemState  = OEThemeStateDefault;

        NSImage *tickMarkImage;
        NSImage *menuItemImage;
        NSImage *submenuArrowImage;

        NSDictionary *textAttributes;
        NSString     *title;

        for(NSMenuItem *menuItem in items)
        {
            // Don't draw hidden items
            if([menuItem isHidden]) continue;

            [[NSColor whiteColor] setStroke];

            // Draw separator (if required)
            if([menuItem isSeparatorItem])
            {
                NSRect separatorRect       = menuItemFrame;
                separatorRect.size.height  = separatorSize.height;
                separatorRect.origin.y    -= OEMenuItemSeparatorOffset;
                [separatorImage drawInRect:separatorRect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];

                menuItemFrame.origin.y -= OEMenuItemSeparatorHeight;
                continue;
            }

            menuItemState           = [self OE_currentStateFromMenuItem:menuItem];
            menuItemFrame.origin.y -= itemHeight;

            // Draw the item's background
            [[menuItemGradient gradientForState:menuItemState] drawInRect:menuItemFrame];

            // Draw the item's tick mark
            if((tickMarkImage = [menuItemTick imageForState:menuItemState]))
            {
                NSRect tickMarkRect   = { .size = [tickMarkImage size] };
                tickMarkRect.origin.x = tickMarkFrame.origin.x + (NSWidth(tickMarkFrame) - NSWidth(tickMarkRect)) / 2.0;
                tickMarkRect.origin.y = menuItemFrame.origin.y + (NSHeight(tickMarkFrame) - NSHeight(tickMarkRect)) / 2.0;

                [tickMarkImage drawInRect:NSIntegralRect(tickMarkRect) fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
            }

            // Draw the item's image (if it has one)
            if(containsImage && (menuItemImage = [menuItem image]))
            {
                NSRect imageRect   = { .size = [menuItemImage size] };
                imageRect.origin.x = imageFrame.origin.x + 2.0;
                imageRect.origin.y = menuItemFrame.origin.y + (NSHeight(imageFrame) - NSHeight(imageRect)) / 2.0;

                [menuItemImage drawInRect:NSIntegralRect(imageRect) fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
            }

            // Draw submenu arrow
            if([menuItem hasSubmenu] && (submenuArrowImage = [submenuArrow imageForState:menuItemState]))
            {
                NSRect arrowRect   = { .size = [submenuArrowImage size] };
                arrowRect.origin.x = submenuArrowFrame.origin.x;
                arrowRect.origin.y = menuItemFrame.origin.y + (NSHeight(submenuArrowFrame) - NSHeight(arrowRect)) / 2.0;

                [submenuArrowImage drawInRect:NSIntegralRect(arrowRect) fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
            }

            // Draw Item Title
            title = [menuItem title];
            textAttributes   = [self OE_textAttributes:menuItemAttributes forState:menuItemState];

            NSRect textRect = { .size = [title sizeWithAttributes:textAttributes] };
            textRect.origin.x = textFrame.origin.x;
            textRect.origin.y = menuItemFrame.origin.y + (NSHeight(textFrame) - NSHeight(textRect)) / 2.0;

            [title drawInRect:textRect withAttributes:textAttributes];
        }
    }
}

- (void)highlightItemAtPoint:(NSPoint)point
{
    NSMenuItem *highlighItem = [self itemAtPoint:point];
    NSLog(@"{%4.0lf, %4.0lf} %@", point.x, point.y, highlighItem);
    [self setHighlightedItem:highlighItem];
}

- (NSMenuItem *)itemAtPoint:(NSPoint)p
{
    NSRect bounds = [self OE_backgroundRect];
    if(!NSPointInRect(p, bounds)) return nil;

    // Check to see if one of the items has an image
    __block BOOL  containsImage = NO;
    NSArray      *items = [_menu itemArray];
    [items enumerateObjectsUsingBlock:
     ^ (NSMenuItem *obj, NSUInteger idx, BOOL *stop) {
         if (![obj isHidden] && [obj image] != nil)
         {
             *stop         = YES;
             containsImage = YES;
         }
     }];

    const NSRect contentRect = NSInsetRectWithEdgeInsets(bounds, _edgeInsets);

    const CGFloat itemHeight    = containsImage ? OEMenuItemHeightWithImage : OEMenuItemHeightWithoutImage;
    NSRect        menuItemFrame = NSMakeRect(NSMinX(bounds), NSMaxY(contentRect), NSWidth(bounds), itemHeight);

    for(NSMenuItem *item in items)
    {
        if([item isHidden]) continue;

        if([item isSeparatorItem])
        {
            menuItemFrame.origin.y -= OEMenuItemSeparatorHeight;
            if(NSPointInRect(p, NSMakeRect(NSMinX(menuItemFrame), NSMinY(menuItemFrame), NSWidth(menuItemFrame), OEMenuItemSeparatorHeight))) return item;
        }
        else
        {
            menuItemFrame.origin.y -= itemHeight;
            if(NSPointInRect(p, menuItemFrame)) return item;
        }
    }

    return nil;
}

- (void)setHighlightedItem:(NSMenuItem *)highlightedItem
{
    NSMenuItem *newHighlightedItem = (![highlightedItem isEnabled] || [highlightedItem isSeparatorItem]) ? nil : highlightedItem;
    if(_highlightedItem != newHighlightedItem)
    {
        _highlightedItem = newHighlightedItem;
        [self setNeedsDisplay:YES];
    }
}

- (NSMenuItem *)highlightedItem
{
    return _highlightedItem;
}

- (void)setMenu:(NSMenu *)menu
{
    if(_menu != menu)
    {
        _menu = menu;
        [self setNeedsDisplay:YES];
    }
}

- (NSMenu *)menu
{
    return _menu;
}

- (void)setStyle:(OEMenuStyle)style
{
    if(_style != style)
    {
        _style = style;
        [self setNeedsDisplay:YES];
    }
}

- (OEMenuStyle)style
{
    return _style;
}

- (void)setEdge:(OERectEdge)edge
{
    if(_edge != edge)
    {
        _edge       = edge;
        _borderPath = nil;

        if(_edge == OENoEdge)        _edgeInsets = OENoEdgeContentInset;
        else if(_edge == OEMinXEdge) _edgeInsets = OEMinXEdgeContentInset;
        else if(_edge == OEMaxXEdge) _edgeInsets = OEMaxXEdgeContentInset;
        else if(_edge == OEMinYEdge) _edgeInsets = OEMinYEdgeContentInset;
        else if(_edge == OEMaxYEdge) _edgeInsets = OEMaxYEdgeContentInset;

        [self setNeedsDisplay:YES];
    }
}

- (OERectEdge)edge
{
    return _edge;
}

@end
