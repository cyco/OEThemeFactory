//
//  OEMenu.h
//  OEThemeFactory
//
//  Created by Faustino Osuna on 3/14/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "OEMenuView.h"
#import "OEPopUpButton.h"

@interface OEMenu : NSWindow
{
@private
    OEMenuView *_view;
    BOOL _cancelTracking;
    id _localMonitor;
}

+ (void)popUpContextMenuForPopUpButton:(OEPopUpButton *)button;
+ (void)popUpContextMenu:(NSMenu *)menu arrowOnEdge:(OERectEdge)edge withRect:(NSRect)rect forView:(NSView *)view;

- (oneway void)cancelTracking;

@end
