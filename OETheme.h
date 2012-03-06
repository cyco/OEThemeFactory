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
    OEThemeStateWindowInactive = 1 <<  0,  // Parent window inactive
    OEThemeStateWindowActive   = 1 <<  1,  // Parent window active
    OEThemeStateOff            = 1 <<  2,  // Toggle off
    OEThemeStateOn             = 1 <<  3,  // Toggle on
    OEThemeStateMixed          = 1 <<  4,  // Toggle mixed
    OEThemeStateUnselected     = 1 <<  5,  // Unpressed
    OEThemeStateSelected       = 1 <<  6,  // Pressed
    OEThemeStateDisabled       = 1 <<  7,  // Disabled
    OEThemeStateEnabled        = 1 <<  8,  // Enabled
    OEThemeStateUnfocused      = 1 <<  9,  // Is not first responder
    OEThemeStateFocused        = 1 << 10,  // Is first responder
    OEThemeStateMouseOff       = 1 << 11,  // Mouse not hovering
    OEThemeStateMouseOver      = 1 << 12,  // Mouse hovering
};
typedef NSUInteger OEThemeState;

enum
{
    OEThemeStateAnyWindowActivityMask = OEThemeStateWindowInactive | OEThemeStateWindowActive,
    OEThemeStateAnyStateMask          = OEThemeStateOff            | OEThemeStateOn             | OEThemeStateMixed,
    OEThemeStateAnySelectionMask      = OEThemeStateUnselected     | OEThemeStateSelected,
    OEThemeStateAnyInteractionMask    = OEThemeStateDisabled       | OEThemeStateEnabled,
    OEThemeStateAnyFocusMask          = OEThemeStateUnfocused      | OEThemeStateFocused,
    OEThemeStateAnyMouseMask          = OEThemeStateMouseOff       | OEThemeStateMouseOver,
    OEThemeStateDefaultMask           = 0xFFFF,
};

extern NSString     *NSStringFromThemeState(OEThemeState state);
extern OEThemeState  OEThemeStateFromString(NSString *state);

@class OEThemeColor;
@class OEThemeTextAttributes;
@class OEThemeImage;
@class OEThemeGradient;

@interface OETheme : NSObject
{
@private
    NSMutableDictionary *_objectsByType;
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
