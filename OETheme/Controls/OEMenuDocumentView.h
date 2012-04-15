//
//  OEMenuDocumentView.h
//  OEThemeFactory
//
//  Created by Faustino Osuna on 4/10/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "OEMenu.h"
#import "OETheme.h"

@interface OEMenuDocumentView : NSView
{
@private
    BOOL   _containImages;           // Flag used to determine menu item height, if there are no images we use a smaller height
    BOOL   _needsLayout;             // Flag used to notify that the menu item's frames should be invalidated
    NSSize _intrinsicSize;           // Natural size of the menu items

    NSUInteger _keyModifierMask;     // Aggregate mask of all the key modifiers used within the menu item (used to trim NSEvent's modifierFlags)
    NSUInteger _lastKeyModifierMask; // Last NSEvent's modifierFlags

    // Themed elements
    NSImage               *_separatorImage;
    OEThemeGradient       *_backgroundGradient;
    OEThemeImage          *_tickImage;
    OEThemeTextAttributes *_textAttributes;
    OEThemeImage          *_submenuArrowImage;
}

@property(nonatomic, retain)   NSArray     *itemArray;
@property(nonatomic, assign)   OEMenuStyle  style;
@property(nonatomic, readonly) NSSize       intrinsicSize;

@end
