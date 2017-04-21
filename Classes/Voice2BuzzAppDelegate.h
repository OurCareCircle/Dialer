//
//  Voice2BuzzAppDelegate.h
//  Voice2Buzz
//
//  Created by sanjay krishnamurthy on 12/21/10.
//  Copyright 2010 Infinear Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RootViewController.h"

@interface Voice2BuzzAppDelegate : NSObject <UIApplicationDelegate, UITabBarControllerDelegate> {
    UIWindow *window;
    UITabBarController *tabBarController;
	IBOutlet UINavigationController*  myNavigationController;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet UITabBarController *tabBarController;
@property (nonatomic, retain) IBOutlet UINavigationController *myNavigationController;

@end
