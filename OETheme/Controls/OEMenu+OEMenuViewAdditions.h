//
//  OEMenu+OEMenuViewAdditions.h
//  OEThemeFactory
//
//  Created by Faustino Osuna on 3/18/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "OEMenu.h"

extern const NSEdgeInsets OEMenuContentEdgeInsets;
extern const NSEdgeInsets OEMenuItemInsets;
extern const CGFloat      OEMenuItemTickMarkWidth;

@interface OEMenu (OEMenuViewAdditions)

+ (OEMenu *)OE_menuAtPoint:(NSPoint)point;

- (void)OE_setClosing:(BOOL)closing;
- (BOOL)OE_closing;

- (void)OE_setSubmenu:(NSMenu *)submenu;
- (OEMenu *)OE_submenu;
- (OEMenu *)OE_supermenu;
- (OEMenuView *)OE_view;

- (void)OE_cancelTrackingWithCompletionHandler:(void (^)(void))completionHandler;
- (void)OE_hideWindowWithoutAnimation;

@end
