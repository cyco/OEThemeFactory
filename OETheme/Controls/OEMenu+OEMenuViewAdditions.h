//
//  OEMenu+OEMenuViewAdditions.h
//  OEThemeFactory
//
//  Created by Faustino Osuna on 3/18/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "OEMenu.h"

@interface OEMenu (OEMenuViewAdditions)

- (void)OE_setClosing:(BOOL)closing;
- (void)OE_setHighlightedItem:(NSMenuItem *)highlightedItem;
- (NSMenuItem *)OE_highlightedItem;

@end
