//
//  OETheme.h
//  OEThemeFactory
//
//  Created by Faustino Osuna on 2/26/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OEThemeItem;

@interface OETheme : NSObject
{
@private
    NSMutableDictionary *_itemsByType;
}

+ (id)sharedTheme;

- (id)colorForKey:(NSString *)key;
- (id)fontForKey:(NSString *)key;

@end
