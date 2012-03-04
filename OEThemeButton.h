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

@interface OEThemeButton : NSButton
{
@package
    NSUInteger _stateMask;

@private
    NSTrackingArea *_mouseTrackingArea;
}

- (void)setBackgroundThemeImageKey:(NSString *)key;
@property (nonatomic, retain) OEThemeImage *backgroundThemeImage;

@end

#pragma mark -

@interface OEImageButtonCell : NSButtonCell

- (OEThemeState)currentState;
- (NSRect)imageRectForButtonState:(OEThemeState)state;
- (BOOL)respondsToStateChangesForMask:(OEThemeState)mask;

@property (nonatomic, retain) OEThemeImage *backgroundThemeImage;

@end