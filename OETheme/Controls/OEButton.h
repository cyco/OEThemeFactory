//
//  OEImageButton.h
//  OEThemeFactory
//
//  Created by Faustino Osuna on 3/3/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "OEButtonCell.h"

@interface OEButton : NSButton
{
@private
    NSTrackingArea *_trackingArea;   // Mouse tracking area used only if the control reacts to the mouse's location

    BOOL _shouldTrackWindowActivity; // Identifies if control reacts to change a window's keyedness
    BOOL _shouldTrackMouseActivity;  // Identifies if control reacts to the mouse's location
}

- (void)setBackgroundThemeImageKey:(NSString *)key;
- (void)setThemeImageKey:(NSString *)key;
- (void)setThemeTextAttributesKey:(NSString *)key;

@property (nonatomic, retain) OEThemeImage          *backgroundThemeImage;
@property (nonatomic, retain) OEThemeImage          *themeImage;
@property (nonatomic, retain) OEThemeTextAttributes *themeTextAttributes;

@end
