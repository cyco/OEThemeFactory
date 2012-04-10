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

extern NSString * const OEMenuOptionsStyleKey;
extern NSString * const OEMenuOptionsArrowEdgeKey;
extern NSString * const OEMenuOptionsMaximumSizeKey;
extern NSString * const OEMenuOptionsHighlightedItemKey;

// Returns an NSRect inset using the specified edge insets
static inline NSRect OENSInsetRectWithEdgeInsets(NSRect rect, NSEdgeInsets inset)
{
    return NSMakeRect(NSMinX(rect) + inset.left, NSMinY(rect) + inset.bottom, NSWidth(rect) - inset.left - inset.right, NSHeight(rect) - inset.bottom - inset.top);
}

@class OEMenuView;
@class OEMenuContentView;

@interface OEMenu : NSWindow
{
@private
    OEMenuView *_view;

    BOOL _cancelTracking;                   // Event tracking loop canceled
    BOOL _closing;                          // Menu is closing

    __unsafe_unretained OEMenu *_supermenu;
    OEMenu                     *_submenu;
}

+ (void)popUpContextMenuForPopUpButton:(OEPopUpButton *)button withEvent:(NSEvent *)event options:(NSDictionary *)options;
+ (void)popUpContextMenu:(NSMenu *)menu forScreenRect:(NSRect)rect withEvent:(NSEvent *)event options:(NSDictionary *)options;

- (void)cancelTracking;
- (void)cancelTrackingWithoutAnimation;

@property(nonatomic, readonly) OEMenuStyle style;
@property(nonatomic, readonly) OERectEdge  arrowEdge;

@property(nonatomic, readonly, getter = isSubmenu) BOOL   submenu;
@property(nonatomic, readonly)                     NSSize intrinsicSize;
@property(nonatomic, readonly)                     NSSize size;

@property(nonatomic, assign) NSMenuItem *highlightedItem;

@end
