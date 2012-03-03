//
//  OEThemeImageStates.m
//  OEThemeFactory
//
//  Created by Faustino Osuna on 2/27/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "OEThemeImageStates.h"
#import "NSImage+OEDrawingAdditions.h"

static NSString * const OEThemeImageResourceAttributeName = @"Resource";
static NSString * const OEThemeImagePartsAttributeName    = @"Parts";
static NSString * const OEThemeImageVerticalAttributeName = @"Vertical";

@implementation OEThemeImageStates

+ (id)parseWithDefinition:(id)definition inheritedDefinition:(NSDictionary *)inherited
{
    id result = nil;
    if([definition isKindOfClass:[NSDictionary class]])
    {
        NSMutableDictionary *newDefinition = nil;
        if(inherited)
        {
            newDefinition = [inherited mutableCopy];
            [newDefinition setValuesForKeysWithDictionary:definition];
        }
        else
        {
            newDefinition = [definition mutableCopy];
        }

        NSString *resource = [newDefinition valueForKey:OEThemeImageResourceAttributeName];
        if(resource)
        {
            NSArray *parts = [newDefinition valueForKey:OEThemeImagePartsAttributeName];
            BOOL vertical  = [[newDefinition objectForKey:OEThemeImageVerticalAttributeName] boolValue];

            if(![parts isKindOfClass:[NSArray class]]) parts = [NSArray array];
            result = [[NSImage imageNamed:resource] imageFromParts:parts vertical:vertical];
        }
    }
    else if([definition isKindOfClass:[NSString class]])
    {
        result = [self parseWithDefinition:[NSDictionary dictionaryWithObject:definition forKey:OEThemeImageResourceAttributeName] inheritedDefinition:inherited];
    }

    return result;
}

- (NSImage *)imageForState:(OEThemeState)state
{
    return (NSImage *)[self itemForState:state];
}

- (void)setInLayer:(CALayer *)layer withState:(OEThemeState)state
{
    [layer setContents:[self imageForState:state]];
}

@end
