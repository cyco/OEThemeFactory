//
//  OEThemeItem.m
//  OEThemeFactory
//
//  Created by Faustino Osuna on 2/26/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "OEThemeItemStates.h"

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

static NSString * const OEThemeStateAnyWindowActivityName = @"Any Window State";
static NSString * const OEThemeStateAnyStateName          = @"Any Activity State";
static NSString * const OEThemeStateAnySelectionName      = @"Any Selection";
static NSString * const OEThemeStateAnyInteractionName    = @"Any Interaction";
static NSString * const OEThemeStateAnyFocusName          = @"Any Focus";
static NSString * const OEThemeStateAnyMouseName          = @"Any Mouse State";

static inline NSString *OEKeyForState(OEThemeState state)
{
    return [NSString stringWithFormat:@"0x%04x", state];
}

@interface OEThemeItemStates ()

- (void)OE_setValue:(id)value forState:(OEThemeState)state;

@end

@implementation OEThemeItemStates

- (id)initWithDefinition:(id)definition
{
    if((self = [super init]))
    {
        _states      = [[NSMutableArray alloc] init];
        _itemByState = [[NSMutableDictionary alloc] init];

        if([definition isKindOfClass:[NSDictionary class]])
        {
            NSMutableDictionary *rootDefinition = [definition mutableCopy];
            [rootDefinition removeObjectForKey:OEThemeItemStatesAttributeName];
            [self OE_setValue:[isa parseWithDefinition:rootDefinition inheritedDefinition:nil] forState:OEThemeStateDefault];

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
            [self OE_setValue:[isa parseWithDefinition:definition inheritedDefinition:nil] forState:OEThemeStateDefault];
        }
    }
    return self;
}

