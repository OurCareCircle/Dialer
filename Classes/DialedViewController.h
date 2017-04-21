//
//  DialedViewController.h
//  Dialer
//
//  Created by sanjay krishnamurthy on 7/11/12.
//  Copyright (c) 2012 Infinear Inc. All rights reserved.
//

#import "RootViewController.h"

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import "PopoverContentViewController.h"
#import "V2bDialed.h"

@interface DialedViewController : RootViewController {
	NSMutableArray                     *callsArray; //all files currently displaying	
    V2bDialed                          *currCall;   //if storing a call, this is non null
}

@property (nonatomic, retain) NSMutableArray                     *callsArray;
@property (nonatomic, retain) V2bDialed                          *currCall;

- (void)saveCall:(NSString *)first last:(NSString *)last phoneNumber:(NSString *)phoneNumber 
         country:(NSString *)country;
-(BOOL)checkCallExists:(NSString*)number ;

@end
