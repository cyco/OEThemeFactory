//
//  OEMenuView.h
//  OEThemeFactory
//
//  Created by Faustino Osuna on 3/10/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "OEMenu.h"

@class OEMenuContentView;

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

    BOOL _needsLayout;

    NSTimer *_delayedHighlightTimer;
    BOOL     _dragging;
    NSPoint  _lastMousePoint;

    NSArray    *_itemArray;
    NSUInteger  _lasKeyModifierMask;
}

- (NSView *)viewThatContainsItem:(NSMenuItem *)item;

@property(nonatomic, assign)   OEMenuStyle  style;
@property(nonatomic, assign)   OERectEdge   arrowEdge;
@property(nonatomic, assign)   NSPoint      attachedPoint;
@property(nonatomic, readonly) NSEdgeInsets backgroundEdgeInsets;
@property(nonatomic, readonly) NSSize       intrinsicSize;

@end