+ (id)parseWithDefinition:(id)definition inheritedDefinition:(NSDictionary *)inherited
{
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (void)OE_setValue:(id)value forState:(OEThemeState)state
{
    NSNumber *stateValue = [NSNumber numberWithUnsignedInteger:state];
    NSUInteger index = 0;

    if([_states count] > 0)
    {
        index = [_states indexOfObject:stateValue inSortedRange:NSMakeRange(0, [_states count]) options:NSBinarySearchingFirstEqual | NSBinarySearchingInsertionIndex usingComparator:
                 ^ NSComparisonResult(id obj1, id obj2)
                 {
                     return [obj1 compare:obj2];
                 }];
    }

    if(index < [_states count] && ![[_states objectAtIndex:index] isEqualTo:stateValue])
        [_states insertObject:stateValue atIndex:index];
    else
        [_states addObject:stateValue];

    [_itemByState setValue:value forKey:OEKeyForState(state)];
}

- (id)itemForState:(OEThemeState)state
{
    __block id results = [_itemByState valueForKey:OEKeyForState(state)];
    if(results == nil)
    {
        [_states enumerateObjectsUsingBlock:
         ^(NSNumber *obj, NSUInteger idx, BOOL *stop) {
            if([obj unsignedIntegerValue] & state)
            {
                results = [_itemByState valueForKey:OEKeyForState([obj unsignedIntegerValue])];
                if(state != OEThemeStateDefault) [self OE_setValue:results forState:state];
                *stop = YES;
            }
         }];

        if(results == nil) [self OE_setValue:[NSNull null] forState:state];
    }

    return (results == [NSNull null] ? nil : results);
}

- (void)setInContext:(CGContextRef)ctx withState:(OEThemeState)state
{
}

- (void)setWithState:(OEThemeState)state
{
}

- (void)setInLayer:(CALayer *)layer withState:(OEThemeState)state
{
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: states = [%@]>", [self className], [[_itemByState allKeys] componentsJoinedByString:@", "]];
}

@end

NSString *NSStringFromThemeState(OEThemeState state)
{
    NSMutableArray *results = [NSMutableArray array];

    if(state == OEThemeStateDefault)
        [results addObject:OEThemeStateDefaultName];
    else
    {
        if((state & OEThemeStateAnyWindowActivityMask) == OEThemeStateAnyWindowActivityMask)
            [results addObject:OEThemeStateAnyWindowActivityName];
        else if(state & OEThemeStateWindowActive)   [results addObject:OEThemeStateWindowActiveName];
        else if(state & OEThemeStateWindowInactive) [results addObject:OEThemeStateWindowInactiveName];

        if((state & OEThemeStateAnyStateMask) == OEThemeStateAnyStateMask)
            [results addObject:OEThemeStateAnyStateName];
        else if(state & OEThemeStateOn)    [results addObject:OEThemeStateOnName];
        else if(state & OEThemeStateMixed) [results addObject:OEThemeStateMixedName];
        else if(state & OEThemeStateOff)   [results addObject:OEThemeStateOffName];

        if((state & OEThemeStateAnySelectionMask) == OEThemeStateAnySelectionMask)
            [results addObject:OEThemeStateAnySelectionName];
        else if(state & OEThemeStateSelected)   [results addObject:OEThemeStateSelectedName];
        else if(state & OEThemeStateUnselected) [results addObject:OEThemeStateUnselectedName];

        if((state & OEThemeStateAnyInteractionMask) == OEThemeStateAnyInteractionMask)
            [results addObject:OEThemeStateAnyInteractionName];
        else if(state & OEThemeStateEnabled)  [results addObject:OEThemeStateEnabledName];
        else if(state & OEThemeStateDisabled) [results addObject:OEThemeStateDisabledName];

        if((state & OEThemeStateAnyFocusMask) == OEThemeStateAnyFocusMask)
            [results addObject:OEThemeStateAnyFocusName];
        else if(state & OEThemeStateFocused)   [results addObject:OEThemeStateFocusedName];
        else if(state & OEThemeStateUnfocused) [results addObject:OEThemeStateUnfocusedName];

        if((state & OEThemeStateAnyMouseMask) == OEThemeStateAnyMouseMask)
            [results addObject:OEThemeStateAnyMouseName];
        else if(state & OEThemeStateMouseOver) [results addObject:OEThemeStateMouseOverName];
        else if(state & OEThemeStateMouseOff)  [results addObject:OEThemeStateMouseOffName];
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
        else if([trimmedComponent caseInsensitiveCompare:OEThemeStateAnyWindowActivityName] == NSOrderedSame)
            result = result | OEThemeStateAnyWindowActivityMask;
        else if([trimmedComponent caseInsensitiveCompare:OEThemeStateAnyStateName] == NSOrderedSame)
            result = result | OEThemeStateAnyStateMask;
        else if([trimmedComponent caseInsensitiveCompare:OEThemeStateAnySelectionName] == NSOrderedSame)
            result = result | OEThemeStateAnySelectionMask;
        else if([trimmedComponent caseInsensitiveCompare:OEThemeStateAnyInteractionName] == NSOrderedSame)
            result = result | OEThemeStateAnyInteractionMask;
        else if([trimmedComponent caseInsensitiveCompare:OEThemeStateAnyFocusName] == NSOrderedSame)
            result = result | OEThemeStateAnyFocusMask;
        else if([trimmedComponent caseInsensitiveCompare:OEThemeStateAnyMouseName] == NSOrderedSame)
            result = result | OEThemeStateAnyMouseMask;
        else if([trimmedComponent caseInsensitiveCompare:OEThemeStateWindowInactiveName] == NSOrderedSame)
            result = result | OEThemeStateWindowInactive;
        else if([trimmedComponent caseInsensitiveCompare:OEThemeStateWindowActiveName] == NSOrderedSame)
            result = result | OEThemeStateWindowActive;
        else if([trimmedComponent caseInsensitiveCompare:OEThemeStateOffName] == NSOrderedSame)
            result = result | OEThemeStateOff;
        else if([trimmedComponent caseInsensitiveCompare:OEThemeStateOnName] == NSOrderedSame)
            result = result | OEThemeStateOn;
        else if([trimmedComponent caseInsensitiveCompare:OEThemeStateMixedName] == NSOrderedSame)
            result = result | OEThemeStateMixed;
        else if([trimmedComponent caseInsensitiveCompare:OEThemeStateUnselectedName] == NSOrderedSame)
            result = result | OEThemeStateUnselected;
        else if([trimmedComponent caseInsensitiveCompare:OEThemeStateSelectedName] == NSOrderedSame)
            result = result | OEThemeStateSelected;
        else if([trimmedComponent caseInsensitiveCompare:OEThemeStateDisabledName] == NSOrderedSame)
            result = result | OEThemeStateDisabled;
        else if([trimmedComponent caseInsensitiveCompare:OEThemeStateEnabledName] == NSOrderedSame)
            result = result | OEThemeStateEnabled;
        else if([trimmedComponent caseInsensitiveCompare:OEThemeStateUnfocusedName] == NSOrderedSame)
            result = result | OEThemeStateUnfocused;
        else if([trimmedComponent caseInsensitiveCompare:OEThemeStateFocusedName] == NSOrderedSame)
            result = result | OEThemeStateFocused;
        else if([trimmedComponent caseInsensitiveCompare:OEThemeStateMouseOffName] == NSOrderedSame)
            result = result | OEThemeStateMouseOff;
        else if([trimmedComponent caseInsensitiveCompare:OEThemeStateMouseOverName] == NSOrderedSame)
            result = result | OEThemeStateMouseOver;
    }

    return result;
}
