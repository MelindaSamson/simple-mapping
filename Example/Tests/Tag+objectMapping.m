//
//  Tag+objectMapping.m
//  SimpleMapping
//
//  Created by Melinda Samson on 01/04/2015.
//  Copyright (c) 2015 MelindaSamson. All rights reserved.
//

#import "Tag+objectMapping.h"

@implementation Tag (objectMapping)

+(NSDictionary *)objectMapping {
    return @{kPrimaryKey : @"guid",
             @"guid" : @"TagId",
             @"text" : @"TagText"
             };
}

@end
