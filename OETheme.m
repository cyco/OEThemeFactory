//
//  OETheme.m
//  OEThemeFactory
//
//  Created by Faustino Osuna on 2/26/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "OETheme.h"

static NSString * const OEThemeColorKey    = @"Colors";
static NSString * const OEThemeFontKey     = @"Fonts";
static NSString * const OEThemeImageKey    = @"Images";
static NSString * const OEThemeGradientKey = @"Gradients";

@interface OETheme ()

- (NSDictionary *)OE_parseThemeSection:(NSDictionary *)section forThemeClass:(Class)class;
- (OEThemeObject *)OE_itemForType:(NSString *)type forKey:(NSString *)key;

@end

@implementation OETheme

- (id)init
{
    NSString *themeFile = [[NSBundle mainBundle] pathForResource:@"Theme" ofType:@"plist"];
    if(!themeFile) return nil;

    if((self = [super init]))
    {
        NSDictionary *dictionary = [NSDictionary dictionaryWithContentsOfFile:themeFile];
        if(!dictionary) return nil;

        NSDictionary *classesBySection = [NSDictionary dictionaryWithObjectsAndKeys:
                                          [OEThemeColor class], OEThemeColorKey,
                                          [OEThemeTextAttributes class], OEThemeFontKey,
                                          [OEThemeImage class], OEThemeImageKey,
                                          [OEThemeGradient class], OEThemeGradientKey,
                                          nil];

        __block NSMutableDictionary *itemsByType = [NSMutableDictionary dictionary];
        [classesBySection enumerateKeysAndObjectsUsingBlock:
         ^(id key, id obj, BOOL *stop)
         {
             NSDictionary *items = [self OE_parseThemeSection:[dictionary valueForKey:key] forThemeClass:obj];
             [itemsByType setValue:(items ?: [NSDictionary dictionary]) forKey:key];
         }];

        _itemsByType = [itemsByType copy];
    }
    return self;
}

+ (id)sharedTheme
{
    static OETheme         *sharedTheme = nil;
    static dispatch_once_t  onceToken;
    dispatch_once(&onceToken, ^{
        sharedTheme = [[OETheme alloc] init];
    });

    return sharedTheme;
}

- (NSDictionary *)OE_parseThemeSection:(NSDictionary *)section forThemeClass:(Class)class
{
    __block NSMutableDictionary *results = [NSMutableDictionary dictionary];
    [section enumerateKeysAndObjectsUsingBlock:
     ^(id key, id obj, BOOL *stop)
    {
        id themeItem = [[class alloc] initWithDefinition:obj];
        if(themeItem) [results setValue:themeItem forKey:key];
    }];

    return [results copy];
}

- (id)OE_itemForType:(NSString *)type forKey:(NSString *)key
{
    return [[_itemsByType valueForKey:type] valueForKey:key];
}

- (OEThemeColor *)themeColorForKey:(NSString *)key
{
    return (OEThemeColor *)[self OE_itemForType:OEThemeColorKey forKey:key];
}

- (NSColor *)colorForKey:(NSString *)key forState:(OEThemeState)state
{
    return [[self themeColorForKey:key] colorForState:state];
}

- (OEThemeTextAttributes *)themeTextAttributesForKey:(NSString *)key
{
    return (OEThemeTextAttributes *)[self OE_itemForType:OEThemeFontKey forKey:key];
}

- (OETextAttributes *)textAttributesForKey:(NSString *)key forState:(OEThemeState)state
{
    return [[self themeTextAttributesForKey:key] textAttributesForState:state];
}

- (NSFont *)fontForKey:(NSString *)key forState:(OEThemeState)state
{
    return [[self textAttributesForKey:key forState:state] font];
}

- (NSColor *)fontColorForKey:(NSString *)key forState:(OEThemeState)state
{
    return [[self textAttributesForKey:key forState:state] color];
}

- (NSShadow *)fontShadowForKey:(NSString *)key forState:(OEThemeState)state;
{
    return [[self textAttributesForKey:key forState:state] shadow];
}

- (OEThemeImage *)themeImageForKey:(NSString *)key
{
    return (OEThemeImage *)[self OE_itemForType:OEThemeImageKey forKey:key];
}

- (NSImage *)imageForKey:(NSString *)key forState:(OEThemeState)state
{
    return [[self themeImageForKey:key] imageForState:state];
}

- (OEThemeGradient *)themeGradientForKey:(NSString *)key
{
    return (OEThemeGradient *)[self OE_itemForType:OEThemeGradientKey forKey:key];
}

- (NSGradient *)gradientForKey:(NSString *)key forState:(OEThemeState)state
{
    return [[self themeGradientForKey:key] gradientForState:state];
}

@end
