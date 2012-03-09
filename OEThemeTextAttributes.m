//
//  OEThemeFont.m
//  OEThemeFactory
//
//  Created by Faustino Osuna on 2/26/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "OEThemeTextAttributes.h"
#import "NSColor+OEAdditions.h"

static NSString * const OEThemeFontForegroundColorAttributeName = @"Foreground Color";
static NSString * const OEThemeFontBackgroundColorAttributeName = @"Background Color";

static NSString * const OEThemeFontFamilyAttributeName          = @"Family";
static NSString * const OEThemeFontSizeAttributeName            = @"Size";
static NSString * const OEThemeFontWeightAttributeName          = @"Weight";
static NSString * const OEThemeFontTraitsAttributeName          = @"Traits";

static NSString * const OEThemeFontShadowAttributeName          = @"Shadow";
static NSString * const OEThemeShadowOffsetAttributeName        = @"Offset";
static NSString * const OEThemeShadowBlurRadiusAttributeName    = @"BlurRadius";
static NSString * const OEThemeShadowColorAttributeName         = @"Color";

static NSString * const OEThemeFontTraitBoldName   = @"Bold";
static NSString * const OEThemeFontTraitUnboldName = @"Unbold";
static NSString * const OEThemeFontTraitItalicName = @"Italic";
static NSString * const OEThemeFontTraitUnitalic   = @"Unitalic";

// Parses a common separated NSString that specifies font traits
NSFontTraitMask NSFontTraitMaskFromString(NSString *string)
{
    __block NSFontTraitMask mask = 0;

    [[string componentsSeparatedByString:@","] enumerateObjectsUsingBlock:
     ^ (NSString *obj, NSUInteger idx, BOOL *stop)
     {
         NSString *trait = [obj stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];

         if([trait caseInsensitiveCompare:OEThemeFontTraitBoldName])        mask |= NSBoldFontMask;
         else if([trait caseInsensitiveCompare:OEThemeFontTraitUnboldName]) mask |= NSUnboldFontMask;
         else if([trait caseInsensitiveCompare:OEThemeFontTraitItalicName]) mask |= NSItalicFontMask;
         else if([trait caseInsensitiveCompare:OEThemeFontTraitUnitalic])   mask |= NSUnitalicFontMask;
     }];

    return mask;
}

// This is a convenience function that allows us to retrieve an object from the specified dictionary
id _OEObjectFromDictionary(NSDictionary *dictionary, NSString *attributeName, Class expectedClass, id (^parse)(id obj))
{
    id obj = [dictionary objectForKey:attributeName];

    // If the object already conforms to the requested class, then return the object, other wise parse the object
    return ([obj isKindOfClass:expectedClass] ? obj : parse(obj));
}

@implementation OEThemeTextAttributes

