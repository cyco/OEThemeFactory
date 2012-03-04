//
//  OETheme.m
//  OEThemeFactory
//
//  Created by Faustino Osuna on 2/26/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "OETheme.h"
#import "OEThemeColor.h"
#import "OEThemeTextAttributes.h"
#import "OEThemeImage.h"
#import "OEThemeGradient.h"

static NSString * const OEThemeStateDefaultName           = @"Default";
static NSString * const OEThemeStateWindowInactiveName    = @"Window Inactive";
static NSString * const OEThemeStateWindowActiveName      = @"Window Active";
static NSString * const OEThemeStateOffName               = @"Off";
static NSString * const OEThemeStateOnName                = @"On";
static NSString * const OEThemeStateMixedName             = @"Mixed";
static NSString * const OEThemeStateUnselectedName        = @"Unselected";
static NSString * const OEThemeStateSelectedName          = @"Selected";
static NSString * const OEThemeStateDisabledName          = @"Disabled";
static NSString * const OEThemeStateEnabledName           = @"Enabled";
static NSString * const OEThemeStateUnfocusedName         = @"Unfocused";
static NSString * const OEThemeStateFocusedName           = @"Focused";
static NSString * const OEThemeStateMouseOverName         = @"Mouse Over";
static NSString * const OEThemeStateMouseOffName          = @"Mouse Off";

static NSString * const OEThemeStateAnyWindowActivityName = @"Any Window State";
static NSString * const OEThemeStateAnyStateName          = @"Any State";
static NSString * const OEThemeStateAnySelectionName      = @"Any Selection";
static NSString * const OEThemeStateAnyInteractionName    = @"Any Interaction";
static NSString * const OEThemeStateAnyFocusName          = @"Any Focus";
static NSString * const OEThemeStateAnyMouseName          = @"Any Mouse State";

static NSString * const OEThemeColorKey                   = @"Colors";
static NSString * const OEThemeFontKey                    = @"Fonts";
static NSString * const OEThemeImageKey                   = @"Images";
static NSString * const OEThemeGradientKey                = @"Gradients";

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

        _objectsByType = [itemsByType copy];
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
    return [[_objectsByType valueForKey:type] valueForKey:key];
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

