//
//  OEThemeGradientStates.m
//  OEThemeFactory
//
//  Created by Faustino Osuna on 3/3/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "OEThemeGradient.h"
#import "NSColor+OEAdditions.h"

static NSString * const OEThemeGradientLocationsAttributeName = @"Locations";
static NSString * const OEThemeGradientColorsAttributeName    = @"Colors";

@implementation OEThemeGradient

+ (id)parseWithDefinition:(NSDictionary *)definition
{
    NSArray *rawLocations    = [definition valueForKey:OEThemeGradientLocationsAttributeName];
    NSArray *rawColorStrings = [definition valueForKey:OEThemeGradientColorsAttributeName];

    if([rawLocations count] == 0 || [rawColorStrings count] == 0 || [rawLocations count] != [rawColorStrings count]) return nil;

    // Translate color strings to NSColor
    id              result = nil;
    NSMutableArray *colors = [NSMutableArray arrayWithCapacity:[rawColorStrings count]];

    [rawColorStrings enumerateObjectsUsingBlock:
     ^ (id obj, NSUInteger idx, BOOL *stop)
     {
         [colors addObject:(NSColorFromString(obj) ?: [NSColor blackColor])];
     }];

    // Translate NSNumber objects to CGFloats
    CGFloat *locations = NULL;
    @try
    {
        if((locations = calloc([colors count], sizeof(CGFloat))) != NULL)
        {
            [rawLocations enumerateObjectsUsingBlock:
             ^ (id obj, NSUInteger idx, BOOL *stop)
             {
                 locations[idx] = [obj floatValue];
             }];

            result = [[NSGradient alloc] initWithColors:colors atLocations:locations colorSpace:[NSColorSpace genericRGBColorSpace]];
        }
    }
    @finally
    {
        if(locations != NULL) free(locations);
    }

    return result;
}

- (NSGradient *)gradientForState:(OEThemeState)state
{
    return (NSGradient *)[self objectForState:state];
}

@end
