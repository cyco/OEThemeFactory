//
//  OEGradientView.h
//  OEThemeFactory
//
//  Created by Faustino Osuna on 3/4/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "OETheme.h"

@interface OEGradientView : NSView
{
@private
    NSUInteger _cachedStateMask;
    OEThemeGradient *_themeGradient;
    NSTrackingArea *_mouseTrackingArea;
}

- (void)setThemeGradientKey:(NSString *)key;
@property(nonatomic, retain) OEThemeGradient *themeGradient;

@end
