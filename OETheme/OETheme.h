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

@class OEThemeColor;
@class OEThemeTextAttributes;
@class OEThemeImage;
@class OEThemeGradient;

/*
 The theme manager is accessed using OETheme's singleton method +sharedTheme.  For example:
   [[OETheme sharedTheme] themeColorForKey:@"my color"];

 This singleton method is responsible for loading / parsing the Theme.plist file and maintaining the necessary UI
 elements to drive the application's interface.  The first call to +sharedTheme will instantiate all the necessary
 objects, therefore, it should be called as early on in the application's lifecycle as possible. If +sharedTheme fails
 to load then (in theory) the application should not be able to function.
 */
@interface OETheme : NSObject
{
@private
    NSMutableDictionary *_objectsByType;  // Dictionary of themed object types
}

+ (id)sharedTheme;

- (OEThemeColor *)themeColorForKey:(NSString *)key;
- (NSColor *)colorForKey:(NSString *)key forState:(OEThemeState)state;

- (OEThemeTextAttributes *)themeTextAttributesForKey:(NSString *)key;
- (NSDictionary *)textAttributesForKey:(NSString *)key forState:(OEThemeState)state;

- (OEThemeImage *)themeImageForKey:(NSString *)key;
- (NSImage *)imageForKey:(NSString *)key forState:(OEThemeState)state;

- (OEThemeGradient *)themeGradientForKey:(NSString *)key;
- (NSGradient *)gradientForKey:(NSString *)key forState:(OEThemeState)state;

@end
