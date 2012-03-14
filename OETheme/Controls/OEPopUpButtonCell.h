//
//  OEThemePopUpButtonCell.h
//  OEThemeFactory
//
//  Created by Faustino Osuna on 3/10/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "OETheme.h"

@interface OEPopUpButtonCell : NSPopUpButtonCell
{
@private
    NSMutableParagraphStyle *_style;

    OEThemeImage          *_backgroundThemeImage;
    OEThemeImage          *_themeImage;
    OEThemeTextAttributes *_themeTextAttributes;
}

@property (nonatomic, readonly) OEThemeState stateMask;

@property (nonatomic, retain) OEThemeImage *backgroundThemeImage;
@property (nonatomic, retain) OEThemeImage *themeImage;
@property (nonatomic, retain) OEThemeTextAttributes *themeTextAttributes;

@end
