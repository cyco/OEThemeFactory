//
//  OEMenuItemExtraData.h
//  OEThemeFactory
//
//  Created by Faustino Osuna on 3/14/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NSMenuItem+OEMenuItemExtraDataAdditions.h"

@interface OEMenuItemExtraData : NSObject

- (id)initWithOwnerItem:(NSMenuItem *)ownerItem;
- (void)addAlternateItem:(NSMenuItem *)item;
- (NSMenuItem *)itemWithModifierMask:(NSUInteger)mask;

@property(nonatomic, assign) NSMenuItem          *ownerItem;
@property(nonatomic, assign) NSMenuItem          *primaryItem;
@property(nonatomic, retain) NSMutableDictionary *alternateItems;
@property(nonatomic, assign) NSRect               frame;

@end
