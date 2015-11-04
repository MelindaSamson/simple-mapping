//
//  Article+objectMapping.m
//  SimpleMapping
//
//  Created by Melinda Samson on 01/04/2015.
//  Copyright (c) 2015 MelindaSamson. All rights reserved.
//

#import "Article+objectMapping.h"

@implementation Article (objectMapping)

+(NSDictionary *)objectMapping {
    return @{kSMPrimaryKey : @"guid",
             @"guid": @"ArticleId",
             @"title" : @"ArticleTitle",
             @"author" : @"ArticleAuthor",
             @"tags" : @"ArticleTags"
            };
}

@end
