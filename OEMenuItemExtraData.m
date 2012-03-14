//
//  OEMenuItemExtraData.m
//  OEThemeFactory
//
//  Created by Faustino Osuna on 3/14/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "OEMenuItemExtraData.h"

@implementation OEMenuItemExtraData
@synthesize ownerItem = _ownerItem;
@synthesize primaryItem = _primaryItem;
@synthesize alternateItems = _alternateItems;
@synthesize frame = _frame;

- (id)initWithOwnerItem:(NSMenuItem *)ownerItem
{
    if(!ownerItem) return nil;

    if((self = [super init]))
    {
        _ownerItem = ownerItem;
    }
    return self;
}

- (void)addAlternateItem:(NSMenuItem *)item
{
    NSAssert(!_primaryItem, @"This item should have a parent.");

    if(!_alternateItems) _alternateItems = [NSMutableDictionary dictionaryWithObject:item forKey:[NSNumber numberWithUnsignedInteger:[item keyEquivalentModifierMask]]];
    else                [_alternateItems setObject:item forKey:[NSNumber numberWithUnsignedInteger:[item keyEquivalentModifierMask]]];

    [[item extraData] setPrimaryItem:_ownerItem];
}

- (NSMenuItem *)itemWithModifierMask:(NSUInteger)mask
{
    if(mask == 0 || !_alternateItems) return _ownerItem;

    __block NSMenuItem *result = _ownerItem;
    [_alternateItems enumerateKeysAndObjectsUsingBlock:
     ^ (NSNumber *key, NSMenuItem *obj, BOOL *stop)
     {
         if(![obj isHidden] && ([key unsignedIntegerValue] & mask) == mask)
         {
             result = obj;
             *stop  = YES;
         }
     }];

    return result;
}

@end
