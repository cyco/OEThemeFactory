//
//  NSMenuItem+OEMenuItemExtraDataAdditions.h
//  OEThemeFactory
//
//  Created by Faustino Osuna on 3/14/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "OEMenuItemExtraData.h"

@interface NSMenuItem (OEMenuItemExtraDataAdditions)

@property(nonatomic, retain) OEMenuItemExtraData *extraData; // Extra data references so that OEMenu can manipulate NSMenuItem's without having to completely subclass it

@end
