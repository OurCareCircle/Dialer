//
//  PaymentViewController.h
//  Recorder
//
//  Created by sanjay krishnamurthy on 5/16/11.
//  Copyright 2011 Infinear Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "XmitMain.h"
#import "RootViewController.h"
#import "v2bPayment.h"
#import <StoreKit/StoreKit.h>

#define kInAppPurchaseManagerProductsFetchedNotification @"kInAppPurchaseManagerProductsFetchedNotification"
// add a couple notifications sent out when the transaction completes
#define kInAppPurchaseManagerTransactionFailedNotification @"kInAppPurchaseManagerTransactionFailedNotification"
#define kInAppPurchaseManagerTransactionSucceededNotification @"kInAppPurchaseManagerTransactionSucceededNotification"

@interface PaymentViewController : UIViewController <XmitMainCallerDelegate,SKProductsRequestDelegate,SKPaymentTransactionObserver,
													 UIAlertViewDelegate> {
	IBOutlet UIButton                 *OnetimePayButton;
	IBOutlet UIButton                 *ThreetimePayButton;
	IBOutlet UIButton                 *FivetimePayButton;
	IBOutlet UIButton                 *RecurringPayButton;
	RootViewController                *persistentController;
	UIActivityIndicatorView           *myIndicator;
	NSManagedObjectContext            *managedObjectContext;
	XmitMain                          *xmit;       //communicate with v2b server with this
	NSNumber                          *paymentOK;  //caller passes in this variable; return true iff payment succeeded
	
	//For payments
	SKProduct                         *proUpgradeProduct;
    SKProductsRequest                 *productsRequest;
	NSString                          *defEmail;  //user email used as primary key for subscription portability
    NSString                          *telNum; //user saved tel# for storing in db with subscriptions
    NSString                          *ccode;  //ccode is needed in validate payment web service
}

extern NSString *DEFAULT_PAYMENT;  //other files will refer to this
extern int64_t   callsRemaining;   //#recordings that are available

//This button press means user wants a single call recording
@property (readwrite, assign) UIButton                           *OnetimePayButton;

//This button pressed means user wants monthly subscription
@property (readwrite, assign) UIButton                           *RecurringPayButton;

@property (nonatomic, assign, readwrite) UIActivityIndicatorView *myIndicator;
//Init the managedObjectContext before executing this ViewController
@property (nonatomic, retain) NSManagedObjectContext             *managedObjectContext;
@property (nonatomic, retain) XmitMain                           *xmit;
@property (nonatomic, retain) NSNumber                           *paymentOK;
@property (nonatomic, retain) NSString                           *defEmail;
@property (nonatomic, retain) NSString                           *telNum;
@property (nonatomic, retain) NSString                           *ccode;

- (IBAction) onetimePayButtonPressed:(id)sender;
- (IBAction) threetimePayButtonPressed:(id)sender;
- (IBAction) fivetimePayButtonPressed:(id)sender;
- (IBAction) recurringPayButtonPressed:(id)sender;
- (void)     invokePaymentWebService:(NSString *)paymentChoice;
- (void)     checkDefaultPayment:(SKPaymentTransaction *)trans pid:(NSString*)pid;
- (void)     checkFreeCalls;
- (int64_t) getBalanceCalls;
- (void)insertPaymentChoice:(NSString *)paymentChoice quantity:(int64_t)quantity;
- (void)addDefaultPayment;
- (v2bPayment *)fetchPaymentByChoice:(NSString *)choice;
- (void)updatePaymentChoice:(NSString *)choice quantity:(int64_t)quantity;
- (BOOL) isEmpty:(id)thing;
- (void)addActivityIndicator:(NSString *)prompt;
-(void)invokePaymentWebService:(NSString *)paymentChoice quantity:(int64_t)quantity receipt:(NSString *)receipt
    trans:(SKPaymentTransaction*)trans pid:(NSString*)pid;
- (void)httpGetCallback:(XmitMain *)fetcher op:(PageGetOperation *)op;
- (void) removeActivityIndicator;
- (NSString*) createEncodedString:(NSData*)data;
- (void) clearPaymentQueue;
- (IBAction)activateButtonPressed:(id)sender;

// payment public methods
- (void)loadStore;
- (BOOL)canMakePurchases;
- (void)purchaseProUpgrade;
- (void) checkExpiry;
- (NSDate *) fetchExpiry;
- (void) insertExpiry:(NSString*)exp;
- (void) incrementExpiry:(int)numberOfDays;
- (int64_t) getMaxDuration;

@end
