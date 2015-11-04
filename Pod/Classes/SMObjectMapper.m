#import "SMObjectMapper.h"

NSString *const kSMRemote = @"smremotekey";
NSString *const kSMLocal = @"smlocalkey";
NSString *const kSMClassName = @"smclassnamekey";
NSString *const kSMRelationshipType = @"smrelationshiptype";

NSString *const kSMPrimaryKey = @"smconstprimarykey";
NSString *const kSMVersionKey = @"smconstversionkey";
NSString *const kSMUpdateBlock = @"smconstupdateblockkey";

NSString *const SMRelationshipTypeAttribute = @"smrelationshiptypeattribute";
NSString *const SMRelationshipTypeToOne = @"smrelationshiptypetoone";
NSString *const SMRelationshipTypeToMany = @"smrelationshiptypetomany";

@implementation SMObjectMapper {
    NSDateFormatter *_iso8601dateFormatter;
    
    NSMutableDictionary *objectMappings;
    NSMutableDictionary *endpointMappings;
}


void SLog(NSString *formatString, ...) {
//#define SIMPLE_MAPPING_LOGGING
    
#ifdef SIMPLE_MAPPING_LOGGING
    va_list args;
    va_start(args, formatString);
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wformat-security"
    NSLog([[NSString alloc] initWithFormat:formatString arguments:args]);
    va_end(args);
#pragma clang diagnostic pop
#endif
}

+ (id)sharedInstance {
    static dispatch_once_t once;
    static SMObjectMapper *sharedInstance;
    
    if(!sharedInstance) {
        dispatch_once(&once, ^{
            sharedInstance = [[self alloc] init];
        });
    }
    
    return sharedInstance;
}

-(id)init {
    self = [super init];
    if(self) {
        [self fetchObjectMappings];
        _iso8601dateFormatter = [[NSDateFormatter alloc] init];
        [_iso8601dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSSZ"];
    }
    return self;
}

- (NSDateFormatter*)defaultDateFormatter {
    if(_dateFormatter) {
        return _dateFormatter;
    }
    return _iso8601dateFormatter;
}

- (void)fetchObjectMappings {
    // mappings can't change runtime
    if(!objectMappings) {
        objectMappings = [[NSMutableDictionary alloc] init];
    
    
        NSManagedObjectModel *model = [DATASTORE managedObjectModel];
        NSDictionary *entityDescriptions = model.entitiesByName;
        
        [entityDescriptions enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            
            NSEntityDescription *entityDescription = obj;
            NSString *entityClassName = entityDescription.managedObjectClassName;
            
            Class entityClass = NSClassFromString(entityClassName);
            if([entityClass conformsToProtocol:@protocol(SMOBjectMapping)]) {
                NSMutableDictionary *mapping = [[entityClass objectMapping] mutableCopy];
                if(mapping) {
                    NSMutableDictionary *propertyDictionary = [[NSMutableDictionary alloc] init];
                    
                    NSDictionary *properties = entityDescription.propertiesByName;
                    
                    // see if there is a primary key
                    NSString *primaryKey = [mapping objectForKey:kSMPrimaryKey];
                    if(primaryKey) {
                        [propertyDictionary setObject:primaryKey forKey:kSMPrimaryKey];
                        // remove the primary key, we don't need it anymore
                        [mapping removeObjectForKey:kSMPrimaryKey];
                    }
                    NSString *version = [mapping objectForKey:kSMVersionKey];
                    if(version) {
                        [propertyDictionary setObject:version forKey:kSMVersionKey];
                        // remove the primary key, we don't need it anymore
                        [mapping removeObjectForKey:kSMVersionKey];
                    }
                    NSString *updateBlock = [mapping objectForKey:kSMUpdateBlock];
                    if(updateBlock) {
                        [propertyDictionary setObject:[updateBlock copy] forKey:kSMUpdateBlock];
                        // remove the primary key, we don't need it anymore
                        [mapping removeObjectForKey:kSMUpdateBlock];
                    }
                    
                    
                    
                    [mapping enumerateKeysAndObjectsUsingBlock:^(id key2, id obj, BOOL *stop) {
                        NSAssert([key2 isKindOfClass:[NSString class]], @"Local key is not a string");
                        NSAssert([obj isKindOfClass:[NSString class]], @"Remote key is not a string");
                        
                        
                        NSString *propertyName = key2;
                        NSString *remoteKey = (NSString*)obj;
                        NSString *relationshipType = nil;
                        NSString *propertyClassname = nil;
                        
                        id property = [properties objectForKey:propertyName];
                        NSAssert(property, @"local key doesn't exist in model");
                        if(property) {
                            if([property isKindOfClass:[NSAttributeDescription class]]) {
                                NSAttributeDescription *attributeDescription = (NSAttributeDescription*)property;
                                relationshipType = SMRelationshipTypeAttribute;
                                // here if attributeValueClassName doesn't work, use attributetype
                                propertyClassname = attributeDescription.attributeValueClassName;
                                
                                
                            } else if([property isKindOfClass:[NSRelationshipDescription class]]) {
                                NSRelationshipDescription *relationshipDescription = (NSRelationshipDescription *)property;
                                relationshipType = relationshipDescription.toMany ? SMRelationshipTypeToMany : SMRelationshipTypeToOne;
                                propertyClassname = relationshipDescription.destinationEntity.managedObjectClassName;
                                
                                
                            } else {
                                NSAssert(NO, @"local key is neither a relationship or a property");
                            }
                        }
                        
                        NSDictionary *propertyInfoDictionary = @{kSMRemote : remoteKey,
                                                                 kSMRelationshipType : relationshipType,
                                                                 kSMClassName : propertyClassname
                                                                 };
                        // key is local property name
                        [propertyDictionary setObject:propertyInfoDictionary forKey:propertyName];
                        
                    }];
                    
                    
                    // key is entity class name
                    [objectMappings setValue:propertyDictionary forKey:entityClassName];
                }
            }
        }];
    }
}

