//
//  OEThemeColor.h
//  OEThemeFactory
//
//  Created by Faustino Osuna on 2/26/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "OEThemeItemStates.h"

extern NSColor *NSColorFromString(NSString *colorString);

@interface OEThemeColorStates : OEThemeItemStates

- (NSColor *)colorForState:(OEThemeState)state;

- (void)setFillInContext:(CGContextRef)ctx withState:(OEThemeState)state;
- (void)setStrokeInContext:(CGContextRef)ctx withState:(OEThemeState)state;
- (void)setFillWithState:(OEThemeState)state;
- (void)setStrokeWithState:(OEThemeState)state;

@end
