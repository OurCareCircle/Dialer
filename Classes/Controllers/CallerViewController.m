//
//  CallerViewController.m
//  Keypad
//
//  Created by Adrian on 10/17/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "CallerViewController.h"
#import "SoundEffect.h"
#import "FirstViewController.h"
#import "DialedViewController.h"
#import "KeypadAppDelegate.h"
#import "MBProgressHUD.h"

@implementation CallerViewController

@synthesize numberLabel;
@synthesize phoneNumber;
@synthesize first;
@synthesize firstName;
@synthesize lastName;
@synthesize country;
@synthesize callRecordNeeded;
@synthesize stvNeeded;
@synthesize shouldShowNavControllerOnExit;

#pragma mark -
#pragma mark Constructor and destructor

- (id)init 
{
    //dialer app doesnt use a nib
    if (self = [super initWithNibName:nil bundle:nil]) 
    {
        shouldShowNavControllerOnExit = YES;
        self.hidesBottomBarWhenPushed = YES;
        NSBundle *mainBundle = [NSBundle mainBundle];
        callingSound = [[SoundEffect alloc] initWithContentsOfFile:[mainBundle pathForResource:@"calling" ofType:@"wav"]];
    }
    return self;
}

- (void)dealloc
{
    [callingSound release];
    [phoneNumber release];
    [numberLabel release];
    [first release];
    [firstName release];
    [lastName  release];
    [country release];
    [super dealloc];
}

#pragma mark -
#pragma mark IBAction methods

- (IBAction)cancel:(id)sender
{
    [[self navigationController] popViewControllerAnimated:YES];
}

#pragma mark -
#pragma mark UIAlertViewDelegate methods

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    [self cancel:self];
}

#pragma mark -
#pragma mark Private methods

- (void)viewWillAppear:(BOOL)animated
{
    //check balance and display message if zero; no nib is used in dialer app
	PaymentViewController *pay = [[PaymentViewController alloc] initWithNibName:@"SecondView" bundle:nil];
	//init PaymentViewController before using any of its methods
	[pay viewDidLoad];
	
    //get max duration of current call BEFORE free count gets decremented by checkFreeCalls method below
    int64_t duration = [pay getMaxDuration];
    
	//check default free calls only; subscriptions need to be checked inside PaymentViewController
	[pay checkFreeCalls];
	
	//check also if ok to do free recordings	
    BOOL ok = true;
	if ([pay.paymentOK boolValue] != true) {
        //check expiry; if ok continue
        [pay checkExpiry];
        
        if ([pay.paymentOK boolValue] != true) {
            numberLabel.text = @"Please renew usage";
            ok = false;
        }
    }
    
    //Display called party's name if present; else tel# will do
    if (ok)
    {
        if (self.firstName == nil && self.lastName == nil) {
            numberLabel.text = [NSString stringWithFormat:@"Calling %@", self.phoneNumber];
        }
        else {
            NSString *name   = nil;
            if (self.firstName != nil && self.lastName != nil) {
                name   = [NSString stringWithFormat:@"%@ %@", self.firstName, self.lastName];
            }
            else if (self.firstName != nil) {
                name = self.firstName;
            }
            else {
                name = self.lastName;
            }
            numberLabel.text = [NSString stringWithFormat:@"Calling %@", name];
            [name release];
        }
    
        //connect the current user and the dialed number
        NSString *maxLength = [[NSString alloc] initWithFormat:@"%ld", duration];
        [first gotoVoicemail:self.phoneNumber toCcode:first.toCcode duration:maxLength callRecordNeeded:callRecordNeeded
                   stvNeeded:stvNeeded];
        [maxLength release];
		
        //store the current call in recents table
        DialedViewController *dvc = [[DialedViewController alloc] init];
        [dvc viewDidLoad]; //this needs to be done prior to calling any method in dvc
        [dvc saveCall:self.firstName last:self.lastName phoneNumber:self.phoneNumber 
              country:self.country];
        
        //update the tabbarcontroller's view to point to this new dvc
        KeypadAppDelegate *appDelegate       = (KeypadAppDelegate *)[[UIApplication sharedApplication] delegate];
        UITabBarController *tabBarController = [appDelegate tabBarController];
        //Alloc a new array of viewcontrollers
        NSArray   *vcs   = [tabBarController viewControllers];
        //add a nav controller for dvc
        UINavigationController *navController3  = [[UINavigationController alloc] initWithRootViewController:dvc];
        NSArray *vcArray =  [[NSArray alloc] initWithObjects:[vcs objectAtIndex:0], [vcs objectAtIndex:1],
                             [vcs objectAtIndex:2], navController3, nil];
        [tabBarController setViewControllers:vcArray]; //update tabbarcontroller of app
        [dvc release];
        [navController3 release];
        
        //After a call is made successfully, remove all non-digits from label area
        //so that user can press call button and redial last number easily
        NSString *phoneNumberString = numberLabel.text;
        NSString *pureNumbers       = [[phoneNumberString componentsSeparatedByCharactersInSet:[[NSCharacterSet decimalDigitCharacterSet] invertedSet]] componentsJoinedByString:@""];
        numberLabel.text = pureNumbers;
		
		//Add a spinner to current view     
        spinner = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        spinner.labelText = @"A US TollFree# will call you...";
        spinner.detailsLabelText = @"After you answer, wait to be connected to other party...";
        
        //add spinner to current view
        KeypadAppDelegate* myDelegate = (((KeypadAppDelegate*) [UIApplication sharedApplication].delegate));
        //doesnt work [self.view addSubview:spinner];
        [myDelegate.window addSubview:spinner];
        
        //remove after 10 secs
		[NSTimer scheduledTimerWithTimeInterval:10 target:self
									   selector:@selector(dismissSpinner) userInfo:nil repeats:NO];
        
    } //else qty > zero
}

//dismiss annoying activity indicator
-(void)dismissSpinner{
	// Dismiss your view    
    [spinner removeFromSuperview];
    
    //you get msg sent to dealloced instance if you remove spinner like this 
    //[MBProgressHUD hideHUDForView:self.view animated:YES];

    //[spinner release];
	
	//pop back after done
	//[[self navigationController] popViewControllerAnimated:NO];
}

- (void)viewWillDisappear:(BOOL)animated
{
    if (shouldShowNavControllerOnExit)
    {
        [[self navigationController] setNavigationBarHidden:NO animated:YES];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    //[[self navigationController] setNavigationBarHidden:NO animated:YES];
    [callingSound play];
}

//- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation 
//{
//    return NO;
//}

@end
