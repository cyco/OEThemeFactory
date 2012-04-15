//
//  OEThemeGradientStates.m
//  OEThemeFactory
//
//  Created by Faustino Osuna on 3/3/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "OEThemeGradient.h"
#import "NSColor+OEAdditions.h"

#pragma mark -
#pragma mark Theme gradient attributes

static NSString * const OEThemeGradientLocationsAttributeName = @"Locations";
static NSString * const OEThemeGradientColorsAttributeName    = @"Colors";
static NSString * const OEThemeGradientAngleAttributeName     = @"Angle";

#pragma mark -
#pragma mark Implementation

@interface OENSGradient : NSGradient

@property(nonatomic, assign) CGFloat angle; // Saves the angle specified by the theme definition

@end

@implementation OEThemeGradient

+ (id)parseWithDefinition:(NSDictionary *)definition
{
    id rawLocations    = [definition objectForKey:OEThemeGradientLocationsAttributeName];
    id rawColorStrings = [definition objectForKey:OEThemeGradientColorsAttributeName];
    id angle           = [definition objectForKey:OEThemeGradientAngleAttributeName];

    // Make sure that the gradient definition is well-formed (we should report errors)
    if([rawLocations isKindOfClass:[NSString class]] || [rawLocations isKindOfClass:[NSNumber class]]) rawLocations = [NSArray arrayWithObject:rawLocations];
    else if(![rawLocations isKindOfClass:[NSArray class]])                                             return nil;

    if([rawColorStrings isKindOfClass:[NSString class]] || [rawColorStrings isKindOfClass:[NSNumber class]]) rawColorStrings = [NSArray arrayWithObject:rawColorStrings];
    else if(![rawColorStrings isKindOfClass:[NSArray class]])                                                return nil;

    if(![angle isKindOfClass:[NSString class]] && ![angle isKindOfClass:[NSNumber class]]) angle = nil;

    // Make sure that there are color stops and colors
    if([rawLocations count] == 0 || [rawColorStrings count] == 0 || [rawLocations count] != [rawColorStrings count]) return nil;

    // Translate color strings into NSColor
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
             ^ (NSNumber *location, NSUInteger idx, BOOL *stop)
             {
                 locations[idx] = [location floatValue];
             }];

            result = [[OENSGradient alloc] initWithColors:colors atLocations:locations colorSpace:[NSColorSpace genericRGBColorSpace]];
            [result setAngle:[angle floatValue]];
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

@implementation NSGradient (OEThemeGradientAdditions)

- (void)drawInRect:(NSRect)rect
{
    [self drawInRect:rect angle:0.0];
}

- (void)drawInBezierPath:(NSBezierPath *)path
{
    [self drawInBezierPath:path angle:0.0];
}

@end

@implementation OENSGradient

@synthesize angle = _angle;

- (void)drawInRect:(NSRect)rect
{
    [self drawInRect:rect angle:_angle];
}

- (void)drawInBezierPath:(NSBezierPath *)path
{
    [self drawInBezierPath:path angle:_angle];
}

@end
