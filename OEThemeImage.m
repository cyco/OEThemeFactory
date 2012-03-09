//
//  OEThemeImageStates.m
//  OEThemeFactory
//
//  Created by Faustino Osuna on 2/27/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "OEThemeImage.h"
#import "NSImage+OEDrawingAdditions.h"

static NSString * const OEThemeImageResourceAttributeName = @"Resource";
static NSString * const OEThemeImagePartsAttributeName    = @"Parts";
static NSString * const OEThemeImageVerticalAttributeName = @"Vertical";

@implementation OEThemeImage

+ (id)parseWithDefinition:(NSDictionary *)definition
{
    NSString *resource = ([definition valueForKey:OEThemeImageResourceAttributeName] ?: [definition valueForKey:OEThemeObjectValueAttributeName]);
    if (resource == nil) return nil;

    NSArray *parts    = [definition valueForKey:OEThemeImagePartsAttributeName];
    BOOL     vertical = [[definition objectForKey:OEThemeImageVerticalAttributeName] boolValue];

    if(![parts isKindOfClass:[NSArray class]]) parts = nil;
    return [[NSImage imageNamed:resource] imageFromParts:parts vertical:vertical];
}

- (NSImage *)imageForState:(OEThemeState)state
{
    return (NSImage *)[self objectForState:state];
}

@end
