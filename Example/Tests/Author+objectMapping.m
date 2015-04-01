//
//  Author+objectMapping.m
//  SimpleMapping
//
//  Created by Melinda Samson on 01/04/2015.
//  Copyright (c) 2015 MelindaSamson. All rights reserved.
//

#import "Author+objectMapping.h"

@implementation Author (objectMapping)

+(NSDictionary *)objectMapping {
    return @{kPrimaryKey : @"guid",
             @"guid" : @"AuthorId",
             @"name" : @"AuthorName"
            };
}

@end
