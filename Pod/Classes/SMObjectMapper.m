#import "SMObjectMapper.h"

NSString *const kRemote = @"remotekey";
NSString *const kLocal = @"localkey";
NSString *const kClassName = @"classnamekey";
NSString *const kRelationshipType = @"relationshiptype";

NSString *const kPrimaryKey = @"constprimarykey";

NSString *const RelationshipTypeAttribute = @"relationshiptypeattribute";
NSString *const RelationshipTypeToOne = @"relationshiptypetoone";
NSString *const RelationshipTypeToMany = @"relationshiptypetomany";

@implementation SMObjectMapper {
    NSDateFormatter *_iso8601dateFormatter;
    
    NSMutableDictionary *objectMappings;
    NSMutableDictionary *endpointMappings;
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
                    NSString *primaryKey = [mapping objectForKey:kPrimaryKey];
                    if(primaryKey) {
                        [propertyDictionary setObject:primaryKey forKey:kPrimaryKey];
                        // remove the primary key, we don't need it anymore
                        [mapping removeObjectForKey:kPrimaryKey];
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
                                relationshipType = RelationshipTypeAttribute;
                                // here if attributeValueClassName doesn't work, use attributetype
                                propertyClassname = attributeDescription.attributeValueClassName;
                                
                                
                            } else if([property isKindOfClass:[NSRelationshipDescription class]]) {
                                NSRelationshipDescription *relationshipDescription = (NSRelationshipDescription *)property;
                                relationshipType = relationshipDescription.toMany ? RelationshipTypeToMany : RelationshipTypeToOne;
                                propertyClassname = relationshipDescription.destinationEntity.managedObjectClassName;
                                
                                
                            } else {
                                NSAssert(NO, @"local key is neither a relationship or a property");
                            }
                        }
                        
                        NSDictionary *propertyInfoDictionary = @{kRemote : remoteKey,
                                                                 kRelationshipType : relationshipType,
                                                                 kClassName : propertyClassname
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
    NSAssert([json isKindOfClass:[NSDictionary class]] || [json isKindOfClass:[NSArray class]], @"json is neither a dictionary or an array (outer method)");
    
    NSManagedObjectContext *context = [DATASTORE managedObjectContextForThread];
    [context performBlock:^{
        [self mapClassname:classname data:json context:context];
        NSError *e = nil;
        if(context.hasChanges) {
            [context save:&e];
        }
        if(e) {
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
    
    NSAssert([json isKindOfClass:[NSDictionary class]] || [json isKindOfClass:[NSArray class]], @"json is neither a dictionary or an array (inner method)");
    
    NSMutableArray *objects = [[NSMutableArray alloc] init];
    
    // get the mapping
    NSDictionary *mapping = [objectMappings valueForKey:classname];
    if(mapping) {
        
        NSEntityDescription *entityDescription = [NSEntityDescription entityForName:classname inManagedObjectContext:context];
        
        NSFetchRequest *request = nil;
        // See if we have a primary key
        if([mapping objectForKey:kPrimaryKey]) {
            if(!request) {
                request = [[NSFetchRequest alloc] init];
                request.fetchLimit = 1;
                request.entity = entityDescription;
            }
        } else {
            // If not, request will be nil and a new object will be added
            NSLog(@"No primary key was found classname: %@ - a new entity will be added without any check!!", classname);
        }
        
        // See if json is dictionary or array
        if([json isKindOfClass:[NSDictionary class]]) {
            NSManagedObject *object = [self mapEntityDescription:entityDescription dictionary:json fetchRequest:request mapping:mapping context:context];
            [objects addObject:object];
            
        } else if([json isKindOfClass:[NSArray class]]) {
            for(NSDictionary *d in json) {
                NSManagedObject *object = [self mapEntityDescription:entityDescription dictionary:d fetchRequest:request mapping:mapping context:context];
                [objects addObject:object];
                
            }
        }
    }
    return objects;
}

-(NSManagedObject*)mapEntityDescription:(NSEntityDescription*)entityDescription dictionary:(NSDictionary*)json fetchRequest:(NSFetchRequest*)fetchRequest mapping:(NSDictionary*)mapping context:(NSManagedObjectContext*)context {
        
    NSManagedObject *object = nil;
    
    NSArray *existingObjects = nil;
    
    if(fetchRequest) {
        NSString *primaryKey = [mapping objectForKey:kPrimaryKey];
        
        NSDictionary *primaryInfo = [mapping objectForKey:primaryKey];
        NSString *primaryRemoteKey = [primaryInfo objectForKey:kRemote];
        
        id guid = [json objectForKey:primaryRemoteKey];
        if(![guid isEqual:[NSNull null]]) {
            
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%@ = %@", primaryKey, guid];
            fetchRequest.predicate = predicate;
            
            NSError *e = nil;
            existingObjects = [context executeFetchRequest:fetchRequest error:&e];
            
        }
    }
    
            
    
    // see if we have already the object
    if(existingObjects && existingObjects.count > 0) {
        object = existingObjects.firstObject;
    } else {
        Class entityClass = NSClassFromString(entityDescription.managedObjectClassName);
        object = [[[entityClass class] alloc] initWithEntity:entityDescription insertIntoManagedObjectContext:context];
        NSLog(@"new Entity added %@", entityDescription.managedObjectClassName);
    }
    
    
    
    if(object) {
        [mapping enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            if(![key isEqual:kPrimaryKey]) {
                NSString *localKey = key;
                NSDictionary *info = obj;
                
                NSString *remoteKey = [info objectForKey:kRemote];
                NSString *relationshipType = [info objectForKey:kRelationshipType];
                NSString *className = [info objectForKey:kClassName];
                
                id value = [json objectForKey:remoteKey];
                if(![value isEqual:[NSNull null]]) {
                    if([relationshipType isEqual:RelationshipTypeAttribute]) {
                        Class class = NSClassFromString(className);

                        
                        if([class isSubclassOfClass:[NSDate class]]) {
                            if([value isKindOfClass:[NSString class]]) {
                                NSDate *date = [[self defaultDateFormatter] dateFromString:value];
                                [object setValue:date forKey:localKey];
                            }
                        } else if([value isKindOfClass:class]) {
                            [object setValue:value forKey:localKey];
                        }
                    } else if([relationshipType isEqual:RelationshipTypeToOne]) {
                        NSArray *objects = [self mapClassname:className data:value context:context];
                        if(objects.count == 1) {
                            NSManagedObject *relationshipObject = [objects firstObject];
                            [object setValue:relationshipObject forKey:localKey];
                        }
                    } else if([relationshipType isEqual:RelationshipTypeToMany]) {
                        NSArray *objects = [self mapClassname:className data:value context:context];
                        NSSet *set = (NSSet*)[object valueForKey:localKey];
                        
                        NSMutableSet *mutableSet = [set mutableCopy];
                        for(NSManagedObject *relationshipObject in objects) {
                            if(![set containsObject:relationshipObject]) {
                                [mutableSet addObject:relationshipObject];
                            }
                        }
                        [object setValue:mutableSet forKey:localKey];
                    }
                } else {
                    NSLog(@"Value is NSNull for key: %@ localkey: %@, entityClass: %@", remoteKey, localKey, entityDescription.managedObjectClassName);
                }
            }
        }];
}

return object;

}

@end