+ (id)parseWithDefinition:(NSDictionary *)definition
{
    // Parse the values from the new definition
    NSColor *foregroundColor = _OEObjectFromDictionary(definition, OEThemeFontForegroundColorAttributeName, [NSColor class],
                                                       ^ id (id color) {
                                                           return ([color isKindOfClass:[NSString class]] ? (NSColorFromString(color) ?: [NSColor blackColor]) : [NSColor blackColor]);
                                                       });

    NSColor *backgroundColor = _OEObjectFromDictionary(definition, OEThemeFontBackgroundColorAttributeName, [NSColor class],
                                                       ^ id (id color) {
                                                           return ([color isKindOfClass:[NSString class]] ? (NSColorFromString(color) ?: nil) : nil);
                                                       });

    NSShadow *shadow = _OEObjectFromDictionary(definition, OEThemeFontShadowAttributeName, [NSShadow class],
                                               ^ id (id shadow) {
                                                   if(![shadow isKindOfClass:[NSDictionary class]]) return nil;

                                                   NSSize  offset     = [[shadow valueForKey:OEThemeShadowOffsetAttributeName] sizeValue];
                                                   CGFloat blurRadius = [[shadow valueForKey:OEThemeShadowBlurRadiusAttributeName] floatValue];
                                                   id      color      = [shadow objectForKey:OEThemeShadowColorAttributeName];

                                                   if([color isKindOfClass:[NSString class]])      color = (NSColorFromString(color) ?: [NSColor blackColor]);
                                                   else if(![color isKindOfClass:[NSColor class]]) color = [NSColor blackColor];

                                                   NSShadow *result = [[NSShadow alloc] init];
                                                   [result setShadowOffset:offset];
                                                   [result setShadowBlurRadius:blurRadius];
                                                   [result setShadowColor:color];

                                                   return result;
                                               });

    NSString   *familyAttribute = ([definition valueForKey:OEThemeFontFamilyAttributeName]   ?: [definition objectForKey:OEThemeObjectValueAttributeName]);
    CGFloat     size            = [([definition objectForKey:OEThemeFontSizeAttributeName]   ?: [NSNumber numberWithFloat:12.0]) floatValue];
    NSUInteger  weight          = [([definition objectForKey:OEThemeFontWeightAttributeName] ?: [NSNumber numberWithInt:5]) intValue];

    NSFontTraitMask  mask = [_OEObjectFromDictionary(definition, OEThemeFontTraitsAttributeName, [NSNumber class],
                                                     ^ id (id mask) {
                                                         if(![mask isKindOfClass:[NSString class]]) return [NSNumber numberWithInt:0];
                                                         return [NSNumber numberWithUnsignedInteger:NSFontTraitMaskFromString(mask)];
                                                     }) unsignedIntegerValue];

    NSFont *font = [[NSFontManager sharedFontManager] fontWithFamily:familyAttribute traits:mask weight:weight size:size];

    NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
    if(font)            [attributes setValue:font            forKey:NSFontAttributeName];
    if(shadow)          [attributes setValue:shadow          forKey:NSShadowAttributeName];
    if(foregroundColor) [attributes setValue:foregroundColor forKey:NSForegroundColorAttributeName];
    if(backgroundColor) [attributes setValue:backgroundColor forKey:NSBackgroundColorAttributeName];

    return [attributes copy];
}

- (NSDictionary *)textAttributesForState:(OEThemeState)state
{
    return (NSDictionary *)[self objectForState:state];
}

- (void)setInContext:(CGContextRef)ctx withState:(OEThemeState)state
{
    NSDictionary *attributes = [self textAttributesForState:state];
    NSFont       *font       = [attributes objectForKey:NSFontAttributeName];
    NSColor      *color      = [attributes objectForKey:NSForegroundColorAttributeName];
    NSShadow     *shadow     = [attributes objectForKey:NSShadowAttributeName];

    if(font)
    {
        CGContextSetFont(ctx, (__bridge CGFontRef)font);
        CGContextSetFontSize(ctx, [font pointSize]);
    }

    if(color)  CGContextSetStrokeColorWithColor(ctx, [color CGColor]);
    if(shadow) CGContextSetShadowWithColor(ctx, [shadow shadowOffset], [shadow shadowBlurRadius], [[shadow shadowColor] CGColor]);
}

- (void)setWithState:(OEThemeState)state
{
    NSDictionary *attributes = [self textAttributesForState:state];
    NSFont       *font       = [attributes objectForKey:NSFontAttributeName];
    NSColor      *color      = [attributes objectForKey:NSForegroundColorAttributeName];
    NSShadow     *shadow     = [attributes objectForKey:NSShadowAttributeName];

    [font set];
    [color set];
    [shadow set];
}

- (void)setInLayer:(CALayer *)layer withState:(OEThemeState)state
{
    if([layer isKindOfClass:[CATextLayer class]])
    {
        NSDictionary *attributes = [self textAttributesForState:state];
        NSFont       *font       = [attributes objectForKey:NSFontAttributeName];
        NSColor      *color      = [attributes objectForKey:NSForegroundColorAttributeName];
        NSShadow     *shadow     = [attributes objectForKey:NSShadowAttributeName];

        CATextLayer *textLayer = (CATextLayer*)layer;
        if(font)
        {
            [textLayer setFont:(__bridge CFTypeRef)font];
            [textLayer setFontSize:[font pointSize]];
        }

        if(color) [textLayer setForegroundColor:[color CGColor]];

        if(shadow)
        {
            [textLayer setShadowColor:[[shadow shadowColor] CGColor]];
            [textLayer setShadowOffset:[shadow shadowOffset]];
            [textLayer setShadowRadius:[shadow shadowBlurRadius]];
            [textLayer setShadowOpacity:1.0];
        }
    }
}

@end
