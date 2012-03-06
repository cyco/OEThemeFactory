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
    OEThemeStateWindowInactive = 1 <<  0,
    OEThemeStateWindowActive   = 1 <<  1,
    OEThemeStateToggleOff      = 1 <<  2,
    OEThemeStateToggleOn       = 1 <<  3,
    OEThemeStateToggleMixed    = 1 <<  4,
    OEThemeStateUnpressed      = 1 <<  5,
    OEThemeStatePressed        = 1 <<  6,
    OEThemeStateDisabled       = 1 <<  7,
    OEThemeStateEnabled        = 1 <<  8,
    OEThemeStateUnfocused      = 1 <<  9,
    OEThemeStateFocused        = 1 << 10,
    OEThemeStateMouseOff       = 1 << 11,
    OEThemeStateMouseOver      = 1 << 12,
};
typedef NSUInteger OEThemeState;

enum
{
    OEThemeStateAnyWindowActivityMask = OEThemeStateWindowInactive | OEThemeStateWindowActive,
    OEThemeStateAnyToggleMask         = OEThemeStateToggleOff      | OEThemeStateToggleOn      | OEThemeStateToggleMixed,
    OEThemeStateAnySelectionMask      = OEThemeStateUnpressed      | OEThemeStatePressed,
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
