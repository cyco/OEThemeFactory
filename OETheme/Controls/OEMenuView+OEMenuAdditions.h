//
//  OEMenuView+OEMenuAdditions.h
//  OEThemeFactory
//
//  Created by Faustino Osuna on 3/20/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "OEMenuView.h"

@interface OEMenuView (OEMenuAdditions)

+ (NSEdgeInsets)OE_backgroundEdgeInsetsForEdge:(OERectEdge)Edge;
- (void)OE_layoutIfNeeded;

@end
