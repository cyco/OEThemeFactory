//
//  OEMenu.h
//  OEThemeFactory
//
//  Created by Faustino Osuna on 3/14/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class OEPopUpButton;

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
#pragma mark Menu options

extern NSString * const OEMenuOptionsStyleKey;           // Defines the menu style (dark or light), OEMenuStyle encapsulated in an -[NSNumber numberWithUnsignedInteger:]
extern NSString * const OEMenuOptionsArrowEdgeKey;       // Defines the edge that the arrow is on, OERectEdge encapsulated in an -[NSNumber numberWithUnsignedInteger:]
extern NSString * const OEMenuOptionsMaximumSizeKey;     // Maximum size of the menu, NSSize encapsulated in an NSValue
extern NSString * const OEMenuOptionsHighlightedItemKey; // Initial item to be highlighted, NSMenuItem
extern NSString * const OEMenuOptionsScreenRectKey;      // Reference screen rect to attach the menu to, NSRect encapsulated in an NSValue

// Returns an NSRect inset using the specified edge insets
static inline NSRect OENSInsetRectWithEdgeInsets(NSRect rect, NSEdgeInsets inset)
{
    return NSMakeRect(NSMinX(rect) + inset.left, NSMinY(rect) + inset.bottom, NSWidth(rect) - inset.left - inset.right, NSHeight(rect) - inset.bottom - inset.top);
}

@class OEMenuView;
@class OEMenuDocumentView;

@interface OEMenu : NSWindow
{
@private
    OEMenuView *_view;    // Menu's actual view

    BOOL _cancelTracking; // Event tracking loop canceled
    BOOL _closing;        // Menu is closing

    __unsafe_unretained OEMenu *_supermenu; // NSWindow does not support a weak reference
    OEMenu                     *_submenu;
}

+ (void)popUpContextMenuForPopUpButton:(OEPopUpButton *)button withEvent:(NSEvent *)event options:(NSDictionary *)options;
+ (void)popUpContextMenu:(NSMenu *)menu withEvent:(NSEvent *)event forView:(NSView *)view options:(NSDictionary *)options;

- (void)cancelTracking;
- (void)cancelTrackingWithoutAnimation;

@property(nonatomic, readonly) OEMenuStyle style;
@property(nonatomic, readonly) OERectEdge  arrowEdge;

@property(nonatomic, readonly, getter = isSubmenu) BOOL   submenu;
@property(nonatomic, readonly)                     NSSize intrinsicSize;
@property(nonatomic, readonly)                     NSSize size;

@property(nonatomic, assign) NSMenuItem *highlightedItem;

@end
