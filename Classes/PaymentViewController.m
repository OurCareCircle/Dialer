//
//  PaymentViewController.m
//  Voice2Buzz
//
//  Created by sanjay krishnamurthy on 12/21/10.
//  Copyright 2010 Infinear Inc. All rights reserved.
//

#import "PaymentViewController.h"
#import "PersistentTableAppDelegate.h"
#import "v2bPayment.h"
#import "v2bFolder.h"
#import "XmitMain.h"
#import "JSON.h"
#import <StoreKit/StoreKit.h>
#import <StoreKit/SKProductsRequest.h>
#import "QuartzCore/CAAnimation.h"

@implementation PaymentViewController

@synthesize OnetimePayButton;
@synthesize RecurringPayButton;
@synthesize paymentOK;
@synthesize defEmail;
@synthesize telNum;
@synthesize ccode;

//Use this payment choice for the initial setting for all users
NSString *DEFAULT_PAYMENT = @"DEFAULT_PAYMENT";

//Use this as the default number of permitted calls
int64_t    DEFAULT_QUANTITY = 3;
//free calls have this duration in seconds
int64_t    FREE_CALL_DURATION = 900;
//regular paid calls have this max duration
int64_t    PAID_CALL_DURATION = 3600;

//Use constants below to provide content based on chosen payment method
int64_t    REC_QUANTITY1 = 31;
int64_t    REC_QUANTITY3 = 91;
int64_t    REC_QUANTITY6 = 181;
int64_t    REC_QUANTITY7 = 7;

//track balance recordings for user
int64_t    callsRemaining;

//Actual transaction code follows; use unique ids every debug run
#define kInAppPurchaseProUpgradeProductId  @"com.infinear.dialer.30"
#define kInAppPurchaseProUpgradeProductId3 @"com.infinear.dialer.90"
#define kInAppPurchaseProUpgradeProductId6 @"com.infinear.dialer.180"
#define kInAppPurchaseProUpgradeProductId7 @"com.infinear.dialer.7"
//DISABLE MONTHLY PAYMENTS for Apple
#define kInAppPurchaseProUpgradeMonthlyProductId @"com.infinear.dialer.Monthly"

//store locally with these flags
#define kInAppPurchaseProUpgradeProductIdStore @"com.infinear.dialer.Single.store.1"
//DISABLE MONTHLY PAYMENTS for Apple
#define kInAppPurchaseProUpgradeMonthlyProductIdStore @"com.infinear.dialer.Monthly.store.1"


