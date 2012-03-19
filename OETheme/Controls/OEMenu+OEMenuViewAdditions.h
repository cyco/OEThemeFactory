//
//  OEMenu+OEMenuViewAdditions.h
//  OEThemeFactory
//
//  Created by Faustino Osuna on 3/18/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "OEMenu.h"

extern const CGFloat      OEMenuItemTickMarkWidth;
extern const CGFloat      OEMenuItemImageWidth;
extern const CGFloat      OEMenuItemSubmenuArrowWidth;
extern const NSEdgeInsets OEMenuContentEdgeInsets;

@interface OEMenu (OEMenuViewAdditions)

- (void)OE_setClosing:(BOOL)closing;
- (void)OE_setSubmenu:(NSMenu *)submenu;
- (OEMenu *)OE_submenu;
- (OEMenuView *)OE_view;
- (void)OE_hideWindowWithoutAnimation;

@end
