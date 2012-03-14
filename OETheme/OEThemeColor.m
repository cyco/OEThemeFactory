//
//  OEThemeColor.m
//  OEThemeFactory
//
//  Created by Faustino Osuna on 2/26/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "OEThemeColor.h"
#import "NSColor+OEAdditions.h"

@implementation OEThemeColor

+ (id)parseWithDefinition:(NSDictionary *)definition
{
    return NSColorFromString([definition valueForKey:OEThemeObjectValueAttributeName]);
}

- (NSColor *)colorForState:(OEThemeState)state
{
    return (NSColor *)[self objectForState:state];
}

@end
