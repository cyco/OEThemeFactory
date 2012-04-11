//
//  OEMenuView.m
//  OEThemeFactory
//
//  Created by Faustino Osuna on 3/10/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "OEMenuView.h"
#import "OEMenuView+OEMenuAdditions.h"
#import "OEMenu+OEMenuViewAdditions.h"
#import "OEMenuScrollView.h"
#import "OEMenuContentView.h"
#import "OEMenuContentView+OEMenuView.h"
#import "NSMenuItem+OEMenuItemExtraDataAdditions.h"
#import "OETheme.h"
#import "OEInlineMenuItem.h"
#import <Carbon/Carbon.h>

#pragma mark -
#pragma mark Background Image Insets

static const NSEdgeInsets OEMenuBackgroundNoEdgeInsets   = { 5.0,  5.0,  5.0,  5.0};
static const NSEdgeInsets OEMenuBackgroundMinXEdgeInsets = { 5.0, 14.0,  5.0,  5.0};
static const NSEdgeInsets OEMenuBackgroundMaxXEdgeInsets = { 5.0,  5.0,  5.0, 14.0};
static const NSEdgeInsets OEMenuBackgroundMinYEdgeInsets = { 5.0,  5.0, 14.0,  5.0};
static const NSEdgeInsets OEMenuBackgroundMaxYEdgeInsets = {14.0,  5.0,  5.0,  5.0};

#pragma mark -
#pragma mark Content Insets

const NSEdgeInsets OEMenuContentEdgeInsets = { 7.0,  0.0,  7.0,  0.0}; // Value is extern, used by OEMenu.m to calculate menu placement

#pragma mark -
#pragma mark Edge Arrow Sizes

static const NSSize OEMinXEdgeArrowSize = (NSSize){10.0, 15.0};
static const NSSize OEMaxXEdgeArrowSize = (NSSize){10.0, 15.0};
static const NSSize OEMinYEdgeArrowSize = (NSSize){15.0, 10.0};
static const NSSize OEMaxYEdgeArrowSize = (NSSize){15.0, 10.0};

#pragma mark -
#pragma mark Animation Timing

static const CGFloat OEMenuItemFlashDelay       = 0.075; // Duration to flash an item on and off, after user wants to perform a menu item action
static const CGFloat OEMenuItemHighlightDelay   = 1.0;   // Delay before changing the highlight of an item with a submenu
static const CGFloat OEMenuItemShowSubmenuDelay = 0.07;  // Delay before showing an item's submenu

#pragma mark -

@interface OEMenuView ()

- (void)OE_recacheTheme;
- (void)OE_setNeedsLayout;
- (OEMenu *)OE_menu;

@end

@implementation OEMenuView
@synthesize style = _style;
@synthesize arrowEdge = _arrowEdge;
@synthesize attachedPoint = _attachedPoint;
@synthesize backgroundEdgeInsets = _backgroundEdgeInsets;

- (id)initWithFrame:(NSRect)frame
{
    if((self = [super initWithFrame:frame]))
    {
        [self OE_recacheTheme];
        [self OE_setNeedsLayout];
    }

    return self;
}

