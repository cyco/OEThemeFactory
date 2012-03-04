//
//  OEThemeImageStates.h
//  OEThemeFactory
//
//  Created by Faustino Osuna on 2/27/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "OEThemeObject.h"

@interface OEThemeImage : OEThemeObject

- (NSImage *)imageForState:(OEThemeState)state;

@end
