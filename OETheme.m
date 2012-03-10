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

/*
 Input state tokens used by OEThemeStateFromString to parse an NSString into an OEThemeState. The 'Default' token
 takes precedent over any other token and will automatically set the OEThemeState to OEThemeStateDefault.
 */
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

/*
 These are extended input state tokens to create OEThemeStates with a 'wild card' for the input states specified. If
 a particular input state is left unspecified, these wild cards are implicitly specified.
 */
static NSString * const OEThemeStateAnyWindowActivityName   = @"Any Window State";
static NSString * const OEThemeStateAnyToggleName           = @"Any Toggle";
static NSString * const OEThemeStateAnySelectionName        = @"Any Selection";
static NSString * const OEThemeStateAnyInteractionName      = @"Any Interaction";
static NSString * const OEThemeStateAnyFocusName            = @"Any Focus";
static NSString * const OEThemeStateAnyMouseName            = @"Any Mouse State";

//  Theme.plist Key Names
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
    // Dealloc self if there is no Theme file to parse, the caller should raise a critical error here and halt
    // the application's progress
    NSString *themeFile = [[NSBundle mainBundle] pathForResource:@"Theme" ofType:@"plist"];
    if(!themeFile) return nil;

    if((self = [super init]))
    {
        // Dealloc self if the Theme.plist failed to load, as in previous critical error, the application should halt
        // at this point.
        NSDictionary *dictionary = [NSDictionary dictionaryWithContentsOfFile:themeFile];
        if(!dictionary) return nil;

        // Parse through all the types of UI elements: Colors, Fonts, Images, and Gradients
        NSDictionary *classesBySection = [NSDictionary dictionaryWithObjectsAndKeys:
                                          [OEThemeColor class],          OEThemeColorKey,
                                          [OEThemeTextAttributes class], OEThemeFontKey,
                                          [OEThemeImage class],          OEThemeImageKey,
                                          [OEThemeGradient class],       OEThemeGradientKey,
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
    // Each type of UI element represented in the Theme.plist should have an associated subclass of OEThemeObject.
    // OEThemeObject is responsible for parsing the elements specified in that section of the Theme.plist
    __block NSMutableDictionary *results = [NSMutableDictionary dictionary];
    [section enumerateKeysAndObjectsUsingBlock:
     ^ (id key, id obj, BOOL *stop)
     {
         // Each subclass of OEThemeObject should implement a customized version of +parseWithDefinition:inheritedDefinition: to be able to parse objects
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

    // Empty states implicitly represent the 'Default' state
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
    __block OEThemeState result = 0;
    [[state componentsSeparatedByString:@","] enumerateObjectsUsingBlock:
     ^ (NSString *obj, NSUInteger idx, BOOL *stop)
     {
         NSString *component = [obj stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];

         if([component caseInsensitiveCompare:OEThemeInputStateDefaultName] == NSOrderedSame)
         {
             // The 'Default' input state takes precendent over any other input state
             result = OEThemeStateDefault;
             *stop  = YES;
         }
         else if([component caseInsensitiveCompare:OEThemeStateAnyWindowActivityName]   == NSOrderedSame) result |= OEThemeStateAnyWindowActivity;
         else if([component caseInsensitiveCompare:OEThemeStateAnyToggleName]           == NSOrderedSame) result |= OEThemeStateAnyToggle;
         else if([component caseInsensitiveCompare:OEThemeStateAnySelectionName]        == NSOrderedSame) result |= OEThemeStateAnySelection;
         else if([component caseInsensitiveCompare:OEThemeStateAnyInteractionName]      == NSOrderedSame) result |= OEThemeStateAnyInteraction;
         else if([component caseInsensitiveCompare:OEThemeStateAnyFocusName]            == NSOrderedSame) result |= OEThemeStateAnyFocus;
         else if([component caseInsensitiveCompare:OEThemeStateAnyMouseName]            == NSOrderedSame) result |= OEThemeStateAnyMouse;
         else if([component caseInsensitiveCompare:OEThemeInputStateWindowInactiveName] == NSOrderedSame) result |= OEThemeInputStateWindowInactive;
         else if([component caseInsensitiveCompare:OEThemeInputStateWindowActiveName]   == NSOrderedSame) result |= OEThemeInputStateWindowActive;
         else if([component caseInsensitiveCompare:OEThemeInputStateToggleOffName]      == NSOrderedSame) result |= OEThemeInputStateToggleOff;
         else if([component caseInsensitiveCompare:OEThemeInputStateToggleOnName]       == NSOrderedSame) result |= OEThemeInputStateToggleOn;
         else if([component caseInsensitiveCompare:OEThemeInputStateToggleMixedName]    == NSOrderedSame) result |= OEThemeInputStateToggleMixed;
         else if([component caseInsensitiveCompare:OEThemeInputStateUnpressedName]      == NSOrderedSame) result |= OEThemeInputStateUnpressed;
         else if([component caseInsensitiveCompare:OEThemeInputStatePressedName]        == NSOrderedSame) result |= OEThemeInputStatePressed;
         else if([component caseInsensitiveCompare:OEThemeInputStateDisabledName]       == NSOrderedSame) result |= OEThemeInputStateDisabled;
         else if([component caseInsensitiveCompare:OEThemeInputStateEnabledName]        == NSOrderedSame) result |= OEThemeInputStateEnabled;
         else if([component caseInsensitiveCompare:OEThemeInputStateUnfocusedName]      == NSOrderedSame) result |= OEThemeInputStateUnfocused;
         else if([component caseInsensitiveCompare:OEThemeInputStateFocusedName]        == NSOrderedSame) result |= OEThemeInputStateFocused;
         else if([component caseInsensitiveCompare:OEThemeInputStateMouseOffName]       == NSOrderedSame) result |= OEThemeInputStateMouseOff;
         else if([component caseInsensitiveCompare:OEThemeInputStateMouseOverName]      == NSOrderedSame) result |= OEThemeInputStateMouseOver;
     }];

    // Implicitly return the default state, if no input state was specified
    return result;
}