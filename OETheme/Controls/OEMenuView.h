//
//  OEMenuView.h
//  OEThemeFactory
//
//  Created by Faustino Osuna on 3/10/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "OEMenu.h"
#import "OEMenuInlineView.h"

@class OEMenuDocumentView;

@interface OEMenuView : NSView
{
@private
    NSTrackingArea *_trackingArea;

    NSBezierPath *_borderPath;
    OERectEdge    _effectiveArrowEdge;
    NSRect        _rectForArrow;

    NSImage    *_arrowImage;
    NSImage    *_backgroundImage;
    NSColor    *_backgroundColor;
    NSGradient *_backgroundGradient;

    NSTimer *_delayedHighlightTimer;
    NSPoint  _lastMousePoint;

    NSEvent          *_lastDragEvent;
    OEMenuInlineView *_draggingView;
    BOOL              _dragging;
    NSTimer          *_autoDragTimer;

    NSArray    *_itemArray;
    NSUInteger  _keyModifierMask;
    NSUInteger  _lastKeyModifierMask;
    BOOL        _needsLayout;
}

- (void)highlightItemAtPoint:(NSPoint)point;

@property(nonatomic, assign)   OEMenuStyle  style;
@property(nonatomic, assign)   OERectEdge   arrowEdge;
@property(nonatomic, assign)   NSPoint      attachedPoint;
@property(nonatomic, readonly) NSEdgeInsets backgroundEdgeInsets;
@property(nonatomic, readonly) NSSize       intrinsicSize;

@end