-(void)mapEndpoint:(NSString*)endpoint success:(void(^)())successBlock error:(void(^)())errorBlock {
    
}

// json can be a dictionary or an array
-(void)mapClassname:(NSString*)classname data:(id)json success:(void(^)())successBlock error:(void(^)(NSError *error))errorBlock {
    //NSAssert([json isKindOfClass:[NSDictionary class]] || [json isKindOfClass:[NSArray class]], @"json is neither a dictionary or an array (outer method)");
    
    NSManagedObjectContext *context = [DATASTORE managedObjectContextForThread];
    [context performBlock:^{
        [self mapClassname:classname data:json context:context];
        NSError *e = nil;
        if(context.hasChanges) {
            [context save:&e];
        }
        if(e) {
            SLog(@"saving error: %@", e.description);
            dispatch_sync(dispatch_get_main_queue(), ^{
                errorBlock(e);
            });
            
        } else {
            dispatch_sync(dispatch_get_main_queue(), ^{
                successBlock();
            });
        }
    }];
}

-(NSArray*)mapClassname:(NSString*)classname data:(id)json context:(NSManagedObjectContext*)context {
    
    //NSAssert([json isKindOfClass:[NSDictionary class]] || [json isKindOfClass:[NSArray class]], @"json is neither a dictionary or an array (inner method)");
    
    NSMutableArray *objects = [[NSMutableArray alloc] init];
    
    // get the mapping
    NSDictionary *mapping = [objectMappings valueForKey:classname];
    if(mapping) {
        
        NSEntityDescription *entityDescription = [NSEntityDescription entityForName:classname inManagedObjectContext:context];
        
        NSFetchRequest *request = nil;
        // See if we have a primary key
        if([mapping objectForKey:kSMPrimaryKey]) {
            if(!request) {
                request = [[NSFetchRequest alloc] init];
                request.fetchLimit = 1;
                request.entity = entityDescription;
            }
        } else {
            // If not, request will be nil and a new object will be added
            SLog(@"No primary key was found classname: %@ - a new entity will be added without any check!!", classname);
        }
        
        // See if json is dictionary or array
        if([json isKindOfClass:[NSArray class]]) {
            for(NSDictionary *d in json) {
                NSManagedObject *object = [self mapEntityDescription:entityDescription dictionary:d fetchRequest:request mapping:mapping context:context];
                [objects addObject:object];
                
            }
        } else {
            NSManagedObject *object = [self mapEntityDescription:entityDescription dictionary:json fetchRequest:request mapping:mapping context:context];
            [objects addObject:object];

        }
    }
    return objects;
}

