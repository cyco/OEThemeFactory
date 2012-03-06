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

static NSString * const OEThemeInputStateDefaultName        = @"Default";
static NSString * const OEThemeInputStateWindowInactiveName = @"Window Inactive";
static NSString * const OEThemeInputStateWindowActiveName   = @"Window Active";
static NSString * const OEThemeInputStateToggleOffName      = @"Toggle Off";
static NSString * const OEThemeInputStateToggleOnName       = @"Toggle On";
static NSString * const OEThemeInputStateToggleMixedName    = @"Toggle Mixed";
static NSString * const OEThemeInputStateUnpressedName      = @"Unpressed";
static NSString * const OEThemeInputStatePressedName        = @"Pressed";
static NSString * const OEThemeInputStateDisabledName       = @"Disabled";
static NSString * const OEThemeInputStateEnabledName        = @"Enabled";
static NSString * const OEThemeInputStateUnfocusedName      = @"Unfocused";
static NSString * const OEThemeInputStateFocusedName        = @"Focused";
static NSString * const OEThemeInputStateMouseOverName      = @"Mouse Over";
static NSString * const OEThemeInputStateMouseOffName       = @"Mouse Off";

static NSString * const OEThemeStateAnyWindowActivityName   = @"Any Window State";
static NSString * const OEThemeStateAnyToggleName           = @"Any Toggle";
static NSString * const OEThemeStateAnySelectionName        = @"Any Selection";
static NSString * const OEThemeStateAnyInteractionName      = @"Any Interaction";
static NSString * const OEThemeStateAnyFocusName            = @"Any Focus";
static NSString * const OEThemeStateAnyMouseName            = @"Any Mouse State";

