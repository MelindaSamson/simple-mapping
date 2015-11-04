#import "SMDataStore.h"

@implementation SMDataStore {
    NSManagedObjectContext *_managedObjectContext;
}

@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;


+ (id)sharedInstance {
    static dispatch_once_t once;
    static SMDataStore *sharedInstance;
    
    if(!sharedInstance) {
        dispatch_once(&once, ^{
            sharedInstance = [[self alloc] init];
        });
    }
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if(self) {
        _databaseName = @"database";
    }
    return self;
}

- (NSURL *)applicationDocumentsDirectory {
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

- (void)setManagedObjectModelFilename:(NSString *)managedObjectModelFilename {
    _managedObjectModelFilename = managedObjectModelFilename;
    if(self.managedObjectModel) {
        NSLog(@"Model is valid");
    } else {
        NSLog(@"Model not valid");
    }
    
}

- (NSManagedObjectModel *)managedObjectModel {
    
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    
    NSString *bundleIdentifier = [[NSBundle bundleForClass:[self class]] bundleIdentifier];
    
    NSString *modelFilename = bundleIdentifier;
    
    if(_managedObjectModelFilename) {
        modelFilename = _managedObjectModelFilename;
    } else {
        NSLog(@"Model Filename not set - using bundle identifier");
    }
    
    NSURL *modelURL = [[NSBundle bundleForClass:[self class]] URLForResource:modelFilename withExtension:@"momd"];
    NSAssert(modelURL, @"Model URL is nil");
    //NSURL *modelURL = [[NSBundle mainBundle] URLForResource:modelFilename withExtension:@"momd"];

    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

-(void)setDatabaseName:(NSString *)databaseName {
    _databaseName = databaseName;
    _persistentStoreCoordinator = nil;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    
    // Create the coordinator and store
    
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:[NSString stringWithFormat:@"%@.sqlite", _databaseName]];
    NSLog(@"DATABASE URL:%@", storeURL.absoluteString);
    NSError *error = nil;
    NSString *failureReason = @"There was an error creating or loading the application's saved data.";
    //////////////////////////////////
    /// ALLOW MIGRATION
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption,
                             [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];
    
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:options error:&error]) {
        // Report any error we got.
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        dict[NSLocalizedDescriptionKey] = @"Failed to initialize the application's saved data";
        dict[NSLocalizedFailureReasonErrorKey] = failureReason;
        dict[NSUnderlyingErrorKey] = error;
        error = [NSError errorWithDomain:@"SMDataStore" code:9999 userInfo:dict];
        //TODO Replace this with code to handle the error appropriately.
        // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    return _persistentStoreCoordinator;
}


- (NSManagedObjectContext *)managedObjectContextForMainThread {
    // Returns the managed object context for main thread
    if (_managedObjectContext != nil) {
        
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (!coordinator) {
        return nil;
    }
    _managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    [_managedObjectContext setPersistentStoreCoordinator:coordinator];

    return _managedObjectContext;
}

- (NSManagedObjectContext *)managedObjectContextForThread {
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (!coordinator) {
        return nil;
    }
    
    NSManagedObjectContext *context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];

    [context setParentContext:[self managedObjectContextForMainThread]];
    
    return context;
}

@end
