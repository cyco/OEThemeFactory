//
//  OEMenuView.m
//  OEThemeFactory
//
//  Created by Faustino Osuna on 3/10/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "OEMenuView.h"
#import "OEMenu.h"
#import "OEMenu+OEMenuViewAdditions.h"
#import "NSImage+OEDrawingAdditions.h"
#import "NSMenuItem+OEMenuItemExtraDataAdditions.h"
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

const static NSEdgeInsets OEMenuContentEdgeInsets        = { 7.0,  5.0,  7.0,  5.0};
const static NSEdgeInsets OEMenuBackgroundNoEdgeInsets   = { 5.0,  5.0,  5.0,  5.0};
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
#pragma mark Animation Timing

static const CGFloat OEMenuItemFlashDelay = 0.075;

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
- (void)OE_updateInsets;
- (void)OE_performAction;

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
    [_flashTimer invalidate];
    _flashTimer = nil;
}

- (void)OE_commonInit
{
    [self OE_setupCachedThemeItems];
    [self OE_updateInsets];
    [self OE_setNeedsLayout];
}

- (void)OE_setupCachedThemeItems
{
    NSString *styleKeyPrefix = OENSStringFromOEMenuStyle(_style, @"");
    _menuItemSeparatorImage  = [[OETheme sharedTheme] imageForKey:[styleKeyPrefix stringByAppendingString:@"separator_item"] forState:OEThemeStateDefault];
    _backgroundImage         = [[OETheme sharedTheme] imageForKey:[styleKeyPrefix stringByAppendingString:@"background"] forState:OEThemeStateDefault];
    _backgroundColor         = [[OETheme sharedTheme] colorForKey:[styleKeyPrefix stringByAppendingString:@"background"] forState:OEThemeStateDefault];
    _backgroundGradient      = [[OETheme sharedTheme] gradientForKey:[styleKeyPrefix stringByAppendingString:@"background"] forState:OEThemeStateDefault];

    _menuItemGradient   = [[OETheme sharedTheme] themeGradientForKey:[styleKeyPrefix stringByAppendingString:@"item_background"]];
    _menuItemTick       = [[OETheme sharedTheme] themeImageForKey:[styleKeyPrefix stringByAppendingString:@"item_tick"]];
    _menuItemAttributes = [[OETheme sharedTheme] themeTextAttributesForKey:[styleKeyPrefix stringByAppendingString:@"item"]];
    _submenuArrow       = [[OETheme sharedTheme] themeImageForKey:[styleKeyPrefix stringByAppendingString:@"submenu_arrow"]];

    if(_edge == OENoEdge)
    {
        _arrowImage = nil;
    }
    else
    {
        NSString *edgeComponent = nil;
        if(_edge == OEMaxXEdge)      edgeComponent = @"maxx_arrow_body";
        else if(_edge == OEMinXEdge) edgeComponent = @"minx_arrow_body";
        else if(_edge == OEMaxYEdge) edgeComponent = @"maxy_arrow_body";
        else if(_edge == OEMinYEdge) edgeComponent = @"miny_arrow_body";

        _arrowImage = [[OETheme sharedTheme] imageForKey:[styleKeyPrefix stringByAppendingString:edgeComponent] forState:OEThemeStateDefault];
    }
}

- (void)OE_updateInsets
{
    if([self OE_isSubmenu] || _edge == OENoEdge) _backgroundEdgeInsets = OEMenuBackgroundNoEdgeInsets;
    else if(_edge == OEMinXEdge)                 _backgroundEdgeInsets = OEMenuBackgroundMinXEdgeInsets;
    else if(_edge == OEMaxXEdge)                 _backgroundEdgeInsets = OEMenuBackgroundMaxXEdgeInsets;
    else if(_edge == OEMinYEdge)                 _backgroundEdgeInsets = OEMenuBackgroundMinYEdgeInsets;
    else if(_edge == OEMaxYEdge)                 _backgroundEdgeInsets = OEMenuBackgroundMaxYEdgeInsets;
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
    if(_closing) return;
    [self highlightItemAtPoint:[self convertPoint:[theEvent locationInWindow] fromView:nil]];
}

- (void)mouseUp:(NSEvent *)theEvent
{
    if(_closing) return;
    [self OE_performAction];
}

- (void)mouseDragged:(NSEvent *)theEvent
{
    if(_closing) return;
    [self highlightItemAtPoint:[self convertPoint:[theEvent locationInWindow] fromView:nil]];
}

- (void)mouseMoved:(NSEvent *)theEvent
{
    if(_closing) return;
    [self highlightItemAtPoint:[self convertPoint:[theEvent locationInWindow] fromView:nil]];
}

- (void)mouseExited:(NSEvent *)theEvent
{
    if(_closing) return;
    [self highlightItemAtPoint:[self convertPoint:[theEvent locationInWindow] fromView:nil]];
}

