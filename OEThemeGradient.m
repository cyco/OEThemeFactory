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

        NSArray *rawLocations    = [definition valueForKey:OEThemeGradientLocationsAttributeName];
        NSArray *rawColorStrings = [definition valueForKey:OEThemeGradientColorsAttributeName];

        if([rawLocations count] == [rawColorStrings count])
        {
            // Translate color strings to NSColor
            NSMutableArray *colors = [NSMutableArray arrayWithCapacity:[rawColorStrings count]];
            [rawColorStrings enumerateObjectsUsingBlock:
             ^(id obj, NSUInteger idx, BOOL *stop)
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
                     ^(id obj, NSUInteger idx, BOOL *stop)
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
        }
        else
            NSLog(@"Inconsistent number of colors and color stops.");
    }

    return result;
}

- (NSGradient *)gradientForState:(OEThemeState)state
{
    return (NSGradient *)[self objectForState:state];
}

@end
