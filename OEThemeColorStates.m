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
    NSUInteger           len = [colorString length];
    NSRegularExpression *regex  = [NSRegularExpression regularExpressionWithPattern:@"^(?:(?:#)|(?:0x))?[0-9a-f]+$" options:NSRegularExpressionCaseInsensitive error:nil];
    NSString            *result = nil;

    if(colorString && [regex numberOfMatchesInString:colorString options:0 range:NSMakeRange(0, len)] == 1)
    {
        result = [colorString lowercaseString];
        if([result hasPrefix:@"0x"])
        {
            result = [result substringFromIndex:2];
            len   -= 2;
        }
        else if([result hasPrefix:@"#"])
        {
            result = [result substringFromIndex:1];
            len   -= 1;
        }

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

NSColor *_NSColorFromString(NSString *colorString)
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
    return [NSColor colorWithColorSpace:[NSColorSpace sRGBColorSpace] components:components count:4];
#else
    return [NSColor colorWithColorSpace:[NSColorSpace deviceRGBColorSpace] components:components count:4];
#endif
}

// Inspired by http://www.w3.org/TR/css3-color/ and https://github.com/kballard/uicolor-utilities/blob/master/UIColor-Expanded.m
NSColor *NSColorFromString(NSString *colorString)
{
    static NSDictionary *namedColors = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        namedColors = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                       @"clear",                        [NSColor clearColor],
                       @"alternateselectedcontrol",     [NSColor alternateSelectedControlColor],
                       @"alternateselectedcontroltext", [NSColor alternateSelectedControlTextColor],
                       @"controlbackground",            [NSColor controlBackgroundColor],
                       @"control",                      [NSColor controlColor],
                       @"controlhighlight",             [NSColor controlHighlightColor],
                       @"controllighthighlight",        [NSColor controlLightHighlightColor],
                       @"controlshadow",                [NSColor controlShadowColor],
                       @"controldarkshadow",            [NSColor controlDarkShadowColor],
                       @"controltext",                  [NSColor controlTextColor],
                       @"disabledcontroltext",          [NSColor disabledControlTextColor],
                       @"grid",                         [NSColor gridColor],
                       @"header",                       [NSColor headerColor],
                       @"headertext",                   [NSColor headerTextColor],
                       @"highlight",                    [NSColor highlightColor],
                       @"keyboardfocusindicator",       [NSColor keyboardFocusIndicatorColor],
                       @"knob",                         [NSColor knobColor],
                       @"scrollbar",                    [NSColor scrollBarColor],
                       @"secondaryselectedcontrol",     [NSColor secondarySelectedControlColor],
                       @"selectedcontrol",              [NSColor selectedControlColor],
                       @"selectedcontroltext",          [NSColor selectedControlTextColor],
                       @"selectedmenuitem",             [NSColor selectedMenuItemColor],
                       @"selectedmenuitemtext",         [NSColor selectedMenuItemTextColor],
                       @"selectedtextbackground",       [NSColor selectedTextBackgroundColor],
                       @"selectedtext",                 [NSColor selectedTextColor],
                       @"selectedknob",                 [NSColor selectedKnobColor],
                       @"shadow",                       [NSColor shadowColor],
                       @"textbackground",               [NSColor textBackgroundColor],
                       @"text",                         [NSColor textColor],
                       @"windowbackground",             [NSColor windowBackgroundColor],
                       @"windowframe",                  [NSColor windowFrameColor],
                       @"windowframetext",              [NSColor windowFrameTextColor],
                       nil];

        static const char *colorNameDB =
        "aliceblue=#f0f8ff;antiquewhite=#faebd7;aqua=#00ffff;aquamarine=#7fffd4;azure=#f0ffff;"
        "beige=#f5f5dc;bisque=#ffe4c4;black=#000000;blanchedalmond=#ffebcd;blue=#0000ff;"
        "blueviolet=#8a2be2;brown=#a52a2a;burlywood=#deb887;cadetblue=#5f9ea0;chartreuse=#7fff00;"
        "chocolate=#d2691e;coral=#ff7f50;cornflowerblue=#6495ed;cornsilk=#fff8dc;crimson=#dc143c;"
        "cyan=#00ffff;darkblue=#00008b;darkcyan=#008b8b;darkgoldenrod=#b8860b;darkgray=#a9a9a9;"
        "darkgreen=#006400;darkgrey=#a9a9a9;darkkhaki=#bdb76b;darkmagenta=#8b008b;"
        "darkolivegreen=#556b2f;darkorange=#ff8c00;darkorchid=#9932cc;darkred=#8b0000;"
        "darksalmon=#e9967a;darkseagreen=#8fbc8f;darkslateblue=#483d8b;darkslategray=#2f4f4f;"
        "darkslategrey=#2f4f4f;darkturquoise=#00ced1;darkviolet=#9400d3;deeppink=#ff1493;"
        "deepskyblue=#00bfff;dimgray=#696969;dimgrey=#696969;dodgerblue=#1e90ff;"
        "firebrick=#b22222;floralwhite=#fffaf0;forestgreen=#228b22;fuchsia=#ff00ff;"
        "gainsboro=#dcdcdc;ghostwhite=#f8f8ff;gold=#ffd700;goldenrod=#daa520;gray=#808080;"
        "green=#008000;greenyellow=#adff2f;grey=#808080;honeydew=#f0fff0;hotpink=#ff69b4;"
        "indianred=#cd5c5c;indigo=#4b0082;ivory=#fffff0;khaki=#f0e68c;lavender=#e6e6fa;"
        "lavenderblush=#fff0f5;lawngreen=#7cfc00;lemonchiffon=#fffacd;lightblue=#add8e6;"
        "lightcoral=#f08080;lightcyan=#e0ffff;lightgoldenrodyellow=#fafad2;lightgray=#d3d3d3;"
        "lightgreen=#90ee90;lightgrey=#d3d3d3;lightpink=#ffb6c1;lightsalmon=#ffa07a;"
        "lightseagreen=#20b2aa;lightskyblue=#87cefa;lightslategray=#778899;"
        "lightslategrey=#778899;lightsteelblue=#b0c4de;lightyellow=#ffffe0;lime=#00ff00;"
        "limegreen=#32cd32;linen=#faf0e6;magenta=#ff00ff;maroon=#800000;mediumaquamarine=#66cdaa;"
        "mediumblue=#0000cd;mediumorchid=#ba55d3;mediumpurple=#9370db;mediumseagreen=#3cb371;"
        "mediumslateblue=#7b68ee;mediumspringgreen=#00fa9a;mediumturquoise=#48d1cc;"
        "mediumvioletred=#c71585;midnightblue=#191970;mintcream=#f5fffa;mistyrose=#ffe4e1;"
        "moccasin=#ffe4b5;navajowhite=#ffdead;navy=#000080;oldlace=#fdf5e6;olive=#808000;"
        "olivedrab=#6b8e23;orange=#ffa500;orangered=#ff4500;orchid=#da70d6;palegoldenrod=#eee8aa;"
        "palegreen=#98fb98;paleturquoise=#afeeee;palevioletred=#db7093;papayawhip=#ffefd5;"
        "peachpuff=#ffdab9;peru=#cd853f;pink=#ffc0cb;plum=#dda0dd;powderblue=#b0e0e6;"
        "purple=#800080;red=#ff0000;rosybrown=#bc8f8f;royalblue=#4169e1;saddlebrown=#8b4513;"
        "salmon=#fa8072;sandybrown=#f4a460;seagreen=#2e8b57;seashell=#fff5ee;sienna=#a0522d;"
        "silver=#c0c0c0;skyblue=#87ceeb;slateblue=#6a5acd;slategray=#708090;slategrey=#708090;"
        "snow=#fffafa;springgreen=#00ff7f;steelblue=#4682b4;tan=#d2b48c;teal=#008080;"
        "thistle=#d8bfd8;tomato=#ff6347;turquoise=#40e0d0;violet=#ee82ee;wheat=#f5deb3;"
        "white=#ffffff;whitesmoke=#f5f5f5;yellow=#ffff00;yellowgreen=#9acd32;";

        const char *lineSeparator  = ";";
        const char *valueSeperator = "=";

        char *names = NULL;
        char *line, *name, *value, *brkt;

        @try
        {
            names = malloc(strlen(colorNameDB));
            if(names != NULL)
            {
                memcpy(names, colorNameDB, strlen(colorNameDB));

                NSString *colorName  = nil;
                NSColor  *colorValue = nil;

                for(line = strtok_r(names, lineSeparator, &brkt); line; line = strtok_r(NULL, lineSeparator, &brkt))
                {
                    name = strtok_r(line, valueSeperator, &value);
                    if(name != NULL && value != NULL)
                    {
                        colorName  = [[NSString stringWithCString:name encoding:NSUTF8StringEncoding] lowercaseString];
                        colorValue = _NSColorFromString([NSString stringWithCString:value encoding:NSUTF8StringEncoding]);

                        if(colorName != nil && colorValue != nil) [namedColors setValue:colorValue forKey:colorName];
                    }
                }
            }
        }
        @finally
        {
            if(names != NULL) free(names);
        }
    });

    if(!colorString) return nil;

    NSColor *result = [namedColors valueForKey:[[colorString lowercaseString] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]];
    if(result == nil) result = _NSColorFromString(colorString);

    return result;
}
