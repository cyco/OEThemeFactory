//
//  OEMenuView.h
//  OEThemeFactory
//
//  Created by Faustino Osuna on 3/10/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "OEMenu.h"

@class OEMenuDocumentView;

@interface OEMenuView : NSView
{
@private
    NSTrackingArea *_trackingArea;     // Tracking area of the menu's primary content

    NSBezierPath *_borderPath;         // Cached copy of the border path
    OERectEdge    _effectiveArrowEdge; // The effective edge that the arrow is on, may be different than arrowEdge
    NSRect        _rectForArrow;       // Placement of the arrow image

    NSPoint  _lastHighlightPoint;      // Last point used to highlight a menu item, used to determine how quickly an item's submenu is closed as the user's mouse gravitates toward the submenu
    NSTimer *_delayedHighlightTimer;   // Used after it is determined that a submenu should stay open a little longer than normal

    NSUInteger  _keyModifierMask;      // Aggregate mask of all the key modifiers used within the menu item (used to trim NSEvent's modifierFlags)
    NSUInteger  _lastKeyModifierMask;  // Last NSEvent's modifierFlags
    BOOL        _needsLayout;          // Flag used to notify that the menu item's frames should be invalidated

    NSEvent *_lastDragEvent;           // Last drag event that is forwarded to the document view's -autoscroll:
    NSTimer *_autoScrollTimer;         // Periodic call to scroll the menu if we are in a drag event and mouse is outside of the menu, or if the mouse is over the scroll up/down indicators
    NSView  *_scrollUpIndicatorView;   // Scroll up indicator, if mouse hovers over this control the menu scrolls up
    NSView  *_scrollDownIndicatorView; // Scroll down indicator, if mouse hovers over this control then menu scrolls down

    // Themed elements
    NSImage    *_arrowImage;
    NSImage    *_backgroundImage;
    NSColor    *_backgroundColor;
    NSGradient *_backgroundGradient;
}

- (void)highlightItemAtPoint:(NSPoint)point;

@property(nonatomic, readonly) NSScrollView       *scrollView;
@property(nonatomic, readonly) OEMenuDocumentView *documentView;

@property(nonatomic, assign)   OEMenuStyle  style;                // Menu's theme style
@property(nonatomic, assign)   OERectEdge   arrowEdge;            // Edge that the arrow should appear on
@property(nonatomic, assign)   NSPoint      attachedPoint;        // Point in this view's coordinate system where the arrow should point to
@property(nonatomic, readonly) NSEdgeInsets backgroundEdgeInsets; // Insets used to determine content placement, this value is dependent on arrowEdge
@property(nonatomic, readonly) NSSize       intrinsicSize;        // Natural size of the menu, does not take into account max and min size requirements
@property(nonatomic, readonly) NSRect       visibleRect;          // Menu item area that is visible

@end
