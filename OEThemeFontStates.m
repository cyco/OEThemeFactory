//
//  OEThemeFont.m
//  OEThemeFactory
//
//  Created by Faustino Osuna on 2/26/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "OEThemeFontStates.h"
#import "OEThemeFont.h"
#import "NSColor+OEAdditions.h"

@implementation OEThemeFontStates

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

        result = [[OEThemeFont alloc] initWithDictionary:newDefinition];
    }
    else
        result = nil;
    return result;
}

- (OEThemeFont *)themeFontForState:(OEThemeState)state
{
    return (OEThemeFont *)[self itemForState:state];
}

- (void)setInContext:(CGContextRef)ctx withState:(OEThemeState)state
{
    OEThemeFont *themeFont = [self themeFontForState:state];
    CGContextSetFont(ctx, (__bridge CGFontRef)[themeFont font]);
    CGContextSetFontSize(ctx, [[themeFont font] pointSize]);
    CGContextSetStrokeColorWithColor(ctx, [[themeFont color] CGColor]);
    if([themeFont shadow])
    {
        NSShadow *shadow = [themeFont shadow];
        CGContextSetShadowWithColor(ctx, [shadow shadowOffset], [shadow shadowBlurRadius], [[shadow shadowColor] CGColor]);
    }
}

- (void)setWithState:(OEThemeState)state
{
    OEThemeFont *themeFont = [self themeFontForState:state];
    [[themeFont font] set];
    [[themeFont color] set];
    [[themeFont shadow] set];
}

- (void)setInLayer:(CALayer *)layer withState:(OEThemeState)state
{
    if([layer isKindOfClass:[CATextLayer class]])
    {
        OEThemeFont *themeFont = [self themeFontForState:state];
        CATextLayer *textLayer = (CATextLayer*)layer;
        [textLayer setFont:(__bridge CFTypeRef)[themeFont font]];
        [textLayer setFontSize:[[themeFont font] pointSize]];
        [textLayer setForegroundColor:[[themeFont color] CGColor]];
        if([themeFont shadow])
        {
            NSShadow *shadow = [themeFont shadow];
            [textLayer setShadowColor:[[shadow shadowColor] CGColor]];
            [textLayer setShadowOffset:[shadow shadowOffset]];
            [textLayer setShadowRadius:[shadow shadowBlurRadius]];
            [textLayer setShadowOpacity:1.0];
        }
    }
}

@end
