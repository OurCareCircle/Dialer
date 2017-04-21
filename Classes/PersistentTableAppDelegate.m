//
//  PersistentTableAppDelegate.m
//  PersistentTable
//
//  Created by sanjay krishnamurthy on 12/24/10.
//  Copyright 2010 Infinear Inc. All rights reserved.
//

#import "PersistentTableAppDelegate.h"
#import "RootViewController.h"
#import "FileViewController.h"
#import "EmailViewController.h"
#import <CoreData/CoreData.h>
#import "UIDevice+IdentifierAddition.h"


@implementation PersistentTableAppDelegate

@synthesize window;
@synthesize navigationController;
@synthesize managedObjectContext;
@synthesize persistentStoreCoordinator;
@synthesize persistentStorePath;


#pragma mark -
#pragma mark Application lifecycle

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {    
    
    RootViewController *rootViewController = [self initRootViewController];
	
    UINavigationController *aNavigationController = [[UINavigationController alloc]
													 initWithRootViewController:rootViewController];
    self.navigationController = aNavigationController;
	
    [window addSubview:[navigationController view]];
    [window makeKeyAndVisible];
	
    [rootViewController release];
    [aNavigationController release];
	
    return YES;
}

//Alloc the root controller; this is used to save/restore persistent settings without any ui 
- (RootViewController *)initRootViewController {
	RootViewController *rootViewController = [[RootViewController alloc]
											  initWithStyle:UITableViewStylePlain];
	
	//init managedobjectcontext
	//managedObjectContext = [[NSManagedObjectContext alloc] init];
    NSManagedObjectContext *context = [self managedObjectContext];
    if (!context) {
        // Handle the error.
		NSLog(@"Error in creating managed object context!!");
    }
	//set the store coordinator in this MOC
	//NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    //if (coordinator != nil) {
    //    [managedObjectContext setPersistentStoreCoordinator:coordinator];
    //    [managedObjectContext setUndoManager:nil];
    //}
	
    // Pass the managed object context to the view controller.
    rootViewController.managedObjectContext = context;
	
	//init  a v2bFile instance for testing player functionality
	//Add a v2bFile with current folder name in it
	//v2bFile *v2bf     = [v2bFile alloc];
	//for testing player view, add url to v2bfile
	//v2bf.fileURL = @"http://www.infinear.com/mon/iphone/F8F575AE-C160-51F4-BD4F-5B084C2DE0DE/10-12-19-08-50-28-F8F575AE-C160-51F4-BD4F-5B084C2DE0DE.mp3";	
	//rootViewController.v2bf = v2bf;
	
	return rootViewController;
}

//Alloc the file view controller;  
- (FileViewController *)initFileViewController {
	FileViewController *fileViewController = [[FileViewController alloc]
											  initWithStyle:UITableViewStylePlain];
	
	//USE THE managedObjectContext setup for reading folders; if you crete a new one,
	//it will not fetch correctly
	//init managedobjectcontext
	//managedObjectContext = [[NSManagedObjectContext alloc] init];
    //NSManagedObjectContext *context = [self managedObjectContext];
    //if (!context) {
        // Handle the error.
		//NSLog(@"Error in creating managed object context!!");
    //}
	//set the store coordinator in this MOC
	//NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    //if (coordinator != nil) {
    //    [managedObjectContext setPersistentStoreCoordinator:coordinator];
    //    [managedObjectContext setUndoManager:nil];
    //}
	
    // Pass the managed object context to the view controller.
    //fileViewController.managedObjectContext = context;
	return fileViewController;
}

//Alloc the email view controller
- (EmailViewController *)initEmailViewController {
	EmailViewController *emailViewController = [[EmailViewController alloc]
	                                            initWithStyle:UITableViewStylePlain];
	
	//USE THE managedObjectContext setup for reading folders; if you create a new one,
	//it will not fetch correctly
	return emailViewController;
}

+(NSString *)getUniqueID{
    NSString *udid = [[UIDevice currentDevice] uniqueDeviceIdentifier];
    
    //remove all dashes, parens and whitespace from udid
    udid = [udid stringByReplacingOccurrencesOfString:@"-" withString:@""];
    udid = [udid stringByReplacingOccurrencesOfString:@" " withString:@""];
    udid = [udid stringByReplacingOccurrencesOfString:@"(" withString:@""];
    udid = [udid stringByReplacingOccurrencesOfString:@")" withString:@""];
    
    return    udid;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    /*
     Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
     If your application supports background execution, called instead of applicationWillTerminate: when the user quits.
     */
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    /*
     Called as part of  transition from the background to the inactive state: here you can undo many of the changes made on entering the background.
     */
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
     */
}


- (void)applicationWillTerminate:(UIApplication *)application {
    /*
     Called when the application is about to terminate.
     See also applicationDidEnterBackground:.
     */
}


#pragma mark -
#pragma mark Memory management

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application {
    /*
     Free up as much memory as possible by purging cached data objects that can be recreated (or reloaded from disk) later.
     */
}


- (void)dealloc {
	[navigationController release];
	[window release];
	[super dealloc];
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    if (persistentStoreCoordinator == nil) {
        NSURL *storeUrl = [NSURL fileURLWithPath:self.persistentStorePath];
		
		//changed for lightweight migration 122611
		//persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[NSManagedObjectModel mergedModelFromBundles:nil]]; 
        //If you want to add a new version, use code below
        persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
		NSError *error = nil;
		
		//122611 add options to migrate old setting data model to new one
		NSDictionary *options = nil;
        //For migrating models, use code below
        options = [NSDictionary dictionaryWithObjectsAndKeys:  
                            [NSNumber numberWithBool:YES],
                   NSMigratePersistentStoresAutomaticallyOption,  
        					 [NSNumber numberWithBool:YES],NSInferMappingModelAutomaticallyOption, nil];  
		//NOTE: options param below changed on 122611
		
        NSPersistentStore *persistentStore = [persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeUrl options:options error:&error];
        NSAssert3(persistentStore != nil, @"Unhandled error adding persistent store in %s at line %d: %@", __FUNCTION__, __LINE__, [error localizedDescription]);
    }
    return persistentStoreCoordinator;
}

- (NSManagedObjectContext *)managedObjectContext {
    if (managedObjectContext == nil) {
        managedObjectContext = [[NSManagedObjectContext alloc] init];
        [managedObjectContext setPersistentStoreCoordinator:self.persistentStoreCoordinator];
    }
    return managedObjectContext;
}

//needed for lightweight migration
- (NSManagedObjectModel *)managedObjectModel {
    
    if (managedObjectModel != nil) {
        return managedObjectModel;
    }
    
    NSString *path = [[NSBundle mainBundle] pathForResource:@"folder" ofType:@"momd"];
    NSURL *momURL = [NSURL fileURLWithPath:path];
    managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:momURL];
	
    return managedObjectModel;
}

- (NSString *)persistentStorePath {
    if (persistentStorePath == nil) {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths lastObject];
		//was 011512 below
        persistentStorePath = [[documentsDirectory stringByAppendingPathComponent:@"V2BFiles0120716.sqlite"] retain];
    }
    return persistentStorePath;
}


@end