- (void)flagsChanged:(NSEvent *)theEvent
{
    if(_closing) return;

    // Figure out if any of the modifier flags that we are interested have changed
    NSUInteger modiferFlags = [theEvent modifierFlags] & _keyModifierMask;
    if(_lasKeyModifierMask != modiferFlags)
    {
        // A redraw will change the menu items, we should probably just redraw the items that need to be redrawn -- but this may be more expensive operation than what it is worth
        _lasKeyModifierMask = modiferFlags;
        [self setNeedsDisplay:YES];
    }
}

- (BOOL)performKeyEquivalent:(NSEvent *)theEvent
{
    if(_closing) return YES;

    // I couldn't find an NSResponder method that was tied to the Reeturn and Space key, therefore, we capture these two key codes separate from the other keyboard navigation methods
    if([theEvent keyCode] == kVK_Return || [theEvent keyCode] == kVK_Space)
    {
        if([_highlightedItem hasSubmenu]) [self moveRight:nil];
        else                              [self OE_performAction];
        return YES;
    }

    return NO;
}

- (void)moveUp:(id)sender
{
    if(_closing) return;

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

    [self setHighlightedItemWithoutExpandingSubmenu:item];
}

- (void)moveDown:(id)sender
{
    if(_closing) return;

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

    [self setHighlightedItemWithoutExpandingSubmenu:item];
}

- (void)moveLeft:(id)sender
{
    if(_closing) return;
    if([self OE_isSubmenu]) [(OEMenu *)[self window] OE_hideWindowWithoutAnimation];
}

- (void)moveRight:(id)sender
{
    if(_closing) return;

    OEMenu *submenu = [(OEMenu *)[self window] OE_submenu];
    if([_highlightedItem hasSubmenu] && [submenu menu] != [_highlightedItem submenu])
    {
        [self setHighlightedItem:_highlightedItem];
        if((submenu = [(OEMenu *)[self window] OE_submenu]))
            [[submenu OE_view] moveDown:sender];
    }
}

- (void)cancelOperation:(id)sender
{
    if(_closing) return;
    [self OE_cancelTracking];
}

- (void)OE_cancelTracking
{
    [(OEMenu *)[self window] cancelTracking];
}

- (void)OE_flashItem:(NSTimer *)sender
{
    NSMenuItem *item = [sender userInfo];
    [self setHighlightedItem:item];

    [_flashTimer invalidate];
    _flashTimer = nil;

    if(item != nil)
    {
        _flashTimer = [NSTimer timerWithTimeInterval:OEMenuItemFlashDelay target:self selector:@selector(OE_flashItem:) userInfo:nil repeats:NO];
        [[NSRunLoop currentRunLoop] addTimer:_flashTimer forMode:NSDefaultRunLoopMode];
    }
    else
    {
        [self OE_cancelTracking];
    }
}

- (void)OE_performAction
{
    if([[self highlightedItem] hasSubmenu]) return;

    _closing = YES;
    [(OEMenu *)[self window] OE_setClosing:YES];

    if([self highlightedItem] != nil && ![[self highlightedItem] isSeparatorItem])
    {
        OEPopUpButtonCell *cell = [[self highlightedItem] target];
        if([cell isKindOfClass:[NSPopUpButtonCell class]]) [cell selectItem:[self highlightedItem]];
        [NSApp sendAction:[[self highlightedItem] action] to:[[self highlightedItem] target] from:[self highlightedItem]];

        _flashTimer = [NSTimer timerWithTimeInterval:OEMenuItemFlashDelay target:self selector:@selector(OE_flashItem:) userInfo:[self highlightedItem] repeats:NO];
        [[NSRunLoop currentRunLoop] addTimer:_flashTimer forMode:NSDefaultRunLoopMode];
        [self setHighlightedItem:nil];
    }
    else
    {
        [self OE_cancelTracking];
    }
}

