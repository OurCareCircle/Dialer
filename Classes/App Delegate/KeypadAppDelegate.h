//
//  KeypadAppDelegate.h
//  Keypad
//
//  Created by Adrian on 10/12/08.
//  Copyright __MyCompanyName__ 2008. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AddressBookUI/AddressBookUI.h>

@interface KeypadAppDelegate : NSObject <UIApplicationDelegate, 
                                        UITabBarControllerDelegate,
                                        ABPeoplePickerNavigationControllerDelegate>
{
@private
    IBOutlet UIWindow *window;
    IBOutlet UITabBarController *tabBarController;
}

@property (readwrite, assign) UITabBarController *tabBarController;
@property (readwrite, assign) UIWindow           *window;

@end
