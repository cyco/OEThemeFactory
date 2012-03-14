//
//  OEMenuView.m
//  OEThemeFactory
//
//  Created by Faustino Osuna on 3/10/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "OEMenuView.h"
#import "NSImage+OEDrawingAdditions.h"
#import <objc/runtime.h>

#pragma mark Item Spaces
const static CGFloat OEMenuItemTickMarkWidth      = 19.0;
const static CGFloat OEMenuItemImageWidth         = 22.0;
const static CGFloat OEMenuItemSubmenuArrowWidth  = 10.0;

const static CGFloat OEMenuItemHeightWithImage    = 20.0;
const static CGFloat OEMenuItemHeightWithoutImage = 17.0;
const static CGFloat OEMenuItemSeparatorHeight    =  7.0;
const static CGFloat OEMenuItemSeparatorOffset    =  3.0;

const static NSEdgeInsets OEMenuContentEdgeInsets        = {7.0, 5.0, 7.0, 5.0};
const static NSEdgeInsets OEMenuBackgroundNoEdgeInsets   = { 4.0,  4.0,  4.0,  4.0};
const static NSEdgeInsets OEMenuBackgroundMinXEdgeInsets = { 5.0, 14.0,  5.0,  5.0};
const static NSEdgeInsets OEMenuBackgroundMaxXEdgeInsets = { 5.0,  5.0,  5.0, 14.0};
const static NSEdgeInsets OEMenuBackgroundMinYEdgeInsets = { 5.0,  5.0, 14.0,  5.0};
const static NSEdgeInsets OEMenuBackgroundMaxYEdgeInsets = {14.0,  5.0,  5.0,  5.0};

#pragma mark -
#pragma mark Edge Sizes
const static NSSize OEMinXEdgeArrowSize = (NSSize){10.0, 15.0};
const static NSSize OEMaxXEdgeArrowSize = (NSSize){10.0, 15.0};
const static NSSize OEMinYEdgeArrowSize = (NSSize){15.0, 10.0};
const static NSSize OEMaxYEdgeArrowSize = (NSSize){15.0, 10.0};

const static char OEMenuItemRectKey;
static const OEThemeState OEMenuItemStateMask = OEThemeStateDefault & ~OEThemeStateAnyWindowActivity & ~OEThemeStateAnyMouse;

static inline NSString *NSStringFromOEMenuStyle(OEMenuStyle style, NSString *component)
{
    return [(style == OEMenuStyleDark ? @"dark_menu_" : @"light_menu_") stringByAppendingString:component];
}

static inline NSRect NSInsetRectWithEdgeInsets(NSRect rect, NSEdgeInsets inset)
{
    return NSMakeRect(NSMinX(rect) + inset.left, NSMinY(rect) + inset.bottom, NSWidth(rect) - inset.left - inset.right, NSHeight(rect) - inset.bottom - inset.top);
}

@interface OEMenuView ()

- (void)OE_setNeedsLayout;
- (void)OE_layoutIfNeeded;

@end

@implementation OEMenuView

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if((self = [super initWithCoder:aDecoder]))
    {
        [self OE_setNeedsLayout];
    }
    return self;
}

- (id)initWithFrame:(NSRect)frameRect
{
    if((self = [super initWithFrame:frameRect]))
    {
        [self OE_setNeedsLayout];
    }
    return self;
}

- (void)dealloc
{
    // Make sure that there are no associations
    NSArray *items = [_menu itemArray];
    [items enumerateObjectsUsingBlock:
     ^ (NSMenuItem *item, NSUInteger idx, BOOL *stop) {
         objc_setAssociatedObject(item, &OEMenuItemRectKey, nil, OBJC_ASSOCIATION_ASSIGN);
     }];
}

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

- (void)mouseDragged:(NSEvent *)theEvent
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
    [self OE_setNeedsLayout];
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

- (OEThemeState)OE_currentStateFromMenuItem:(NSMenuItem *)item
{
    return [OEThemeObject themeStateWithWindowActive:NO buttonState:[item state] selected:(_highlightedItem == item) enabled:[item isEnabled] focused:[item isAlternate] houseHover:NO] & OEMenuItemStateMask;
}

- (NSDictionary *)OE_textAttributes:(OEThemeTextAttributes *)themeTextAttributes forState:(OEThemeState)state
{
    if(!themeTextAttributes) return nil;

    // This is a convenience method for creating the attributes for an NSAttributedString
    static NSParagraphStyle *paragraphStyle = nil;
    if(!paragraphStyle)
    {
        NSMutableParagraphStyle *ps = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
        [ps setLineBreakMode:NSLineBreakByTruncatingTail];
        paragraphStyle = [ps copy];
    }

    NSDictionary *attributes = [themeTextAttributes textAttributesForState:state];
    if(![attributes objectForKey:NSParagraphStyleAttributeName])
    {
        NSMutableDictionary *newAttributes = [attributes mutableCopy];
        [newAttributes setValue:paragraphStyle forKey:NSParagraphStyleAttributeName];
        attributes = [newAttributes copy];
    }

    return attributes;
}