//clear out payment queue before using any payment method
- (void) clearPaymentQueue
{		
	[[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
	return;
}

//
// oneTimePayButtonPressed:
//
// Handles the single payment button press action
//
// Parameters:
//    sender - normally, the save button.
//
- (IBAction) onetimePayButtonPressed:(id)sender
{		
	//REMOVE THIS AFTER TESTING IN SANDBOX 010212 !!!
	//[[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
	//return;
	
	//Log all user selections
	NSLog(@"User chose one time payment option");
	
	//choose correct product first
	[self requestProUpgradeProductData:kInAppPurchaseProUpgradeProductId7];
	
	//Display a message stating choice has been saved
	NSString            *prompt = @"Choice noted";
	self.navigationItem.title   = prompt;
	
} //OneTimePayButtonPressed

//
// Handles the 3 recordings payment button press action
//
// Parameters:
//    sender - normally, the save button.
//
- (IBAction) threetimePayButtonPressed:(id)sender
{
	//Log all user selections
	NSLog(@"User chose three  time payment option");
	
	//choose correct product first
	[self requestProUpgradeProductData:kInAppPurchaseProUpgradeProductId];
	
	//Display a message stating choice has been saved
	NSString            *prompt = @"Choice noted";
	self.navigationItem.title   = prompt;
	
} //threeTimePayButtonPressed

//
// Handles the 3 recordings payment button press action
//
// Parameters:
//    sender - normally, the save button.
//
- (IBAction) fivetimePayButtonPressed:(id)sender
{
	//Log all user selections
	NSLog(@"User chose five  time payment option");
	
	//choose correct product first
	[self requestProUpgradeProductData:kInAppPurchaseProUpgradeProductId6];
	
	//Display a message stating choice has been saved
	NSString            *prompt = @"Choice noted";
	self.navigationItem.title   = prompt;
	
} //fiveTimePayButtonPressed

//
// Handles the single payment button press action
//
// Parameters:
//    sender - normally, the save button.
//
- (IBAction) recurringPayButtonPressed:(id)sender
{
	//Log all user selections
	NSLog(@"User chose recurring payment option");
	
	//choose correct product first
	[self requestProUpgradeProductData:kInAppPurchaseProUpgradeMonthlyProductId];
	
	//Display a message stating choice has been saved
	NSString            *prompt = @"Choice noted";
	self.navigationItem.title   = prompt;
	
} //RecurringPayButtonPressed

//
// activateButtonPressed:
//
// Handles the activate additional devices button press action
//
// Parameters:
//    sender - normally, the save button.
//
- (IBAction)activateButtonPressed:(id)sender
{	
	//check default free calls only; subscriptions need to be checked inside PaymentViewController
	[self checkDefaultPayment:NULL pid:NULL]; //no transaction and pid available
	
}

//Payments code follows
- (void)requestProUpgradeProductData:(NSString *)choice
{
	//Add popup to show activity being done on server
	//show activity indicator; dismiss when response arrives from apple
	NSString *prompt = [NSString stringWithFormat:@"%@", @"Contacting Apple.."];	
	[self addActivityIndicator:prompt];
	
    NSSet *productIdentifiers = [NSSet setWithObject:choice ];
    productsRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:productIdentifiers];
    productsRequest.delegate = self;
    [productsRequest start];
    
    // we will release the request object in the delegate callback
    //082113 retain else you get exception
    [defEmail retain];
}

#pragma mark -
#pragma mark SKProductsRequestDelegate methods

- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response
{
	//dismiss activity indicator; it will be added gain iff the response was valid; else 
	//an alert is shown
	[self removeActivityIndicator];
	
    NSArray *products = response.products;
    proUpgradeProduct = [products count] == 1 ? [[products firstObject] retain] : nil;
	BOOL     isValid  = true; //did you get valid response back from apple?
	
    if (proUpgradeProduct)
    {
        NSLog(@"Product title: %@" ,       proUpgradeProduct.localizedTitle);
        NSLog(@"Product description: %@" , proUpgradeProduct.localizedDescription);
        NSLog(@"Product price: %@" ,       proUpgradeProduct.price);
        NSLog(@"Product id: %@" ,          proUpgradeProduct.productIdentifier);
    }
    
    for (NSString *invalidProductId in response.invalidProductIdentifiers)
    {
        NSLog(@"Invalid product id: %@" , invalidProductId);
		isValid = false;
    }
    
    // finally release the reqest we alloc/init’ed in requestProUpgradeProductData
    [productsRequest release];
    [[NSNotificationCenter defaultCenter] postNotificationName:kInAppPurchaseManagerProductsFetchedNotification object:self userInfo:nil];
	
	//if the response is valid, proceed with payment process; else display error alert
	if (isValid) {
		if ([self canMakePurchases]) {
			[self purchaseProUpgrade:proUpgradeProduct.productIdentifier];
		}
	}
	else {
		//show an alert to the user
		NSString *message  = [NSString stringWithFormat:@"%@%@", @"Invalid Product id:",proUpgradeProduct.productIdentifier];
		UIAlertView *alert = [[UIAlertView alloc]
							  initWithTitle: @"Error"
							  message: message
							  delegate: nil
							  cancelButtonTitle:@"OK"
							  otherButtonTitles:nil];
		[alert show];
		[alert release];
	}
}

//delegate for the sole alert view in this viewcontroller
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	if (buttonIndex == 0) {
		NSLog(@"user pressed OK");
	}
	else {
		NSLog(@"user pressed Cancel");
	}
}

#pragma -
#pragma Public methods

