//
//  KeypadAppDelegate.m
//  Keypad
//
//  Created by Adrian on 10/12/08.
//  Copyright __MyCompanyName__ 2008. All rights reserved.
//

#import "KeypadAppDelegate.h"
#import "KeypadViewController.h"
#import "CallerViewController.h"
#import "FirstViewController.h"
#import "RootViewController.h"
#import "DialedViewController.h"

NSString *retrieveValueForPropertyAtIndex(ABRecordRef person, ABPropertyID property, ABMultiValueIdentifier index)
{
    ABMultiValueRef items = ABRecordCopyValue(person, property);
    NSString *value = (NSString *)ABMultiValueCopyValueAtIndex(items, index);
    CFRelease(items);
    return value;
}

@implementation KeypadAppDelegate

@synthesize tabBarController, window;

#pragma mark -
#pragma mark Destructor

- (void)dealloc 
{
    [tabBarController release];
    [window release];
    [super dealloc];
}

#pragma mark -
#pragma mark UIApplicationDelegate methods

- (void)applicationDidFinishLaunching:(UIApplication *)application 
{
    KeypadViewController   *keypad        = [[KeypadViewController alloc] init];
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:keypad];
    [keypad release];
    navController.navigationBarHidden     = YES;
    
    //Add a Settings navcontroller to obtain user's details
    FirstViewController    *first                       = [[FirstViewController alloc] init];
    UINavigationController *navController1              = [[UINavigationController alloc]  initWithRootViewController:first];
    [first release];
    navController1.navigationBarHidden                  = NO;
    
    //Add a Folders viewcontroller to show user recordings
    RootViewController     *root           = [[RootViewController alloc] init];
    UINavigationController *navController2 = [[UINavigationController alloc] initWithRootViewController:root];
    [root release];
    navController2.navigationBarHidden     = NO;
    
    //Add a Dialed Calls viewcontroller to show recent calls dialed by user
    DialedViewController     *dvc           = [[DialedViewController alloc] init];
    UINavigationController *navController3  = [[UINavigationController alloc] initWithRootViewController:dvc];
    [dvc release];
    navController3.navigationBarHidden      = NO;

    tabBarController.viewControllers = [[NSArray alloc] initWithObjects:navController, navController2,navController1, navController3, nil];
    [navController release];
    [window addSubview:tabBarController.view];
}

#pragma mark -
#pragma mark ABPeoplePickerNavigationControllerDelegate methods

- (BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)picker 
      shouldContinueAfterSelectingPerson:(ABRecordRef)person
{
    return YES;
}

- (BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)picker 
      shouldContinueAfterSelectingPerson:(ABRecordRef)person 
                                property:(ABPropertyID)property 
                              identifier:(ABMultiValueIdentifier)identifier
{
    if (property == kABPersonPhoneProperty)
    {
        NSString *phoneNumber = retrieveValueForPropertyAtIndex(person, property, identifier);
        CallerViewController *caller = [[CallerViewController alloc] init];
        caller.shouldShowNavControllerOnExit = YES;
        caller.phoneNumber = phoneNumber;
        
        //Init firstvc to dialout
        FirstViewController *first = [[FirstViewController alloc] init];
        [first viewDidLoad];
        //store in caller view so that you can call out
        caller.first = first;
        
        //Add first and last name
        caller.firstName = (NSString *)ABRecordCopyValue(person, kABPersonFirstNameProperty);
        caller.lastName  = (NSString *)ABRecordCopyValue(person, kABPersonLastNameProperty); 
        [picker pushViewController:caller animated:YES];
        return NO;
    }
    return YES;
}

- (void)peoplePickerNavigationControllerDidCancel:(ABPeoplePickerNavigationController *)picker
{
	//012912 force keypad view to be displayed
	 [tabBarController setSelectedIndex:0];
}

#pragma mark -
#pragma mark UITabBarControllerDelegate methods

- (void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController 
{
}

- (void)tabBarController:(UITabBarController *)tabBarController didEndCustomizingViewControllers:(NSArray *)viewControllers changed:(BOOL)changed 
{
}

@end

