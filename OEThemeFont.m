//
//  OEFont.m
//  OEThemeFactory
//
//  Created by Faustino Osuna on 2/26/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "OEThemeFont.h"
#import "OEThemeColorStates.h"

@implementation OEThemeFont

@synthesize font = _font;
@synthesize color = _color;
@synthesize shadow = _shadow;

NSString * const OEThemeShadowOffsetAttributeName     = @"Offset";
NSString * const OEThemeShadowBlurRadiusAttributeName = @"BlurRadius";
NSString * const OEThemeShadowColorAttributeName      = @"Color";

NSString * const OEThemeFontColorAttributeName  = @"Color";
NSString * const OEThemeFontShadowAttributeName = @"Shadow";

NSString * const OEThemeFontFamilyAttributeName = @"Family";
NSString * const OEThemeFontSizeAttributeName   = @"Size";
NSString * const OEThemeFontWeightAttributeName = @"Weight";
NSString * const OEThemeFontTraitsAttributeName = @"Traits";

NSFontTraitMask NSFontTraitMaskFromString(NSString *string)
{
    NSFontTraitMask mask = 0;
    NSArray *components = [string componentsSeparatedByString:@","];
    for(NSString *component in components)
    {
        NSString *trimmedComponent = [component stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        if([trimmedComponent caseInsensitiveCompare:@"Bold"])
            mask = mask | NSBoldFontMask;
        else if([trimmedComponent caseInsensitiveCompare:@"Unbold"])
            mask = mask | NSUnboldFontMask;
        else if([trimmedComponent caseInsensitiveCompare:@"Italic"])
            mask = mask | NSItalicFontMask;
        else if([trimmedComponent caseInsensitiveCompare:@"Unitalic"])
            mask = mask | NSUnitalicFontMask;
    }

    return mask;
}

- (id)initWithDictionary:(NSDictionary *)dictionary
{
    if((self = [super init]))
    {
        id color = [dictionary objectForKey:OEThemeFontColorAttributeName];
        if([color isKindOfClass:[NSColor class]])
            _color = color;
        else if([color isKindOfClass:[NSString class]])
            _color = (NSColorFromString(color) ?: [NSColor blackColor]);
        else
            _color = [NSColor blackColor];

        id shadow = [dictionary objectForKey:OEThemeFontShadowAttributeName];
        if([shadow isKindOfClass:[NSShadow class]])
            _shadow = shadow;
        else if([shadow isKindOfClass:[NSDictionary class]])
        {
            NSSize  offset     = [[shadow valueForKey:OEThemeShadowOffsetAttributeName] sizeValue];
            CGFloat blurRadius = [[shadow valueForKey:OEThemeShadowBlurRadiusAttributeName] floatValue];
            id      color      = [shadow objectForKey:OEThemeShadowColorAttributeName];

            if([color isKindOfClass:[NSString class]])
                color = (NSColorFromString(color) ?: [NSColor blackColor]);
            else if(![color isKindOfClass:[NSColor class]])
                color = [NSColor blackColor];


            _shadow = [[NSShadow alloc] init];
            [_shadow setShadowOffset:offset];
            [_shadow setShadowBlurRadius:blurRadius];
            [_shadow setShadowColor:color];
        }

        NSString        *familyAttribute = [dictionary valueForKey:OEThemeFontFamilyAttributeName];
        CGFloat          size            = [([dictionary objectForKey:OEThemeFontSizeAttributeName] ?: [NSNumber numberWithFloat:12.0]) floatValue];
        NSUInteger       weight          = [([dictionary objectForKey:OEThemeFontWeightAttributeName] ?: [NSNumber numberWithInt:5]) intValue];
        NSFontTraitMask  mask            = NSFontTraitMaskFromString([dictionary objectForKey:OEThemeFontTraitsAttributeName]);

        _font = [[NSFontManager sharedFontManager] fontWithFamily:familyAttribute traits:mask weight:weight size:size];
    }

    return self;
}

- (NSString *)description
{
    NSMutableArray *components = [NSMutableArray array];
    [components addObject:[NSString stringWithFormat:@"font = %@", _font]];

    if(![_color isEqualTo:[NSColor blackColor]])
        [components addObject:[NSString stringWithFormat:@"color = %@", _color]];
    if(_shadow)
        [components addObject:[NSString stringWithFormat:@"shadow = %@", _shadow]];

    return [components componentsJoinedByString:@"; "];
}

@end
