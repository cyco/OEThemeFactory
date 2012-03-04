//
//  OEThemeItem.m
//  OEThemeFactory
//
//  Created by Faustino Osuna on 2/26/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "OEThemeObject.h"

NSString * const OEThemeObjectStatesAttributeName         = @"States";
NSString * const OEThemeObjectValueAttributeName          = @"Value";

static inline NSString *OEKeyForState(OEThemeState state)
{
    return [NSString stringWithFormat:@"0x%04x", state];
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
            NSMutableDictionary *rootDefinition = [definition mutableCopy];
            [rootDefinition removeObjectForKey:OEThemeObjectStatesAttributeName];
            [self OE_setValue:[isa parseWithDefinition:rootDefinition inheritedDefinition:nil] forState:OEThemeStateDefault];

            NSDictionary *states = [definition valueForKey:OEThemeObjectStatesAttributeName];
            if([states isKindOfClass:[NSDictionary class]])
            {
                [states enumerateKeysAndObjectsUsingBlock:
                 ^(id key, id obj, BOOL *stop)
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
                if(_stateMask & OEThemeStateAnyWindowActivityMask) _stateMask |= OEThemeStateAnyWindowActivityMask;
                if(_stateMask & OEThemeStateAnyStateMask)          _stateMask |= OEThemeStateAnyStateMask;
                if(_stateMask & OEThemeStateAnySelectionMask)      _stateMask |= OEThemeStateAnySelectionMask;
                if(_stateMask & OEThemeStateAnyInteractionMask)    _stateMask |= OEThemeStateAnyInteractionMask;
                if(_stateMask & OEThemeStateAnyFocusMask)          _stateMask |= OEThemeStateAnyFocusMask;
                if(_stateMask & OEThemeStateAnyMouseMask)          _stateMask |= OEThemeStateAnyMouseMask;
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
    return ((windowActive ? OEThemeStateWindowActive : OEThemeStateWindowInactive) |
            (selected     ? OEThemeStateSelected     : OEThemeStateUnselected)     |
            (enabled      ? OEThemeStateEnabled      : OEThemeStateDisabled)       |
            (focused      ? OEThemeStateFocused      : OEThemeStateUnfocused)      |
            (hover        ? OEThemeStateMouseOver    : OEThemeStateMouseOff)       |
            (state == NSOnState ? OEThemeStateOn : (state == NSMixedState ? OEThemeStateMixed : OEThemeStateOff)));
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
    if(maskedState == 0) return [_objectByState valueForKey:OEKeyForState(OEThemeStateDefault)];

    __block id results = [_objectByState valueForKey:OEKeyForState(maskedState)];
    if(results == nil)
    {
        [_states enumerateObjectsUsingBlock:
         ^(NSNumber *obj, NSUInteger idx, BOOL *stop) {
            if(([obj unsignedIntegerValue] & maskedState) == maskedState)
            {
                results = [_objectByState valueForKey:OEKeyForState([obj unsignedIntegerValue])];
                if(state != OEThemeStateDefault) [self OE_setValue:results forState:maskedState];
                *stop = YES;
            }
         }];

        if(results == nil) [self OE_setValue:[NSNull null] forState:maskedState];
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
