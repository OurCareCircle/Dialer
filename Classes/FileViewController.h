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
#import "XmitMain.h"

@interface FileViewController : RootViewController <XmitMainCallerDelegate> {
	NSMutableArray                     *filesArray; //all files currently displaying	
    v2bFile                            *currFile;   //if storing a file, this is non null
	XmitMain                           *xmit;       //communicate with v2b server with this
}

@property (nonatomic, retain) NSMutableArray                     *filesArray;
@property (nonatomic, retain) v2bFile                            *currFile;
@property (nonatomic, retain) XmitMain                           *xmit;

- (void)storeFile:(NSDictionary *)dict;
- (void)clearState;

@end
