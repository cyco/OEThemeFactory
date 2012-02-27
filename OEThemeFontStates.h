//
//  OEThemeFont.h
//  OEThemeFactory
//
//  Created by Faustino Osuna on 2/26/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "OEThemeItemStates.h"
#import "OEThemeFont.h"

@interface OEThemeFontStates : OEThemeItemStates

- (OEThemeFont *)themeFontForState:(OEThemeState)state;

@end
