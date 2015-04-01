//
//  SMMockResponseContainer.m
//  SimpleMapping
//
//  Created by Melinda Samson on 01/04/2015.
//  Copyright (c) 2015 MelindaSamson. All rights reserved.
//

#import "SMMockResponseContainer.h"

@implementation SMMockResponseContainer

+(NSArray*)articles {
    return @[
             @{@"ArticleId" : @1,
               @"ArticleTitle" : @"FirstArticle",
               @"ArticleAuthor" :
                   @{@"AuthorId" : @100,
                     @"AuthorName" : @"John Appleseed"},
               @"ArticleTags" :
                   @[
                       @{@"TagId" : @55,
                         @"TagText" : @"Kitty"},
                       @{@"TagId" : @56,
                         @"TagText" : @"Bunny"}
                    ]
               },
             @{@"ArticleId" : @2,
               @"ArticleTitle" : @"SecondArticle",
               @"ArticleAuthor" :
                   @{@"AuthorId" : @101,
                     @"AuthorName" : @"Gordon Freeman"},
               @"ArticleTags" :
                   @[
                       @{@"TagId" : @55,
                         @"TagText" : @"Kitty"},
                       @{@"TagId" : @65,
                         @"TagText" : @"Alien"}
                       ]
               }
            ];
}



@end
