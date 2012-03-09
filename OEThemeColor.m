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

- (void)setInContext:(CGContextRef)ctx withState:(OEThemeState)state
{
    [self setFillInContext:ctx withState:state];
    [self setStrokeInContext:ctx withState:state];
}

- (void)setFillInContext:(CGContextRef)ctx withState:(OEThemeState)state
{
    CGContextSetFillColorWithColor(ctx, [[self colorForState:state] CGColor]);
}

- (void)setStrokeInContext:(CGContextRef)ctx withState:(OEThemeState)state
{
    CGContextSetStrokeColorWithColor(ctx, [[self colorForState:state] CGColor]);
}

- (void)setWithState:(OEThemeState)state
{
    [[self colorForState:state] set];
}

- (void)setFillWithState:(OEThemeState)state
{
    [[self colorForState:state] setFill];
}

- (void)setStrokeWithState:(OEThemeState)state
{
    [[self colorForState:state] setStroke];
}

- (void)setInLayer:(CALayer *)layer withState:(OEThemeState)state
{
    [layer setBackgroundColor:[[self colorForState:state] CGColor]];
}

@end
