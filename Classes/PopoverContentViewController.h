//
//  PopoverContentViewController.h
//  PersistentTable
//
//  Created by sanjay krishnamurthy on 12/24/10.
//  Copyright 2010 Infinear Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PopoverContentViewController : UIViewController <UITextFieldDelegate> {
	UITextField  *name;
}

@property (nonatomic, retain) IBOutlet UITextField *name;
- (id)initWithFrame:(CGRect)viewRect;

@end
