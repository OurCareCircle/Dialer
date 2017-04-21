//
//  FirstViewController.h
//  Voice2Buzz
//
//  Created by sanjay krishnamurthy on 12/21/10.
//  Copyright 2010 Infinear Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RootViewController.h"
#import "XmitMain.h"
#import "PaymentViewController.h"

@interface FirstViewController : UIViewController <XmitMainCallerDelegate, UIAlertViewDelegate, UIPickerViewDelegate, UIPickerViewDataSource
> {
	
	IBOutlet UIButton                 *addDirButton;
	IBOutlet UITextField              *defaultEmail;
	IBOutlet UITextField              *yourName;
	IBOutlet UISegmentedControl       *xferSpeed;
	IBOutlet UITextField              *telNum;
	IBOutlet UIPickerView             *pickerView;
	         NSNumber                 *balanceSeconds;
	IBOutlet UIBarButtonItem          *saveButton;
	IBOutlet UIBarButtonItem          *recButton;
	XmitMain                          *xmit;	
	UIActivityIndicatorView           *myIndicator;
	RootViewController                *persistentController;
	PaymentViewController             *pay;
	NSString						  *ccode;
    NSString						  *toCcode;
}

@property (readwrite, assign) UIButton                 *addDirButton;
@property (readwrite, assign) UITextField              *defaultEmail;
@property (readwrite, assign) UITextField              *yourName;
@property (readwrite, assign) UITextField              *telNum;
@property (readwrite, assign) NSNumber                 *balanceSeconds;
@property (readwrite, assign) UISegmentedControl       *xferSpeed;
@property (readwrite, assign) UIBarButtonItem          *saveButton;
@property (readwrite, assign) UIBarButtonItem          *recButton;
@property (nonatomic, retain) XmitMain                 *xmit;
@property (nonatomic, assign, readwrite) UIActivityIndicatorView *myIndicator;
@property (readwrite, assign) RootViewController       *persistentController;
@property (readwrite, assign) PaymentViewController    *pay;
@property (readwrite, assign) NSString                 *ccode;
@property (readwrite, assign) NSString                 *toCcode;

- (IBAction)saveButtonPressed:(id)sender;
- (IBAction)testButtonPressed:(id)sender;
- (IBAction)saveButtonPressedInternal:(id)sender;
- (IBAction)recButtonPressed:(id)sender;
- (IBAction)creditButtonPressed:(id)sender;
- (IBAction)addDirButtonPressed:(id)sender;
- (void) addActivityIndicator:(NSString *)prompt;
- (void) removeActivityIndicator;
- (void) startCallRecording;
- (void) checkTelNumber;
-(void)gotoVoicemail:(NSString *)dialedNumber toCcode:(NSString*)toCcode duration:(NSString*)duration
    callRecordNeeded:(NSNumber*)callRecordNeeded stvNeeded:(NSNumber*)stvNeeded;
- (void) httpGetCallback:(XmitMain *)fetcher op:(PageGetOperation *)op;
- (BOOL) isOK;
- (void) addSaveButton;
- (BOOL) isEmpty:(id)thing;
+ (NSInteger) sizeofCountries;
-(NSString*)genUniqueFilename;

@end
