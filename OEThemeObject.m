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
    // Implicitly define a zero state as the default state
    return [NSNumber numberWithUnsignedInteger:(state == 0 ? OEThemeStateDefault : state)];
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
            // Create a root definition that can be inherited by the states specified
            NSMutableDictionary *rootDefinition = [definition mutableCopy];
            [rootDefinition removeObjectForKey:OEThemeObjectStatesAttributeName];
            [self OE_setValue:[isa parseWithDefinition:rootDefinition] forState:OEThemeStateDefault];

            // Iterate through each of the state descriptions and create a state table
            NSDictionary *states = [definition valueForKey:OEThemeObjectStatesAttributeName];
            if([states isKindOfClass:[NSDictionary class]])
            {
                [states enumerateKeysAndObjectsUsingBlock:
                 ^ (id key, id obj, BOOL *stop)
                 {
                     NSMutableDictionary *newDefinition = [rootDefinition mutableCopy];
                     if([obj isKindOfClass:[NSDictionary class]]) [newDefinition setValuesForKeysWithDictionary:obj];
                     else                                         [newDefinition setValue:obj forKey:OEThemeObjectValueAttributeName];

                     NSString     *trimmedKey = [key stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                     OEThemeState  state      = ([trimmedKey length] == 0 ? OEThemeStateDefault : OEThemeStateFromString(trimmedKey));
                     id            value      = [isa parseWithDefinition:newDefinition];
                     [self OE_setValue:value forState:state];

                     // Append the state to the state mask
                     if(state != OEThemeStateDefault) _stateMask |= state;
                 }];
            }

            if(_stateMask != OEThemeStateDefault)
            {
                // Aggregate the bit-mask that all the state's cover
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
                         // Implicitly set any unspecified input state with it's wild card counter part
                         if(!(state & OEThemeStateAnyWindowActivity)) state |= OEThemeStateAnyWindowActivity;
                         if(!(state & OEThemeStateAnyToggle))         state |= OEThemeStateAnyToggle;
                         if(!(state & OEThemeStateAnySelection))      state |= OEThemeStateAnySelection;
                         if(!(state & OEThemeStateAnyInteraction))    state |= OEThemeStateAnyInteraction;
                         if(!(state & OEThemeStateAnyFocus))          state |= OEThemeStateAnyFocus;
                         if(!(state & OEThemeStateAnyMouse))          state |= OEThemeStateAnyMouse;

                         // Trim bits not specified in the state mask
                         state &= _stateMask;

                         // Update state table if the state was modified
                         if(state != [obj unsignedIntegerValue])
                         {
                             [_objectByState setValue:[_objectByState objectForKey:obj] forKey:OEKeyForState(state)];
                             [_objectByState removeObjectForKey:obj];
                             updateStates = YES;
                         }
                     }
                 }];

                // If the state table was modified then get a sorted list of states that can be used by -objectForState:
                if(updateStates) _states = [[[_objectByState allKeys] sortedArrayUsingSelector:@selector(compare:)] mutableCopy];
            }
        }
        else
        {
            NSDictionary *newDefinition = [NSDictionary dictionaryWithObject:definition forKey:OEThemeObjectValueAttributeName];
            [self OE_setValue:[isa parseWithDefinition:newDefinition] forState:OEThemeStateDefault];
        }
    }
    return self;
}

+ (id)parseWithDefinition:(id)definition
{
    // It is critical that the subclass implements this method
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

+ (OEThemeState)themeStateWithWindowActive:(BOOL)windowActive buttonState:(NSCellStateValue)state selected:(BOOL)selected enabled:(BOOL)enabled focused:(BOOL)focused houseHover:(BOOL)hover
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
    // Assign the state look up table
    [_objectByState setValue:(value ?: [NSNull null]) forKey:OEKeyForState(state)];

    // Insert the state in the states array (while maintaining a sorted array)
    const NSUInteger  count      = [_states count];
    NSNumber         *stateValue = [NSNumber numberWithUnsignedInteger:state];

    if(count > 0)
    {
        NSUInteger index = [_states indexOfObject:stateValue inSortedRange:NSMakeRange(0, [_states count]) options:NSBinarySearchingFirstEqual | NSBinarySearchingInsertionIndex usingComparator:
                            ^ NSComparisonResult(id obj1, id obj2)
                            {
                                return [obj1 compare:obj2];
                            }];

        if(![[_states objectAtIndex:index] isEqualToNumber:stateValue]) [_states insertObject:stateValue atIndex:index];
    }
    else
    {
        [_states addObject:stateValue];
    }
}

- (id)objectForState:(OEThemeState)state
{
    OEThemeState maskedState = state & _stateMask; // Trim unused bits
    __block id   results     = nil;

    if(maskedState == 0)
    {
        results = [_objectByState objectForKey:OEKeyForState(OEThemeStateDefault)];
    }
    else
    {
        // Return object explicitly defined by state
        results = [_objectByState objectForKey:OEKeyForState(maskedState)];
        if(results == nil)
        {
            // Try to implicitly determine what object represents the supplied state
            [_states enumerateObjectsUsingBlock:
             ^ (NSNumber *obj, NSUInteger idx, BOOL *stop)
             {
                 const OEThemeState state = [obj unsignedIntegerValue];
                 if((maskedState & state) == maskedState)
                 {
                     // This state is the best we are going to get for the requested state
                     results = [_objectByState objectForKey:OEKeyForState(state)];

                     // Explicitly set the state table to contain the requested state to the object we have just implicitly discovered
                     if(state != 0 && state != OEThemeStateDefault) [self OE_setValue:results forState:maskedState];
                     *stop = YES;
                 }
             }];

            // If no object was found, then explicitly set it to Null, so the next time we try to obtain an object for the specified state we will quickly return nil
            if(results == nil) [self OE_setValue:[NSNull null] forState:maskedState];
        }
    }

    // Return nil vice [NSNull null]
    return (results == [NSNull null] ? nil : results);
}

@end
