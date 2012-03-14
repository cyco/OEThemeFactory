//
//  OEMenuView.m
//  OEThemeFactory
//
//  Created by Faustino Osuna on 3/10/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "OEMenuView.h"
#import "NSImage+OEDrawingAdditions.h"
#import "OEMenuItemExtraData.h"
#import <Carbon/Carbon.h>

#pragma mark -
#pragma mark Menu Item Spacing
const static CGFloat OEMenuItemTickMarkWidth      = 19.0;
const static CGFloat OEMenuItemImageWidth         = 22.0;
const static CGFloat OEMenuItemSubmenuArrowWidth  = 10.0;
const static CGFloat OEMenuItemHeightWithImage    = 20.0;
const static CGFloat OEMenuItemHeightWithoutImage = 17.0;
const static CGFloat OEMenuItemSeparatorHeight    =  7.0;
const static CGFloat OEMenuItemSeparatorOffset    =  3.0;

#pragma mark -
#pragma mark Background Image Insets

const static NSEdgeInsets OEMenuContentEdgeInsets        = {7.0, 5.0, 7.0, 5.0};
const static NSEdgeInsets OEMenuBackgroundNoEdgeInsets   = { 4.0,  4.0,  4.0,  4.0};
const static NSEdgeInsets OEMenuBackgroundMinXEdgeInsets = { 5.0, 14.0,  5.0,  5.0};
const static NSEdgeInsets OEMenuBackgroundMaxXEdgeInsets = { 5.0,  5.0,  5.0, 14.0};
const static NSEdgeInsets OEMenuBackgroundMinYEdgeInsets = { 5.0,  5.0, 14.0,  5.0};
const static NSEdgeInsets OEMenuBackgroundMaxYEdgeInsets = {14.0,  5.0,  5.0,  5.0};

#pragma mark -
#pragma mark Edge Arrow Sizes

const static NSSize OEMinXEdgeArrowSize = (NSSize){10.0, 15.0};
const static NSSize OEMaxXEdgeArrowSize = (NSSize){10.0, 15.0};
const static NSSize OEMinYEdgeArrowSize = (NSSize){15.0, 10.0};
const static NSSize OEMaxYEdgeArrowSize = (NSSize){15.0, 10.0};

#pragma mark -
#pragma mark Menu Item Default Mask

static const OEThemeState OEMenuItemStateMask = OEThemeStateDefault & ~OEThemeStateAnyWindowActivity & ~OEThemeStateAnyMouse;

#pragma mark -
#pragma mark Convenience Functions

// Returns an NSString key that represents the specified menu style and component
static inline NSString *OENSStringFromOEMenuStyle(OEMenuStyle style, NSString *component)
{
    return [(style == OEMenuStyleDark ? @"dark_menu_" : @"light_menu_") stringByAppendingString:component];
}

// Returns an NSRect inset using the specified edge insets
static inline NSRect OENSInsetRectWithEdgeInsets(NSRect rect, NSEdgeInsets inset)
{
    return NSMakeRect(NSMinX(rect) + inset.left, NSMinY(rect) + inset.bottom, NSWidth(rect) - inset.left - inset.right, NSHeight(rect) - inset.bottom - inset.top);
}

#pragma mark -
#pragma mark Implementation

@interface OEMenuView ()

- (void)OE_commonInit;
- (void)OE_setupCachedThemeItems;
- (void)OE_setNeedsLayout;
- (void)OE_layoutIfNeeded;

@end

@implementation OEMenuView

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if((self = [super initWithCoder:aDecoder]))
    {
        [self OE_commonInit];
    }
    return self;
}

- (id)initWithFrame:(NSRect)frameRect
{
    if((self = [super initWithFrame:frameRect]))
    {
        [self OE_commonInit];
    }
    return self;
}

- (void)dealloc
{
    // Make sure that there are no associations
    [[_menu itemArray] makeObjectsPerformSelector:@selector(setExtraData:) withObject:nil];
}

- (void)OE_commonInit
{
    [self OE_setupCachedThemeItems];
    [self OE_setNeedsLayout];
}

