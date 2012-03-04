//
//  OETheme.h
//  OEThemeFactory
//
//  Created by Faustino Osuna on 2/26/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OEThemeObject.h"
#import "OEThemeColor.h"
#import "OEThemeTextAttributes.h"
#import "OEThemeImage.h"
#import "OEThemeGradient.h"

@class OEThemeObject;

@interface OETheme : NSObject
{
@private
    NSMutableDictionary *_itemsByType;
}

+ (id)sharedTheme;

- (OEThemeColor *)themeColorForKey:(NSString *)key;
- (NSColor *)colorForKey:(NSString *)key forState:(OEThemeState)state;

- (OEThemeTextAttributes *)themeTextAttributesForKey:(NSString *)key;
- (OETextAttributes *)textAttributesForKey:(NSString *)key forState:(OEThemeState)state;
- (NSFont *)fontForKey:(NSString *)key forState:(OEThemeState)state;
- (NSColor *)fontColorForKey:(NSString *)key forState:(OEThemeState)state;
- (NSShadow *)fontShadowForKey:(NSString *)key forState:(OEThemeState)state;

- (OEThemeImage *)themeImageForKey:(NSString *)key;
- (NSImage *)imageForKey:(NSString *)key forState:(OEThemeState)state;

- (OEThemeGradient *)themeGradientForKey:(NSString *)key;
- (NSGradient *)gradientForKey:(NSString *)key forState:(OEThemeState)state;

@end
