//
//  OEThemeItem.m
//  OEThemeFactory
//
//  Created by Faustino Osuna on 2/26/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "OEThemeItem.h"

NSString * const OEThemeItemStatesAttributeName = @"States";
NSString * const OEThemeItemValueAttributeName  = @"Value";

static NSString * const OEThemeStateDefaultName        = @"Default";
static NSString * const OEThemeStateWindowInactiveName = @"Window Inactive";
static NSString * const OEThemeStateWindowActiveName   = @"Window Active";
static NSString * const OEThemeStateOffName            = @"Off";
static NSString * const OEThemeStateOnName             = @"On";
static NSString * const OEThemeStateMixedName          = @"Mixed";
static NSString * const OEThemeStateUnselectedName     = @"Unselected";
static NSString * const OEThemeStateSelectedName       = @"Selected";
static NSString * const OEThemeStateDisabledName       = @"Disabled";
static NSString * const OEThemeStateEnabledName        = @"Enabled";
static NSString * const OEThemeStateUnfocusedName      = @"Unfocused";
static NSString * const OEThemeStateFocusedName        = @"Focused";
static NSString * const OEThemeStateMouseOverName      = @"Mouse Over";
static NSString * const OEThemeStateMouseOffName       = @"Mouse Off";

static NSString * const OEThemeStateAnyWindowStateName   = @"Any Window State";
static NSString * const OEThemeStateAnyActivityStateName = @"Any Activity State";
static NSString * const OEThemeStateAnySelectionName     = @"Any Selection";
static NSString * const OEThemeStateAnyInteractionName   = @"Any Interaction";
static NSString * const OEThemeStateAnyFocusName         = @"Any Focus";
static NSString * const OEThemeStateAnyMouseStateName    = @"Any Mouse State";

static inline NSString *OEKeyForState(OEThemeState state)
{
    return [NSString stringWithFormat:@"0x%x", state];
}

@interface OEThemeItem ()

- (void)OE_adjustItemForMask:(OEThemeState)mask witheState:(OEThemeState)state;

@end

@implementation OEThemeItem

