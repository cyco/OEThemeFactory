//
//  OEAppDelegate.m
//  OEThemeFactory
//
//  Created by Faustino Osuna on 2/26/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "OEAppDelegate.h"
#import "OETheme.h"
#import "OEThemeItemStates.h"

@implementation OEAppDelegate

@synthesize window = _window;
@synthesize button1 = _button1;
@synthesize button2 = _button2;
@synthesize button3 = _button3;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    NSLog(@"%@", [[OETheme sharedTheme] colorStatesForKey:@"color1"]);
    [_button1 setImageStatesThemeKey:@"image1"];
    [_button2 setImageStatesThemeKey:@"image2"];
    [_button3 setImageStatesThemeKey:@"image3"];
}

@end
