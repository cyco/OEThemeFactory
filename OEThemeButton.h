//
//  OEImageButton.h
//  OEThemeFactory
//
//  Created by Faustino Osuna on 3/3/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "OEThemeButtonCell.h"

@interface OEThemeButton : NSButton
{
@private
    NSTrackingArea *_mouseTrackingArea;

    BOOL _shouldTrackWindowActivity;
    BOOL _shouldTrackMouseActivity;
}

- (void)setBackgroundThemeImageKey:(NSString *)key;
- (void)setThemeImageKey:(NSString *)key;
- (void)setThemeTextAttributesKey:(NSString *)key;

@property (nonatomic, retain) OEThemeImage *backgroundThemeImage;
@property (nonatomic, retain) OEThemeImage *themeImage;
@property (nonatomic, retain) OEThemeTextAttributes *themeTextAttributes;

@end