- (id)initWithDefinition:(id)definition
{
    if((self = [super init]))
    {
        NSMutableDictionary *itemByState = [NSMutableDictionary dictionary];
        if([definition isKindOfClass:[NSDictionary class]])
        {
            NSMutableDictionary *rootDefinition = [definition mutableCopy];
            [rootDefinition removeObjectForKey:OEThemeItemStatesAttributeName];
            [itemByState setValue:[isa parseWithDefinition:rootDefinition inheritedDefinition:nil] forKey:OEThemeStateDefaultName];

            NSDictionary *states = [definition valueForKey:OEThemeItemStatesAttributeName];
            if([states isKindOfClass:[NSDictionary class]])
            {
                [states enumerateKeysAndObjectsUsingBlock:
                 ^(id key, id obj, BOOL *stop)
                 {
                     NSString     *trimmedKey = [key stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                     OEThemeState  state      = ([trimmedKey length] == 0 ? OEThemeStateDefault : OEThemeStateFromString(trimmedKey));
                     id            value      = ([isa parseWithDefinition:obj inheritedDefinition:rootDefinition] ?: [NSNull null]);
                     [self OE_setValue:value forState:state];
                 }];
            }
        }
        else
        {
            [itemByState setValue:[isa parseWithDefinition:definition inheritedDefinition:nil] forKey:OEThemeStateDefaultName];
        }
        _itemByState = [itemByState copy];
    }
    return self;
}

+ (id)parseWithDefinition:(id)definition inheritedDefinition:(NSDictionary *)inherited
{
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (id)itemForState:(OEThemeState)state
{
    id results = ([_itemByState valueForKey:OEKeyForState(state)] ?: [_itemByState valueForKey:OEThemeStateDefaultName]);
    return (results == [NSNull null] ? nil : results);
}

- (void)OE_setValue:(id)value forState:(OEThemeState)state
{

}

- (void)OE_adjustItemForMask:(OEThemeState)mask witheState:(OEThemeState)state
{
    if(mask == 0)
        return;

    OEThemeState newState = state & ~mask;

    int lsb = __builtin_ffs(mask) - 1;
    int count = __builtin_popcount(mask);
    OEThemeState m = 1 << lsb;

    for(int i = 0; i < count; i++, m <<= 1)
    {
        NSLog(@"%@", NSStringFromThemeState(newState | m));
    }
}

@end

NSString *NSStringFromThemeState(OEThemeState state)
{
    NSMutableArray *results = [NSMutableArray array];

    if(state == OEThemeStateDefault)
        [results addObject:OEThemeStateDefaultName];
    else
    {
        if((state & OEThemeStateWindowInactive) == (state & OEThemeStateWindowActive))
            [results addObject:OEThemeStateAnyWindowStateName];
        else if(state & OEThemeStateWindowInactive) [results addObject:OEThemeStateWindowInactiveName];
        else if(state & OEThemeStateWindowActive)   [results addObject:OEThemeStateWindowActiveName];

        if((state & OEThemeStateOff) == (state & OEThemeStateOn) == (state & OEThemeStateMixed))
            [results addObject:OEThemeStateAnyActivityStateName];
        else if(state & OEThemeStateMixed) [results addObject:OEThemeStateOffName];
        else if(state & OEThemeStateOn)    [results addObject:OEThemeStateOnName];
        else if(state & OEThemeStateMixed) [results addObject:OEThemeStateMixedName];

        if((state & OEThemeStateUnselected) == (state & OEThemeStateSelected))
            [results addObject:OEThemeStateAnySelectionName];
        else if(state & OEThemeStateUnselected) [results addObject:OEThemeStateUnselectedName];
        else if(state & OEThemeStateSelected)   [results addObject:OEThemeStateSelectedName];

        if((state & OEThemeStateDisabled) == (state & OEThemeStateEnabled))
            [results addObject:OEThemeStateAnyInteractionName];
        else if(state & OEThemeStateDisabled) [results addObject:OEThemeStateDisabledName];
        else if(state & OEThemeStateEnabled)  [results addObject:OEThemeStateEnabledName];

        if((state & OEThemeStateUnfocused) == (state & OEThemeStateFocused))
            [results addObject:OEThemeStateAnyFocusName];
        else if(state & OEThemeStateUnfocused) [results addObject:OEThemeStateUnfocusedName];
        else if(state & OEThemeStateFocused)   [results addObject:OEThemeStateFocusedName];


        if((state & OEThemeStateMouseOver) == (state & OEThemeStateMouseOff))
            [results addObject:OEThemeStateAnyMouseStateName];
        else if(state & OEThemeStateMouseOver) [results addObject:OEThemeStateMouseOverName];
        else if(state & OEThemeStateMouseOff)  [results addObject:OEThemeStateMouseOffName];
    }

    return [results componentsJoinedByString:@", "];
}

OEThemeState OEThemeStateFromString(NSString *state)
{
    OEThemeState  result     = OEThemeStateDefault;
    NSArray      *components = [state componentsSeparatedByString:@","];

    for(id component in components)
    {
        NSString *trimmedComponent = [component stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        if ([trimmedComponent caseInsensitiveCompare:OEThemeStateDefaultName] == NSOrderedSame)
        {
            result = OEThemeStateDefault;
            break;
        }
        else
        {
            if ([trimmedComponent caseInsensitiveCompare:OEThemeStateAnyWindowStateName] == NSOrderedSame)
                result = result | OEThemeStateAnyWindowState;
            {
                if ([trimmedComponent caseInsensitiveCompare:OEThemeStateWindowInactiveName] == NSOrderedSame)
                    result = result | OEThemeStateWindowInactive;
                else if ([trimmedComponent caseInsensitiveCompare:OEThemeStateWindowActiveName] == NSOrderedSame)
                    result = result | OEThemeStateWindowActive;
            }

            if ([trimmedComponent caseInsensitiveCompare:OEThemeStateAnyActivityStateName] == NSOrderedSame)
                result = result | OEThemeStateAnyActivityState;
            {
                if ([trimmedComponent caseInsensitiveCompare:OEThemeStateOffName] == NSOrderedSame)
                    result = result | OEThemeStateOff;
                else if ([trimmedComponent caseInsensitiveCompare:OEThemeStateOnName] == NSOrderedSame)
                    result = result | OEThemeStateOn;
                else if ([trimmedComponent caseInsensitiveCompare:OEThemeStateMixedName] == NSOrderedSame)
                    result = result | OEThemeStateMixed;
            }

            if ([trimmedComponent caseInsensitiveCompare:OEThemeStateAnySelectionName] == NSOrderedSame)
                result = result | OEThemeStateAnySelection;
            else
            {
                if ([trimmedComponent caseInsensitiveCompare:OEThemeStateUnselectedName] == NSOrderedSame)
                    result = result | OEThemeStateUnselected;
                if ([trimmedComponent caseInsensitiveCompare:OEThemeStateSelectedName] == NSOrderedSame)
                    result = result | OEThemeStateSelected;
            }

            if ([trimmedComponent caseInsensitiveCompare:OEThemeStateAnyInteractionName] == NSOrderedSame)
                result = result | OEThemeStateAnyInteraction;
            else
            {
                if ([trimmedComponent caseInsensitiveCompare:OEThemeStateDisabledName] == NSOrderedSame)
                    result = result | OEThemeStateDisabled;
                if ([trimmedComponent caseInsensitiveCompare:OEThemeStateEnabledName] == NSOrderedSame)
                    result = result | OEThemeStateEnabled;
            }

            if ([trimmedComponent caseInsensitiveCompare:OEThemeStateAnyFocusName] == NSOrderedSame)
                result = result | OEThemeStateAnyFocus;
            else
            {
                if ([trimmedComponent caseInsensitiveCompare:OEThemeStateUnfocusedName] == NSOrderedSame)
                    result = result | OEThemeStateUnfocused;
                if ([trimmedComponent caseInsensitiveCompare:OEThemeStateFocusedName] == NSOrderedSame)
                    result = result | OEThemeStateFocused;
            }

            if ([trimmedComponent caseInsensitiveCompare:OEThemeStateAnyMouseStateName] == NSOrderedSame)
                result = result | OEThemeStateAnyMouseState;
            else
            {
                if ([trimmedComponent caseInsensitiveCompare:OEThemeStateMouseOverName] == NSOrderedSame)
                    result = result | OEThemeStateMouseOver;
                if ([trimmedComponent caseInsensitiveCompare:OEThemeStateMouseOffName] == NSOrderedSame)
                    result = result | OEThemeStateMouseOff;
            }
        }
    }

    if((result & OEThemeStateWindowInactive) == (result & OEThemeStateWindowActive))
        result = result | OEThemeStateAnyWindowState;
    if((result & OEThemeStateOn) == (result & OEThemeStateOff))
        result = result | OEThemeStateAnyActivityState;
    if((result & OEThemeStateUnselected) == (result & OEThemeStateSelected))
        result = result | OEThemeStateAnySelection;
    if((result & OEThemeStateDisabled) == (result & OEThemeStateEnabled))
        result = result | OEThemeStateAnyInteraction;
    if((result & OEThemeStateUnfocused) == (result & OEThemeStateFocused))
        result = result| OEThemeStateAnyFocus;
    if((result & OEThemeStateMouseOver) == (result & OEThemeStateMouseOff))
        result = result | OEThemeStateAnyMouseState;

    return (result == OEThemeStateAnyState ? OEThemeStateDefault : result);
}
