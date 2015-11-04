//
//  SMTestCases.m
//  SimpleMapping
//
//  Created by Melinda Samson on 01/04/2015.
//  Copyright (c) 2015 MelindaSamson. All rights reserved.
//

#import "SMTestCases.h"
#import "SMMockResponseContainer.h"
#import <SimpleMapping/SMObjectMapper.h>
#import "Article.h"

@implementation SMTestCases

-(void)test {
    XCTestExpectation *dataMapExpectation = [self expectationWithDescription:@"data mapping"];
    
    NSArray *data = [SMMockResponseContainer articles];
    NSLog(@"%@", data.description);
    
    DATASTORE.managedObjectModelFilename = @"TestModel";
    
    
    [OBJECTMAPPER  mapClassname:@"Article" data:data success:^{
        
        NSArray *articles = [OBJECTMAPPER fetchObjectsOnMainThreadWithClassname:@"Article" predicate:nil];
        XCTAssert(articles.count == 2);
        
        Article *article = articles.firstObject;
        
        XCTAssert(article.tags.count == 2);
        
        [dataMapExpectation fulfill];
    } error:^(NSError *error) {
        
        XCTAssert(NO);
        [dataMapExpectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:10000 handler:^(NSError *error) {
 
    }];
}

@end
