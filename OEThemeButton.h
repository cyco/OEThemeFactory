//
//  OEImageButton.h
//  OEThemeFactory
//
//  Created by Faustino Osuna on 3/3/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "OETheme.h"
#import "OEThemeItemStates.h"

@interface OEThemeButton : NSButton
{
@package
    NSUInteger _stateMask;

@private
    NSTrackingArea *_mouseTrackingArea;
}

- (void)setImageStatesThemeKey:(NSString *)key;
@property (nonatomic, retain) OEThemeImageStates *imageStates;

@end

#pragma mark -

@interface OEImageButtonCell : NSButtonCell

- (NSRect)imageRectForButtonState:(OEThemeState)state;
- (BOOL)respondsToStateChangesForMask:(OEThemeState)mask;


@property (nonatomic, retain) OEThemeImageStates *imageStates;

@end