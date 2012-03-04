//
//  OETheme.h
//  OEThemeFactory
//
//  Created by Faustino Osuna on 2/26/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

enum
{
    OEThemeStateWindowInactive = 1 <<  0,
    OEThemeStateWindowActive   = 1 <<  1,
    OEThemeStateOff            = 1 <<  2,
    OEThemeStateOn             = 1 <<  3,
    OEThemeStateMixed          = 1 <<  4,
    OEThemeStateUnselected     = 1 <<  5,
    OEThemeStateSelected       = 1 <<  6,
    OEThemeStateDisabled       = 1 <<  7,
    OEThemeStateEnabled        = 1 <<  8,
    OEThemeStateUnfocused      = 1 <<  9,
    OEThemeStateFocused        = 1 << 10,
    OEThemeStateMouseOff       = 1 << 11,
    OEThemeStateMouseOver      = 1 << 12,
    OEThemeStateDefault        = 0xFFFF,
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
