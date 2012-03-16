//
//  OEAppDelegate.m
//  OEThemeFactory
//
//  Created by Faustino Osuna on 2/26/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "OEAppDelegate.h"
#import "OETheme.h"
#import "NSColor+OEAdditions.h"
#import "OEMenu.h"

@implementation OEAppDelegate
@synthesize menu = _menu;
@synthesize window = _window;
@synthesize darkCheckBox = _darkCheckBox;
@synthesize glossCheckBox = _glossCheckBox;
@synthesize popupButton = _popupButton;
@synthesize menuView = _menuView;
@synthesize menuWindow = _menuWindow;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [[_window contentView] setWantsLayer:YES];
    [[[_window contentView] layer] setBackgroundColor:[[NSColor colorWithDeviceWhite:0.25 alpha:1.0] CGColor]];

    [_darkCheckBox setThemeImageKey:@"dark_checkbox"];
    [_darkCheckBox setThemeTextAttributesKey:@"dark_checkbox"];

    [_glossCheckBox setThemeImageKey:@"gloss_checkbox"];
    [_glossCheckBox setThemeTextAttributesKey:@"gloss_checkbox"];

    [_popupButton setBackgroundThemeImageKey:@"dark_popupbutton"];
    [_popupButton setThemeTextAttributesKey:@"dark_popupbutton"];

    [_menuView setEdge:OEMinXEdge];
    [_menuView setMenu:[self menu]];
}

@end
