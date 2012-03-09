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
    NSMutableDictionary *_objectByState;  // State table
    NSMutableArray *_states;              // Used for implicit selection of object for desired state
}

- (id)initWithDefinition:(id)definition;

// Must be overridden by subclasses to be able to parse customized UI element
+ (id)parseWithDefinition:(NSDictionary *)definition;

// Convenience function for retrieving an OEThemeState based on the supplied inputs
+ (OEThemeState)themeStateWithWindowActive:(BOOL)windowActive buttonState:(NSInteger)state selected:(BOOL)selected enabled:(BOOL)enabled focused:(BOOL)focused houseHover:(BOOL)hover;

// Retrieves UI object for state specified
- (id)objectForState:(OEThemeState)state;

// Aggregate mask that filters out any unspecified state input
@property (nonatomic, readonly) NSUInteger stateMask;

@end