-(NSManagedObject*)mapEntityDescription:(NSEntityDescription*)entityDescription dictionary:(NSDictionary*)json fetchRequest:(NSFetchRequest*)fetchRequest mapping:(NSDictionary*)mapping context:(NSManagedObjectContext*)context {
        
    NSManagedObject *object = nil;
    
    NSArray *existingObjects = nil;
    
    if(fetchRequest) {
        NSString *primaryKey = [mapping objectForKey:kSMPrimaryKey];
        
        NSDictionary *primaryInfo = [mapping objectForKey:primaryKey];
        NSString *primaryRemoteKey = [primaryInfo objectForKey:kSMRemote];
        
        id guid = [json valueForKeyPath:primaryRemoteKey];
        SLog(@"GUID: %@", guid);
        if(![guid isEqual:[NSNull null]] && guid != 0 && guid != nil) {
            NSString *formatString = [primaryInfo[kSMClassName] isEqual:@"NSString"] ? @"%K like %@" : @"%@ = %@";
            NSPredicate *predicate = [NSPredicate predicateWithFormat:formatString, primaryKey, guid];
            fetchRequest.predicate = predicate;
            
            NSError *e = nil;
            existingObjects = [context executeFetchRequest:fetchRequest error:&e];
            
        }
    }
    
    // see if we have already the object
    if(existingObjects && existingObjects.count > 0) {
        object = existingObjects.firstObject;
        SLog(@"existing object found %@", entityDescription.managedObjectClassName);
        
        // check the version key if exists
        NSString *versionKey = [mapping objectForKey:kSMVersionKey];
        if(versionKey) {
            NSString *currentVersion = [object valueForKey:versionKey];
            
            NSDictionary *versionInfo = [mapping objectForKey:versionKey];
            NSString *remoteVersionKey = [versionInfo objectForKey:kSMRemote];
            
            NSString *newVersion = [json objectForKey:remoteVersionKey];
            // if versions are different, perform updateblock
            if(![newVersion isEqual:currentVersion] && currentVersion != nil && newVersion != nil) {
            
                SMObjectMappingUpdateBlock updateBlock = [mapping objectForKey:kSMUpdateBlock];
                if(updateBlock) {
                    BOOL updateObject = updateBlock(object, context);
                    // if returned NO, don't continue the mapping
                    if(!updateObject) {
                        return object;
                    }
                    // see if the object was deleted during the updateBlock. If yes, create a new object
                    if(object.isDeleted || ![object managedObjectContext]) {
                        Class entityClass = NSClassFromString(entityDescription.managedObjectClassName);
                        object = [[[entityClass class] alloc] initWithEntity:entityDescription insertIntoManagedObjectContext:context];
                        SLog(@"new object added %@", entityDescription.managedObjectClassName);
                    }
                }
            }
        }
        
    } else {
        Class entityClass = NSClassFromString(entityDescription.managedObjectClassName);
        object = [[[entityClass class] alloc] initWithEntity:entityDescription insertIntoManagedObjectContext:context];
        SLog(@"new object added %@", entityDescription.managedObjectClassName);
        
    }
    
    if(object) {
        [mapping enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            if(![key isEqual:kSMPrimaryKey] && ![key isEqual:kSMUpdateBlock] && ![key isEqual:kSMVersionKey]) {
                
                NSString *localKey = key;
                NSDictionary *info = obj;
                
                NSString *remoteKey = [info objectForKey:kSMRemote];
                NSString *relationshipType = [info objectForKey:kSMRelationshipType];
                NSString *className = [info objectForKey:kSMClassName];
                
                id value = [json valueForKeyPath:remoteKey];
                
                SLog(@"mapping for local key:%@ remote key:%@", localKey, remoteKey);
                if(value && ![value isEqual:[NSNull null]]) {
                    if([relationshipType isEqual:SMRelationshipTypeAttribute]) {
                        Class class = NSClassFromString(className);

                        if([class isSubclassOfClass:[NSDate class]]) {
                            if([value isKindOfClass:[NSString class]]) {
                                NSDate *date = [[self defaultDateFormatter] dateFromString:value];
                                [object setValue:date forKey:localKey];
                            } else {
                                [object setValue:value forKey:localKey];
                            }
                        } else if([value isKindOfClass:class]) {
                            [object setValue:value forKey:localKey];
                        }
                    } else if([relationshipType isEqual:SMRelationshipTypeToOne]) {
                        NSArray *objects = [self mapClassname:className data:value context:context];
                        if(objects.count == 1) {
                            NSManagedObject *relationshipObject = [objects firstObject];
                            [object setValue:relationshipObject forKey:localKey];
                        }
                    } else if([relationshipType isEqual:SMRelationshipTypeToMany]) {
                        NSArray *objects = [self mapClassname:className data:value context:context];
                        if([[objects firstObject] respondsToSelector:@selector(name)]) {
                            NSLog(@"%@", [objects valueForKeyPath:@"name"]);
                        }
                        
                        NSSet *set = (NSSet*)[object valueForKey:localKey];
                        
                        NSMutableSet *mutableSet = [set mutableCopy];
                        
                        for(id member in mutableSet) {
                            if([member respondsToSelector:@selector(name)]) {
                                NSLog(@"%@", [member valueForKeyPath:@"name"]);
                            }
                        }
                        
                        for(NSManagedObject *relationshipObject in objects) {
                            if(![set containsObject:relationshipObject]) {
                                [mutableSet addObject:relationshipObject];
                            }
                        }
                        [object setValue:mutableSet forKey:localKey];
                    }
                } else {
                    SLog(@"Value is NSNull for key: %@ localkey: %@, entityClass: %@", remoteKey, localKey, entityDescription.managedObjectClassName);
                }
            }
        }];
    }

    return object;

}

