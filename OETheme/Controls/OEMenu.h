//
//  OEMenu.h
//  OEThemeFactory
//
//  Created by Faustino Osuna on 3/14/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "OEMenuView.h"
#import "OEPopUpButton.h"

@interface OEMenu : NSWindow
{
@private
    OEMenuView *_view;
}

+ (OEMenu *)openMenuForPopUpButton:(OEPopUpButton *)button;
+ (OEMenu *)openMenu:(NSMenu *)menu arrowOnEdge:(OERectEdge)edge withRect:(NSRect)rect;

@property(nonatomic, assign) NSMenu *menu;

@end
