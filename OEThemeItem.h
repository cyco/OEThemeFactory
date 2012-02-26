//
//  OEThemeItem.h
//  OEThemeFactory
//
//  Created by Faustino Osuna on 2/26/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

enum
{
    OEThemeStateDefault        = 0 << 0,
    OEThemeStateWindowInactive = 1 << 0,
    OEThemeStateWindowActive   = 1 << 1,
    OEThemeStateOff            = 1 << 2,
    OEThemeStateOn             = 1 << 3,
    OEThemeStateMixed          = 1 << 4,
    OEThemeStateUnselected     = 1 << 5,
    OEThemeStateSelected       = 1 << 6,
    OEThemeStateDisabled       = 1 << 7,
    OEThemeStateEnabled        = 1 << 8,
    OEThemeStateUnfocused      = 1 << 9,
    OEThemeStateFocused        = 1 << 10,
    OEThemeStateMouseOver      = 1 << 11,
    OEThemeStateMouseOff       = 1 << 12,
};

enum
{
    OEThemeStateAnyWindowState   = 0x0003,
    OEThemeStateAnyActivityState = 0x001C,
    OEThemeStateAnySelection     = 0x0060,
    OEThemeStateAnyInteraction   = 0x0180,
    OEThemeStateAnyFocus         = 0x0600,
    OEThemeStateAnyMouseState    = 0x1800,
    OEThemeStateAnyState         = 0x07FF,
};

typedef NSUInteger OEThemeState;

extern NSString * const OEThemeItemStatesAttributeName;
extern NSString * const OEThemeItemValueAttributeName;

extern NSString *NSStringFromThemeState(OEThemeState state);
extern OEThemeState OEThemeStateFromString(NSString *state);

@interface OEThemeItem : NSObject
{
@private
    NSDictionary *_itemByState;
}

- (id)initWithDefinition:(id)definition;
+ (id)parseWithDefinition:(id)definition inheritedDefinition:(id)inherited;

- (id)itemForState:(OEThemeState)state;

@end
