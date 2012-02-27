//
//  OEThemeColor.m
//  OEThemeFactory
//
//  Created by Faustino Osuna on 2/26/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "OEThemeColorStates.h"
#import "NSColor+OEAdditions.h"

static NSString *OENormalizeColorString(NSString *colorString);

@implementation OEThemeColorStates

+ (id)parseWithDefinition:(id)definition inheritedDefinition:(NSDictionary *)inherited
{
    id result = nil;
    if([definition isKindOfClass:[NSDictionary class]])
        result = NSColorFromString([definition valueForKey:OEThemeItemValueAttributeName]);
    else if([definition isKindOfClass:[NSString class]])
        result = NSColorFromString(definition);
    else
        result = nil;
    return result;
}

- (NSColor *)colorForState:(OEThemeState)state
{
    return (NSColor *)[self itemForState:state];
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

NSString *OENormalizeColorString(NSString *colorString)
{
    const NSUInteger     len = [colorString length];
    NSRegularExpression *regex  = [NSRegularExpression regularExpressionWithPattern:@"^(?:(?:#)|(?:0x))?[0-9a-f]+$" options:NSRegularExpressionCaseInsensitive error:nil];
    NSString            *result = nil;

    if(colorString && [regex numberOfMatchesInString:colorString options:0 range:NSMakeRange(0, len)] == 1)
    {
        result = [colorString lowercaseString];
        if([result hasPrefix:@"0x"])
            result = [result substringFromIndex:2];
        else if([result hasPrefix:@"#"])
            result = [result substringFromIndex:1];

        unichar a, r, g, b;
        switch (len)
        {
            case 4: // argb format
            case 3: // rgb format
                if (len == 4)
                    a = [result characterAtIndex:len-4];
                else
                    a = 'F';
                r = [result characterAtIndex:len-3];
                g = [result characterAtIndex:len-2];
                b = [result characterAtIndex:len-1];
                result = [NSString stringWithFormat:@"%c%c%c%c%c%c%c%c", a, a, r, r, g, g, b, b];
                break;
            case 6: // rrggbb format
                result = [@"ff" stringByAppendingFormat:result];
            case 8: // aarrggbb format
                break;
            default:
                result = [result substringToIndex:8];
                break;
        }
    }
    return result;
}

NSColor *NSColorFromString(NSString *colorString)
{
    static NSDictionary *namedColors = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        namedColors = [NSDictionary dictionaryWithObjectsAndKeys:
                       @"black",                           [NSColor blackColor],
                       @"blue",                            [NSColor blueColor],
                       @"brown",                           [NSColor brownColor],
                       @"clear",                           [NSColor clearColor],
                       @"cyan",                            [NSColor cyanColor],
                       @"darkgray",                        [NSColor darkGrayColor],
                       @"gray",                            [NSColor grayColor],
                       @"green",                           [NSColor greenColor],
                       @"lightgray",                       [NSColor lightGrayColor],
                       @"magenta",                         [NSColor magentaColor],
                       @"orange",                          [NSColor orangeColor],
                       @"purple",                          [NSColor purpleColor],
                       @"red",                             [NSColor redColor],
                       @"white",                           [NSColor whiteColor],
                       @"yellow",                          [NSColor yellowColor],
                       @"alternateselectedcontrol",        [NSColor alternateSelectedControlColor],
                       @"alternateselectedcontroltext",    [NSColor alternateSelectedControlTextColor],
                       @"controlbackground",               [NSColor controlBackgroundColor],
                       @"control",                         [NSColor controlColor],
                       @"controlhighlight",                [NSColor controlHighlightColor],
                       @"controllighthighlight",           [NSColor controlLightHighlightColor],
                       @"controlshadow",                   [NSColor controlShadowColor],
                       @"controldarkshadow",               [NSColor controlDarkShadowColor],
                       @"controltext",                     [NSColor controlTextColor],
                       @"disabledcontroltext",             [NSColor disabledControlTextColor],
                       @"grid",                            [NSColor gridColor],
                       @"header",                          [NSColor headerColor],
                       @"headertext",                      [NSColor headerTextColor],
                       @"highlight",                       [NSColor highlightColor],
                       @"keyboardfocusindicator",          [NSColor keyboardFocusIndicatorColor],
                       @"knob",                            [NSColor knobColor],
                       @"scrollbar",                       [NSColor scrollBarColor],
                       @"secondaryselectedcontrol",        [NSColor secondarySelectedControlColor],
                       @"selectedcontrol",                 [NSColor selectedControlColor],
                       @"selectedcontroltext",             [NSColor selectedControlTextColor],
                       @"selectedmenuitem",                [NSColor selectedMenuItemColor],
                       @"selectedmenuitemtext",            [NSColor selectedMenuItemTextColor],
                       @"selectedtextbackground",          [NSColor selectedTextBackgroundColor],
                       @"selectedtext",                    [NSColor selectedTextColor],
                       @"selectedknob",                    [NSColor selectedKnobColor],
                       @"shadow",                          [NSColor shadowColor],
                       @"textbackground",                  [NSColor textBackgroundColor],
                       @"text",                            [NSColor textColor],
                       @"windowbackground",                [NSColor windowBackgroundColor],
                       @"windowframe",                     [NSColor windowFrameColor],
                       @"windowframetext",                 [NSColor windowFrameTextColor],
                       nil];
    });

    if(!colorString) return nil;

    NSColor *result = [namedColors valueForKey:[[colorString lowercaseString] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]];
    if(result == nil)
    {
        long long unsigned int colorARGB = 0;

        NSScanner *hexScanner = [NSScanner scannerWithString:OENormalizeColorString(colorString)];
        [hexScanner scanHexLongLong:&colorARGB];

        const CGFloat components[] =
        {
            (CGFloat)((colorARGB & 0x00FF0000) >> 16) / 255.0f, // r
            (CGFloat)((colorARGB & 0x0000FF00) >>  8) / 255.0f, // g
            (CGFloat)((colorARGB & 0x000000FF) >>  0) / 255.0f, // b
            (CGFloat)((colorARGB & 0xFF000000) >> 24) / 255.0f  // a
        };

#if defined(OE_USE_SRGB_COLORSPACE) && OE_USE_SRGB_COLORSPACE == 1
        result = [NSColor colorWithColorSpace:[NSColorSpace sRGBColorSpace] components:components count:4];
#else
        result = [NSColor colorWithColorSpace:[NSColorSpace deviceRGBColorSpace] components:components count:4];
#endif
    }
    return result;
}
