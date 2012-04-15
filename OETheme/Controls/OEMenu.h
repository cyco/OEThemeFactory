//
//  OEMenu.h
//  OEThemeFactory
//
//  Created by Faustino Osuna on 3/14/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class OEPopUpButton;

#pragma mark -
#pragma mark Enumerations

typedef enum
{
    OEMenuStyleDark,
    OEMenuStyleLight
} OEMenuStyle;

typedef enum
{
    OENoEdge,
    OEMinYEdge,
    OEMaxYEdge,
    OEMinXEdge,
    OEMaxXEdge
} OERectEdge;

#pragma mark -
#pragma mark Menu option keys

extern NSString * const OEMenuOptionsStyleKey;           // Defines the menu style (dark or light), OEMenuStyle encapsulated in an -[NSNumber numberWithUnsignedInteger:]
extern NSString * const OEMenuOptionsArrowEdgeKey;       // Defines the edge that the arrow is on, OERectEdge encapsulated in an -[NSNumber numberWithUnsignedInteger:]
extern NSString * const OEMenuOptionsMaximumSizeKey;     // Maximum size of the menu, NSSize encapsulated in an NSValue
extern NSString * const OEMenuOptionsHighlightedItemKey; // Initial item to be highlighted, NSMenuItem
extern NSString * const OEMenuOptionsScreenRectKey;      // Reference screen rect to attach the menu to, NSRect encapsulated in an NSValue

#pragma mark -
#pragma mark Implementation

static inline NSRect OENSInsetRectWithEdgeInsets(NSRect rect, NSEdgeInsets insets)
{
    return NSMakeRect(NSMinX(rect) + insets.left, NSMinY(rect) + insets.bottom, NSWidth(rect) - insets.left - insets.right, NSHeight(rect) - insets.bottom - insets.top);
}

@class OEMenuView;
@class OEMenuDocumentView;

@interface OEMenu : NSWindow
{
@private
    BOOL _cancelTracking; // Event tracking loop canceled
    BOOL _closing;        // Menu is closing

    OEMenuView *_view;    // Menu's content view
    OEMenu     *_submenu; // Used to track submenu open
}

+ (void)openMenuForPopUpButton:(OEPopUpButton *)button withEvent:(NSEvent *)event options:(NSDictionary *)options;
+ (void)openMenu:(NSMenu *)menu withEvent:(NSEvent *)event forView:(NSView *)view options:(NSDictionary *)options;

- (void)cancelTracking;
- (void)cancelTrackingWithoutAnimation;

@property(nonatomic, readonly) OEMenuStyle style;                        // Menu's theme style
@property(nonatomic, readonly) OERectEdge  arrowEdge;                    // Edge that the arrow should appear on

@property(nonatomic, readonly, getter = isSubmenu) BOOL   submenu;       // Identifies if this menu represents a submenu
@property(nonatomic, readonly)                     NSSize intrinsicSize; // Natural, unrestricted size of the menu
@property(nonatomic, readonly)                     NSSize size;          // A confined representation of the menu's size, this ensures a menu is completely visible on the screen and does not extend beyond the maximum size specified

@property(nonatomic, assign) NSMenuItem *highlightedItem;                // Currently highlighted menu item (can be a primary or alternate menu item)

@end
