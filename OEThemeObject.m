//
//  OEThemeItem.m
//  OEThemeFactory
//
//  Created by Faustino Osuna on 2/26/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "OEThemeObject.h"

NSString * const OEThemeObjectStatesAttributeName = @"States";
NSString * const OEThemeObjectValueAttributeName  = @"Value";

static inline id OEKeyForState(OEThemeState state)
{
    return [NSNumber numberWithUnsignedInteger:state];
}

@interface OEThemeObject ()

- (void)OE_setValue:(id)value forState:(OEThemeState)state;

@end

@implementation OEThemeObject

@synthesize stateMask = _stateMask;

- (id)initWithDefinition:(id)definition
{
    if((self = [super init]))
    {
        _states        = [[NSMutableArray alloc] init];
        _objectByState = [[NSMutableDictionary alloc] init];

        if([definition isKindOfClass:[NSDictionary class]])
        {
            // Create a root definition that is inherited by the sttes specified
            NSMutableDictionary *rootDefinition = [definition mutableCopy];
            [rootDefinition removeObjectForKey:OEThemeObjectStatesAttributeName];
            [self OE_setValue:[isa parseWithDefinition:rootDefinition inheritedDefinition:nil] forState:OEThemeStateDefault];

            // Iterate through each of the state descriptions and create a state table
            NSDictionary *states = [definition valueForKey:OEThemeObjectStatesAttributeName];
            if([states isKindOfClass:[NSDictionary class]])
            {
                [states enumerateKeysAndObjectsUsingBlock:
                 ^ (id key, id obj, BOOL *stop)
                 {
                     NSString     *trimmedKey = [key stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                     OEThemeState  state      = ([trimmedKey length] == 0 ? OEThemeStateDefault : OEThemeStateFromString(trimmedKey));
                     id            value      = [isa parseWithDefinition:obj inheritedDefinition:rootDefinition];

                     if(state != OEThemeStateDefault) _stateMask |= state;
                     [self OE_setValue:value forState:state];
                 }];
            }

            if(_stateMask != OEThemeStateDefault)
            {
                // Accumulate the bit-mask that all the state's cover
                if(_stateMask & OEThemeStateAnyWindowActivity) _stateMask |= OEThemeStateAnyWindowActivity;
                if(_stateMask & OEThemeStateAnyToggle)         _stateMask |= OEThemeStateAnyToggle;
                if(_stateMask & OEThemeStateAnySelection)      _stateMask |= OEThemeStateAnySelection;
                if(_stateMask & OEThemeStateAnyInteraction)    _stateMask |= OEThemeStateAnyInteraction;
                if(_stateMask & OEThemeStateAnyFocus)          _stateMask |= OEThemeStateAnyFocus;
                if(_stateMask & OEThemeStateAnyMouse)          _stateMask |= OEThemeStateAnyMouse;

                // Iterate through each state to determine if unspecified inputs should be discarded
                __block BOOL updateStates = FALSE;
                [_states enumerateObjectsUsingBlock:
                 ^ (NSNumber *obj, NSUInteger idx, BOOL *stop)
                 {
                     OEThemeState state = [obj unsignedIntegerValue];
                     if(state != OEThemeStateDefault)
                     {
                         if(!(state & OEThemeStateAnyWindowActivity)) state |= OEThemeStateAnyWindowActivity;
                         if(!(state & OEThemeStateAnyToggle))         state |= OEThemeStateAnyToggle;
                         if(!(state & OEThemeStateAnySelection))      state |= OEThemeStateAnySelection;
                         if(!(state & OEThemeStateAnyInteraction))    state |= OEThemeStateAnyInteraction;
                         if(!(state & OEThemeStateAnyFocus))          state |= OEThemeStateAnyFocus;
                         if(!(state & OEThemeStateAnyMouse))          state |= OEThemeStateAnyMouse;

                         state &= _stateMask;

                         if(state != [obj unsignedIntegerValue])
                         {
                             [_objectByState setValue:[_objectByState objectForKey:obj] forKey:OEKeyForState(state)];
                             [_objectByState removeObjectForKey:obj];
                             updateStates = YES;
                         }
                     }
                 }];

                if(updateStates) _states = [[[_objectByState allKeys] sortedArrayUsingSelector:@selector(compare:)] mutableCopy];
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

+ (OEThemeState)themeStateWithWindowActive:(BOOL)windowActive buttonState:(NSInteger)state selected:(BOOL)selected enabled:(BOOL)enabled focused:(BOOL)focused houseHover:(BOOL)hover
{
    return ((windowActive ? OEThemeInputStateWindowActive : OEThemeInputStateWindowInactive) |
            (selected     ? OEThemeInputStatePressed      : OEThemeInputStateUnpressed)      |
            (enabled      ? OEThemeInputStateEnabled      : OEThemeInputStateDisabled)       |
            (focused      ? OEThemeInputStateFocused      : OEThemeInputStateUnfocused)      |
            (hover        ? OEThemeInputStateMouseOver    : OEThemeInputStateMouseOff)       |
            (state == NSOnState ? OEThemeInputStateToggleOn : (state == NSMixedState ? OEThemeInputStateToggleMixed : OEThemeInputStateToggleOff)));
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: states = [%@]>", [self className], [[_objectByState allKeys] componentsJoinedByString:@", "]];
}

- (void)OE_setValue:(id)value forState:(OEThemeState)state
{
    const NSUInteger  count      = [_states count];
    NSNumber         *stateValue = [NSNumber numberWithUnsignedInteger:state];
    NSUInteger        index      = 0;

    if(count)
    {
        index = [_states indexOfObject:stateValue inSortedRange:NSMakeRange(0, [_states count]) options:NSBinarySearchingFirstEqual | NSBinarySearchingInsertionIndex usingComparator:
                 ^ NSComparisonResult(id obj1, id obj2)
                 {
                     return [obj1 compare:obj2];
                 }];
    }

    if(((index == 0) && (count == 0)) || ((index < count) && ![[_states objectAtIndex:index] isEqualToNumber:stateValue])) [_states insertObject:stateValue atIndex:index];

    [_objectByState setValue:(value ?: [NSNull null]) forKey:OEKeyForState(state)];
}

- (id)objectForState:(OEThemeState)state
{
    OEThemeState maskedState = state & _stateMask;
    __block id results = nil;
    if(maskedState == 0)
    {
        results = [_objectByState objectForKey:OEKeyForState(OEThemeStateDefault)];
    }
    else
    {
        results = [_objectByState objectForKey:OEKeyForState(maskedState)];
        if(results == nil)
        {
            [_states enumerateObjectsUsingBlock:
             ^ (NSNumber *obj, NSUInteger idx, BOOL *stop)
             {
                 const OEThemeState state = [obj unsignedIntegerValue];
                 if((maskedState & state) == maskedState)
                 {
                     results = [_objectByState objectForKey:OEKeyForState(state)];
                     if(state != OEThemeStateDefault) [self OE_setValue:results forState:maskedState];
                     *stop = YES;
                 }
             }];

            if(results == nil) [self OE_setValue:[NSNull null] forState:maskedState];
        }
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

@end
