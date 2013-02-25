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
@synthesize window = _window;
@synthesize darkCheckBox = _darkCheckBox;
@synthesize glossCheckBox = _glossCheckBox;
@synthesize redHudButton = _redHudButton;
@synthesize popupButton = _popupButton;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [[_window contentView] setWantsLayer:YES];
    [[[_window contentView] layer] setBackgroundColor:[[NSColor colorWithDeviceWhite:0.25 alpha:1.0] CGColor]];

    [_popupButton setMenuStyle:OEMenuStyleLight];
}

- (IBAction)showMenu:(id)sender
{
    NSMenu *menu = [[NSMenu alloc] initWithTitle:@"Test"];
    [menu setMinimumWidth:500];

    [menu addItemWithTitle:@"Test 1" action:nil keyEquivalent:@""];

    NSMenuItem *item = [menu addItemWithTitle:@"Test X" action:nil keyEquivalent:@""];
    [item setKeyEquivalentModifierMask:NSShiftKeyMask];
    [item setAlternate:YES];
    [menu addItem:[NSMenuItem separatorItem]];

    [menu addItemWithTitle:@"Test 2" action:nil keyEquivalent:@""];
    [menu addItemWithTitle:@"Test 3" action:nil keyEquivalent:@""];
    [menu addItem:[NSMenuItem separatorItem]];
    [menu addItemWithTitle:@"Test 4" action:nil keyEquivalent:@""];
    [menu addItemWithTitle:@"Test 5" action:nil keyEquivalent:@""];
    [menu addItemWithTitle:@"Test 6" action:nil keyEquivalent:@""];
    [menu addItem:[NSMenuItem separatorItem]];
    [menu addItemWithTitle:@"Test 7" action:nil keyEquivalent:@""];
    [menu addItemWithTitle:@"Test 8" action:nil keyEquivalent:@""];
    [menu addItemWithTitle:@"Test 9" action:nil keyEquivalent:@""];
    [menu addItem:[NSMenuItem separatorItem]];
    [menu addItemWithTitle:@"Test 10" action:nil keyEquivalent:@""];
    [menu addItemWithTitle:@"Test 11" action:nil keyEquivalent:@""];
    [menu addItemWithTitle:@"Test 12" action:nil keyEquivalent:@""];
    [menu addItem:[NSMenuItem separatorItem]];
    [menu addItemWithTitle:@"Test 13" action:nil keyEquivalent:@""];
    [menu addItemWithTitle:@"Test 14" action:nil keyEquivalent:@""];
    [menu addItemWithTitle:@"Test 15" action:nil keyEquivalent:@""];
    [menu addItem:[NSMenuItem separatorItem]];
    [menu addItemWithTitle:@"Test 16" action:nil keyEquivalent:@""];
    [menu addItemWithTitle:@"Test 17" action:nil keyEquivalent:@""];
    [menu addItemWithTitle:@"Test 18" action:nil keyEquivalent:@""];

    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithUnsignedInteger:OEMaxYEdge], OEMenuOptionsArrowEdgeKey,
                             [NSNumber numberWithUnsignedInteger:OEMenuStyleDark], OEMenuOptionsStyleKey,
                             [NSValue valueWithSize:NSMakeSize(2000, 200)], OEMenuOptionsMaximumSizeKey,
                             nil];
    [OEMenu openMenu:menu withEvent:nil forView:sender options:options];
}

@end