- (void)OE_setNeedsLayout
{
    _needsLayout = YES;
    [self setNeedsDisplay:YES];
}

- (void)OE_layoutIfNeeded
{
    if(!_needsLayout) return;
    _needsLayout = NO;

    if([self OE_isSubmenu] || _edge == OENoEdge) _backgroundEdgeInsets = OEMenuBackgroundNoEdgeInsets;
    else if(_edge == OEMinXEdge)                 _backgroundEdgeInsets = OEMenuBackgroundMinXEdgeInsets;
    else if(_edge == OEMaxXEdge)                 _backgroundEdgeInsets = OEMenuBackgroundMaxXEdgeInsets;
    else if(_edge == OEMinYEdge)                 _backgroundEdgeInsets = OEMenuBackgroundMinYEdgeInsets;
    else if(_edge == OEMaxYEdge)                 _backgroundEdgeInsets = OEMenuBackgroundMaxYEdgeInsets;

    const NSRect bounds      = NSInsetRectWithEdgeInsets([self bounds], _backgroundEdgeInsets);
    const NSRect contentRect = NSInsetRectWithEdgeInsets(bounds, OEMenuContentEdgeInsets);

    // Recalculate border path
    const BOOL isSubmenu = [self OE_isSubmenu];
    if(isSubmenu || _edge == OENoEdge)
    {
        _borderPath = [NSBezierPath bezierPathWithRoundedRect:bounds xRadius:(isSubmenu ? 0 : 2) yRadius:2];
    }
    else
    {
        _borderPath = [NSBezierPath bezierPath];

        switch(_edge)
        {
            case OEMinXEdge:
                [_borderPath moveToPoint:NSMakePoint(NSMinX(bounds),                             NSMidY(bounds) + OEMaxXEdgeArrowSize.height / 2)];
                [_borderPath lineToPoint:NSMakePoint(NSMinX(bounds) - OEMaxXEdgeArrowSize.width, NSMidY(bounds))];
                [_borderPath lineToPoint:NSMakePoint(NSMinX(bounds),                             NSMidY(bounds) - OEMaxXEdgeArrowSize.height / 2)];
                [_borderPath lineToPoint:NSMakePoint(NSMinX(bounds),                             NSMidY(bounds) + OEMaxXEdgeArrowSize.height)];
                break;
            case OEMaxXEdge:
                [_borderPath moveToPoint:NSMakePoint(NSMaxX(bounds),                             NSMidY(bounds) + OEMinXEdgeArrowSize.height / 2)];
                [_borderPath lineToPoint:NSMakePoint(NSMaxX(bounds) + OEMinXEdgeArrowSize.width, NSMidY(bounds))];
                [_borderPath lineToPoint:NSMakePoint(NSMaxX(bounds),                             NSMidY(bounds) - OEMinXEdgeArrowSize.height / 2)];
                [_borderPath lineToPoint:NSMakePoint(NSMaxX(bounds),                             NSMidY(bounds) + OEMinXEdgeArrowSize.height)];
                break;
            case OEMinYEdge:
                [_borderPath moveToPoint:NSMakePoint(NSMidX(bounds) - OEMaxYEdgeArrowSize.width / 2, NSMinY(bounds))];
                [_borderPath lineToPoint:NSMakePoint(NSMidX(bounds),                                 NSMinY(bounds) - OEMaxYEdgeArrowSize.height)];
                [_borderPath lineToPoint:NSMakePoint(NSMidX(bounds) + OEMaxYEdgeArrowSize.width / 2, NSMinY(bounds))];
                [_borderPath lineToPoint:NSMakePoint(NSMidX(bounds) - OEMaxYEdgeArrowSize.width / 2, NSMinY(bounds))];
                break;
            case OEMaxYEdge:
                [_borderPath moveToPoint:NSMakePoint(NSMidX(bounds) - OEMinYEdgeArrowSize.width / 2, NSMaxY(bounds))];
                [_borderPath lineToPoint:NSMakePoint(NSMidX(bounds),                                 NSMaxY(bounds) + OEMinYEdgeArrowSize.height)];
                [_borderPath lineToPoint:NSMakePoint(NSMidX(bounds) + OEMinYEdgeArrowSize.width / 2, NSMaxY(bounds))];
                [_borderPath lineToPoint:NSMakePoint(NSMidX(bounds) - OEMinYEdgeArrowSize.width / 2, NSMaxY(bounds))];
                break;
            default: break;
        }

        [_borderPath appendBezierPathWithRoundedRect:bounds xRadius:2 yRadius:2];
    }

    // Recaculate item positioning
    NSArray *items = [[self menu] itemArray];
    if([items count] > 0)
    {
        // Figure out if any item has an image
        _containsImage = NO;
        [items enumerateObjectsUsingBlock:
         ^ (NSMenuItem *item, NSUInteger idx, BOOL *stop)
         {
             if([item image])
             {
                 _containsImage = YES;
                 *stop          = YES;
             }
         }];

        const CGFloat itemHeight = _containsImage ? OEMenuItemHeightWithImage : OEMenuItemHeightWithoutImage;
        __block CGFloat y        = 0.0;

        [items enumerateObjectsUsingBlock:
         ^(NSMenuItem *item, NSUInteger idx, BOOL *stop)
         {
             if(![item isHidden])
             {
                 const CGFloat height    = ([item isSeparatorItem] ? OEMenuItemSeparatorHeight : itemHeight);
                 const NSRect  itemFrame = NSMakeRect(NSMinX(bounds), NSMaxY(contentRect) - y - height, NSWidth(bounds), height);
                 objc_setAssociatedObject(item, &OEMenuItemRectKey, [NSValue valueWithRect:itemFrame], OBJC_ASSOCIATION_COPY_NONATOMIC);
                 y += height;
             }
         }];
    }
}

