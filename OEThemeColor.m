//
//  OEThemeColor.m
//  OEThemeFactory
//
//  Created by Faustino Osuna on 2/26/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "OEThemeColor.h"

static NSString *OENormalizeColorString(NSString *colorString);

@implementation OEThemeColor

+ (id)parseWithDefinition:(id)definition inheritedDefinition:(NSDictionary *)inherited
{
    id result = nil;
    if([definition isKindOfClass:[NSDictionary class]])
        result = [definition valueForKey:OEThemeItemValueAttributeName];
    else if([definition isKindOfClass:[NSString class]])
        result = (id)NSColorFromString(definition);
    else
        result = nil;
    return result;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %@>", [self className], [[self itemForState:OEThemeStateDefault] description]];
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
    if (!colorString)
        return nil;

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
