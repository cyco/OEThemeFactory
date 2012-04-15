//
//  OEThemeImageStates.m
//  OEThemeFactory
//
//  Created by Faustino Osuna on 2/27/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "OEThemeImage.h"
#import "NSImage+OEDrawingAdditions.h"

#pragma mark -
#pragma mark Theme image attributes

static NSString * const OEThemeImageResourceAttributeName = @"Resource";
static NSString * const OEThemeImagePartsAttributeName    = @"Parts";
static NSString * const OEThemeImageVerticalAttributeName = @"Vertical";

#pragma mark -
#pragma mark Implementation

@implementation OEThemeImage

+ (id)parseWithDefinition:(NSDictionary *)definition
{
    NSString *resource = [definition valueForKey:OEThemeImageResourceAttributeName];
    if (resource == nil) return nil;

    id   parts    = ([definition objectForKey:OEThemeImagePartsAttributeName] ?: [definition objectForKey:OEThemeObjectValueAttributeName]);
    BOOL vertical = [[definition objectForKey:OEThemeImageVerticalAttributeName] boolValue];

    if([parts isKindOfClass:[NSString class]])      parts = [NSArray arrayWithObject:parts];
    else if(![parts isKindOfClass:[NSArray class]]) parts = nil;

    return [[NSImage imageNamed:resource] imageFromParts:parts vertical:vertical];
}

- (NSImage *)imageForState:(OEThemeState)state
{
    return (NSImage *)[self objectForState:state];
}

@end
