//
//  EmailViewController.h
//  Voice2Buzz
//
//  Created by sanjay krishnamurthy on 1/2/11.
//  Copyright 2011 Infinear Inc. All rights reserved.
//
#import "v2bFile.h"
#import "XmitMain.h"

@interface EmailViewController : UITableViewController <UIPopoverControllerDelegate,XmitMainCallerDelegate>{
	NSMutableArray                     *emailsArray;
    NSManagedObjectContext             *managedObjectContext;
	UIBarButtonItem                    *addButton;
	UIButton	                       *doneButton;
	//add a popover for getting email address input
	PopoverContentViewController       *detailViewPopover;
	v2bFile                            *v2bf; //pass folder and file name via this var to email view
	XmitMain                           *xmit;
	UIActivityIndicatorView            *myIndicator;
}

@property (nonatomic, retain) NSMutableArray                *emailsArray;
@property (nonatomic, retain) NSManagedObjectContext        *managedObjectContext;
@property (nonatomic, retain) UIBarButtonItem               *addButton;
@property (nonatomic, retain) UIButton                      *doneButton;
@property (nonatomic, retain) PopoverContentViewController  *detailViewPopover;
@property (nonatomic, retain) v2bFile                       *v2bf;
@property (nonatomic, retain) XmitMain                      *xmit;
@property (nonatomic, assign, readwrite) UIActivityIndicatorView *myIndicator;
- (id)init;
- (void)addActivityIndicator:(NSString *)prompt;
- (void)removeActivityIndicator;
- (BOOL) isEmpty:(id)thing;

@end
