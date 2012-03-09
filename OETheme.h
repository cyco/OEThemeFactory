//
//  OETheme.h
//  OEThemeFactory
//
//  Created by Faustino Osuna on 2/26/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

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

@class OEThemeColor;
@class OEThemeTextAttributes;
@class OEThemeImage;
@class OEThemeGradient;

/*
 The theme manager is accessed using OETheme's singleton method +sharedTheme.  For example:
   [[OETheme sharedTheme] themeColorForKey:@"my color"];

 This singleton method is responsible for loading / parsing the Theme.plist file and maintaining the necessary UI
 elements to drive the application's interface.  The first call to +sharedTheme will instantiate all the necessary
 objects, therefore, it should be called as early on in the application's lifecycle as possible. If +sharedTheme fails
 to load then (in theory) the application should not be able to function.
 */
@interface OETheme : NSObject
{
@private
    NSMutableDictionary *_objectsByType;  // Storage location where the themed objects for the various types are stored
}

+ (id)sharedTheme;

- (OEThemeColor *)themeColorForKey:(NSString *)key;
- (NSColor *)colorForKey:(NSString *)key forState:(OEThemeState)state;

- (OEThemeTextAttributes *)themeTextAttributesForKey:(NSString *)key;
- (NSDictionary *)textAttributesForKey:(NSString *)key forState:(OEThemeState)state;

- (OEThemeImage *)themeImageForKey:(NSString *)key;
- (NSImage *)imageForKey:(NSString *)key forState:(OEThemeState)state;

- (OEThemeGradient *)themeGradientForKey:(NSString *)key;
- (NSGradient *)gradientForKey:(NSString *)key forState:(OEThemeState)state;

@end