- (void)OE_setupCachedThemeItems
{
    NSString *styleKeyFormat = OENSStringFromOEMenuStyle(_style, @"%@");
    _menuItemSeparatorImage  = [[OETheme sharedTheme] imageForKey:[NSString stringWithFormat:styleKeyFormat, @"separator_item"] forState:OEThemeStateDefault];
    _backgroundImage         = [[OETheme sharedTheme] imageForKey:[NSString stringWithFormat:styleKeyFormat, @"background"] forState:OEThemeStateDefault];
    _backgroundColor         = [[OETheme sharedTheme] colorForKey:[NSString stringWithFormat:styleKeyFormat, @"background"] forState:OEThemeStateDefault];
    _backgroundGradient      = [[OETheme sharedTheme] gradientForKey:[NSString stringWithFormat:styleKeyFormat, @"background"] forState:OEThemeStateDefault];

    if(_edge == OENoEdge) return;

    NSString *edgeComponent = nil;
    if(_edge == OEMaxXEdge)      edgeComponent = @"maxx_arrow_body";
    else if(_edge == OEMinXEdge) edgeComponent = @"minx_arrow_body";
    else if(_edge == OEMaxYEdge) edgeComponent = @"maxy_arrow_body";
    else if(_edge == OEMinYEdge) edgeComponent = @"miny_arrow_body";

    _arrowImage = [[OETheme sharedTheme] imageForKey:[NSString stringWithFormat:styleKeyFormat, edgeComponent] forState:OEThemeStateDefault];
}

- (BOOL)acceptsFirstResponder
{
    return YES;
}

- (void)updateTrackingAreas
{
    if(_trackingArea) [self removeTrackingArea:_trackingArea];

    const NSRect bounds = OENSInsetRectWithEdgeInsets([self bounds], _backgroundEdgeInsets);
    _trackingArea = [[NSTrackingArea alloc] initWithRect:bounds options:NSTrackingMouseMoved | NSTrackingMouseEnteredAndExited | NSTrackingActiveInActiveApp owner:self userInfo:nil];
    [self addTrackingArea:_trackingArea];
}

- (void)mouseEntered:(NSEvent *)theEvent
{
    [self highlightItemAtPoint:[self convertPoint:[theEvent locationInWindow] fromView:nil]];
}

- (void)mouseUp:(NSEvent *)theEvent
{
    // TODO: When mouse is released we should check which item it was released over, flash the item, and close the menu
    NSLog(@"Flash the item");
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

- (void)flagsChanged:(NSEvent *)theEvent
{
    // Figure out if any of the modifier flags that we are interested have changed
    NSUInteger modiferFlags = [theEvent modifierFlags] & _keyModifierMask;
    if(_lasKeyModifierMask != modiferFlags)
    {
        // A redraw will change the menu items, we should probably just redraw the items that need to be redrawn -- but this may be more expensive operation than what it is worth
        _lasKeyModifierMask = modiferFlags;

        [self highlightItemAtPoint:[self convertPoint:[[self window] mouseLocationOutsideOfEventStream] fromView:nil]];
        [self setNeedsDisplay:YES];
    }
}

- (void)moveUp:(id)sender
{
    // There is nothing to do if there are no items
    const NSInteger count = [[_menu itemArray] count];
    if(count == 0) return;

    // On Mac OS X, the up key does not roll over the highlighted item to the bottom -- if we are at the top, then we are done
    NSMenuItem *item  = [self highlightedItem];
    NSInteger   index = [[_menu itemArray] indexOfObject:item];
    if(index == 0) return;

    // If no item is highlighted then we begin from the bottom of the list, if an item is highlighted we go to the next preceeding valid item (not seperator, not disabled, and not hidden)
    for(NSInteger i = (item == nil ? count : index) - 1; i >= 0; i--)
    {
        NSMenuItem *obj = [[[[_menu itemArray] objectAtIndex:i] extraData] itemWithModifierMask:_lasKeyModifierMask];
        if(![obj isHidden] && ![obj isSeparatorItem] && [obj isEnabled] && ![obj isAlternate])
        {
            item = obj;
            break;
        }
    }

    [self setHighlightedItem:item];
}

- (void)moveDown:(id)sender
{
    // There is nothing to do if there are no items
    const NSInteger count = [[_menu itemArray] count];
    if(count == 0) return;

    // On Mac OS X, the up key does not roll over the highlighted item to the top -- if we are at the bottom, then we are done
    NSMenuItem *item  = [self highlightedItem];
    NSInteger   index = [[_menu itemArray] indexOfObject:item];
    if(index == count - 1) return;

    // If no item is highlighted then we begin from the top of the list, if an item is highlighted we go to the next proceeding valid item (not seperator, not disabled, and not hidden)
    for(NSInteger i = (item == nil ? -1 : index) + 1; i < count; i++)
    {
        NSMenuItem *obj = [[[[_menu itemArray] objectAtIndex:i] extraData] itemWithModifierMask:_lasKeyModifierMask];
        if(![obj isHidden] && ![obj isSeparatorItem] && [obj isEnabled] && ![obj isAlternate])
        {
            item = obj;
            break;
        }
    }

    [self setHighlightedItem:item];
}

- (BOOL)performKeyEquivalent:(NSEvent *)theEvent
{
    // I couldn't find an NSResponder method that was tied to the Reeturn and Space key, therefore, we capture these two key codes separate from the other keyboard navigation methods
    if([theEvent keyCode] == kVK_Return || [theEvent keyCode] == kVK_Space)
    {
        // TODO: We should run the selector for the highlighted item, flash the item, and close the menu
        NSLog(@"Flash the item");
        return YES;
    }

    return NO;
}

- (void)moveLeft:(id)sender
{
    // TODO: Collapse submenu
}

- (void)moveRight:(id)sender
{
    // TODO: Expand submenu
}

- (void)cancelOperation:(id)sender
{
    // TODO: Cancel / Close menu
    NSLog(@"Escape pressed.");
}

- (void)setFrameSize:(NSSize)newSize
{
    // TODO: This is only for debugging purposes once OEMEnu is complete, this should be removed
    [self OE_setNeedsLayout];
    [super setFrameSize:newSize];
}

- (BOOL)OE_isSubmenu
{
    // Convenience function to determine if this menu is a submenu
    return [[self menu] supermenu] != nil;
}

- (OEThemeState)OE_currentStateFromMenuItem:(NSMenuItem *)item
{
    return [OEThemeObject themeStateWithWindowActive:NO buttonState:[item state] selected:[self highlightedItem] == item enabled:[item isEnabled] focused:[item isAlternate] houseHover:NO] & OEMenuItemStateMask;
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

    // Implicitly set the paragraph style if it's not explicitly set
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

    const NSRect bounds      = OENSInsetRectWithEdgeInsets([self bounds], _backgroundEdgeInsets);
    const NSRect contentRect = OENSInsetRectWithEdgeInsets(bounds, OEMenuContentEdgeInsets);

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

        const CGFloat       itemHeight    = _containsImage ? OEMenuItemHeightWithImage : OEMenuItemHeightWithoutImage;
        __block CGFloat     y             = 0.0;
        __block NSMenuItem *lastValidItem = nil;

        [items enumerateObjectsUsingBlock:
         ^(NSMenuItem *item, NSUInteger idx, BOOL *stop)
         {
             if(![item isHidden])
             {
                 OEMenuItemExtraData *extraData = [item extraData];
                 if([extraData primaryItem])
                 {
                     [extraData setFrame:[[[extraData primaryItem] extraData] frame]];
                 }
                 else
                 {
                     const CGFloat height    = ([item isSeparatorItem] ? OEMenuItemSeparatorHeight : itemHeight);
                     const NSRect  itemFrame = NSMakeRect(NSMinX(bounds), NSMaxY(contentRect) - y - height, NSWidth(bounds), height);
                     [extraData setFrame:itemFrame];
                     y += height;

                     lastValidItem = item;
                 }
             }
         }];
    }
}

