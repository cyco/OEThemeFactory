//
//  OEThemeItem.h
//  OEThemeFactory
//
//  Created by Faustino Osuna on 2/26/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>

/*
 The following available state inputs that a state mask is composed of:
 - Window Activity
 - Toggle State
 - Pressed State
 - Interaction State
 - Mouse State

 When all 5 state inputs are either zero's (0x0000) or ones (0xFFFF), it is considered a default state mask. When a
 looking for the most appropriate object, based a system's state, the default state mask is used if no other state mask
 could be found.
 */
enum
{
    OEThemeInputStateWindowInactive = 1 <<  0,
    OEThemeInputStateWindowActive   = 1 <<  1,
    OEThemeInputStateToggleOff      = 1 <<  2,
    OEThemeInputStateToggleOn       = 1 <<  3,
    OEThemeInputStateToggleMixed    = 1 <<  4,
    OEThemeInputStateUnpressed      = 1 <<  5,
    OEThemeInputStatePressed        = 1 <<  6,
    OEThemeInputStateDisabled       = 1 <<  7,
    OEThemeInputStateEnabled        = 1 <<  8,
    OEThemeInputStateUnfocused      = 1 <<  9,
    OEThemeInputStateFocused        = 1 << 10,
    OEThemeInputStateMouseOff       = 1 << 11,
    OEThemeInputStateMouseOver      = 1 << 12,
};

/*
 In the Theme.plist you can define an 'Any' input state for input states that should be ignored when determining which
 object to apply.  'Any' input states can be set explicitly, if an input state is unspecified then the 'Any' mask is
 set implicitly.
 */
enum
{
    OEThemeStateAnyWindowActivity = OEThemeInputStateWindowInactive | OEThemeInputStateWindowActive,
    OEThemeStateAnyToggle         = OEThemeInputStateToggleOff      | OEThemeInputStateToggleOn      | OEThemeInputStateToggleMixed,
    OEThemeStateAnySelection      = OEThemeInputStateUnpressed      | OEThemeInputStatePressed,
    OEThemeStateAnyInteraction    = OEThemeInputStateDisabled       | OEThemeInputStateEnabled,
    OEThemeStateAnyFocus          = OEThemeInputStateUnfocused      | OEThemeInputStateFocused,
    OEThemeStateAnyMouse          = OEThemeInputStateMouseOff       | OEThemeInputStateMouseOver,
    OEThemeStateDefault           = 0xFFFF,
};
typedef NSUInteger OEThemeState;

// Retrieves an NSString from an OEThemeState
extern NSString     *NSStringFromThemeState(OEThemeState state);

// Parses an NSString into an OEThemeState, the NSString is a comma separated list of tokens. The order of the token's
// appearance has no effect on the final value.
extern OEThemeState  OEThemeStateFromString(NSString *state);

extern NSString * const OEThemeObjectStatesAttributeName;
extern NSString * const OEThemeObjectValueAttributeName;

@interface OEThemeObject : NSObject
{
@private
    NSMutableDictionary *_objectByState;  // State table
    NSMutableArray *_states;              // Used for implicit selection of object for desired state
}

- (id)initWithDefinition:(id)definition;

// Must be overridden by subclasses to be able to parse customized UI element
+ (id)parseWithDefinition:(NSDictionary *)definition;

// Convenience function for retrieving an OEThemeState based on the supplied inputs
+ (OEThemeState)themeStateWithWindowActive:(BOOL)windowActive buttonState:(NSCellStateValue)state selected:(BOOL)selected enabled:(BOOL)enabled focused:(BOOL)focused houseHover:(BOOL)hover;

// Retrieves UI object for state specified
- (id)objectForState:(OEThemeState)state;

// Aggregate mask that filters out any unspecified state input
@property (nonatomic, readonly) NSUInteger stateMask;

@end
