//
//  OEThemeGradientStates.h
//  OEThemeFactory
//
//  Created by Faustino Osuna on 3/3/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "OEThemeItemStates.h"

@interface OEThemeGradientStates : OEThemeItemStates

- (NSGradient *)gradientForState:(OEThemeState)state;

@end
