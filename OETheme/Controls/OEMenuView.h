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

    NSEvent *_lastDragEvent;
    NSTimer *_autoScrollTimer;

    NSUInteger  _keyModifierMask;
    NSUInteger  _lastKeyModifierMask;
    BOOL        _needsLayout;

    NSView *_scrollUpButton;
    NSView *_scrollDownButton;
}

- (void)highlightItemAtPoint:(NSPoint)point;

@property(nonatomic, readonly) NSScrollView       *scrollView;
@property(nonatomic, readonly) OEMenuDocumentView *documentView;

@property(nonatomic, assign)   OEMenuStyle  style;
@property(nonatomic, assign)   OERectEdge   arrowEdge;
@property(nonatomic, assign)   NSPoint      attachedPoint;
@property(nonatomic, readonly) NSEdgeInsets backgroundEdgeInsets;
@property(nonatomic, readonly) NSSize       intrinsicSize;
@property(nonatomic, readonly) NSRect       clippingRect;

@end
