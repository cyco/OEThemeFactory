//
//  OEImageButton.h
//  OEThemeFactory
//
//  Created by Faustino Osuna on 3/3/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "OETheme.h"
#import "OEThemeObject.h"
#import "OEThemeImage.h"
#import "OEThemeTextAttributes.h"

@interface OEThemeButton : NSButton
{
@package
    NSUInteger _cachedStateMask;

@private
    NSTrackingArea *_mouseTrackingArea;
}

- (void)setBackgroundThemeImageKey:(NSString *)key;
- (void)setThemeTextAttributesKey:(NSString *)key;

@property (nonatomic, retain) OEThemeImage *backgroundThemeImage;
@property (nonatomic, retain) OEThemeTextAttributes *themeTextAttributes;

@end

#pragma mark -

@interface OEThemeButtonCell : NSButtonCell
{
@private
    NSMutableParagraphStyle *_style;
}

@property (nonatomic, retain) OEThemeImage *backgroundThemeImage;
@property (nonatomic, retain) OEThemeTextAttributes *themeTextAttributes;

@end