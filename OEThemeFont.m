//
//  OEThemeFont.m
//  OEThemeFactory
//
//  Created by Faustino Osuna on 2/26/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "OEThemeFont.h"
#import "OEFont.h"

@implementation OEThemeFont

+ (id)parseWithDefinition:(id)definition inheritedDefinition:(NSDictionary *)inherited
{
    id result = nil;
    if([definition isKindOfClass:[NSDictionary class]])
    {
        NSMutableDictionary *newDefinition = nil;
        if(inherited)
        {
            newDefinition = [inherited mutableCopy];
            [newDefinition setValuesForKeysWithDictionary:definition];
        }
        else
        {
            newDefinition = [definition mutableCopy];
        }

        result = [[OEFont alloc] initWithDictionary:newDefinition];
    }
    else
        result = nil;
    return result;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %@>", [self className], [[self itemForState:OEThemeStateDefault] description]];
}

@end
