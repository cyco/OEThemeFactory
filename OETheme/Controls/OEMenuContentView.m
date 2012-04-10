//
//  OEMenuContentView.m
//  OEThemeFactory
//
//  Created by Faustino Osuna on 4/10/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "OEMenuContentView.h"
#import "OEMenuContentView+OEMenuView.h"
#import "OEMenu.h"
#import "NSMenuItem+OEMenuItemExtraDataAdditions.h"

#pragma mark -
#pragma mark Menu Item Spacing

const CGFloat        OEMenuItemTickMarkWidth      = 19.0;
static const CGFloat OEMenuItemImageWidth         = 22.0;
static const CGFloat OEMenuItemSubmenuArrowWidth  = 10.0;
static const CGFloat OEMenuItemHeightWithImage    = 20.0;
static const CGFloat OEMenuItemHeightWithoutImage = 17.0;
static const CGFloat OEMenuItemSeparatorHeight    =  7.0;
static const CGFloat OEMenuItemSeparatorOffset    =  3.0;

#pragma mark -
#pragma mark Menu Item Insets

const NSEdgeInsets OEMenuItemInsets        = { 0.0, 5.0, 0.0, 5.0 };

#pragma mark -
#pragma mark Menu Item Default Mask

static const OEThemeState OEMenuItemStateMask = OEThemeStateDefault & ~OEThemeStateAnyWindowActivity & ~OEThemeStateAnyMouse;

#pragma mark -
#pragma mark Animation Timing

static const CGFloat OEMenuItemFlashDelay       = 0.075;
static const CGFloat OEMenuItemHighlightDelay   = 1.0;
static const CGFloat OEMenuItemShowSubmenuDelay = 0.07;

#pragma mark -

@implementation OEMenuContentView
@synthesize style = _style;
@synthesize itemArray = _itemArray;
@synthesize containImages = _containImages;

- (id)initWithFrame:(NSRect)frame
{
    if ((self = [super initWithFrame:frame]))
    {
        [self OE_recacheTheme];
    }

    return self;
}

- (void)dealloc
{
    // TODO: May not need following statement
    [self setItemArray:nil];
}

- (void)drawRect:(NSRect)dirtyRect
{
    [self OE_layoutIfNeeded];

    NSArray *items         = _itemArray;
    const NSUInteger count = [items count];

    if(count == 0) return;

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

                NSDivideRect(tickMarkFrame, &tickMarkFrame,     &imageFrame, OEMenuItemTickMarkWidth,                                   NSMinXEdge);
                NSDivideRect(imageFrame,    &imageFrame,        &textFrame,  ([self doesMenuContainImages] ? OEMenuItemImageWidth : 0), NSMinXEdge);
                NSDivideRect(textFrame,     &submenuArrowFrame, &textFrame,  OEMenuItemSubmenuArrowWidth,                               NSMaxXEdge);

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

- (NSMenu *)menuForEvent:(NSEvent *)event
{
    return nil;
}

- (void)flagsChanged:(NSEvent *)theEvent
{
    // Figure out if any of the modifier flags that we are interested have changed
    NSUInteger modiferFlags = [theEvent modifierFlags] & _keyModifierMask;
    if(_lasKeyModifierMask != modiferFlags)
    {
        // A redraw will change the menu items, we should probably just redraw the items that need to be redrawn -- but figuring this out may be more expensive than what it is worth
        _lasKeyModifierMask = modiferFlags;
        [self setNeedsDisplay:YES];
    }
}

- (OEThemeState)OE_currentStateFromMenuItem:(NSMenuItem *)item
{
    return [OEThemeObject themeStateWithWindowActive:NO buttonState:[item state] selected:([self highlightedItem] == item) enabled:[item isEnabled] focused:[item isAlternate] houseHover:NO] & OEMenuItemStateMask;
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

- (void)OE_layout
{
    _needsLayout = NO;

    NSArray *items = _itemArray;
    if([items count] == 0) return;

    const NSRect bounds      = [self bounds];
    const NSRect contentRect = OENSInsetRectWithEdgeInsets(bounds, OEMenuItemInsets);

    NSDictionary       *attributes    = [_menuItemAttributes textAttributesForState:OEThemeStateDefault];
    const CGFloat       itemHeight    = [self doesMenuContainImages] ? OEMenuItemHeightWithImage : OEMenuItemHeightWithoutImage;
    __block CGFloat     y             = 0.0;
    __block CGFloat     width         = 0.0;
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
                 y     += height;
                 width  = MAX(width, [[item title] sizeWithAttributes:attributes].width);

                 lastValidItem = item;
             }
         }
     }];

    const CGFloat minimumWidthPadding  = OEMenuItemTickMarkWidth + ([self doesMenuContainImages] ? OEMenuItemImageWidth : 0) + OEMenuItemSubmenuArrowWidth + OEMenuItemInsets.left + OEMenuItemInsets.right;
    const CGFloat minimumHeightPadding = OEMenuItemInsets.top + OEMenuItemInsets.bottom;
    _intrinsicSize = NSMakeSize(ceil(width + minimumWidthPadding), ceil(y + minimumHeightPadding));
}