#pragma mark - Fetch Helper Methods

-(void)fetchObjectOnBackgroundThreadWithClassname:(NSString*)classname guid:(NSString*)guid completion:(void(^)(NSManagedObject* object))completionBlock {
    NSManagedObjectContext *context = [DATASTORE managedObjectContextForThread];
    [context performBlock:^{
        NSManagedObject* object = [self fetchObjectWithClassname:classname guid:guid context:context];
        if(object) {
            if(completionBlock) {
                completionBlock(object);
            }
        }
    }];
}

-(NSManagedObject*)fetchObjectOnMainThreadWithClassname:(NSString*)classname guid:(NSString*)guid {
    return [self fetchObjectWithClassname:classname guid:guid context:[DATASTORE managedObjectContextForMainThread]];
}

-(NSManagedObject*)fetchObjectWithClassname:(NSString*)classname guid:(NSString*)guid context:(NSManagedObjectContext*)context {
    NSParameterAssert(classname);
    NSParameterAssert(guid);
    NSParameterAssert(context);
    
    NSDictionary *mapping = [objectMappings valueForKey:classname];
    if(mapping) {
        NSString *primaryKey = [mapping objectForKey:kSMPrimaryKey];
        
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K like %@", primaryKey, guid];
        
        NSArray *existingObjects = [self fetchObjectsWithClassname:classname predicate:predicate context:context];
       
        if(existingObjects.count == 1) {
                
                NSManagedObject* object = existingObjects.firstObject;
                return object;
        }
    }
    return nil;
}

-(NSArray*)fetchObjectsOnMainThreadWithClassname:(NSString*)classname predicate:(NSPredicate*)predicate {
    return [self fetchObjectsWithClassname:classname predicate:predicate context:[DATASTORE managedObjectContextForMainThread]];
}

-(NSArray*)fetchObjectsWithClassname:(NSString*)classname predicate:(NSPredicate*)predicate context:(NSManagedObjectContext*)context {
    NSParameterAssert(classname);
    NSParameterAssert(context);
    
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    
    NSEntityDescription *entityDesc = [NSEntityDescription entityForName:classname inManagedObjectContext:context];
    request.entity = entityDesc;
    if(predicate) {
        request.predicate = predicate;
    }
    // TODO think about this error here
    NSError *e = nil;
    NSArray *existingObjects = [context executeFetchRequest:request error:&e];
    if(e) {
        SLog(@"%@", e.description);
    } else {
        return existingObjects;
    }
    
    return nil;
}

-(void)deleteObjectOnMainThreadWithClassname:(NSString*)classname guid:(NSString*)guid {
    NSManagedObject *object = [self fetchObjectOnMainThreadWithClassname:classname guid:guid];
    if(object) {
        [[DATASTORE managedObjectContextForMainThread] deleteObject:object];
    }
}

@end
