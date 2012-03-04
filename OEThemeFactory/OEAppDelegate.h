//
//  OEAppDelegate.h
//  OEThemeFactory
//
//  Created by Faustino Osuna on 2/26/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "OEThemeButton.h"
#import "OEGradientView.h"

@interface OEAppDelegate : NSObject <NSApplicationDelegate>

@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet OEThemeButton *button1;
@property (assign) IBOutlet OEThemeButton *button2;
@property (assign) IBOutlet OEThemeButton *button3;
@property (assign) IBOutlet OEThemeButton *button4;
@property (assign) IBOutlet OEThemeButton *button5;
@property (assign) IBOutlet OEGradientView *view;

@end
