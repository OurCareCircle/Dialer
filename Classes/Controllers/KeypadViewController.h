//
//  KeypadViewController.h
//  Keypad
//
//  Created by Adrian on 10/16/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PaymentViewController.h"
#import "CountryViewController.h"
#import <AddressBookUI/AddressBookUI.h>

@class SoundEffect;

@interface KeypadViewController : UIViewController <ABPeoplePickerNavigationControllerDelegate>
{
@private
    IBOutlet UILabel  *numberLabel;
    IBOutlet UIButton *buttonCountry;
    IBOutlet UIButton *buttonExpiry;
    
    IBOutlet UIButton *button0;
    IBOutlet UIButton *button1;
    IBOutlet UIButton *button2;
    IBOutlet UIButton *button3;
    IBOutlet UIButton *button4;
    IBOutlet UIButton *button5;
    IBOutlet UIButton *button6;
    IBOutlet UIButton *button7;
    IBOutlet UIButton *button8;
    IBOutlet UIButton *button9;

    IBOutlet UIButton *buttonStar;
    IBOutlet UIButton *buttonNumeral;
    IBOutlet UIButton *callRecordButton;
    IBOutlet UIButton *stvButton;
    
    SoundEffect *tone0;
    SoundEffect *tone1;
    SoundEffect *tone2;
    SoundEffect *tone3;
    SoundEffect *tone4;
    SoundEffect *tone5;
    SoundEffect *tone6;
    SoundEffect *tone7;
    SoundEffect *tone8;
    SoundEffect *tone9;
    SoundEffect *toneStar;
    SoundEffect *toneNumeral;
    
    PaymentViewController  *pay;
    CountryViewController  *country;
    ABPeoplePickerNavigationController *picker;
    NSNumber                           *pickerChosen; //did user use contacts picker??
    NSString                           *phoneNumber;  //if pickerChosen == true, set tel# here
    NSString                           *firstName;
    NSString                           *lastName;
    UINavigationController             *parent; //picker uses a new nav controller; so store original one here
    BOOL                                callRecordNeeded; //did the user want to record this call?
    BOOL                                stvNeeded;        //did the user want to go directly to voicemail?
    BOOL                                cancelFlag;       //user pressed cancel button to return to main menu
    BOOL                                incomingRecordNeeded; //user wants to record incoming call
    
    //for checking network access
	Reachability*                       internetReachable;
	Reachability*                       hostReachable;
    UIActivityIndicatorView            *myIndicator;
    BOOL                                wifi; //set to true iff web access available

}

@property (readwrite, assign) PaymentViewController              *pay;
@property (readwrite, assign) CountryViewController              *country;
@property (readwrite, assign) ABPeoplePickerNavigationController *picker;
@property (readwrite, assign) UINavigationController             *parent;
@property (readwrite, copy) NSString                             *phoneNumber;
@property (readwrite, copy) NSString                             *firstName;
@property (readwrite, copy) NSString                             *lastName;
@property (readwrite, copy) NSNumber                             *pickerChosen;

- (void) displayBalance;
- (BOOL) isEmpty:(id)thing;
- (IBAction)typeNumberOrSymbol:(id)sender;
- (IBAction)goBack:(id)sender;
- (IBAction)call:(id)sender;
- (IBAction)gotoWeb:(id)sender;
-(IBAction)gotoGroupVM:(id)sender;
- (void) showAlert1;
- (void) showAlert2;
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex;
- (IBAction)creditButtonPressed:(id)sender;
- (IBAction)countryButtonPressed:(id)sender;
- (NSString *)convertToCcode:(NSString *)countryName;
- (void) showModal:(UIView*) modalView;
- (void) hideModal:(UIView*) modalView;
- (void) hideModalEnded:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context;
- (IBAction)callRecButtonPressed:(id)sender;
- (IBAction)stvButtonPressed:(id)sender;
- (IBAction)contButtonPressed:(id)sender;
-(void)checkWiFi;
- (void) checkNetworkStatus:(NSNotification *)notice;
- (void)addActivityIndicator:(NSString *)prompt;
- (void) removeActivityIndicator;
-(void)restOfCall;
-(void)clearState;
- (IBAction)incomingRecordButtonPressed:(id)sender;
- (IBAction)cancelButtonPressed:(id)sender;

@end
