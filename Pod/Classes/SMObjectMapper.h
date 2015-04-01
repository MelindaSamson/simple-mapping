

#import <Foundation/Foundation.h>
#import "SMDataStore.h"

@protocol SMOBjectMapping <NSObject>
@required
+(NSDictionary*)objectMapping;

@end

extern NSString *const kPrimaryKey;

@interface SMObjectMapper : NSObject

@property(nonatomic, strong) NSDateFormatter *dateFormatter;

+(id)sharedInstance;

-(void)mapEndpoint:(NSString*)endpoint success:(void(^)())successBlock error:(void(^)())errorBlock;

// Use this to map on a background thread
-(void)mapClassname:(NSString*)classname data:(id)json success:(void(^)())successBlock error:(void(^)(NSError *error))errorBlock;
// Use this for custom context
-(NSArray*)mapClassname:(NSString*)classname data:(id)json context:(NSManagedObjectContext*)context;



#define OBJECTMAPPER ((SMObjectMapper *)[SMObjectMapper sharedInstance])


@end
