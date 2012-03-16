//
//  OEAppDelegate.h
//  OEThemeFactory
//
//  Created by Faustino Osuna on 2/26/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "OEButton.h"
#import "OEPopUpButton.h"

@interface OEAppDelegate : NSObject <NSApplicationDelegate, NSMenuDelegate>

@property(assign) IBOutlet NSWindow *window;
@property(assign) IBOutlet OEButton *darkCheckBox;
@property(assign) IBOutlet OEButton *glossCheckBox;
@property(assign) IBOutlet OEButton *redHudButton;
@property(assign) IBOutlet OEPopUpButton *popupButton;

- (IBAction)showMenu:(id)sender;

@end
