//
//  OEThemePopUpButton.h
//  OEThemeFactory
//
//  Created by Faustino Osuna on 3/10/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "OEPopUpButtonCell.h"
#import "OEMenu.h"

@interface OEPopUpButton : NSPopUpButton
{
@private
    NSTrackingArea *_mouseTrackingArea;

    BOOL _shouldTrackWindowActivity;
    BOOL _shouldTrackMouseActivity;
}

- (void)setBackgroundThemeImageKey:(NSString *)key;
- (void)setThemeImageKey:(NSString *)key;
- (void)setThemeTextAttributesKey:(NSString *)key;

@property(nonatomic, retain) OEThemeImage *backgroundThemeImage;
@property(nonatomic, retain) OEThemeImage *themeImage;
@property(nonatomic, retain) OEThemeTextAttributes *themeTextAttributes;
@property(nonatomic, assign) OEMenuStyle menuStyle;

@end
