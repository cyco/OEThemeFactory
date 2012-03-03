//
//  OEThemeItem.h
//  OEThemeFactory
//
//  Created by Faustino Osuna on 2/26/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>

enum
{
    OEThemeStateWindowInactive   = 1 <<  0,
    OEThemeStateWindowActive     = 1 <<  1,
    OEThemeStateOff              = 1 <<  2,
    OEThemeStateOn               = 1 <<  3,
    OEThemeStateMixed            = 1 <<  4,
    OEThemeStateUnselected       = 1 <<  5,
    OEThemeStateSelected         = 1 <<  6,
    OEThemeStateDisabled         = 1 <<  7,
    OEThemeStateEnabled          = 1 <<  8,
    OEThemeStateUnfocused        = 1 <<  9,
    OEThemeStateFocused          = 1 << 10,
    OEThemeStateMouseOff         = 1 << 11,
    OEThemeStateMouseOver        = 1 << 12,
    OEThemeStateDefault          = 0xFFFF,
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

extern NSString * const OEThemeItemStatesAttributeName;
extern NSString * const OEThemeItemValueAttributeName;

extern NSString     *NSStringFromThemeState(OEThemeState state);
extern OEThemeState  OEThemeStateFromString(NSString *state);

@interface OEThemeItemStates : NSObject
{
@private
    NSMutableDictionary *_itemByState;
    NSMutableArray *_states;
}

- (id)initWithDefinition:(id)definition;
+ (id)parseWithDefinition:(id)definition inheritedDefinition:(id)inherited;

+ (OEThemeState)themeStateWithWindowActive:(BOOL)windowActive buttonState:(NSInteger)state selected:(BOOL)selected enabled:(BOOL)enabled focused:(BOOL)focused houseHover:(BOOL)hover;

- (id)itemForState:(OEThemeState)state;

- (void)setInContext:(CGContextRef)ctx withState:(OEThemeState)state;
- (void)setWithState:(OEThemeState)state;
- (void)setInLayer:(CALayer *)layer withState:(OEThemeState)state;

@property (nonatomic, readonly) NSUInteger stateMask;

@end
