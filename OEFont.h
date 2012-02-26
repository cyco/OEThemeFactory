//
//  OEFont.h
//  OEThemeFactory
//
//  Created by Faustino Osuna on 2/26/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OEFont : NSObject

- (id)initWithDictionary:(NSDictionary *)dictionary;

@property(nonatomic, readonly) NSFont   *font;
@property(nonatomic, readonly) NSColor  *color;
@property(nonatomic, readonly) NSShadow *shadow;

@end
