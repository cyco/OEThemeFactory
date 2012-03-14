//
//  NSMenuItem+OEMenuItemExtraDataAdditions.h
//  OEThemeFactory
//
//  Created by Faustino Osuna on 3/14/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class OEMenuItemExtraData;

@interface NSMenuItem (OEMenuItemExtraDataAdditions)

@property(nonatomic, retain) OEMenuItemExtraData *extraData;

@end
