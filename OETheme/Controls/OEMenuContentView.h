//
//  OEMenuContentView.h
//  OEThemeFactory
//
//  Created by Faustino Osuna on 4/10/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "OEMenu.h"
#import "OETheme.h"

@interface OEMenuContentView : NSView
{
@private
    NSArray *_itemArray;                        // Array of NSMenu items
    BOOL     _needsLayout;                      // Flag used to notify that the menu item's frames should be invalidated
    NSSize   _intrinsicSize;                    // Full size of the component, does not account for min / max sizes

    NSUInteger _keyModifierMask;                // Aggregate mask of all the key modifiers used within the menu item (used to trim NSEvent's modifierFlags)
    NSUInteger _lasKeyModifierMask;             // Last NSEvent's modifierFlags

    NSImage               *_separatorImage;
    OEThemeGradient       *_backgroundGradient;
    OEThemeImage          *_tickImage;
    OEThemeTextAttributes *_textAttributes;
    OEThemeImage          *_submenuArrowImage;
}

@property(nonatomic, assign)   OEMenuStyle style;
@property(nonatomic, readonly) NSSize       intrinsicSize;
@property(nonatomic, retain)   NSArray     *itemArray;

@property(nonatomic, assign, getter = doesMenuContainImages) BOOL containImages;

@end
