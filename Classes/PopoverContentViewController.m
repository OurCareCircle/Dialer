    //
//  PopoverContentViewController.m
//  PersistentTable
//
//  Created by sanjay krishnamurthy on 12/24/10.
//  Copyright 2010 Infinear Inc. All rights reserved.
//

#import "PopoverContentViewController.h"
#import <QuartzCore/QuartzCore.h>

@implementation PopoverContentViewController

@synthesize name;

#pragma mark -
#pragma mark View lifecycle

-(void)loadView {
	//create a view and then add elements to it
	self.view = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];	
	
	//Add a logo to the background
	/*UIImage *image       = [UIImage imageNamed: @"handsfreelogo-180X120.jpg"];
	UIImageView *imgView = [[UIImageView alloc] initWithFrame:CGRectMake(80, 0, 180, 120)];
	[imgView setImage:image];
	[self.view addSubview:imgView];
	imgView.backgroundColor = [UIColor colorWithRed:0.773f green:0.80f blue:0.831f alpha:1.0f];
	[imgView release]; */

	UITextField * textFieldRounded = [[UITextField alloc] initWithFrame:CGRectMake(20, 100, 280, 40)];
	textFieldRounded.borderStyle = UITextBorderStyleRoundedRect;
	textFieldRounded.layer.cornerRadius = 10;
	textFieldRounded.textColor = [UIColor blackColor]; //text color
	textFieldRounded.font = [UIFont systemFontOfSize:17.0];  //font size
	//textFieldRounded.placeholder = @"Enter name here";  //place holder
	textFieldRounded.backgroundColor = [UIColor colorWithRed:0.773f green:0.80f blue:0.831f alpha:1.0f]; //background color
	textFieldRounded.autocorrectionType = UITextAutocorrectionTypeNo;	// no auto correction support	
	textFieldRounded.autocapitalizationType = UITextAutocapitalizationTypeNone; //Shift key not pressed
	textFieldRounded.keyboardType = UIKeyboardTypeDefault;  // type of the keyboard
	textFieldRounded.returnKeyType = UIReturnKeyDone;  // type of the return key	
	textFieldRounded.clearButtonMode = UITextFieldViewModeWhileEditing;	// has a clear 'x' button to the right
	textFieldRounded.delegate = self;	// let us be the delegate so we know when the keyboard's "Done" button is pressed
	[textFieldRounded becomeFirstResponder];
	//[textFieldRounded resignFirstResponder];
	[self.view addSubview:textFieldRounded];
	
	//Remember it in the name field
	name = textFieldRounded;
}

#pragma mark -
#pragma mark UITextFieldDelegate Protocol

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    NSLog(@"In %s -- calling save", _cmd);
    [textField resignFirstResponder];
    return YES;
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Overriden to allow any orientation.
    return YES;
}


#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}


- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}


- (void)dealloc {
    [super dealloc];
}


@end
