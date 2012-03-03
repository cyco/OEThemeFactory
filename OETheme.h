//
//  OETheme.h
//  OEThemeFactory
//
//  Created by Faustino Osuna on 2/26/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OEThemeColorStates.h"
#import "OEThemeFontStates.h"
#import "OEThemeImageStates.h"
#import "OEThemeGradientStates.h"

@class OEThemeItemStates;

@interface OETheme : NSObject
{
@private
    NSMutableDictionary *_itemsByType;
}

+ (id)sharedTheme;

- (OEThemeColorStates *)colorStatesForKey:(NSString *)key;
- (NSColor *)colorForKey:(NSString *)key forState:(OEThemeState)state;

- (OEThemeFontStates *)fontStatesForKey:(NSString *)key;
- (OEThemeFont *)themeFontForKey:(NSString *)key forState:(OEThemeState)state;
- (NSFont *)fontForKey:(NSString *)key forState:(OEThemeState)state;
- (NSColor *)fontColorForKey:(NSString *)key forState:(OEThemeState)state;
- (NSShadow *)fontShadowForKey:(NSString *)key forState:(OEThemeState)state;

- (OEThemeImageStates *)imageStatesForKey:(NSString *)key;
- (NSImage *)imageForKey:(NSString *)key forState:(OEThemeState)state;

- (OEThemeGradientStates *)gradientStatesForKey:(NSString *)key;
- (NSGradient *)gradientForKey:(NSString *)key forState:(OEThemeState)state;

@end
