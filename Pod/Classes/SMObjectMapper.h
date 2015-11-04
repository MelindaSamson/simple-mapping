#import <Foundation/Foundation.h>
#import "SMDataStore.h"

@protocol SMOBjectMapping <NSObject>
@required

+(NSDictionary*)objectMapping;

@end

// block to custom update object. If returns NO indicates the mapping to stop.
typedef BOOL (^SMObjectMappingUpdateBlock)(id object, NSManagedObjectContext *context);

extern NSString *const kSMPrimaryKey;
extern NSString *const kSMVersionKey;
extern NSString *const kSMUpdateBlock;

@interface SMObjectMapper : NSObject

@property(nonatomic, strong) NSDateFormatter *dateFormatter;

void SLog(NSString *formatString, ...) NS_FORMAT_FUNCTION(1,2);

+(id)sharedInstance;

-(void)mapEndpoint:(NSString*)endpoint success:(void(^)())successBlock error:(void(^)())errorBlock;

// Use this to map on a background thread
-(void)mapClassname:(NSString*)classname data:(id)json success:(void(^)())successBlock error:(void(^)(NSError *error))errorBlock;
// Use this for custom context
-(NSArray*)mapClassname:(NSString*)classname data:(id)json context:(NSManagedObjectContext*)context;


// fetch helper methods
-(void)fetchObjectOnBackgroundThreadWithClassname:(NSString*)classname guid:(NSString*)guid completion:(void(^)(NSManagedObject* object))completionBlock;
-(NSManagedObject*)fetchObjectOnMainThreadWithClassname:(NSString*)classname guid:(NSString*)guid;
-(NSManagedObject*)fetchObjectWithClassname:(NSString*)classname guid:(NSString*)guid context:(NSManagedObjectContext*)context;

-(NSArray*)fetchObjectsOnMainThreadWithClassname:(NSString*)classname predicate:(NSPredicate*)predicate;
-(NSArray*)fetchObjectsWithClassname:(NSString*)classname predicate:(NSPredicate*)predicate context:(NSManagedObjectContext*)context;

-(void)deleteObjectOnMainThreadWithClassname:(NSString*)classname guid:(NSString*)guid;

#define OBJECTMAPPER ((SMObjectMapper *)[SMObjectMapper sharedInstance])


@end
