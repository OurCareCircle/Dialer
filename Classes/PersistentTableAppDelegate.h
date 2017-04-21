//
//  PersistentTableAppDelegate.h
//  PersistentTable
//
//  Created by sanjay krishnamurthy on 12/24/10.
//  Copyright 2010 Infinear Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import "RootViewController.h"
#import "EmailViewController.h"

@interface PersistentTableAppDelegate : NSObject <UIApplicationDelegate> {
    
    UIWindow *window;
    UINavigationController *navigationController;
	
	//Added for persistence
	NSManagedObjectContext       *managedObjectContext;
	NSManagedObjectModel         *managedObjectModel;
	NSPersistentStoreCoordinator *persistentStoreCoordinator;
    NSString *persistentStorePath;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet UINavigationController *navigationController;

//Added for persistence
@property (nonatomic, retain, readonly) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, retain, readonly) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, retain, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic, retain, readonly) NSString *persistentStorePath;

- (RootViewController *) initRootViewController;
- (EmailViewController *)initEmailViewController;
+ (NSString *)getUniqueID;
- (NSURL *)applicationDocumentsDirectory;
- (void)saveContext;
- (NSManagedObjectModel *)managedObjectModel;
@end

