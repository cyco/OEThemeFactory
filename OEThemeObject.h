//
//  OEThemeItem.h
//  OEThemeFactory
//
//  Created by Faustino Osuna on 2/26/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>
#import "OETheme.h"

extern NSString * const OEThemeObjectStatesAttributeName;
extern NSString * const OEThemeObjectValueAttributeName;

@interface OEThemeObject : NSObject
{
@private
    NSMutableDictionary *_objectByState;
    NSMutableArray *_states;
}

- (id)initWithDefinition:(id)definition;
+ (id)parseWithDefinition:(id)definition inheritedDefinition:(id)inherited;

+ (OEThemeState)themeStateWithWindowActive:(BOOL)windowActive buttonState:(NSInteger)state selected:(BOOL)selected enabled:(BOOL)enabled focused:(BOOL)focused houseHover:(BOOL)hover;

- (id)objectForState:(OEThemeState)state;

- (void)setInContext:(CGContextRef)ctx withState:(OEThemeState)state;
- (void)setWithState:(OEThemeState)state;
- (void)setInLayer:(CALayer *)layer withState:(OEThemeState)state;

@property (nonatomic, readonly) OEThemeState stateMask;

@end