- (void)drawRect:(NSRect)dirtyRect
{
    [self OE_layoutIfNeeded];

    if(_backgroundColor != nil && _backgroundColor != [NSColor clearColor])
    {
        [_backgroundColor setFill];
        [_borderPath fill];
    }
    [_backgroundGradient drawInBezierPath:_borderPath angle:90];

    if([[self OE_menu] isSubmenu] || _effectiveArrowEdge == OENoEdge)
    {
        [_backgroundImage drawInRect:[self bounds] fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
    }
    else
    {
        NSRect borderRect = [self bounds];
        switch(_effectiveArrowEdge)
        {
            case OEMaxXEdge:
                borderRect.size.width -= OEMinXEdgeArrowSize.width - 1.0;
                break;
            case OEMinXEdge:
                borderRect.origin.x   += OEMaxXEdgeArrowSize.width - 1.0;
                borderRect.size.width -= OEMaxXEdgeArrowSize.width - 1.0;
                break;
            case OEMaxYEdge:
                borderRect.size.height -= OEMinYEdgeArrowSize.height - 1.0;
                break;
            case OEMinYEdge:
                borderRect.origin.y    += OEMaxYEdgeArrowSize.height - 1.0;
                borderRect.size.height -= OEMaxYEdgeArrowSize.height - 1.0;
                break;
            default:
                break;
        }

        [_arrowImage drawInRect:_rectForArrow fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0 respectFlipped:YES hints:nil];

        NSBezierPath *clipPath = [NSBezierPath bezierPathWithRect:borderRect];
        [clipPath appendBezierPathWithRect:_rectForArrow];
        [clipPath setWindingRule:NSEvenOddWindingRule];

        [NSGraphicsContext saveGraphicsState];
        [clipPath addClip];
        [_backgroundImage drawInRect:borderRect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
        [NSGraphicsContext restoreGraphicsState];
    }
}

- (void)updateTrackingAreas
{
    if(_trackingArea) [self removeTrackingArea:_trackingArea];

    const NSRect bounds = OENSInsetRectWithEdgeInsets([self bounds], _backgroundEdgeInsets);
    _trackingArea = [[NSTrackingArea alloc] initWithRect:bounds options:NSTrackingMouseMoved | NSTrackingMouseEnteredAndExited | NSTrackingActiveInActiveApp owner:self userInfo:nil];
    [self addTrackingArea:_trackingArea];
}

- (NSMenu *)menuForEvent:(NSEvent *)event
{
    return nil;
}

- (BOOL)acceptsFirstResponder
{
    // Return yes, we want to capture key board events to send to the various views as necessary
    return YES;
}

- (void)mouseEntered:(NSEvent *)theEvent
{
    if([[self OE_menu] OE_closing]) return;
    [self highlightItemAtPoint:[self convertPoint:[theEvent locationInWindow] fromView:nil]];
}

- (void)mouseUp:(NSEvent *)theEvent
{
    if([[self OE_menu] OE_closing]) return;

    // If we are recovering from a mouse drag operation and the selected menu item has a submenu, then cancel our tracking
    OEMenu *menu = [self OE_menu];
    if (_dragging && [[menu highlightedItem] hasSubmenu]) [menu cancelTracking];
    else                                                  [self OE_performAction];
}

- (void)mouseDragged:(NSEvent *)theEvent
{
    if([[self OE_menu] OE_closing]) return;
    [self highlightItemAtPoint:[self convertPoint:[theEvent locationInWindow] fromView:nil]];
}

- (void)mouseMoved:(NSEvent *)theEvent
{
    if([[self OE_menu] OE_closing]) return;
    [self highlightItemAtPoint:[self convertPoint:[theEvent locationInWindow] fromView:nil]];
}

- (void)mouseExited:(NSEvent *)theEvent
{
    if([[self OE_menu] OE_closing]) return;
    [self highlightItemAtPoint:[self convertPoint:[theEvent locationInWindow] fromView:nil]];
}

- (void)flagsChanged:(NSEvent *)theEvent
{
    if([[self OE_menu] OE_closing]) return;

    // Figure out if any of the modifier flags that we are interested have changed
    NSUInteger modiferFlags = [theEvent modifierFlags] & _keyModifierMask;
    if(_lastKeyModifierMask != modiferFlags)
    {
        _lastKeyModifierMask = modiferFlags;
        [[self subviews] enumerateObjectsUsingBlock:
         ^ (OEMenuScrollView *obj, NSUInteger idx, BOOL *stop)
         {
             [[obj documentView] flagsChanged:theEvent];
         }];
    }
}

- (BOOL)performKeyEquivalent:(NSEvent *)theEvent
{
    if([[self OE_menu] OE_closing]) return YES;

    // I couldn't find an NSResponder method that was tied to the Return and Space key
    if([theEvent keyCode] == kVK_Return || [theEvent keyCode] == kVK_Space)
    {
        // Open the associated submenu or perform the associated action
        if([[[self OE_menu] highlightedItem] hasSubmenu]) [self moveRight:nil];
        else                                              [self OE_performAction];

        return YES;
    }

    return NO;
}

- (void)moveUp:(id)sender
{
    OEMenu *menu = [self OE_menu];
    if([menu OE_closing]) return;

    const NSInteger count = [_itemArray count];
    if(count == 0) return;

    // On Mac OS X, the up key does not roll over the highlighted item to the bottom -- if we are at the top, then we are done
    NSMenuItem *item  = [menu highlightedItem];
    NSInteger   index = [_itemArray indexOfObject:item];
    if(index == 0) return;

    // If no item is highlighted then we begin from the bottom of the list, if an item is highlighted we go to the next preceeding valid item (not seperator, not disabled, and not hidden)
    for(NSInteger i = (item == nil ? count : index) - 1; i >= 0; i--)
    {
        NSMenuItem *obj = [[[_itemArray objectAtIndex:i] extraData] itemWithModifierMask:_lastKeyModifierMask];
        if(![obj isHidden] && ![obj isSeparatorItem] && [obj isEnabled] && ![obj isAlternate])
        {
            item = obj;
            break;
        }
    }

    [menu setHighlightedItem:item];
}

- (void)moveDown:(id)sender
{
    OEMenu *menu = [self OE_menu];
    if([menu OE_closing]) return;

    const NSInteger count = [_itemArray count];
    if(count == 0) return;

    // On Mac OS X, the up key does not roll over the highlighted item to the top -- if we are at the bottom, then we are done
    NSMenuItem *item  = [menu highlightedItem];
    NSInteger   index = [_itemArray indexOfObject:item];
    if(index == count - 1) return;

    // If no item is highlighted then we begin from the top of the list, if an item is highlighted we go to the next proceeding valid item (not seperator, not disabled, and not hidden)
    for(NSInteger i = (item == nil ? -1 : index) + 1; i < count; i++)
    {
        NSMenuItem *obj = [[[_itemArray objectAtIndex:i] extraData] itemWithModifierMask:_lastKeyModifierMask];
        if(![obj isHidden] && ![obj isSeparatorItem] && [obj isEnabled] && ![obj isAlternate])
        {
            item = obj;
            break;
        }
    }

    [menu setHighlightedItem:item];
}

- (void)moveLeft:(id)sender
{
    OEMenu *menu = [self OE_menu];
    if([menu OE_closing]) return;

    // Hide the menu, if this is a submenu
    if([menu isSubmenu]) [menu OE_hideWindowWithoutAnimation];
}

- (void)moveRight:(id)sender
{
    OEMenu *menu = [self OE_menu];
    if([menu OE_closing]) return;

    // If there was a submenu to expand, select the first entry of the submenu
    [self OE_immediatelyExpandHighlightedItemSubmenu];
    if([[menu highlightedItem] hasSubmenu]) [[[menu OE_submenu] OE_view] moveDown:self];
}

- (void)cancelOperation:(id)sender
{
    OEMenu *menu = [self OE_menu];
    if([menu OE_closing]) return;
    [menu cancelTracking];
}

- (void)OE_flashItem:(NSMenuItem *)highlightedItem
{
    [[self OE_menu] setHighlightedItem:highlightedItem];
    [self performSelector:@selector(OE_sendAction:) withObject:highlightedItem afterDelay:OEMenuItemFlashDelay];
}

- (void)OE_sendAction:(NSMenuItem *)highlightedItem
{
    [[self OE_menu] OE_cancelTrackingWithCompletionHandler:^{
        NSDictionary *userInfo = [NSDictionary dictionaryWithObject:highlightedItem forKey:@"MenuItem"];
        [[NSNotificationCenter defaultCenter] postNotificationName:NSMenuWillSendActionNotification object:[self menu] userInfo:userInfo];
        [NSApp sendAction:[highlightedItem action] to:[highlightedItem target] from:highlightedItem];
        [[NSNotificationCenter defaultCenter] postNotificationName:NSMenuDidSendActionNotification object:[self menu] userInfo:userInfo];
    }];
}

- (void)OE_performAction
{
    OEMenu     *menu            = [self OE_menu];
    NSMenuItem *highlightedItem = [menu highlightedItem];

    if([menu OE_closing] || [highlightedItem hasSubmenu]) return;
    [menu OE_setClosing:YES];

    if(highlightedItem != nil && ![highlightedItem isSeparatorItem])
    {
        // Flash the highlighted item right before closing the submenu
        [self performSelector:@selector(OE_flashItem:) withObject:highlightedItem afterDelay:OEMenuItemFlashDelay];
        [menu setHighlightedItem:nil];
    }
    else
    {
        [menu cancelTracking];
    }
}

- (void)OE_immediatelyExpandHighlightedItemSubmenu
{
    OEMenu *menu = [self OE_menu];
    [menu OE_setSubmenu:[[menu highlightedItem] submenu]];
}

- (void)OE_expandHighlightedItemSubmenu
{
    [self performSelector:@selector(OE_immediatelyExpandHighlightedItemSubmenu) withObject:nil afterDelay:OEMenuItemShowSubmenuDelay];
}

- (void)OE_setHighlightedItem:(NSMenuItem *)highlightedItem
{
    // Go ahead and switch the highlighted item (and expand the submenu as appropriate)
    OEMenu *menu = [self OE_menu];
    [menu OE_setSubmenu:nil];
    [menu setHighlightedItem:highlightedItem];
    if([highlightedItem hasSubmenu]) [self OE_expandHighlightedItemSubmenu];
}

- (void)OE_delayedSetHighlightedItem:(NSTimer *)timer
{
    NSMenuItem *highlightedItem = [timer userInfo];
    _delayedHighlightTimer      = nil;

    // If the mouse is hovering over one of the descendent menus, then ignore the request to highlight a new item and expand it's menu.  Figuring out if the mouse is over a descendent
    // menu is done backwards, we start with the menu that is under the mouse and keep comparing it's supermenu to our view's associated menu. If they ever match, then the focusedMenu
    // has to be a descendent of this view's associated menu.
    OEMenu *focusedMenu = [OEMenu OE_menuAtPoint:[NSEvent mouseLocation]];
    while (focusedMenu)
    {
        if ([focusedMenu OE_supermenu] == [self window]) return;
        focusedMenu = [focusedMenu OE_supermenu];
    }

    [self OE_setHighlightedItem:highlightedItem];
}

- (void)highlightItemAtPoint:(NSPoint)point
{
    NSMenuItem *highlightedItem = [self itemAtPoint:point];

    if(_delayedHighlightTimer)
    {
        // Check to see if we are already waiting to highlight the requested item
        if ([_delayedHighlightTimer userInfo] == highlightedItem)
        {
            _lastMousePoint = point;
            return;
        }

        // We intend on highlighting a different item now
        [_delayedHighlightTimer invalidate];
        _delayedHighlightTimer = nil;
    }

    OEMenu *menu    = [self OE_menu];
    OEMenu *submenu = [menu OE_submenu];

    // Check to see if the item is already highlighted
    if([menu highlightedItem] == highlightedItem)
    {
        _lastMousePoint = point;
        return;
    }

    // If there is a menu open, then check to see if we are trying to move our mouse to that menu -- if we are, then delay any changes to see if the user makes it to the menu
    BOOL isMouseMovingCloser = NO;
    if(submenu)
    {
        const CGFloat distance = point.x - _lastMousePoint.x;
        isMouseMovingCloser    = ([submenu arrowEdge] == OEMinXEdge) ? (distance < -1.0) : (distance > 1.0);
    }

    if(isMouseMovingCloser)
    {
        _delayedHighlightTimer = [NSTimer timerWithTimeInterval:OEMenuItemHighlightDelay target:self selector:@selector(OE_delayedSetHighlightedItem:) userInfo:highlightedItem repeats:NO];
        [[NSRunLoop currentRunLoop] addTimer:_delayedHighlightTimer forMode:NSDefaultRunLoopMode];
    }
    else
    {
        [self OE_setHighlightedItem:highlightedItem];
    }
    _lastMousePoint = point;
}

- (NSMenuItem *)itemAtPoint:(NSPoint)point
{
    NSView *view = [self hitTest:point];
    if((view != nil) && (view != self) && [view isKindOfClass:[OEMenuContentView class]]) return [(OEMenuContentView *)view OE_itemAtPoint:[self convertPoint:point toView:view]];
    return nil;
}

- (void)setFrameSize:(NSSize)newSize
{
    [super setFrameSize:newSize];
    [self OE_setNeedsLayout];
}

- (void)setMenu:(NSMenu *)menu
{
    __block NSMutableArray *inlineMenus     = nil;
    __block NSMutableArray *itemArray       = [NSMutableArray array];
    __block NSMutableSet   *scrollMenus     = [NSMutableSet set];
    __block NSMutableArray *lastInlineMenu  = nil;
    __block BOOL            containsImages  = NO;
    __block NSUInteger      keyModifierMask = 0;

    if(menu != nil)
    {
        inlineMenus = [NSMutableArray array];

        [[menu itemArray] enumerateObjectsUsingBlock:
         ^ (NSMenuItem *obj, NSUInteger idx, BOOL *stop)
         {
             if(![obj isHidden])
             {
                 keyModifierMask |= [obj keyEquivalentModifierMask];
                 if([obj isKindOfClass:[OEInlineMenuItem class]])
                 {
                     lastInlineMenu = [NSMutableArray array];
                     [inlineMenus addObject:lastInlineMenu];

                     [[[obj submenu] itemArray] enumerateObjectsUsingBlock:
                      ^ (id obj, NSUInteger idx, BOOL *stop)
                      {
                          [lastInlineMenu addObject:obj];
                          [itemArray addObject:obj];
                          containsImages = containsImages && ([obj image] != nil);
                      }];
                     [scrollMenus addObject:lastInlineMenu];
                     lastInlineMenu = nil;
                 }
                 else
                 {
                     if(lastInlineMenu == nil)
                     {
                         lastInlineMenu = [NSMutableArray array];
                         [inlineMenus addObject:lastInlineMenu];
                     }
                     [lastInlineMenu addObject:obj];
                     [itemArray addObject:obj];
                     containsImages = containsImages && ([obj image] != nil);
                 }
             }
         }];
    }

    _itemArray       = [itemArray copy];
    _keyModifierMask = keyModifierMask;

    [[self subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [inlineMenus enumerateObjectsUsingBlock:
     ^(NSArray *itemArray, NSUInteger idx, BOOL *stop)
     {
         OEMenuScrollView *scrollView = [[OEMenuScrollView alloc] initWithFrame:NSZeroRect];
         [scrollView setScrollable:[scrollMenus containsObject:itemArray]];
         [scrollView setItemArray:itemArray];
         [scrollView setContainImages:containsImages];
         [scrollView setStyle:[self style]];
         [self addSubview:scrollView];
     }];

    [super setMenu:menu];
    [self OE_setNeedsLayout];
}

- (void)setStyle:(OEMenuStyle)style
{
    if(_style != style)
    {
        _style = style;

        NSNumber *styleValue = [NSNumber numberWithUnsignedInteger:_style];
        [[self subviews] makeObjectsPerformSelector:@selector(setStyle:) withObject:styleValue];
        [self OE_recacheTheme];
    }
}

- (void)setArrowEdge:(OERectEdge)arrowEdge
{
    if(_arrowEdge != arrowEdge)
    {
        _arrowEdge = arrowEdge;
        [self OE_recacheTheme];
    }
}

- (void)setAttachedPoint:(NSPoint)attachedPoint
{
    if(!NSEqualPoints(attachedPoint, _attachedPoint))
    {
        _attachedPoint = attachedPoint;
        [self OE_setNeedsLayout];
    }
}

- (NSSize)intrinsicSize
{
    [self OE_layoutIfNeeded];

    // Go through each item and calculate the maximum width and the sum of the height
    __block CGFloat width  = 0.0;
    __block CGFloat height = 0.0;

    [[self subviews] enumerateObjectsUsingBlock:
     ^(OEMenuScrollView *obj, NSUInteger idx, BOOL *stop) {
         NSSize size  = [obj intrinsicSize];
         width        = MAX(width, size.width);
         height      += size.height;
     }];

    // Return a size with the appropriate padding
    return NSMakeSize(width + _backgroundEdgeInsets.left + _backgroundEdgeInsets.right + OEMenuContentEdgeInsets.left + OEMenuContentEdgeInsets.right, height + _backgroundEdgeInsets.top + _backgroundEdgeInsets.bottom + OEMenuContentEdgeInsets.top + OEMenuContentEdgeInsets.bottom);
}

- (void)OE_setNeedsLayout
{
    _needsLayout = YES;
    [self setNeedsDisplay:YES];
}

- (OEMenu *)OE_menu
{
    return (OEMenu *)[self window];
}

- (void)OE_recacheTheme
{
    NSString *styleKeyPrefix = (_style == OEMenuStyleDark ? @"dark_menu_" : @"light_menu_");
    _backgroundImage         = [[OETheme sharedTheme] imageForKey:[styleKeyPrefix stringByAppendingString:@"background"] forState:OEThemeStateDefault];
    _backgroundColor         = [[OETheme sharedTheme] colorForKey:[styleKeyPrefix stringByAppendingString:@"background"] forState:OEThemeStateDefault];
    _backgroundGradient      = [[OETheme sharedTheme] gradientForKey:[styleKeyPrefix stringByAppendingString:@"background"] forState:OEThemeStateDefault];

    if([[self OE_menu] isSubmenu] || _arrowEdge == OENoEdge)
    {
        _arrowImage = nil;
    }
    else
    {
        NSString *edgeComponent = nil;
        switch (_arrowEdge) {
            case OEMinXEdge:
                edgeComponent = @"minx_arrow_body";
                break;
            case OEMaxXEdge:
                edgeComponent = @"maxx_arrow_body";
                break;
            case OEMinYEdge:
                edgeComponent = @"miny_arrow_body";
                break;
            case OEMaxYEdge:
                edgeComponent = @"maxy_arrow_body";
                break;
            default:
                break;
        }
        _arrowImage = [[OETheme sharedTheme] imageForKey:[styleKeyPrefix stringByAppendingString:edgeComponent] forState:OEThemeStateDefault];
    }

    [self OE_setNeedsLayout];
}

@end

@implementation OEMenuView (OEMenuAdditions)

+ (NSEdgeInsets)OE_backgroundEdgeInsetsForEdge:(OERectEdge)edge
{
    switch(edge)
    {
        case OEMinXEdge: return OEMenuBackgroundMinXEdgeInsets;
        case OEMaxXEdge: return OEMenuBackgroundMaxXEdgeInsets;
        case OEMinYEdge: return OEMenuBackgroundMinYEdgeInsets;
        case OEMaxYEdge: return OEMenuBackgroundMaxYEdgeInsets;
        case OENoEdge:
        default:         return OEMenuBackgroundNoEdgeInsets;
    }
}

- (void)OE_layoutIfNeeded
{
    if(!_needsLayout) return;
    _needsLayout = NO;

    const BOOL isSubmenu  = [[self OE_menu] isSubmenu];
    const NSRect bounds   = [self bounds];
    NSPoint attachedPoint = _attachedPoint;

    if(NSEqualPoints(attachedPoint, NSZeroPoint))
    {
        // Calculate the attached point if it is not set but the arrow edge is set
        switch(_arrowEdge)
        {
            case OEMinXEdge:
                attachedPoint.x = NSMinX([self bounds]);
                attachedPoint.y = NSMidY([self bounds]);
                break;
            case OEMaxXEdge:
                attachedPoint.x = NSMaxX([self bounds]);
                attachedPoint.y = NSMidY([self bounds]);
                break;
            case OEMinYEdge:
                attachedPoint.x = NSMidX([self bounds]);
                attachedPoint.y = NSMinY([self bounds]);
                break;
            case OEMaxYEdge:
                attachedPoint.x = NSMidX([self bounds]);
                attachedPoint.y = NSMaxY([self bounds]);
                break;
            default:
                break;
        }
        _effectiveArrowEdge = _arrowEdge;
    }
    else if(attachedPoint.x < NSMinX(bounds) || attachedPoint.x > NSMaxX(bounds) || attachedPoint.y < NSMinY(bounds) || attachedPoint.y > NSMaxY(bounds))
    {
        // If the attached point is not visible, then effectively hide the arrow
        _effectiveArrowEdge = OENoEdge;
    }
    else
    {
        // There are no problems...so the effective arrow edge is the edge that was requested
        _effectiveArrowEdge = _arrowEdge;
    }

    // Recalculate border path
    _backgroundEdgeInsets         = [OEMenuView OE_backgroundEdgeInsetsForEdge:(isSubmenu ? OENoEdge : _effectiveArrowEdge)];
    const NSRect backgroundBounds = OENSInsetRectWithEdgeInsets([self bounds], _backgroundEdgeInsets);

    if(isSubmenu || _effectiveArrowEdge == OENoEdge)
    {
        _borderPath = [NSBezierPath bezierPathWithRoundedRect:backgroundBounds xRadius:(isSubmenu ? 0 : 2) yRadius:2];
    }
    else
    {
        NSRect  arrowRect;
        NSPoint point1;
        NSPoint point2;
        NSPoint point3;
        CGFloat v1, v2;

        switch(_effectiveArrowEdge)
        {
            case OEMinXEdge:
            case OEMaxXEdge:
                if(_effectiveArrowEdge == OEMinXEdge)
                {
                    arrowRect.size     = OEMinXEdgeArrowSize;
                    arrowRect.origin.x = attachedPoint.x +_backgroundEdgeInsets.left - arrowRect.size.width;
                    v1 = NSMaxX(arrowRect);
                    v2 = NSMaxX(arrowRect);
                }
                else
                {
                    arrowRect.size     = OEMaxXEdgeArrowSize;
                    arrowRect.origin.x = attachedPoint.x - _backgroundEdgeInsets.right;
                    v1                 = NSMinX(arrowRect);
                    v2                 = NSMaxX(arrowRect);
                }
                arrowRect.origin.y = attachedPoint.y - floor((abs(_backgroundEdgeInsets.top - _backgroundEdgeInsets.bottom) + arrowRect.size.height) / 2.0);

                point1 = NSMakePoint(v1, NSMinY(arrowRect));
                point2 = NSMakePoint(v2, floor(NSMidY(arrowRect)));
                point3 = NSMakePoint(v1, NSMaxY(arrowRect));
                break;
            case OEMinYEdge:
            case OEMaxYEdge:
                if(_effectiveArrowEdge == OEMinYEdge)
                {
                    arrowRect.size     = OEMinYEdgeArrowSize;
                    arrowRect.origin.y = attachedPoint.y + _backgroundEdgeInsets.bottom - arrowRect.size.height;
                    v1 = NSMaxY(arrowRect);
                    v2 = NSMinY(arrowRect);
                }
                else
                {
                    arrowRect.size     = OEMinYEdgeArrowSize;
                    arrowRect.origin.y = attachedPoint.y - _backgroundEdgeInsets.top;
                    v1                 = NSMinY(arrowRect);
                    v2                 = NSMaxY(arrowRect);
                }
                arrowRect.origin.x = attachedPoint.x - floor((abs(_backgroundEdgeInsets.left - _backgroundEdgeInsets.right) + arrowRect.size.width) / 2.0);

                point1 = NSMakePoint(NSMinX(arrowRect),        v1);
                point2 = NSMakePoint(floor(NSMidX(arrowRect)), v2);
                point3 = NSMakePoint(NSMaxX(arrowRect),        v1);

                break;
            default:
                break;
        }

        _borderPath = [NSBezierPath bezierPath];
        [_borderPath moveToPoint:point1];
        [_borderPath lineToPoint:point2];
        [_borderPath lineToPoint:point3];
        [_borderPath lineToPoint:point1];
        [_borderPath appendBezierPathWithRoundedRect:backgroundBounds xRadius:2 yRadius:2];

        _rectForArrow.origin = NSZeroPoint;
        _rectForArrow.size   = [_arrowImage size];
        switch(_effectiveArrowEdge)
        {
            case OEMaxXEdge:
                _rectForArrow.origin.y = NSMidY(arrowRect) - NSMidY(_rectForArrow);
                _rectForArrow.origin.x = NSMaxX(bounds) - NSWidth(_rectForArrow);
                break;
            case OEMinXEdge:
                _rectForArrow.origin.y = NSMidY(arrowRect) - NSMidY(_rectForArrow);
                break;
            case OEMaxYEdge:
                _rectForArrow.origin.x = NSMidX(arrowRect) - NSMidX(_rectForArrow);
                _rectForArrow.origin.y = NSMaxY(bounds) - NSHeight(_rectForArrow);
                break;
            case OEMinYEdge:
                _rectForArrow.origin.x = NSMidX(arrowRect) - NSMidX(_rectForArrow);
                break;
            default:
                break;
        }
        _rectForArrow = NSIntegralRect(_rectForArrow);
    }

    const NSRect  contentBounds = OENSInsetRectWithEdgeInsets(backgroundBounds, OEMenuContentEdgeInsets);
    NSArray      *subviews      = [self subviews];
    if([subviews count] == 1)
    {
        OEMenuScrollView *view = [subviews lastObject];
        [view setFrame:contentBounds];
    }
    else if([subviews count] > 1)
    {
        // TODO: Fix this
        __block CGFloat contentHeight   = NSHeight(contentBounds);
        __block CGFloat intrinsicHeight = [self intrinsicSize].height - _backgroundEdgeInsets.top - _backgroundEdgeInsets.bottom - OEMenuContentEdgeInsets.top - OEMenuContentEdgeInsets.bottom;

        NSArray      *subviews        = [self subviews];
        NSMutableSet *scrollableMenus = [NSMutableSet set];

        [subviews enumerateObjectsUsingBlock:
         ^ (OEMenuScrollView *obj, NSUInteger idx, BOOL *stop)
         {
            if([obj isScrollable])
            {
                [scrollableMenus addObject:obj];
            }
            else
            {
                contentHeight   -= [obj intrinsicSize].height;
                intrinsicHeight -= [obj intrinsicSize].height;
            }
        }];

        __block CGFloat y = 0;
        [[self subviews] enumerateObjectsUsingBlock:
         ^ (OEMenuScrollView *obj, NSUInteger idx, BOOL *stop)
         {
             const CGFloat height = [obj intrinsicSize].height;

             NSRect frame      = NSZeroRect;
             frame.size.height = ([obj isScrollable] ? contentHeight * (height / intrinsicHeight) : height);
             frame.size.width  = NSWidth(contentBounds);
             frame.origin.x    = NSMinX(contentBounds);
             frame.origin.y    = NSMaxY(contentBounds) - NSHeight(frame) - y;
             [obj setFrame:NSIntegralRect(frame)];

             y += NSHeight(frame);
         }];
    }
}

- (NSView *)OE_viewThatContainsItem:(NSMenuItem *)item
{
    __block OEMenuScrollView *results = nil;
    [[self subviews] enumerateObjectsUsingBlock:
     ^ (OEMenuScrollView *obj, NSUInteger idx, BOOL *stop)
     {
         if ([[obj itemArray] containsObject:item])
         {
             *stop = YES;
             results = obj;
         }
     }];

    return [results documentView];
}

@end