- (void)drawRect:(NSRect)dirtyRect
{
    [self OE_layoutIfNeeded];

    // Draw Background
    if(_backgroundColor != nil && _backgroundColor != [NSColor clearColor])
    {
        [_backgroundColor setFill];
        [_borderPath fill];
    }
    [_backgroundGradient drawInBezierPath:_borderPath angle:90];

    if([self OE_isSubmenu] || _edge == OENoEdge)
    {
        [_backgroundImage drawInRect:[self bounds] fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
    }
    else
    {
        NSRect arrowRect  = {.size = [_arrowImage size]};
        NSRect borderRect = [self bounds];

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
        [_arrowImage drawInRect:arrowRect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0 respectFlipped:YES hints:nil];

        [NSGraphicsContext saveGraphicsState];
        NSBezierPath *clipPath = [NSBezierPath bezierPathWithRect:borderRect];
        [clipPath appendBezierPathWithRect:arrowRect];
        [clipPath setWindingRule:NSEvenOddWindingRule];
        [clipPath addClip];

        [_backgroundImage drawInRect:borderRect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
        [NSGraphicsContext restoreGraphicsState];
    }

    // Draw Items
    NSArray *items         = [[self menu] itemArray];
    const NSUInteger count = [items count];
    if(count > 0)
    {
        // Retrieve themed items
        OEThemeGradient       *menuItemGradient   = [[OETheme sharedTheme] themeGradientForKey:@"dark_menu_item_background"];
        OEThemeImage          *menuItemTick       = [[OETheme sharedTheme] themeImageForKey:@"dark_menu_item_tick"];
        OEThemeTextAttributes *menuItemAttributes = [[OETheme sharedTheme] themeTextAttributesForKey:@"dark_menu_item"];
        OEThemeImage          *submenuArrow       = [[OETheme sharedTheme] themeImageForKey:@"dark_menu_submenu_arrow"];

        NSSize separatorSize  = [_menuItemSeparatorImage size];

        for(NSUInteger i = 0; i < count; i++)
        {
            NSMenuItem *item = [items objectAtIndex:i];
            if(![item isHidden])
            {
                // Figure out if an alternate item should be rendered
                OEMenuItemExtraData *extraData = [item extraData];
                item = [extraData itemWithModifierMask:_lasKeyModifierMask];
                i   += [[extraData alternateItems] count];

                NSRect menuItemFrame = [extraData frame];
                if([item isSeparatorItem])
                {
                    menuItemFrame.origin.y    = NSMaxY(menuItemFrame) - OEMenuItemSeparatorOffset;
                    menuItemFrame.size.height = separatorSize.height;
                    [_menuItemSeparatorImage drawInRect:menuItemFrame fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
                }
                else
                {
                    // Set up positioning frames
                    NSRect tickMarkFrame = menuItemFrame;
                    NSRect imageFrame;
                    NSRect textFrame;
                    NSRect submenuArrowFrame;

                    NSDivideRect(tickMarkFrame, &tickMarkFrame,     &imageFrame, OEMenuItemTickMarkWidth,                     NSMinXEdge);
                    NSDivideRect(imageFrame,    &imageFrame,        &textFrame,  (_containsImage ? OEMenuItemImageWidth : 0), NSMinXEdge);
                    NSDivideRect(textFrame,     &submenuArrowFrame, &textFrame,  OEMenuItemSubmenuArrowWidth,                 NSMaxXEdge);

                    // Retrieve UI objects from the themed items
                    OEThemeState  menuItemState     = [self OE_currentStateFromMenuItem:item];
                    NSImage      *tickMarkImage     = [menuItemTick imageForState:menuItemState];
                    NSImage      *submenuArrowImage = [submenuArrow imageForState:menuItemState];
                    NSDictionary *textAttributes    = [self OE_textAttributes:menuItemAttributes forState:menuItemState];

                    // Retrieve the item's image and title
                    NSImage  *menuItemImage = [item image];
                    NSString *title         = [item title];

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
                    if(menuItemImage)
                    {
                        NSRect imageRect   = { .size = [menuItemImage size] };
                        imageRect.origin.x = imageFrame.origin.x + 2.0;
                        imageRect.origin.y = menuItemFrame.origin.y + (NSHeight(imageFrame) - NSHeight(imageRect)) / 2.0;

                        [menuItemImage drawInRect:NSIntegralRect(imageRect) fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
                    }

                    // Draw submenu arrow if the item has a submenu
                    if([item hasSubmenu] && submenuArrowImage)
                    {
                        NSRect arrowRect   = { .size = [submenuArrowImage size] };
                        arrowRect.origin.x = submenuArrowFrame.origin.x;
                        arrowRect.origin.y = menuItemFrame.origin.y + (NSHeight(submenuArrowFrame) - NSHeight(arrowRect)) / 2.0;

                        [submenuArrowImage drawInRect:NSIntegralRect(arrowRect) fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
                    }

                    // Draw Item Title
                    NSRect textRect   = { .size = [title sizeWithAttributes:textAttributes] };
                    textRect.origin.x = textFrame.origin.x;
                    textRect.origin.y = menuItemFrame.origin.y + (NSHeight(textFrame) - NSHeight(textRect)) / 2.0;

                    [title drawInRect:textRect withAttributes:textAttributes];
                }
            }
        }
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
        if(NSPointInRect(point, [[item  extraData] frame])) return item;
    }

    return nil;
}

- (void)setHighlightedItem:(NSMenuItem *)highlightedItem
{
    NSMenuItem *realHighlightedItem = [[highlightedItem extraData] primaryItem] ?: highlightedItem;
    if(_highlightedItem != realHighlightedItem)
    {
        _highlightedItem = realHighlightedItem;
        [self setNeedsDisplay:YES];
    }
}

- (NSMenuItem *)highlightedItem
{
    NSMenuItem *realHighlightedItem = [[_highlightedItem extraData] itemWithModifierMask:_lasKeyModifierMask];
    return ([realHighlightedItem isEnabled] && ![realHighlightedItem isSeparatorItem] ? realHighlightedItem : nil);
}

- (void)setMenu:(NSMenu *)menu
{
    if(_menu != menu)
    {
        _menu = menu;
        [self OE_setNeedsLayout];

        NSArray            *items         = [_menu itemArray];
        __block NSMenuItem *lastValidItem = nil;

        _keyModifierMask = 0;
        [items enumerateObjectsUsingBlock:
         ^ (NSMenuItem *item, NSUInteger idx, BOOL *stop)
         {
             if(![item isHidden])
             {
                 _keyModifierMask |= [item keyEquivalentModifierMask];
                 if([item isAlternate] && [[lastValidItem keyEquivalent] isEqualToString:[item keyEquivalent]])
                 {
                     [[lastValidItem extraData] addAlternateItem:item];
                 }
                 else
                 {
                     lastValidItem = item;
                 }
             }
         }];
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
        [self OE_setupCachedThemeItems];
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
        [self OE_setupCachedThemeItems];
        [self OE_setNeedsLayout];
    }
}

- (OERectEdge)edge
{
    return _edge;
}

@end