- (void)setFrameSize:(NSSize)newSize
{
    [super setFrameSize:newSize];
    [self OE_setNeedsLayout];
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
                    NSImage      *tickMarkImage     = [_menuItemTick imageForState:menuItemState];
                    NSImage      *submenuArrowImage = [_submenuArrow imageForState:menuItemState];
                    NSDictionary *textAttributes    = [self OE_textAttributes:_menuItemAttributes forState:menuItemState];

                    // Retrieve the item's image and title
                    NSImage  *menuItemImage = [item image];
                    NSString *title         = [item title];

                    // Draw the item's background
                    [[_menuItemGradient gradientForState:menuItemState] drawInRect:menuItemFrame];

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

- (NSSize)sizeThatFits:(NSRect)frame
{
    NSArray *items = [_menu itemArray];
    if([items count] == 0) return NSZeroSize;

    [self OE_layoutIfNeeded];

    NSDictionary *attributes = [self OE_textAttributes:[[OETheme sharedTheme] themeTextAttributesForKey:@"dark_menu_item"] forState:OEThemeStateDefault];

    const CGFloat   itemHeight = _containsImage ? OEMenuItemHeightWithImage : OEMenuItemHeightWithoutImage;
    __block CGFloat height     = 0.0;
    __block CGFloat width      = 0.0;

    [items enumerateObjectsUsingBlock:
     ^ (NSMenuItem *item, NSUInteger idx, BOOL *stop)
     {
         if(![item isHidden] && ![[item extraData] primaryItem])
         {
             height += ([item isSeparatorItem] ? OEMenuItemSeparatorHeight : itemHeight);
             width   = MAX(width, [[item title] sizeWithAttributes:attributes].width);
         }
     }];

    const CGFloat minimumWidthPadding  = _backgroundEdgeInsets.left + _backgroundEdgeInsets.right + OEMenuContentEdgeInsets.left + OEMenuContentEdgeInsets.right;
    const CGFloat minimumHeightPadding = _backgroundEdgeInsets.top + _backgroundEdgeInsets.bottom + OEMenuContentEdgeInsets.top + OEMenuContentEdgeInsets.bottom;
    const CGFloat minimumWidth         = OEMenuItemTickMarkWidth + (_containsImage ? OEMenuItemImageWidth : 0) + OEMenuItemSubmenuArrowWidth + 25;

    width  = ceil(MAX(MAX(width + minimumWidth, frame.size.width), [_menu minimumWidth]) + minimumWidthPadding);
    height = ceil(height + minimumHeightPadding);

    return NSMakeSize(width, height);
}

- (NSPoint)calculateTopLeftPointWithRect:(NSRect)rect
{
    [self OE_layoutIfNeeded];

    NSPoint result = rect.origin;
    if(_edge == OENoEdge)
    {
        result = NSMakePoint(NSMinX(rect) - _backgroundEdgeInsets.left + 1.0, NSMinY(rect));
    }
    else
    {
        const NSRect bounds = [[self window] convertRectToScreen:[self convertRect:[self bounds] toView:nil]];
        switch(_edge)
        {
            case OEMinXEdge:
                result = NSMakePoint(NSMaxX(rect) - _backgroundEdgeInsets.left, NSMaxY(rect) - (NSMidY(rect) - NSMidY(bounds)));
                break;
            case OEMaxXEdge:
                result = NSMakePoint(NSMinX(rect) - NSWidth(bounds) + _backgroundEdgeInsets.right, NSMaxY(rect) - (NSMidY(rect) - NSMidY(bounds)));
                break;
            case OEMinYEdge:
                result = NSMakePoint(NSMinX(rect) + NSMidX(rect) - NSMidX(bounds), NSMaxY(rect) + NSHeight(bounds) - _backgroundEdgeInsets.bottom);
                break;
            case OEMaxYEdge:
                result = NSMakePoint(NSMinX(rect) + NSMidX(rect) - NSMidX(bounds), NSMinY(rect) - _backgroundEdgeInsets.top);
                break;
            default:
                break;
        }
    }
    return result;
}

- (NSPoint)calculateTopLeftPointForPopButtonWithRect:(NSRect)rect
{
    if(_edge != OENoEdge) return [self calculateTopLeftPointWithRect:rect];

    [self OE_layoutIfNeeded];
    return NSMakePoint(NSMinX(rect) - OEMenuItemTickMarkWidth - _backgroundEdgeInsets.left + 1.0, NSMaxY(rect) + NSHeight([self bounds]) - NSMaxY([[[self highlightedItem] extraData] frame]) + 1.0);
}

- (NSPoint)calculateTopLeftPointForSubMenuWithRect:(NSRect)rect
{
    if(_edge != OENoEdge) return [self calculateTopLeftPointWithRect:rect];

    [self OE_layoutIfNeeded];
    return NSMakePoint(NSMaxX(rect) - _backgroundEdgeInsets.right - OEMenuContentEdgeInsets.left, NSMaxY(rect) + _backgroundEdgeInsets.top + OEMenuContentEdgeInsets.top);
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
                 if([item isAlternate] && [[lastValidItem keyEquivalent] isEqualToString:[item keyEquivalent]]) [[lastValidItem extraData] addAlternateItem:item];
                 else                                                                                           lastValidItem = item;
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
        [self OE_updateInsets];
        [self OE_setNeedsLayout];
    }
}

- (OERectEdge)edge
{
    return _edge;
}

- (void)setHighlightedItemWithoutExpandingSubmenu:(NSMenuItem *)highlightedItem
{
    NSMenuItem *realHighlightedItem = [highlightedItem isSeparatorItem] ? nil : [[highlightedItem extraData] primaryItem] ?: highlightedItem;
    if(_highlightedItem != realHighlightedItem)
    {
        _highlightedItem = realHighlightedItem;
        [self setNeedsDisplay:YES];
    }
}

- (void)setHighlightedItem:(NSMenuItem *)highlightedItem
{
    [self setHighlightedItemWithoutExpandingSubmenu:highlightedItem];

    OEMenu *menu = (OEMenu *)[self window];
    [menu OE_setSubmenu:[_highlightedItem submenu]];
}

- (NSMenuItem *)highlightedItem
{
    NSMenuItem *realHighlightedItem = [[_highlightedItem extraData] itemWithModifierMask:_lasKeyModifierMask];
    return ([realHighlightedItem isEnabled] && ![realHighlightedItem isSeparatorItem] ? realHighlightedItem : nil);
}

@end
