//
//  NSMenuItem+OEMenuItemExtraDataAdditions.m
//  OEThemeFactory
//
//  Created by Faustino Osuna on 3/14/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "NSMenuItem+OEMenuItemExtraDataAdditions.h"
#import "OEMenuItemExtraData.h"
#import <objc/runtime.h>

const static char OEMenuItemExtraDataKey;

@implementation NSMenuItem (OEMenuItemExtraDataAdditions)

- (void)setExtraData:(OEMenuItemExtraData *)extraData
{
    objc_setAssociatedObject(self, &OEMenuItemExtraDataKey, extraData, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (OEMenuItemExtraData  *)extraData
{
    OEMenuItemExtraData *extraData = objc_getAssociatedObject(self, &OEMenuItemExtraDataKey);
    if(!extraData)
    {
        extraData = [[OEMenuItemExtraData alloc] initWithOwnerItem:self];
        [self setExtraData:extraData];
    }
    return extraData;
}

@end