- (NSDictionary *)textAttributesForKey:(NSString *)key forState:(OEThemeState)state
{
    return [[self themeTextAttributesForKey:key] textAttributesForState:state];
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

NSString *NSStringFromThemeState(OEThemeState state)
{
    NSMutableArray *results = [NSMutableArray array];

    if(state == 0 || state == OEThemeStateDefault) [results addObject:OEThemeStateDefaultName];
    else
    {
        if((state & OEThemeStateAnyWindowActivityMask) == OEThemeStateAnyWindowActivityMask) [results addObject:OEThemeStateAnyWindowActivityName];
        else if(state & OEThemeStateWindowActive)                                            [results addObject:OEThemeStateWindowActiveName];
        else if(state & OEThemeStateWindowInactive)                                          [results addObject:OEThemeStateWindowInactiveName];

        if((state & OEThemeStateAnyStateMask) == OEThemeStateAnyStateMask)                   [results addObject:OEThemeStateAnyStateName];
        else if(state & OEThemeStateOn)                                                      [results addObject:OEThemeStateOnName];
        else if(state & OEThemeStateMixed)                                                   [results addObject:OEThemeStateMixedName];
        else if(state & OEThemeStateOff)                                                     [results addObject:OEThemeStateOffName];

        if((state & OEThemeStateAnySelectionMask) == OEThemeStateAnySelectionMask)           [results addObject:OEThemeStateAnySelectionName];
        else if(state & OEThemeStateSelected)                                                [results addObject:OEThemeStateSelectedName];
        else if(state & OEThemeStateUnselected)                                              [results addObject:OEThemeStateUnselectedName];

        if((state & OEThemeStateAnyInteractionMask) == OEThemeStateAnyInteractionMask)       [results addObject:OEThemeStateAnyInteractionName];
        else if(state & OEThemeStateEnabled)                                                 [results addObject:OEThemeStateEnabledName];
        else if(state & OEThemeStateDisabled)                                                [results addObject:OEThemeStateDisabledName];

        if((state & OEThemeStateAnyFocusMask) == OEThemeStateAnyFocusMask)                   [results addObject:OEThemeStateAnyFocusName];
        else if(state & OEThemeStateFocused)                                                 [results addObject:OEThemeStateFocusedName];
        else if(state & OEThemeStateUnfocused)                                               [results addObject:OEThemeStateUnfocusedName];

        if((state & OEThemeStateAnyMouseMask) == OEThemeStateAnyMouseMask)                   [results addObject:OEThemeStateAnyMouseName];
        else if(state & OEThemeStateMouseOver)                                               [results addObject:OEThemeStateMouseOverName];
        else if(state & OEThemeStateMouseOff)                                                [results addObject:OEThemeStateMouseOffName];
    }

    return [results componentsJoinedByString:@", "];
}

OEThemeState OEThemeStateFromString(NSString *state)
{
    OEThemeState  result     = 0;
    NSArray      *components = [state componentsSeparatedByString:@","];

    for(id component in components)
    {
        NSString *trimmedComponent = [component stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        if([trimmedComponent caseInsensitiveCompare:OEThemeStateDefaultName] == NSOrderedSame)
        {
            result = OEThemeStateDefault;
            break;
        }
        else if([trimmedComponent caseInsensitiveCompare:OEThemeStateAnyWindowActivityName] == NSOrderedSame) result |= OEThemeStateAnyWindowActivityMask;
        else if([trimmedComponent caseInsensitiveCompare:OEThemeStateAnyStateName] == NSOrderedSame)          result |= OEThemeStateAnyStateMask;
        else if([trimmedComponent caseInsensitiveCompare:OEThemeStateAnySelectionName] == NSOrderedSame)      result |= OEThemeStateAnySelectionMask;
        else if([trimmedComponent caseInsensitiveCompare:OEThemeStateAnyInteractionName] == NSOrderedSame)    result |= OEThemeStateAnyInteractionMask;
        else if([trimmedComponent caseInsensitiveCompare:OEThemeStateAnyFocusName] == NSOrderedSame)          result |= OEThemeStateAnyFocusMask;
        else if([trimmedComponent caseInsensitiveCompare:OEThemeStateAnyMouseName] == NSOrderedSame)          result |= OEThemeStateAnyMouseMask;
        else if([trimmedComponent caseInsensitiveCompare:OEThemeStateWindowInactiveName] == NSOrderedSame)    result |= OEThemeStateWindowInactive;
        else if([trimmedComponent caseInsensitiveCompare:OEThemeStateWindowActiveName] == NSOrderedSame)      result |= OEThemeStateWindowActive;
        else if([trimmedComponent caseInsensitiveCompare:OEThemeStateOffName] == NSOrderedSame)               result |= OEThemeStateOff;
        else if([trimmedComponent caseInsensitiveCompare:OEThemeStateOnName] == NSOrderedSame)                result |= OEThemeStateOn;
        else if([trimmedComponent caseInsensitiveCompare:OEThemeStateMixedName] == NSOrderedSame)             result |= OEThemeStateMixed;
        else if([trimmedComponent caseInsensitiveCompare:OEThemeStateUnselectedName] == NSOrderedSame)        result |= OEThemeStateUnselected;
        else if([trimmedComponent caseInsensitiveCompare:OEThemeStateSelectedName] == NSOrderedSame)          result |= OEThemeStateSelected;
        else if([trimmedComponent caseInsensitiveCompare:OEThemeStateDisabledName] == NSOrderedSame)          result |= OEThemeStateDisabled;
        else if([trimmedComponent caseInsensitiveCompare:OEThemeStateEnabledName] == NSOrderedSame)           result |= OEThemeStateEnabled;
        else if([trimmedComponent caseInsensitiveCompare:OEThemeStateUnfocusedName] == NSOrderedSame)         result |= OEThemeStateUnfocused;
        else if([trimmedComponent caseInsensitiveCompare:OEThemeStateFocusedName] == NSOrderedSame)           result |= OEThemeStateFocused;
        else if([trimmedComponent caseInsensitiveCompare:OEThemeStateMouseOffName] == NSOrderedSame)          result |= OEThemeStateMouseOff;
        else if([trimmedComponent caseInsensitiveCompare:OEThemeStateMouseOverName] == NSOrderedSame)         result |= OEThemeStateMouseOver;
    }

    return result;
}