static NSString * const OEThemeColorKey                     = @"Colors";
static NSString * const OEThemeFontKey                      = @"Fonts";
static NSString * const OEThemeImageKey                     = @"Images";
static NSString * const OEThemeGradientKey                  = @"Gradients";

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
         ^ (id key, id obj, BOOL *stop)
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
     ^ (id key, id obj, BOOL *stop)
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

    if(state == 0 || state == OEThemeStateDefault) [results addObject:OEThemeInputStateDefaultName];
    else
    {
        if((state & OEThemeStateAnyWindowActivity) == OEThemeStateAnyWindowActivity) [results addObject:OEThemeStateAnyWindowActivityName];
        else if(state & OEThemeInputStateWindowActive)                               [results addObject:OEThemeInputStateWindowActiveName];
        else if(state & OEThemeInputStateWindowInactive)                             [results addObject:OEThemeInputStateWindowInactiveName];

        if((state & OEThemeStateAnyToggle) == OEThemeStateAnyToggle)                 [results addObject:OEThemeStateAnyToggleName];
        else if(state & OEThemeInputStateToggleOn)                                   [results addObject:OEThemeInputStateToggleOnName];
        else if(state & OEThemeInputStateToggleMixed)                                [results addObject:OEThemeInputStateToggleMixedName];
        else if(state & OEThemeInputStateToggleOff)                                  [results addObject:OEThemeInputStateToggleOffName];

        if((state & OEThemeStateAnySelection) == OEThemeStateAnySelection)           [results addObject:OEThemeStateAnySelectionName];
        else if(state & OEThemeInputStatePressed)                                    [results addObject:OEThemeInputStatePressedName];
        else if(state & OEThemeInputStateUnpressed)                                  [results addObject:OEThemeInputStateUnpressedName];

        if((state & OEThemeStateAnyInteraction) == OEThemeStateAnyInteraction)       [results addObject:OEThemeStateAnyInteractionName];
        else if(state & OEThemeInputStateEnabled)                                    [results addObject:OEThemeInputStateEnabledName];
        else if(state & OEThemeInputStateDisabled)                                   [results addObject:OEThemeInputStateDisabledName];

        if((state & OEThemeStateAnyFocus) == OEThemeStateAnyFocus)                   [results addObject:OEThemeStateAnyFocusName];
        else if(state & OEThemeInputStateFocused)                                    [results addObject:OEThemeInputStateFocusedName];
        else if(state & OEThemeInputStateUnfocused)                                  [results addObject:OEThemeInputStateUnfocusedName];

        if((state & OEThemeStateAnyMouse) == OEThemeStateAnyMouse)                   [results addObject:OEThemeStateAnyMouseName];
        else if(state & OEThemeInputStateMouseOver)                                  [results addObject:OEThemeInputStateMouseOverName];
        else if(state & OEThemeInputStateMouseOff)                                   [results addObject:OEThemeInputStateMouseOffName];
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
        if([trimmedComponent caseInsensitiveCompare:OEThemeInputStateDefaultName] == NSOrderedSame)             break;
        else if([trimmedComponent caseInsensitiveCompare:OEThemeStateAnyWindowActivityName] == NSOrderedSame)   result |= OEThemeStateAnyWindowActivity;
        else if([trimmedComponent caseInsensitiveCompare:OEThemeStateAnyToggleName] == NSOrderedSame)           result |= OEThemeStateAnyToggle;
        else if([trimmedComponent caseInsensitiveCompare:OEThemeStateAnySelectionName] == NSOrderedSame)        result |= OEThemeStateAnySelection;
        else if([trimmedComponent caseInsensitiveCompare:OEThemeStateAnyInteractionName] == NSOrderedSame)      result |= OEThemeStateAnyInteraction;
        else if([trimmedComponent caseInsensitiveCompare:OEThemeStateAnyFocusName] == NSOrderedSame)            result |= OEThemeStateAnyFocus;
        else if([trimmedComponent caseInsensitiveCompare:OEThemeStateAnyMouseName] == NSOrderedSame)            result |= OEThemeStateAnyMouse;
        else if([trimmedComponent caseInsensitiveCompare:OEThemeInputStateWindowInactiveName] == NSOrderedSame) result |= OEThemeInputStateWindowInactive;
        else if([trimmedComponent caseInsensitiveCompare:OEThemeInputStateWindowActiveName] == NSOrderedSame)   result |= OEThemeInputStateWindowActive;
        else if([trimmedComponent caseInsensitiveCompare:OEThemeInputStateToggleOffName] == NSOrderedSame)      result |= OEThemeInputStateToggleOff;
        else if([trimmedComponent caseInsensitiveCompare:OEThemeInputStateToggleOnName] == NSOrderedSame)       result |= OEThemeInputStateToggleOn;
        else if([trimmedComponent caseInsensitiveCompare:OEThemeInputStateToggleMixedName] == NSOrderedSame)    result |= OEThemeInputStateToggleMixed;
        else if([trimmedComponent caseInsensitiveCompare:OEThemeInputStateUnpressedName] == NSOrderedSame)      result |= OEThemeInputStateUnpressed;
        else if([trimmedComponent caseInsensitiveCompare:OEThemeInputStatePressedName] == NSOrderedSame)        result |= OEThemeInputStatePressed;
        else if([trimmedComponent caseInsensitiveCompare:OEThemeInputStateDisabledName] == NSOrderedSame)       result |= OEThemeInputStateDisabled;
        else if([trimmedComponent caseInsensitiveCompare:OEThemeInputStateEnabledName] == NSOrderedSame)        result |= OEThemeInputStateEnabled;
        else if([trimmedComponent caseInsensitiveCompare:OEThemeInputStateUnfocusedName] == NSOrderedSame)      result |= OEThemeInputStateUnfocused;
        else if([trimmedComponent caseInsensitiveCompare:OEThemeInputStateFocusedName] == NSOrderedSame)        result |= OEThemeInputStateFocused;
        else if([trimmedComponent caseInsensitiveCompare:OEThemeInputStateMouseOffName] == NSOrderedSame)       result |= OEThemeInputStateMouseOff;
        else if([trimmedComponent caseInsensitiveCompare:OEThemeInputStateMouseOverName] == NSOrderedSame)      result |= OEThemeInputStateMouseOver;
    }

    return (result == 0 ? OEThemeStateDefault : result);
}