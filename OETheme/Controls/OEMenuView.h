//
//  OEMenuView.h
//  OEThemeFactory
//
//  Created by Faustino Osuna on 3/10/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "OETheme.h"

typedef enum _OEMenuStyle
{
    OEMenuStyleDark,
    OEMenuStyleLight
} OEMenuStyle;

typedef enum _OERectEdge
{
    OENoEdge,
    OEMinYEdge,
    OEMaxYEdge,
    OEMinXEdge,
    OEMaxXEdge
} OERectEdge;

@interface OEMenuView : NSView
{
@private
    NSMenu       *_menu;                // Original menu to display
    OEMenuStyle   _style;               // Menu style to use
    OERectEdge    _edge;                // The arrow's edge
    NSBezierPath *_borderPath;          // The path of the background image (to include the arrow)
    NSPoint       _attachedPoint;
    NSRect        _rectForArrow;

    NSSize        _minimumSize;
    NSSize        _maximumSize;

    NSTrackingArea   *_trackingArea;    // Tracking area

    BOOL _needsLayout;                  // Flag used to notify that the menu item's frames should be invalidated
    BOOL _containsImage;                // Flag for determining if any of the menu item has an image (changes how -drawRect: renders)

    NSUInteger _keyModifierMask;        // Aggregate mask of all the key modifiers used within the menu item (used to trim NSEvent's modifierFlags)
    NSUInteger _lasKeyModifierMask;     // Las NSEvent's modifierFlags

    NSImage    *_menuItemSeparatorImage;
    NSImage    *_arrowImage;
    NSImage    *_backgroundImage;
    NSColor    *_backgroundColor;
    NSGradient *_backgroundGradient;

    OEThemeGradient       *_menuItemGradient;
    OEThemeImage          *_menuItemTick;
    OEThemeTextAttributes *_menuItemAttributes;
    OEThemeImage          *_submenuArrow;

    BOOL        _dragging;
    NSMenuItem *_highlightedItem;
    NSTimer    *_delayedHighlightTimer;
    NSPoint     _lastMousePoint;
}

// Highlights item at specified point
- (void)highlightItemAtPoint:(NSPoint)point;

// Retrieves item at the specified point
- (NSMenuItem *)itemAtPoint:(NSPoint)point;
- (NSSize)size;

@property(nonatomic, assign)   NSMenuItem   *highlightedItem;
@property(nonatomic, retain)   NSMenu       *menu;
@property(nonatomic, assign)   OEMenuStyle   style;
@property(nonatomic, assign)   OERectEdge    edge;
@property(nonatomic, assign)   NSSize        minimumSize;
@property(nonatomic, assign)   NSSize        maximumSize;
@property(nonatomic, readonly) NSEdgeInsets  backgroundEdgeInsets;
@property(nonatomic, assign)   NSPoint       attachedPoint;

@end
