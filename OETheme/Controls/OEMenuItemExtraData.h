//
//  OEMenuItemExtraData.h
//  OEThemeFactory
//
//  Created by Faustino Osuna on 3/14/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OEMenuItemExtraData : NSObject

- (id)initWithOwnerItem:(NSMenuItem *)ownerItem;
- (void)addAlternateItem:(NSMenuItem *)item;
- (NSMenuItem *)itemWithModifierMask:(NSUInteger)mask;

@property(nonatomic, weak)   NSMenuItem          *ownerItem;      // NSMenuItem that owns this extra data object
@property(nonatomic, weak)   NSMenuItem          *primaryItem;    // Points to the primary item, if the ownerItem refers to an alternate menu item
@property(nonatomic, retain) NSMutableDictionary *alternateItems; // Alternate items indexed by it's modifier flags
@property(nonatomic, assign) NSRect               frame;          // Menu item's placement

@end
