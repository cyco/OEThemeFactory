//
//  OEThemeGradientStates.h
//  OEThemeFactory
//
//  Created by Faustino Osuna on 3/3/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "OEThemeObject.h"

@interface NSGradient (OEThemeGradientAdditions)

- (void)drawInRect:(NSRect)rect;
- (void)drawInBezierPath:(NSBezierPath *)path;

@end

@interface OEThemeGradient : OEThemeObject

- (NSGradient *)gradientForState:(OEThemeState)state;

@end