- (NSMenuItem *)highlightedItem
{
    return [(OEMenu *)[self window] highlightedItem];
}

- (void)setFrameSize:(NSSize)newSize
{
    [super setFrameSize:newSize];
    [self OE_setNeedsLayout];
}

- (void)setItemArray:(NSArray *)itemArray
{
    if(_itemArray != itemArray)
    {
        [_itemArray makeObjectsPerformSelector:@selector(setExtraData:) withObject:nil];
        _itemArray = itemArray;

        __block NSMenuItem *lastValidItem = nil;

        _keyModifierMask = 0;
        [_itemArray enumerateObjectsUsingBlock:
         ^ (NSMenuItem *item, NSUInteger idx, BOOL *stop)
         {
             if(![item isHidden])
             {
                 _keyModifierMask |= [item keyEquivalentModifierMask];
                 if([item isAlternate] && [[lastValidItem keyEquivalent] isEqualToString:[item keyEquivalent]]) [[lastValidItem extraData] addAlternateItem:item];
                 else                                                                                           lastValidItem = item;
             }
         }];

        [self OE_setNeedsLayout];
    }
}

- (void)setContainImages:(BOOL)containImages
{
    if(_containImages != containImages)
    {
        _containImages = containImages;
        [self OE_setNeedsLayout];
    }
}

- (void)setStyle:(OEMenuStyle)style
{
    if(_style != style)
    {
        _style = style;
        [self OE_recacheTheme];
    }
}

- (NSSize)intrinsicSize
{
    [self OE_layoutIfNeeded];
    return _intrinsicSize;
}

- (void)OE_recacheTheme
{
    NSString *styleKeyPrefix = (_style == OEMenuStyleDark ? @"dark_menu_" : @"light_menu_");
    _menuItemSeparatorImage  = [[OETheme sharedTheme] imageForKey:[styleKeyPrefix stringByAppendingString:@"separator_item"] forState:OEThemeStateDefault];
    _menuItemGradient        = [[OETheme sharedTheme] themeGradientForKey:[styleKeyPrefix stringByAppendingString:@"item_background"]];
    _menuItemTick            = [[OETheme sharedTheme] themeImageForKey:[styleKeyPrefix stringByAppendingString:@"item_tick"]];
    _menuItemAttributes      = [[OETheme sharedTheme] themeTextAttributesForKey:[styleKeyPrefix stringByAppendingString:@"item"]];
    _submenuArrow            = [[OETheme sharedTheme] themeImageForKey:[styleKeyPrefix stringByAppendingString:@"submenu_arrow"]];

    [self setNeedsDisplay:YES];
}

@end

@implementation OEMenuContentView (OEMenuView)

- (void)OE_layoutIfNeeded
{
    if(!_needsLayout) return;
    [self OE_layout];
}

- (NSMenuItem *)OE_itemAtPoint:(NSPoint)point
{
    for(NSMenuItem *item in _itemArray)
    {
        if(NSPointInRect(point, [[item extraData] frame])) return [item isSeparatorItem] ? nil : ([[item extraData] primaryItem] ?: item);
    }

    return nil;
}

@end