//
// call this method once on startup
//
- (void)loadStore
{
    // restarts any purchases if they were interrupted last time the app was open
    [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
    
    // get the product description (defined in early sections)
    //DONE in method that invokes proper payment type
	//[self requestProUpgradeProductData];
}

//
// call this before making a purchase
//
- (BOOL)canMakePurchases
{
    return [SKPaymentQueue canMakePayments];
}

//
// kick off the upgrade transaction
//
- (void)purchaseProUpgrade:(NSString *)choice
{
	//Add popup to show activity being done on server
	//show activity indicator; dismiss when get op done
	NSString *prompt = [NSString stringWithFormat:@"%@", @"Contacting Apple.."];	
	[self addActivityIndicator:prompt];
	
    SKPayment *payment = [SKPayment paymentWithProductIdentifier:choice];
    [[SKPaymentQueue defaultQueue] addPayment:payment];
}

#pragma -
#pragma Purchase helpers

//
// saves a record of the transaction by storing the receipt to disk
//
- (void)recordTransaction:(SKPaymentTransaction *)transaction
{
    NSString *pid = transaction.payment.productIdentifier;
    if ([pid isEqualToString:kInAppPurchaseProUpgradeProductId]  ||
		[pid isEqualToString:kInAppPurchaseProUpgradeProductId3] ||
		[pid isEqualToString:kInAppPurchaseProUpgradeProductId6] ||
        [pid isEqualToString:kInAppPurchaseProUpgradeProductId7] ||
		[pid isEqualToString:kInAppPurchaseProUpgradeMonthlyProductId])
    {
		//store receipt on local disk; use store flags instead of default productid
		NSString *storeFlag = kInAppPurchaseProUpgradeProductIdStore;
        
        //DISABLE MONTHLY PAYMENT choice for Apple
		//if ([transaction.payment.productIdentifier isEqualToString:kInAppPurchaseProUpgradeMonthlyProductId]) {
		//	storeFlag = kInAppPurchaseProUpgradeMonthlyProductIdStore;
		//}
        
        //fetch receipt
        NSData    *receipt      = transaction.transactionReceipt;
        NSString *receiptString = [self createEncodedString:receipt];
        NSLog(@"Receipt:%@", receiptString);
		
		//Archive receipt to store file
		NSMutableData *data;
		NSString *archivePath = [NSTemporaryDirectory() stringByAppendingPathComponent:storeFlag];
		NSKeyedArchiver *archiver;
		BOOL result;
		
		data = [NSMutableData data];
		archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
		// Customize archiver here
		[archiver encodeObject:receipt forKey:storeFlag];
		[archiver finishEncoding];
		result = [data writeToFile:archivePath atomically:YES];
		[archiver release];
        
        //remove contacting apple activity indicator coz checkdefaultpayment will add a new one
        [self removeActivityIndicator];
        
        //to protect against malafide transactions, validate receipt against v2b server
        [self checkDefaultPayment:transaction pid:pid];
    }
}

//
// enable pro features
//
- (void)provideContent:(NSString *)productId
{
	//fetch callsRemaining from persistent store and update it
	//callsRemaining = [self getBalanceCalls];
	
	//if 1 rec or 3 recs or 5 recs button pressed, update callsRemaining variable and store persistently too
	if ([productId isEqualToString:kInAppPurchaseProUpgradeProductId] ||
		[productId isEqualToString:kInAppPurchaseProUpgradeProductId3] ||
        [productId isEqualToString:kInAppPurchaseProUpgradeProductId7] ||
		[productId isEqualToString:kInAppPurchaseProUpgradeProductId6] )
    {
		if ([productId isEqualToString:kInAppPurchaseProUpgradeProductId]) {
			callsRemaining = REC_QUANTITY1;
		}
		else if ([productId isEqualToString:kInAppPurchaseProUpgradeProductId3]) {
			callsRemaining = REC_QUANTITY3;
		}
		else  if ([productId isEqualToString:kInAppPurchaseProUpgradeProductId6]){
			callsRemaining = REC_QUANTITY6;
		}
        else  if ([productId isEqualToString:kInAppPurchaseProUpgradeProductId7]) {
            callsRemaining = REC_QUANTITY7;
        }
		
		//update persistent store
		//[self updatePaymentChoice:DEFAULT_PAYMENT quantity:callsRemaining];
        [self incrementExpiry:callsRemaining]; //increment expiry period by this many days
	}		
	
	if ([productId isEqualToString:kInAppPurchaseProUpgradeProductId]  ||
		[productId isEqualToString:kInAppPurchaseProUpgradeProductId3] ||
		[productId isEqualToString:kInAppPurchaseProUpgradeProductId6] ||
        [productId isEqualToString:kInAppPurchaseProUpgradeProductId7] ||
		[productId isEqualToString:kInAppPurchaseProUpgradeMonthlyProductId])
    {
        // enable the pro features
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"isProUpgradePurchased" ];
        [[NSUserDefaults standardUserDefaults] synchronize];
		
		//set boolean to indicate payment went ok
		paymentOK = [[NSNumber alloc] initWithBool:true];
		
		//pop back to parent view; 012112 moved pop to finishTransaction
		//012112 UINavigationController *nav = [self navigationController];		
		//012112 [nav popViewControllerAnimated:NO];
    }
}

//
// removes the transaction from the queue and posts a notification with the transaction result
//
- (void)finishTransaction:(SKPaymentTransaction *)transaction wasSuccessful:(BOOL)wasSuccessful
{
    // remove the transaction from the payment queue.
    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
    
    NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:transaction, @"transaction" , nil];
    if (wasSuccessful)
    {
        // send out a notification that we’ve finished the transaction
        [[NSNotificationCenter defaultCenter] postNotificationName:kInAppPurchaseManagerTransactionSucceededNotification object:self userInfo:userInfo];
    }
    else
    {
        // send out a notification for the failed transaction
        [[NSNotificationCenter defaultCenter] postNotificationName:kInAppPurchaseManagerTransactionFailedNotification object:self userInfo:userInfo];
    }
		
	//Remove activity indicator setup in purchaseProUpgrade method
	[self removeActivityIndicator];
	
	//remove observer; else you will get exception
	[[SKPaymentQueue defaultQueue] removeTransactionObserver:self];
	
	//pop back to parent view; 
	UINavigationController *nav = [self navigationController];		
	[nav popToRootViewControllerAnimated:NO];

}

//
// called when the transaction was successful
//
- (void)completeTransaction:(SKPaymentTransaction *)transaction
{
    //recordTransaction invokes v2b server to validate receipt; if receipt invalid,
    //dont provide content
	[self recordTransaction:transaction];
    
}

