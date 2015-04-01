//
//  Author.h
//  SimpleMapping
//
//  Created by Melinda Samson on 01/04/2015.
//  Copyright (c) 2015 MelindaSamson. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Article;

@interface Author : NSManagedObject

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber * guid;
@property (nonatomic, retain) NSSet *articles;
@end

@interface Author (CoreDataGeneratedAccessors)

- (void)addArticlesObject:(Article *)value;
- (void)removeArticlesObject:(Article *)value;
- (void)addArticles:(NSSet *)values;
- (void)removeArticles:(NSSet *)values;

@end
