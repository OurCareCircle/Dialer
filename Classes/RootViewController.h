//
//  RootViewController.h
//  PersistentTable
//
//  Created by sanjay krishnamurthy on 12/24/10.
//  Copyright 2010 Infinear Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import "PopoverContentViewController.h"
#import "v2bFile.h"
@class Reachability; //for checking network access

@interface RootViewController : UITableViewController <UIPopoverControllerDelegate> {
	NSMutableArray         *foldersArray;
    NSManagedObjectContext *managedObjectContext;
	
    NSString                           *folderName;
    UIBarButtonItem                    *addButton;
	UIButton	                       *doneButton;
	//add a popover for getting folder name input
	PopoverContentViewController       *detailViewPopover;
	//remember to restore back button after edits are done
	UIBarButtonItem                    *history;
	//User picks one or more email addresses and inits this with the addresses
	v2bFile                            *v2bf;
	//030311 add all buttons in footer view
	UIView                             *footerView;
	//for checking network access
	Reachability*                       internetReachable;
	Reachability*                       hostReachable;
	UIActivityIndicatorView            *myIndicator;
}

extern NSString                                                  *callRecFolder;
@property (nonatomic, retain) NSMutableArray                     *foldersArray;
@property (nonatomic, retain) NSManagedObjectContext             *managedObjectContext;

@property (nonatomic, retain) NSString                           *folderName;
@property (nonatomic, retain) UIBarButtonItem                    *addButton;
@property (nonatomic, retain) UIButton                           *doneButton;
@property (nonatomic, retain) PopoverContentViewController       *detailViewPopover;
@property (nonatomic, retain) UIBarButtonItem                    *history;
@property (nonatomic, retain) v2bFile                            *v2bf;
@property (nonatomic, assign, readwrite) UIActivityIndicatorView *myIndicator;

- (void)initPopover;
- (IBAction)showPopover:(id)sender;
- (NSMutableArray *)fetchEvent;
- (void)storeSettings:(NSDictionary *)dict;
- (NSDictionary *)fetchSettings;
- (BOOL)isRecordingView;
- (void)addRecordingButtons;
- (void) checkWiFi;
- (IBAction)connectRecordingButtons;
- (void)addV2bRecFolder;
- (void) checkNetworkStatus:(NSNotification *)notice;
- (void)addActivityIndicator:(NSString *)prompt;
- (void)removeActivityIndicator;

@end
