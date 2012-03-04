//
//  OEThemeColor.h
//  OEThemeFactory
//
//  Created by Faustino Osuna on 2/26/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "OEThemeObject.h"

extern NSColor *NSColorFromString(NSString *colorString);

@interface OEThemeColor : OEThemeObject

- (NSColor *)colorForState:(OEThemeState)state;

- (void)setFillInContext:(CGContextRef)ctx withState:(OEThemeState)state;
- (void)setStrokeInContext:(CGContextRef)ctx withState:(OEThemeState)state;
- (void)setFillWithState:(OEThemeState)state;
- (void)setStrokeWithState:(OEThemeState)state;

@end