- (void)drawRect:(NSRect)dirtyRect
{
    [self OE_layoutIfNeeded];

    // Draw background
    NSColor    *backgroundColor    = [self OE_backgroundColor];
    NSGradient *backgroundGradient = [self OE_backgroundGradient];

    // Draw Background
    if(backgroundColor != nil && backgroundColor != [NSColor clearColor])
    {
        [backgroundColor setFill];
        [_borderPath fill];
    }
    [backgroundGradient drawInBezierPath:_borderPath angle:90];

    if([self OE_isSubmenu] || _edge == OENoEdge)
    {
        [[self OE_backgroundImage] drawInRect:[self bounds] fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
    }
    else
    {
        NSImage *arrow     = [self OE_arrowImageForEdge:_edge];
        NSRect  arrowRect  = {.size = [arrow size]};
        NSRect  borderRect = [self bounds];

        switch(_edge)
        {
            case OEMaxXEdge:
                arrowRect.origin.x     = NSMaxX(borderRect) - NSWidth(arrowRect);
                arrowRect.origin.y     = NSMidY(borderRect) - NSMidY(arrowRect);
                borderRect.size.width -= OEMinXEdgeArrowSize.width - 1.0;
                break;
            case OEMinXEdge:
                arrowRect.origin.y     = NSMidY(borderRect) - NSMidY(arrowRect);
                borderRect.origin.x   += OEMaxXEdgeArrowSize.width - 1.0;
                borderRect.size.width -= OEMaxXEdgeArrowSize.width - 1.0;
                break;
            case OEMaxYEdge:
                arrowRect.origin.y      = NSMaxY(borderRect) - NSHeight(arrowRect);
                arrowRect.origin.x      = NSMidX(borderRect) - NSMidX(arrowRect);
                borderRect.size.height -= OEMinYEdgeArrowSize.height - 1.0;
                break;
            case OEMinYEdge:
                arrowRect.origin.x      = NSMidX(borderRect) - NSMidX(arrowRect);
                borderRect.origin.y    += OEMaxYEdgeArrowSize.height - 1.0;
                borderRect.size.height -= OEMaxYEdgeArrowSize.height - 1.0;
                break;
            default:
                break;
        }

        arrowRect = NSIntegralRect(arrowRect);
        [arrow drawInRect:arrowRect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0 respectFlipped:YES hints:nil];

        [NSGraphicsContext saveGraphicsState];
        NSBezierPath *clipPath = [NSBezierPath bezierPathWithRect:borderRect];
        [clipPath appendBezierPathWithRect:arrowRect];
        [clipPath setWindingRule:NSEvenOddWindingRule];
        [clipPath addClip];

        [[self OE_backgroundImage] drawInRect:borderRect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
        [NSGraphicsContext restoreGraphicsState];
    }

    // Draw Items
    NSArray *items = [[self menu] itemArray];
    if([items count] > 0)
    {
        OEThemeGradient       *menuItemGradient   = [[OETheme sharedTheme] themeGradientForKey:@"dark_menu_item_background"];
        OEThemeImage          *menuItemTick       = [[OETheme sharedTheme] themeImageForKey:@"dark_menu_item_tick"];
        OEThemeTextAttributes *menuItemAttributes = [[OETheme sharedTheme] themeTextAttributesForKey:@"dark_menu_item"];
        OEThemeImage          *submenuArrow       = [[OETheme sharedTheme] themeImageForKey:@"dark_menu_submenu_arrow"];

        NSImage *separatorImage = [self OE_menuItemSeparator];
        NSSize   separatorSize  = [separatorImage size];

        [items enumerateObjectsUsingBlock:
         ^ (NSMenuItem *item, NSUInteger idx, BOOL *stop)
         {
             if(![item isHidden])
             {
                 NSRect menuItemFrame = [objc_getAssociatedObject(item, &OEMenuItemRectKey) rectValue];
                 if([item isSeparatorItem])
                 {
                     menuItemFrame.origin.y    = NSMaxY(menuItemFrame) - OEMenuItemSeparatorOffset;
                     menuItemFrame.size.height = separatorSize.height;
                     [separatorImage drawInRect:menuItemFrame fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
                 }
                 else
                 {
                     NSRect tickMarkFrame = menuItemFrame;
                     NSRect imageFrame;
                     NSRect textFrame;
                     NSRect submenuArrowFrame;

                     NSDivideRect(tickMarkFrame, &tickMarkFrame,     &imageFrame, OEMenuItemTickMarkWidth,                     NSMinXEdge);
                     NSDivideRect(imageFrame,    &imageFrame,        &textFrame,  (_containsImage ? OEMenuItemImageWidth : 0), NSMinXEdge);
                     NSDivideRect(textFrame,     &submenuArrowFrame, &textFrame,  OEMenuItemSubmenuArrowWidth,                 NSMaxXEdge);

                     OEThemeState menuItemState   = [self OE_currentStateFromMenuItem:item];
                     NSImage *tickMarkImage       = [menuItemTick imageForState:menuItemState];
                     NSImage *submenuArrowImage   = [submenuArrow imageForState:menuItemState];
                     NSDictionary *textAttributes = [self OE_textAttributes:menuItemAttributes forState:menuItemState];

                     NSImage  *menuItemImage;
                     NSString *title = [item title];;

                     // Draw the item's background
                     [[menuItemGradient gradientForState:menuItemState] drawInRect:menuItemFrame];

                     // Draw the item's tick mark
                     if(tickMarkImage)
                     {
                         NSRect tickMarkRect   = { .size = [tickMarkImage size] };
                         tickMarkRect.origin.x = tickMarkFrame.origin.x + (NSWidth(tickMarkFrame) - NSWidth(tickMarkRect)) / 2.0;
                         tickMarkRect.origin.y = menuItemFrame.origin.y + (NSHeight(tickMarkFrame) - NSHeight(tickMarkRect)) / 2.0;

                         [tickMarkImage drawInRect:NSIntegralRect(tickMarkRect) fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
                     }

                     // Draw the item's image (if it has one)
                     if(_containsImage && (menuItemImage = [item image]))
                     {
                         NSRect imageRect   = { .size = [menuItemImage size] };
                         imageRect.origin.x = imageFrame.origin.x + 2.0;
                         imageRect.origin.y = menuItemFrame.origin.y + (NSHeight(imageFrame) - NSHeight(imageRect)) / 2.0;

                         [menuItemImage drawInRect:NSIntegralRect(imageRect) fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
                     }

                     // Draw submenu arrow
                     if([item hasSubmenu] && submenuArrowImage)
                     {
                         NSRect arrowRect   = { .size = [submenuArrowImage size] };
                         arrowRect.origin.x = submenuArrowFrame.origin.x;
                         arrowRect.origin.y = menuItemFrame.origin.y + (NSHeight(submenuArrowFrame) - NSHeight(arrowRect)) / 2.0;

                         [submenuArrowImage drawInRect:NSIntegralRect(arrowRect) fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
                     }

                     // Draw Item Title
                     NSRect textRect = { .size = [title sizeWithAttributes:textAttributes] };
                     textRect.origin.x = textFrame.origin.x;
                     textRect.origin.y = menuItemFrame.origin.y + (NSHeight(textFrame) - NSHeight(textRect)) / 2.0;

                     [title drawInRect:textRect withAttributes:textAttributes];
                 }
             }
         }];
    }
}

- (void)highlightItemAtPoint:(NSPoint)point
{
    [self setHighlightedItem:[self itemAtPoint:point]];
}

- (NSMenuItem *)itemAtPoint:(NSPoint)point
{
    NSArray *items = [_menu itemArray];
    for(NSMenuItem *item in items)
    {
        if(NSPointInRect(point, [objc_getAssociatedObject(item, &OEMenuItemRectKey) rectValue])) return item;
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
        [self OE_setNeedsLayout];
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
        _edge = edge;
        [self OE_setNeedsLayout];
    }
}

- (OERectEdge)edge
{
    return _edge;
}

@end
