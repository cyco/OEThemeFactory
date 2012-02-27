//
//  OETheme.m
//  OEThemeFactory
//
//  Created by Faustino Osuna on 2/26/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "OETheme.h"
#import "OEThemeItemStates.h"
#import "OEThemeColorStates.h"
#import "OEThemeFontStates.h"

static NSString * const OEThemeColorKey = @"Colors";
static NSString * const OEThemeFontKey  = @"Fonts";
static NSString * const OEThemeImageKey = @"Images";

@interface OETheme ()

- (BOOL)OE_parseThemeFileAtPath:(NSString *)themeFile;
- (NSDictionary *)OE_parseThemeSection:(NSDictionary *)section forThemeClass:(Class)class;
- (OEThemeItemStates *)OE_itemForType:(NSString *)type forKey:(NSString *)key;

@end

@implementation OETheme

+ (id)sharedTheme
{
    static OETheme         *sharedTheme = nil;
    static dispatch_once_t  onceToken;
    dispatch_once(&onceToken, ^{
        sharedTheme = [[OETheme alloc] init];
    });

    return sharedTheme;
}

- (id)init
{
    NSString *themeFile = [[NSBundle mainBundle] pathForResource:@"Theme" ofType:@"plist"];
    if(!themeFile)
        return nil;

    if((self = [super init]))
    {
        if(![self OE_parseThemeFileAtPath:themeFile])
            return nil;
    }
    return self;
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

- (BOOL)OE_parseThemeFileAtPath:(NSString *)themeFile
{
    NSDictionary *dictionary = [NSDictionary dictionaryWithContentsOfFile:themeFile];
    if(!dictionary)
        return NO;

    NSDictionary *classesBySection = [NSDictionary dictionaryWithObjectsAndKeys:
                                      [OEThemeColorStates class], OEThemeColorKey,
                                      [OEThemeFontStates class], OEThemeFontKey,
                                      [OEThemeImageStates class], OEThemeImageKey,
                                      nil];

    __block NSMutableDictionary *itemsByType = [NSMutableDictionary dictionary];
    [classesBySection enumerateKeysAndObjectsUsingBlock:
     ^(id key, id obj, BOOL *stop)
    {
        NSDictionary *items = [self OE_parseThemeSection:[dictionary valueForKey:key] forThemeClass:obj];
        [itemsByType setValue:(items ?: [NSDictionary dictionary]) forKey:key];
    }];

    _itemsByType = [itemsByType copy];
    return YES;
}

- (id)OE_itemForType:(NSString *)type forKey:(NSString *)key
{
    return [[_itemsByType valueForKey:type] valueForKey:key];
}

- (OEThemeColorStates *)colorStatesForKey:(NSString *)key
{
    return (OEThemeColorStates *)[self OE_itemForType:OEThemeColorKey forKey:key];
}

- (NSColor *)colorForKey:(NSString *)key forState:(OEThemeState)state
{
    return [[self colorStatesForKey:key] colorForState:state];
}

- (OEThemeFontStates *)fontStatesForKey:(NSString *)key
{
    return (OEThemeFontStates *)[self OE_itemForType:OEThemeFontKey forKey:key];
}

- (OEThemeFont *)themeFontForKey:(NSString *)key forState:(OEThemeState)state
{
    return [[self fontStatesForKey:key] themeFontForState:state];
}

- (NSFont *)fontForKey:(NSString *)key forState:(OEThemeState)state
{
    return [[self themeFontForKey:key forState:state] font];
}

- (NSColor *)fontColorForKey:(NSString *)key forState:(OEThemeState)state
{
    return [[self themeFontForKey:key forState:state] color];
}

- (NSShadow *)fontShadowForKey:(NSString *)key forState:(OEThemeState)state;
{
    return [[self themeFontForKey:key forState:state] shadow];
}

- (OEThemeImageStates *)imageStatesForKey:(NSString *)key
{
    return (OEThemeImageStates *)[self OE_itemForType:OEThemeImageKey forKey:key];
}

- (NSImage *)imageForKey:(NSString *)key forState:(OEThemeState)state
{
    return [[self imageStatesForKey:key] imageForState:state];
}

@end
