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
