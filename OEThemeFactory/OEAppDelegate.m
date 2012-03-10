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
@synthesize darkCheckBox = _darkCheckBox;
@synthesize glossCheckBox = _glossCheckBox;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [_darkCheckBox setThemeImageKey:@"dark_checkbox"];
    [_darkCheckBox setThemeTextAttributesKey:@"dark_checkbox"];

    [_glossCheckBox setThemeImageKey:@"gloss_checkbox"];
    [_glossCheckBox setThemeTextAttributesKey:@"gloss_checkbox"];
}

@end
