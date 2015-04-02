# SimpleMapping

SimpleMapping is an easy to use library for mapping REST API responses to Core Data objects.

## Features

- [x] Preconfigured Core Data stack
- [x] Automated relationship handling
- [x] Configurable dateformatter for dates
- [x] Built in typechecking
- [x] Easy to configure data mappings

## Example

To run the test, clone the repo, and run `pod install` from the Example directory first.

## Installation

SimpleMapping is available through [CocoaPods](http://cocoapods.org) or [Set up manually](#setting-up-manually)

To install, simply add the following line to your Podfile:

```ruby
pod "SimpleMapping"
```

## Usage

Every ManagedObject subclasses used must implement the ObjectMapper protocol. It can be accomplished in different ways, but the most convinient way is to create a category for the class and implement the protocol in that category. That way when the ManagedObject subclasses are regenerated from the model the mapping won't be lost.

The classes have to return an NSDictionary* containing the mapping where the keys are the properties of the ManagedObject subclass and the values are the keys of the response object to be mapped.

Additionally the key kPrimaryKey can be used to define the property which will be used as unique identifier for the Entity, so the library will update the corresponding objects instead of creating new ones.

The name of the data model can be set on the Datastore like the following:

```objective-c
DATASTORE.managedObjectModelFilename = @"TestModel";
```

Then an entity can be mapped using the method:
```objective-c
-(void)mapClassname:(NSString*)classname data:(id)json success:(void(^)())successBlock error:(void(^)(NSError *error))errorBlock;
```
Where the data input can be type of NSDictionary or NSArray.

The mapper will map every relationships recursively. The main thread context can be used as source of NSFetchedResultsController for example, due it's updated with the database changes.

## Author

MelindaSamson, melinda.samson.it@gmail.com

## License

SimpleMapping is available under the MIT license. See the LICENSE file for more info.


## Usage