//
// called when a transaction has been restored and and successfully completed
//
- (void)restoreTransaction:(SKPaymentTransaction *)transaction
{
	NSLog(@"Abandoning restore of  transaction with product id %@", transaction.originalTransaction.payment.productIdentifier);
	// remove the transaction from the payment queue.
    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
	
	//061111 I am getting random restores from Apple that I need to ignore
	/*
    [self recordTransaction:transaction.originalTransaction];
    [self provideContent:transaction.originalTransaction.payment.productIdentifier];
    [self finishTransaction:transaction wasSuccessful:YES];
	*/
}

//
// called when a transaction has failed
//
- (void)failedTransaction:(SKPaymentTransaction *)transaction
{
	//For cancellations too, remove activity indicator setup during purchaseProUpgrade
	[self removeActivityIndicator];
	
    if (transaction.error.code != SKErrorPaymentCancelled)
    {
        // error!
        [self finishTransaction:transaction wasSuccessful:NO];
    }
    else
    {
        // this is fine, the user just cancelled, so don’t notify
        [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
    }
}

#pragma mark -
#pragma mark SKPaymentTransactionObserver methods

//
// called when the transaction status is updated
//
- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions
{
    for (SKPaymentTransaction *transaction in transactions)
    {
        switch (transaction.transactionState)
        {
            case SKPaymentTransactionStatePurchased:
                [self completeTransaction:transaction];
                break;
            case SKPaymentTransactionStateFailed:
                [self failedTransaction:transaction];
                break;
            case SKPaymentTransactionStateRestored:
                [self restoreTransaction:transaction];
                break;
            default:
                break;
        }
    }
}

//Main method to decide if user is ok to proceed with call recording;
//sets paymentOK to true iff default number of call recordings is > 0
//DISABLING MONTHLY PAYMENT checks on 091611 for Apple
- (void) checkDefaultPayment:(SKPaymentTransaction *)trans pid:(NSString*)pid {

	//Mark payment not ok; then check for recurring transactions; it will be set to ok if things  succeed
	paymentOK = [[NSNumber alloc] initWithBool:FALSE];
		
	//default number of free recordings unavailable; now check for existing valid recurring transaction
	//get old transaction this way; NOTE use store flag instead of product id
	NSData *receipt = nil;
    
    NSString *storeFlag = kInAppPurchaseProUpgradeProductIdStore;
    
    //DISABLE MONTHLY PAYMENT choice for Apple
    //if ([transaction.payment.productIdentifier isEqualToString:kInAppPurchaseProUpgradeMonthlyProductId]) {
    //	storeFlag = kInAppPurchaseProUpgradeMonthlyProductIdStore;
    //}
		
	NSData *data;
	NSKeyedUnarchiver *unarchiver; 
	NSString *archivePath = [NSTemporaryDirectory() stringByAppendingPathComponent:storeFlag];
		
	data = [NSData dataWithContentsOfFile:archivePath];
	unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
	// Customize unarchiver here; 
	receipt = [unarchiver decodeObjectForKey:storeFlag];
	[unarchiver finishDecoding];
	[unarchiver release];
		
	//if no monthly subscription exists in local db, check v2b server anyways for existing
	//subscription 070311
	NSString* receiptString = @""; //send empty receipt to v2b server by default
	if (![self isEmpty:receipt]) {
		//base64 encode receipt
		receiptString = [self createEncodedString:receipt];
	}
    
    //determine quantity ie #days of this subscription using the product id
    //110112 The default qty should be zero not 30; else when you activate devices, you will increment
    //exp date needlessly.
    int qty = 0; //default is 0 days
    if ([pid isEqualToString:kInAppPurchaseProUpgradeProductId]) {
        qty = 30;
    }
    else if ([pid isEqualToString:kInAppPurchaseProUpgradeProductId3]) {
        qty = 90;
    }
    else if ([pid isEqualToString:kInAppPurchaseProUpgradeProductId6]) {
        qty = 180;
    }
    else if ([pid isEqualToString:kInAppPurchaseProUpgradeProductId7]) {
        qty = 7;
    }
		
	//invoke v2b server for validation; note qty is passed in to v2b server
	[self invokePaymentWebService:storeFlag quantity:qty receipt:receiptString trans:trans pid:pid ccode:ccode];
	[receiptString release];
		
	//052311 I tried just restoring monthly subscriptions on client. But user
	//is prompted for password EVERY call which is very bad. So, we now validate
	//against Apple servers
	//[[SKPaymentQueue defaultQueue] restoreCompletedTransactions];

}

//check free calls only; not subscriptions
- (void) checkFreeCalls {
	v2bPayment *pay = [self fetchPaymentByChoice:DEFAULT_PAYMENT];
	NSNumber   *num = [pay valueForKey:@"Quantity"];  //always use this mechanism for managed objects
	int64_t     qty = [num intValue];
	
	if  (qty > 0) {
		//free recordings still available
		paymentOK = [[NSNumber alloc] initWithBool:true];
		
		qty = qty -1;
		[self updatePaymentChoice:DEFAULT_PAYMENT quantity:qty];
		//update callsRemaining variable used to display balance to user
		callsRemaining = qty;
        
	}
    else {
        paymentOK = [[NSNumber alloc] initWithBool:false];
    }
	
}

//fetch current expiry period
- (NSDate *) fetchExpiry {
	v2bPayment *pay = [self fetchPaymentByChoice:DEFAULT_PAYMENT];
    //always use the mechanism below for managed objects
	NSDate   *exp = [pay valueForKey:@"PaymentDate"];	
    return exp;	
}

//insert a date string fetched from v2b server into local db
- (void) insertExpiry:(NSString*)exp {

    NSDateFormatter *dateFormatter=[[[NSDateFormatter alloc] init] autorelease] ;
    [dateFormatter setDateFormat:@"yyyy-MM-dd"];
    NSDate *date                  = [[[NSDate alloc] init] autorelease];
    date                          = [dateFormatter dateFromString:exp];

    
    //update the expiry period in persistent store
    v2bPayment *pay = [self fetchPaymentByChoice:DEFAULT_PAYMENT];
    pay.PaymentDate = date;
    
    // Commit the change.
    NSError *error = nil;
    if (![managedObjectContext save:&error]) {
        // Handle the error.
        NSLog(@"Error inserting exp date: %@", [error localizedDescription]);
    }
}


//check if current expiry period is ok or not; sets paymentOK flag on exit
- (void) checkExpiry {
    NSDate *startDate            = [NSDate date];
    NSDate *endDate              = [self fetchExpiry];
    
    NSCalendar *gregorian        = [[NSCalendar alloc]
                                     initWithCalendarIdentifier:NSGregorianCalendar];
    
    NSUInteger unitFlags         = NSMonthCalendarUnit | NSDayCalendarUnit;
    
    NSDateComponents *components = [gregorian components:unitFlags
                                                fromDate:startDate
                                                  toDate:endDate options:0];
    NSInteger months             = [components month];
    NSInteger days               = [components day];
    
    //mark all diffs greater than zero as ok; NOTE current day will return false
    //So diff has to be greater than zero
    if (months > 0 || days > 0) {
        paymentOK = [[NSNumber alloc] initWithBool:true];
    }
    else {
        paymentOK = [[NSNumber alloc] initWithBool:false];
    }
}

//add x days to expiry period; used when user purchases additional time
- (void) incrementExpiry:(int)numberOfDays {
    //if current subscription is still valid, use current expiry date; else use today's date
    NSDate *exp  = [self fetchExpiry];
    [self checkExpiry];
    if (paymentOK.boolValue == false) {
        //subscription isnt valid; use todays date
        exp = [NSDate date];
    }
    
    NSCalendar *gregorian = [[NSCalendar alloc]
                             initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents *offsetComponents = [[NSDateComponents alloc] init];
    [offsetComponents setDay:numberOfDays];
    
    // Calculate new expiry period
    NSDate *newExpiry = [gregorian dateByAddingComponents:offsetComponents
                         toDate:exp options:0];
    
    //update the expiry period in persistent store
    v2bPayment *pay = [self fetchPaymentByChoice:DEFAULT_PAYMENT];
    pay.PaymentDate = newExpiry;
    
    // Commit the change.
    NSError *error = nil;
    if (![managedObjectContext save:&error]) {
        // Handle the error.
        NSLog(@"Error deleting file: %@", [error localizedDescription]);
    }
}

//returns the max duration of current call; free calls have smaller durations
//than regular paid calls. 
- (int64_t) getMaxDuration {
    int64_t  bal  = [self getBalanceCalls];
    int64_t limit = 0; //default
    
    //check expiry; if ok then use higher call duration
    [self checkExpiry];
    if (paymentOK.boolValue == true) {
        limit = PAID_CALL_DURATION;
    }
    else if (bal > 0) {
        limit = FREE_CALL_DURATION;
    }
    return limit;
}

//return balance #calls from persistent storage
- (int64_t) getBalanceCalls {
	v2bPayment *pay = [self fetchPaymentByChoice:DEFAULT_PAYMENT];
	NSNumber   *num = [pay valueForKey:@"Quantity"];  //always use this mechanism for managed objects
	int64_t     qty = [num intValue];
	
	return qty;
}

//transaction receipts need to be base64 encoded to be validated by Apple
- (NSString*) createEncodedString:(NSData*)data
{
    static char table[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=";
	
    const int size = ((data.length + 2)/3)*4;
    uint8_t output[size];
	
    const uint8_t* input = (const uint8_t*)[data bytes];
    for (int i = 0; i < data.length; i += 3)
    {
        int value = 0;
        for (int j = i; j < (i + 3); j++)
        {
            value <<= 8;
            if (j < data.length)
                value |= (0xFF & input[j]);
        }
		
        const int index = (i / 3) * 4;
        output[index + 0] =  table[(value >> 18) & 0x3F];
        output[index + 1] =  table[(value >> 12) & 0x3F];
        output[index + 2] = (i + 1) < data.length ? table[(value >> 6)  & 0x3F] : '=';
        output[index + 3] = (i + 2) < data.length ? table[(value >> 0)  & 0x3F] : '=';
    }    
	
    return  [[NSString alloc] initWithBytes:output length:size encoding:NSASCIIStringEncoding];
}


- (void)insertPaymentChoice:(NSString *)paymentChoice quantity:(int64_t)quantity {	
	NSLog(@"User chose payment choice %@ Qty %d", paymentChoice, quantity);
	
	//create an v2bPayment object to store the current date and current folder name
	// Create and configure a new instance of the Event entity.	
	v2bPayment *event = (v2bPayment *)[NSEntityDescription insertNewObjectForEntityForName:@"v2bPayment" inManagedObjectContext:managedObjectContext];
	[((v2bPayment *)event) setPaymentDate:[NSDate date]];
	[((v2bPayment *)event) setPaymentType:paymentChoice];
	[((v2bPayment *)event) setQuantity:[[NSNumber alloc] initWithInt:quantity]];
	
	//save the new v2bPayment object persistently
	NSError *error = nil;
	if (![managedObjectContext save:&error]) {
		// Handle the error.
		NSLog(@"Error saving payment persistently: %@", [error localizedDescription]);
		
		//no more processing
		return;
	}
}

//Add a special v2b payment for call recordings IFF not present in persistent store
- (void)addDefaultPayment {
	//Is there a v2b payment choice called DEFAULT_PAYMENT in persistent storage?
	v2bPayment *event = (v2bPayment *)[self fetchPaymentByChoice:DEFAULT_PAYMENT];
	
	//insert new folder iff not present
	if (event == nil) {
		[self insertPaymentChoice:DEFAULT_PAYMENT quantity:DEFAULT_QUANTITY];
	}
}

//Self explanatory; returns nil if the particular payment choice doesnt exist
- (v2bPayment *)fetchPaymentByChoice:(NSString *)choice {
	//create fetch request
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"v2bPayment" inManagedObjectContext:managedObjectContext];
	[request setEntity:entity];
	
	// Add a predicate to get a particular folder;	if (currFile != nil && currFile.folderName != nil) {
	NSPredicate *predicate = [NSPredicate predicateWithFormat:
							  @"(PaymentType LIKE[c] %@)", choice];
	[request setPredicate:predicate];
	
	//do the fetch now
	NSError *error = nil;
	NSMutableArray *mutableFetchResults = [[managedObjectContext executeFetchRequest:request error:&error] mutableCopy];
	if (mutableFetchResults == nil || error != NULL) {
		// Handle the error.
		NSLog(@"Error fetching payment choice: %@", [error localizedDescription]);
		return nil;
	}
	
	//if zero results, then no call rec folder exists
	if (mutableFetchResults.count != 1) {
		NSLog(@"Error fetching payment choice: %@", choice);
		return nil;
	}
	
	//cleanup before return
	[request release];
	
	return (v2bPayment *)[mutableFetchResults objectAtIndex:0];
	
} //fetchPaymentByChoice

//Self explanatory; find and update the particular payment choice
- (void)updatePaymentChoice:(NSString *)choice quantity:(int64_t)quantity {
	v2bPayment *pay = [self fetchPaymentByChoice:choice];
	
	//delete this existing payment object
	[managedObjectContext deleteObject:pay];
	
	//Update the current object with new quantity
	[pay setQuantity:[[NSNumber alloc] initWithInt:quantity]];
	
	//insert updated payment object into persistent store
	[self insertPaymentChoice:choice quantity:quantity];
	
} //updatePaymentChoice

//check if string is empty
- (BOOL) isEmpty:(id)thing 
{
    return thing == nil
    || [thing isKindOfClass:[NSNull class]]
    || ([thing respondsToSelector:@selector(length)]
        && [(NSData *)thing length] == 0)
    || ([thing respondsToSelector:@selector(count)]
        && [(NSArray *)thing count] == 0);
}

//Show a custom view when GET ops are being done
- (void)addActivityIndicator:(NSString *)prompt
{
	//Disable all buttons on this page when any long latency event occurs
	OnetimePayButton.enabled            = NO;
	RecurringPayButton.enabled          = NO;
	self.navigationItem.hidesBackButton = YES;
	//Disable all tab bar items too-couldnt get this to work
	/*
	UITabBar  *tabBar = self.tabBarController.tabBar;
	for(UITabBarItem *item in tabBar.items) {
		item.enabled = false;
	}
	 */
	
    myIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
	myIndicator.center = CGPointMake(120, 200);
	myIndicator.hidesWhenStopped = YES; //means when stop is called it is dismissed
	UINavigationController *nav = [self navigationController];
	
	//Add a custom image to indicator view
	UIImage *image       = [UIImage imageNamed: @"loading-128X128.png"];
	UIImageView *imgView = [[UIImageView alloc] initWithImage:image];
	[myIndicator addSubview:imgView];
	
	//Animate the image by rotating it
	CABasicAnimation *fullRotation; 
	fullRotation = [CABasicAnimation 
					animationWithKeyPath:@"transform.rotation"]; 
	fullRotation.fromValue = [NSNumber numberWithFloat:0]; 
	fullRotation.toValue = [NSNumber numberWithFloat:(2*M_PI)]; 
	fullRotation.duration = 1.0;        //durarion in seconds
	fullRotation.repeatCount = 1e100f;  //repeat forever
	// Add the animation group to the layer 
	[imgView.layer addAnimation:fullRotation forKey:@"loading"]; //the forKey is a random id for this animation	
	[imgView release];
	
	//Add a label below the image
	UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(-20, 140, 190, 20)];
	label.text     =  prompt;
	label.backgroundColor = [UIColor colorWithRed:0.773f green:0.80f blue:0.831f alpha:1.0f];
	[myIndicator addSubview:label];
	[label release];
	
	[nav.view  addSubview:myIndicator];
	[myIndicator startAnimating];
}

//Use these local vars to keep state between the invoke and the callback
//callback needs these vars set properly
SKPaymentTransaction *transaction;
NSString             *productId;

//Invoke a webservice wih appropriate user choices for payment to v2b
-(void)invokePaymentWebService:(NSString *)paymentChoice quantity:(int64_t)quantity receipt:(NSString *)receipt
trans:(SKPaymentTransaction*)trans pid:(NSString*)pid ccode:(NSString*)ccode
{
	NSAutoreleasePool *	pool = [[NSAutoreleasePool alloc] init];
	//show activity indicator; dismiss when get op done
	NSString *prompt = [NSString stringWithFormat:@"%@%@", @"Checking Subscription", paymentChoice];	
	[self addActivityIndicator:prompt];
		
	//what is the unique id of this user; use user's default email as key for subscriptions
	NSString *uid       = defEmail; //[PersistentTableAppDelegate getUniqueID];
    //send the udid too to v2b; used to create fileNames for incoming call recordings
    NSString *udid      = [PersistentTableAppDelegate getUniqueID];
    NSString *telNumber = telNum;
		
	//Store uid, current timestamp, payment choice on server
	NSDateFormatter* formatter = [[[NSDateFormatter alloc] init] autorelease];
	[formatter setDateFormat:@"yyyy-MM-dd-HH-MM-SS"];
	NSDate* date       = [NSDate date];
    //if there is a valid expiry date in local db, use that instead
    [self checkExpiry];
    if (paymentOK.boolValue == true) {
        date = [self fetchExpiry];
    }
	NSString* str      = [formatter stringFromDate:date];
	NSString* qty      = [NSString stringWithFormat:@"%d", quantity];
		
	//allocate xmit class with right url; the format for the record op is
	//http://www.infinear.com/call/validatePayment.php?uid=%@&currDate=%@&payment=%@&quantity=%@&receipt=%@
	//Make sure all params to record op are non-empty
		
	//sanitize all params by  replacing all spaces with at chars
	str     = [str  stringByReplacingOccurrencesOfString:@" " withString:@"@"];
		
	//Gen final URL
	//NSString *URLparam = [[[NSString alloc] initWithFormat:@"%@%@%@%@%@%@%@%@%@%@", 
	//					   @"http://www.infinear.com/call/validatePayment.php?uid=", uid,
	//					   @"&currDate=", str,
	//					   @"&payment=",  paymentChoice,
	//					   @"&quantity=", qty,
	//					   @"&receipt=",  receipt ]
	//					   stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
	//remove encoding; 121011 changed url below for ec2
	//NSString *URLparam = [[NSString alloc] initWithFormat:@"%@%@%@%@%@%@%@%@%@%@", 
	//					   @"http://www.infinear.com/call/validatePayment.php?uid=", uid,
	//					   @"&currDate=", str,
	//					   @"&payment=",  paymentChoice,
	//					   @"&quantity=", qty,
	//					   @"&receipt=",  receipt ];
	NSString *URLparam = [[NSString alloc] initWithFormat:@"%@%@%@%@%@%@%@%@%@%@%@%@%@%@%@%@", 
						  @"http://ec2-107-21-106-75.compute-1.amazonaws.com/call/validatePayment.php?uid=", uid,
						  @"&currDate=",  str,
						  @"&payment=",   paymentChoice,
						  @"&quantity=",  qty,
						  @"&receipt=",   receipt,
                          @"&telNumber=", telNumber,
                          @"&ccode=",     ccode,
                          @"&udid=",       udid];
	NSString *OP       = @"GET";  
	NSLog(@"URLparam is %@", URLparam);
	NSURL    *param    = [NSURL URLWithString:URLparam];
	xmit               = [[XmitMain alloc] initWithURL:param xmitop:OP fileName:nil];
		
	//set the callback inside the xmit class
    transaction = trans;
    productId   = pid;
	[xmit setDelegate:self];
		
	//020511 increase retain count so that self is retained till callback invoked
	[self retain];
		
	[xmit start];	
	//[URLparam release];
	[pool release];
	
} //invokePaymentWebService

//implement callback for GET contents; this is invoked by XmitMain
- (void)httpGetCallback:(XmitMain *)fetcher op:(PageGetOperation *)op {
	//op could be junk
	if (op != nil) {
		//dismiss activity indicator
		//[self removeActivityIndicator];
		
		NSData *responseData = [op responseBody];
		NSString *content    = [[NSString alloc]  initWithBytes:[responseData bytes]
														 length:[responseData length] encoding: NSUTF8StringEncoding];
		NSLog(@"Call recording reply from server is \"%@\"", content);	
		
		//content ought to be sane JSON data-parse it and extract the reply  from server
		//usually in this form {"true"} or {"false"}
		NSDictionary *dictionary = [content JSONValue];
		NSString *reply          = [dictionary objectForKey:@"validity"];
        NSString *expDate        = [dictionary objectForKey:@"expDate"];

		NSLog(@"Validate payment reply from server is \"%@\" and expDate is \"%@\"", reply, expDate);
		//[content release];
		
		//convert reply to boolean and set global flag before returning from this view
		BOOL  flag = [reply boolValue];
		if (flag) {
            //set boolean to indicate payment went ok
            paymentOK = [[NSNumber alloc] initWithBool:true];
		}
		else {
			//Display a brief message in the title indicating the user is done now
			NSString            *prompt = @"Invalid subscription";
			self.navigationItem.title   = prompt;
            //set boolean to indicate payment is not ok
            paymentOK = [[NSNumber alloc] initWithBool:false];
		}
        
        //if there is an expiry date in response from server and there is no valid transaction,
        //just insert expiry date into local db
        if (![self isEmpty:expDate] && transaction == NULL) {
            [self insertExpiry:expDate];
            
            //dismiss activity indicator
            [self removeActivityIndicator];
            
            //pop back to parent view coz you are done processing
            UINavigationController *nav = [self navigationController];
            [nav popToRootViewControllerAnimated:NO];
        }
        else {
            //serve content iff receipt is valid
            if (paymentOK.boolValue == true) {
                [self provideContent:productId];
                [self finishTransaction:transaction wasSuccessful:YES];
            }
            else {
                //end transaction without providing content
                [self finishTransaction:transaction wasSuccessful:NO];
            }
        }
		
		//release self retained before http call is issued
		//[self release];
		
	}
} //httpGetCallback

- (void) removeActivityIndicator {
	//Enable all buttons on this page when activity done
	OnetimePayButton.enabled            = YES;
	RecurringPayButton.enabled          = YES;
	self.navigationItem.hidesBackButton = NO;
	//Enable all tab bar items too-couldnt get this to work properly
	/*
	UITabBar  *tabBar = self.tabBarController.tabBar;
	for(UITabBarItem *item in tabBar.items) {
		item.enabled = TRUE;
	}
	*/
	
	[myIndicator stopAnimating];
    //if transaction observors fire without user action, then this release will fail
    if (![self isEmpty:defEmail]) {
        [myIndicator release];
    }
}

/*
 // The designated initializer. Override to perform setup that is required before the view is loaded.
 - (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
 self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
 if (self) {
 // Custom initialization
 }
 return self;
 }
 */

/*
 // Implement loadView to create a view hierarchy programmatically, without using a nib.
 - (void)loadView {
 }
 */


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
	
	//Alloc a persistent controller
	persistentController = [[PersistentTableAppDelegate alloc] initRootViewController];
	managedObjectContext = persistentController.managedObjectContext;
	[persistentController release]; //done with root controller; just need the store context
	
	//add the default number of call recordings if not present
	[self addDefaultPayment];
	
	//do onetime setup for payments
	[self loadStore];

}

- (void)viewWillAppear:(BOOL)animated {
	//Reset title every time view is loaded
	NSString            *prompt = @"handsfree.ly Payment Options";
	self.navigationItem.title   = prompt;
}

//check subscriptions only after this view has been pushed onto the nav stack
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
	
	//DISABLING MONTHLY PAYMENT checks on 091611 for Apple
	//[self checkDefaultPayment];
}


 // Override to allow orientations other than the default portrait orientation.
 - (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
 // Return YES for supported orientations
 return (interfaceOrientation == UIInterfaceOrientationPortrait);
 }
 

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
	self.OnetimePayButton = nil;
	self.RecurringPayButton = nil;
}


- (void)dealloc {
	//remove observer; else you will get exception
	[[SKPaymentQueue defaultQueue] removeTransactionObserver:self];
	//For some reason, I cant release button explicitly; I get an exception if I do??? 071711
	//[OnetimePayButton release];
	//[RecurringPayButton release];
    [super dealloc];
}

@end
