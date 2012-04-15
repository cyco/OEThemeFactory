//
//  OEThemeButtonCell.h
//  OEThemeFactory
//
//  Created by Faustino Osuna on 3/10/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "OETheme.h"

@interface OEButtonCell : NSButtonCell
{
@private
    NSMutableParagraphStyle *_style;  // Cached paragraph style used to render text
    BOOL                     _themed; // Identifies that the object is themed
}

@property (nonatomic, readonly) OEThemeState stateMask;

@property (nonatomic, retain) OEThemeImage          *backgroundThemeImage;
@property (nonatomic, retain) OEThemeImage          *themeImage;
@property (nonatomic, retain) OEThemeTextAttributes *themeTextAttributes;

@end