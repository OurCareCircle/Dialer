//
//  CallerViewController.h
//  Keypad
//
//  Created by Adrian on 10/17/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FirstViewController.h"
#import "MBProgressHUD.h"

@class SoundEffect;

@interface CallerViewController : UIViewController <UIAlertViewDelegate>
{
@private
    IBOutlet UILabel                  *numberLabel;
	IBOutlet MBProgressHUD            *spinner;
    NSString                          *phoneNumber;
    NSString                          *firstName;
    NSString                          *lastName;
    NSString                          *country;
    NSNumber                          *callRecordNeeded; //did the user want to record this call?
    NSNumber                          *stvNeeded;        //did the user want to go directly to voicemail?
    BOOL                               shouldShowNavControllerOnExit;
    SoundEffect                       *callingSound;
    FirstViewController               *first;
}

@property (nonatomic, retain) UILabel             *numberLabel;
@property (nonatomic, retain) NSString            *phoneNumber;
@property (nonatomic, retain) NSString            *firstName;
@property (nonatomic, retain) NSString            *lastName;
@property (nonatomic, retain) NSString            *country;
@property (nonatomic, retain) NSNumber            *callRecordNeeded;
@property (nonatomic, retain) NSNumber            *stvNeeded;
@property (nonatomic, retain) FirstViewController *first;
@property (nonatomic) BOOL    shouldShowNavControllerOnExit;

- (IBAction)cancel:(id)sender;
- (void)dismissSpinner;

@end
