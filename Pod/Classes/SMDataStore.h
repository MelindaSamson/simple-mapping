
#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface SMDataStore : NSObject


@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContextForThread;
@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContextForMainThread;
// Custom configurations
@property (nonatomic, strong) NSString *managedObjectModelFilename;
@property(nonatomic, strong) NSString *databaseName;

+ (id)sharedInstance;
// Helper methods
- (NSURL *)applicationDocumentsDirectory;

#define DATASTORE ((SMDataStore *)[SMDataStore sharedInstance])

@end
