//
//  OEAppDelegate.m
//  OEThemeFactory
//
//  Created by Faustino Osuna on 2/26/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "OEAppDelegate.h"
#import "OETheme.h"
#import "OEThemeObject.h"

@implementation OEAppDelegate

@synthesize window = _window;
@synthesize button1 = _button1;
@synthesize button2 = _button2;
@synthesize button3 = _button3;
@synthesize button4 = _button4;
@synthesize button5 = _button5;
@synthesize view = _view;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    NSLog(@"%@", [[OETheme sharedTheme] themeGradientForKey:@"gradient1"]);
    [_button1 setBackgroundThemeImageKey:@"image1"];
    [_button2 setBackgroundThemeImageKey:@"image2"];
    [_button3 setBackgroundThemeImageKey:@"image3"];
    [_button4 setBackgroundThemeImageKey:@"gloss_blue"];
    [_button4 setThemeTextAttributesKey:@"gloss_blue"];
    [_button5 setThemeTextAttributesKey:@"weblink_arrow"];
    [_button5 setThemeImageKey:@"weblink_arrow"];
    [_view setThemeGradientKey:@"gradient1"];
}

@end
