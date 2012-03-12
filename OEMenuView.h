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
    NSMenu       *_menu;
    NSMenuItem   *_highlightedItem;
    OEMenuStyle   _style;
    OERectEdge    _edge;
    NSEdgeInsets  _edgeInsets;
    NSBezierPath *_borderPath;

    NSParagraphStyle *_paragraphStyle;
    NSTrackingArea   *_trackingArea;
}

- (void)highlightItemAtPoint:(NSPoint)point;

@property(nonatomic, assign) NSMenuItem  *highlightedItem;
@property(nonatomic, retain) NSMenu      *menu;
@property(nonatomic, assign) OEMenuStyle  style;
@property(nonatomic, assign) OERectEdge   edge;

@end
