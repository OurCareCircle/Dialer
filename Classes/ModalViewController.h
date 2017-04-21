//
//  ModalViewController.h
//  Dialer
//
//  Created by sanjay krishnamurthy on 7/12/12.
//  Copyright (c) 2012 Infinear Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ModalViewController : UIViewController
{
@private
    IBOutlet UIButton    *callRecordButton;
    IBOutlet UIButton    *stvButton;
    IBOutlet UIButton    *contButton;
    IBOutlet UIButton    *cancelButton;
    IBOutlet UIButton    *incomingRecordButton;
    IBOutlet UILabel     *callingCountry;
    NSString             *country;
}

@property (nonatomic, retain) UIButton    *callRecordButton;
@property (nonatomic, retain) UIButton    *stvButton;
@property (nonatomic, retain) UIButton    *contButton;
@property (nonatomic, retain) UIButton    *cancelButton;
@property (nonatomic, retain) UIButton    *incomingRecordButton;
@property (nonatomic, retain) UILabel     *callingCountry;
@property (nonatomic, copy)   NSString    *country;
@end
