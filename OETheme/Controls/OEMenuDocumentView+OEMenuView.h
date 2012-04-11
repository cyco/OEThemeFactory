//
//  OEMenuDocumentView+OEMenuView.h
//  OEThemeFactory
//
//  Created by Faustino Osuna on 4/10/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "OEMenuDocumentView.h"

@interface OEMenuDocumentView (OEMenuView)

- (void)OE_layoutIfNeeded;
- (NSMenuItem *)OE_itemAtPoint:(NSPoint)point;

@end
