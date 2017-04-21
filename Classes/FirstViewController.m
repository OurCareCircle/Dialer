//
//  FirstViewController.m
//  Voice2Buzz
//
//  Created by sanjay krishnamurthy on 12/21/10.
//  Copyright 2010 Infinear Inc. All rights reserved.
//

#import "FirstViewController.h"
#import "PersistentTableAppDelegate.h"
#import "v2bSettings.h"
#import "XmitMain.h"
#import "PaymentViewController.h"
#import "QuartzCore/CAAnimation.h"
#import "KeypadAppDelegate.h"

@implementation FirstViewController

@synthesize addDirButton;
@synthesize defaultEmail;
@synthesize yourName;
@synthesize xferSpeed;
@synthesize saveButton;
@synthesize telNum;
@synthesize balanceSeconds;
@synthesize recButton;
@synthesize persistentController;
@synthesize ccode;
@synthesize toCcode;

//Keep the countries array in sync with the ccodes array below
NSString *countries[] = {
	@"US/Canada",
	@"India",
    @"Cambodia",
	@"Israel",
	@"Australia",
	@"Vietnam",
	@"Algeria",
	@"Angola",
	@"Anguilla",
	@"Antigua and Barbuda",
	@"Argentina",
	@"Armenia",
	@"Australia",
	@"Austria",
	@"Azerbaijan",
	@"Bahamas",
	@"Bahrain",
	@"Barbados",
	@"Belarus",
	@"Belgium",
	@"Belize",
	@"Bermuda",
	@"Bolivia",
	@"Botswana",
	@"Brazil",
	@"Brunei",
	@"Bulgaria",
	@"Canada",
	@"Cayman Islands",
	@"Chile",
	@"China",
	@"Costa Rica",
	@"Croatia",
	@"Cyprus",
	@"Czech Republic",
	@"Denmark",
	@"Dominica",
	@"Dominican Republic",
	@"Ecuador",
	@"Egypt",
	@"El Salvador",
	@"Estonia",
	@"Finland",
	@"France",
	@"Germany",
	@"Ghana",
	@"Greece",
	@"Grenada",
	@"Guam",
	@"Guatemala",
	@"Guyana",
	@"Honduras",
	@"Hong Kong",
	@"Hungary",
	@"Iceland",
	@"India",
	@"Indonesia",
	@"Ireland",
	@"Israel",
	@"Italy",
	@"Jamaica",
	@"Japan",
	@"Jordan",
	@"Kazakhstan",
	@"Kenya",
	@"Kuwait",
	@"Latvia",
	@"Lebanon",
	@"Lithuania",
	@"Luxembourg",
	@"Macau",
	@"Macedonia",
	@"Madagascar",
	@"Malaysia",
	@"Mali",
	@"Malta",
	@"Mauritius",
	@"Mexico",
	@"Moldova",
	@"Montserrat",
	@"Morocco",
	@"Mozambique",
	@"Netherlands",
	@"New Zealand",
	@"Nicaragua",
	@"Niger",
	@"Nigeria",
	@"Norway",
	@"Oman",
	@"Pakistan",
	@"Palau",
	@"Panama",
	@"Paraguay",
	@"Peru",
	@"Philippines",
	@"Poland",
	@"Portugal",
	@"Qatar",
	@"Romania",
	@"Russia",
	@"Rwanda",
	@"Saudi Arabia",
	@"Senegal",
	@"Singapore",
	@"Slovakia",
	@"Slovenia",
	@"South Africa",
	@"South Korea",
	@"Spain",
	@"Sri Lanka",
	@"Saint Kitts and Nevis",
	@"Saint Lucia",
	@"Suriname",
	@"Sweden",
	@"Switzerland",
	@"Taiwan",
	@"Tanzania",
	@"Thailand",
	@"Trinidad and Tobago",
	@"Tunisia",
	@"Turkey",
	@"Turks and Caicos Islands",
	@"United Arab Emirates",
	@"Uganda",
	@"United Kingdom",
	@"Uruguay",
	@"United States",
	@"Uzbekistan",
	@"Venezuela",
	@"Vietnam",
	@"US Virgin Islands",
	@"Yemen"
};

NSString *ccodes[] = {
	@"1",
	@"91",
    @"855",
	@"972",
	@"61",
	@"84",
	@"213",
	@"244",
	@"1264",
	@"1268",
	@"54",
	@"374",
	@"61",
	@"43",
	@"994",
	@"1242",
	@"973",
	@"1246",
	@"375",
	@"32",
	@"501",
	@"1441",
	@"591",
	@"267",
	@"55",
	@"673",
	@"359",
	@"1",
	@"1345",
	@"56",
	@"86",
	@"506",
	@"385",
	@"357",
	@"420",
	@"45",
	@"1767",
	@"1809",
	@"593",
	@"20",
	@"503",
	@"372",
	@"358",
	@"33",
	@"49",
	@"233",
	@"30",
	@"1473",
	@"1671",
	@"502",
	@"592",
	@"504",
	@"852",
	@"36",
	@"354",
	@"91",
	@"62",
	@"353",
	@"972",
	@"39",
	@"1876",
	@"81",
	@"962",
	@"7",
	@"254",
	@"965",
	@"371",
	@"961",
	@"370",
	@"352",
	@"853",
	@"389",
	@"261",
	@"60",
	@"223",
	@"356",
	@"230",
	@"52",
	@"373",
	@"1664",
	@"212",
	@"258",
	@"31",
	@"64",
	@"505",
	@"227",
	@"234",
	@"47",
	@"968",
	@"92",
	@"680",
	@"507",
	@"595",
	@"51",
	@"63",
	@"48",
	@"351",
	@"974",
	@"40",
	@"7",
	@"250",
	@"966",
	@"221",
	@"65",
	@"421",
	@"386",
	@"27",
	@"82",
	@"34",
	@"94",
	@"1869",
	@"1758",
	@"597",
	@"46",
	@"41",
	@"886",
	@"255",
	@"66",
	@"1868",
	@"216",
	@"90",
	@"1649",
	@"971",
	@"256",
	@"44",
	@"598",
	@"1",
	@"998",
	@"58",
	@"84",
	@"1340",
	@"967"
};

//Need static method to find size of extern array from other files
+ (NSInteger) sizeofCountries {
    return sizeof(countries)/sizeof(NSString *);
}

//Same delegate processes multiple alerts by tagging each alerts
#define kAlertViewOne 1
#define kAlertViewTwo 2

//picker view delegates
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView;
{
    return 1;
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    ccode = ccodes[row];
	NSLog(@"Picked country %@ with code %@ %d %d\n", countries[row], ccodes[row], sizeof(countries), sizeof(ccodes));
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component;
{
    return [FirstViewController sizeofCountries];
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component;
{
    return countries[row];
}

- (IBAction)saveButtonPressed:(id)sender
{
	//show an alert to the user with data transmission details
	NSString *message  = [NSString stringWithFormat:@"%@", @"Your tel#, country location and email address is transmitted to the server on every call. handsfree.ly does not share this information with any other partner or vendor. The complete handsfree.ly privacy policy can be found at http://handsfree.ly/privacy.php"];
	UIAlertView *alert = [[UIAlertView alloc]
						  initWithTitle: @"User Data Transmission"
						  message: message
						  delegate:self
						  cancelButtonTitle:@"Allow"
						  otherButtonTitles:@"Disallow",
						  nil];
	
	//tag this alert
	alert.tag = kAlertViewOne;
	[alert show];
	[alert release];
}

//Add an alert when user presses Test button
- (IBAction)testButtonPressed:(id)sender
{
	//show an alert to the user with data transmission details
	NSString *message  = [NSString stringWithFormat:@"%@", @"In 5-10seconds, handsfree.ly will call this tel#. If you do not receive a call, make sure US numbers look like 14085551212. i.e. one followed by your area code followed by your tel#.\nNumbers outside USA, please use zero followed by country code followed by your tel#\nSample number outside USA: 0919980199963 where 91 = India country code, 9980199963 = tel#"];
	UIAlertView *alert = [[UIAlertView alloc]
						  initWithTitle: @"Testing tel#"
						  message: message
						  delegate:self
						  cancelButtonTitle:@"OK"
						  otherButtonTitles:nil,
						  nil];
	
	//tag this alert
	alert.tag = kAlertViewTwo;
	[alert show];
	[alert release];
}

//delegate for the sole alert view in this viewcontroller
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	//check the tag before processing
	if(alertView.tag == kAlertViewOne) {
		if (buttonIndex == 0) {
			NSLog(@"user pressed OK");
			[self saveButtonPressedInternal:nil];
		}
		else {
			NSLog(@"user pressed Cancel");
		}
	}
	else {
		//invoke server side method to test user tel#
		NSLog(@"Testing alert: user pressed OK");
		[self checkTelNumber];
	}
}


//
// saveButtonPressedInternal:
//
// Handles the save settings button press action
//
// Parameters:
//    sender - normally, the save button.
//
- (IBAction)saveButtonPressedInternal:(id)sender
{
	//Log all user settings; for vmail
	//force segemnt to be zero
	int selectedSegmentIndex = 0; //for vmail only [xferSpeed selectedSegmentIndex];
	
	//init doesnt get called when app is in background; so set yourName again here
	yourName     = [[UITextField alloc] init];
	[yourName setText:@"vmailDefault"];
	
	NSLog(@"segmentAction: selected segment = %d", selectedSegmentIndex);
	NSLog(@"defaultEmail:  %@", [defaultEmail text]);
	NSLog(@"name:  %@", [yourName text]);
	NSLog(@"ccode:  %@", ccode);
	NSLog(@"tel:  %@",  [telNum text]);
	
	//create a dictionary of user settings
	NSNumber *xSpeed   = [[v2bSettings getV2bXferArr] objectAtIndex:selectedSegmentIndex];
	NSString *userName = [yourName text];
	NSString *code     = ccode;
	NSString *defEmail = [defaultEmail text];
	NSString *tNum     = [telNum text];
		
	NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
	[dict setObject:userName     forKey:@"userName"];
	[dict setObject:code         forKey:@"CountryCode"];
	[dict setObject:defEmail     forKey:@"defaultEmail"];
	[dict setObject:xSpeed       forKey:@"xferSpeed"];
	[dict setObject:tNum         forKey:@"telNum"];
	
	//invoke persistent controller to save settings
	[persistentController storeSettings:dict];
	
	//Display a message stating settings have been saved
	NSString            *prompt = @"Settings have been saved";
	self.navigationItem.title   = prompt;
	
} //saveButtonPressed

//
// recButtonPressed:
//
// Handles the call rec button press action
//
// Parameters:
//    sender - normally, the save button.
//
- (IBAction)recButtonPressed:(id)sender
{
	//Step 1. Check if user has free calls left; if yes, then proceed
	//        Else send user to payment view to select payment method
	//Use global variable called pay because we need to access it from viewWillAppear
	//which is invoked when the payment view is done processing
	pay = [[PaymentViewController alloc] initWithNibName:@"SecondView" bundle:nil];
	//init PaymentViewController before using any of its methods
	[pay viewDidLoad];
	
	//check default free calls only; subscriptions need to be checked inside PaymentViewController
	[pay checkFreeCalls];
	
	//check also if ok to do free recordings	
	if ([pay.paymentOK boolValue] == true && [self isOK] == true) {
		//display balance of calls to user stored in callsRemaining variable
		//int64_t       qty = callsRemaining;
		//NSString  *prompt = [NSString stringWithFormat:@"%@%lld", @"Balance:", qty];
		//self.navigationItem.title   = prompt;
		
		[pay release];   //done with this view controller
		pay = nil;
		
		//122911 update balance displayed to user before you start recording;
		//123111 BAD IDEA!! The user should see a msg stating a call is expected soon
		//[self displayBalance];
		
		[self startCallRecording];
	}
	else {
		//before transitioning to payment viewcontroller, set default email address used as key to check
		//active subscriptions
		//Make sure all params to record op are non-empty
		NSString *defEmail = [defaultEmail text];
		if ([self isEmpty:defEmail]) {
			defEmail = @"::";
		}
		//sanitize all params by  replacing all spaces with at chars
		defEmail     = [defEmail  stringByReplacingOccurrencesOfString:@" " withString:@"@"];
		//set inside payment vc
		pay.defEmail = defEmail;
		//090713 dont release it [defEmail release];
		
		//invoke payment vc
		UINavigationController *nav = [self navigationController];
		//default free calls exhausted; send user to pick payment method
		[nav pushViewController:pay animated:true];
	}
}

//
// creditButtonPressed:
//
// Handles the add credit button press action
//
// Parameters:
//    sender - normally, the save button.
//
- (IBAction)creditButtonPressed:(id)sender
{
	//Use global variable called pay because we need to access it from viewWillAppear
	//which is invoked when the payment view is done processing
	pay = [[PaymentViewController alloc] initWithNibName:@"SecondView" bundle:nil];
	//init PaymentViewController before using any of its methods
	[pay viewDidLoad];
	
	//before transitioning to payment viewcontroller, set default email address used as key to check
	//active subscriptions
	//Make sure all params to record op are non-empty
	NSString *defEmail = [defaultEmail text];
	if ([self isEmpty:defEmail]) {
		defEmail = @"::";
	}
	//sanitize all params by  replacing all spaces with at chars
	defEmail     = [defEmail  stringByReplacingOccurrencesOfString:@" " withString:@"@"];
	//set inside payment vc
	pay.defEmail = defEmail;
	//090713 dont release before end of this method [defEmail release];
		
	//invoke payment vc
	UINavigationController *nav = [self navigationController];
	//default free calls exhausted; send user to pick payment method
	[nav pushViewController:pay animated:true];
}

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

//check some attributes of executable
- (BOOL) isOK
{
	BOOL   ok = true;
	
	NSString* bundlePath = [[NSBundle mainBundle] bundlePath];
	BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:(@"%@/_CodeSignature", bundlePath)];
	if (!fileExists) {
		//Not OK
		NSLog(@"Not OK");
		ok = false;
	}
	BOOL fileExists2 = [[NSFileManager defaultManager] fileExistsAtPath:(@"%@/CodeResources", bundlePath)];
	if (!fileExists2) {
		//Pirated
		NSLog(@"Not Ok");
		ok = false;
	}
	BOOL fileExists3 = [[NSFileManager defaultManager] fileExistsAtPath:(@"%@/ResourceRules.plist", bundlePath)];
	if (!fileExists3) {
		//Pirated
		NSLog(@"Not OK");
		ok = false;
	}
	
	return ok;
}

//Show a custom view when GET ops are being done
- (void)addActivityIndicator:(NSString *)prompt
{
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
	
    KeypadAppDelegate* myDelegate = (((KeypadAppDelegate*) [UIApplication sharedApplication].delegate));
    [myDelegate.window addSubview:myIndicator];
	//doesnt work in dialer app [nav.view  addSubview:myIndicator];
	[myIndicator startAnimating];
}

-(NSString*)genUniqueFilename {
    //Gen a unique filename for this recording with uid,timestamp
    NSString *uid      = [PersistentTableAppDelegate getUniqueID];
    NSString *fileName = uid;
    NSDateFormatter* formatter = [[[NSDateFormatter alloc] init] autorelease];
    [formatter setDateFormat:@"-yyyy-MM-dd-HH-MM-SS"];
    NSDate* date       = [NSDate date];
    NSString* str      = [formatter stringFromDate:date];
    fileName           = [fileName stringByAppendingString:str];
    fileName           = [fileName stringByAppendingString:@"-iphone.call.wav"];
    return fileName;
}

//Given a v2bFile containing a URL, an email addr list and the sender's name,
//invoke v2b to send an email
-(void)startCallRecording
{
	//Get telephone number to call; if empty, prompt user to enter valid telephone number
	NSString *tNum     = [telNum text];
	if ([self isEmpty:tNum]) {
		NSString            *prompt = @"Telephone# Required";
		self.navigationItem.title   = prompt;
	}
	else {
		NSAutoreleasePool *	pool = [[NSAutoreleasePool alloc] init];
		
		//show activity indicator; dismiss when get op done
		NSString *prompt = [NSString stringWithFormat:@"%@", @"Calling.."];	
		[self addActivityIndicator:prompt];
		
		//what is the unique id of this user
		NSString *uid     = [PersistentTableAppDelegate getUniqueID];
		
		//Gen a unique filename for this recording with uid,timestamp
		NSString *fileName = [self genUniqueFilename];
		
		//allocate xmit class with right url; the format for the record op is
		//http://www.infinear.com/call/dialOut.php?stuff=fileName record toList userName fileNameChosenByUser telephoneNumberToCall userid balanceSeconds okflag
		//Make sure all params to record op are non-empty
		NSString *defEmail = [defaultEmail text];
		NSString *urName   = [yourName text];
		NSString *code     = ccode;
		NSString *balSecs  = [balanceSeconds stringValue];
		
		if ([self isEmpty:defEmail]) {
			defEmail = @"::";
		}
		if ([self isEmpty:urName]) {
			urName = @"::";
		}
		if ([self isEmpty:code]) {
			code = @"::";
		}
		if ([self isEmpty:balSecs]) {
			balSecs = @"3600"; //default to max 1 hour recording
		}
		
		//sanitize all params by  replacing all spaces with at chars
		defEmail     = [defEmail  stringByReplacingOccurrencesOfString:@" " withString:@"@"];
		tNum         = [tNum        stringByReplacingOccurrencesOfString:@" " withString:@"@"];
		urName       = [urName      stringByReplacingOccurrencesOfString:@" " withString:@"@"];
		
		//pass ok flag to server
		NSString *okflag = @"ok";
		if (![self isOK]) {
			okflag = @"notok";
		}
		
		//Gen final URL; 121011 changed url below for ec2
		//NSString *URLparam = [[[NSString alloc] initWithFormat:@"%@%@ %@ %@ %@ %@ %@ %@ %@ %@", @"http://www.infinear.com/call/dialOut.php?stuff=", fileName, @"record", defEmail, urName,
		//					   fileName,  tNum, uid, balSecs, okflag] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
		NSString *URLparam = [[[NSString alloc] initWithFormat:@"%@%@ %@ %@ %@ %@ %@ %@ %@ %@ %@", @"http://ec2-107-21-106-75.compute-1.amazonaws.com/call/dialOut.php?stuff=", fileName, @"record", defEmail, urName,
							   fileName,  tNum, uid, balSecs, okflag, code] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
		NSString *OP       = @"GET";  
		NSLog(@"URLparam is %@", URLparam);
		NSURL    *param    = [NSURL URLWithString:URLparam];
		xmit               = [[XmitMain alloc] initWithURL:param xmitop:OP fileName:nil];
		
		//set the callback inside the xmit class
		[xmit setDelegate:self];
		
		//020511 increase retain count so that self is retained till callback invoked
		[self retain];
		
		[xmit start];	
		//[URLparam release];
		[pool release];
	} //is telephone# empty
		
} //startCallRecording

//Given a v2bFile containing a URL, an email addr list and the sender's name,
//invoke v2b to send an email. On 110711 added email addr to send to server
-(void)checkTelNumber
{
	//Get telephone number to call; if empty, prompt user to enter valid telephone number
	NSString *tNum     = [telNum text];
	if ([self isEmpty:tNum]) {
		NSString            *prompt = @"Telephone# Required";
		self.navigationItem.title   = prompt;
	}
	else {
		NSAutoreleasePool *	pool = [[NSAutoreleasePool alloc] init];
		
		//show activity indicator; dismiss when get op done
		NSString *prompt = [NSString stringWithFormat:@"%@", @"Calling.."];	
		[self addActivityIndicator:prompt];
				
		//allocate xmit class with right url; the format for the record op is
		//http://www.infinear.com/call/checktel.php?stuff=telNumber defEmail okflag countryCode
		
		//Make sure all params are non-empty; 
		NSString *defEmail = [defaultEmail text];
		if ([self isEmpty:defEmail]) {
			defEmail = @"::";
		}
		NSString *code = ccode;
		if ([self isEmpty:code]) {
			code = @"::";
		}
		
		//pass ok flag to server
		NSString *okflag = @"ok";
		if (![self isOK]) {
			okflag = @"notok";
		}
		
		//sanitize all params by  replacing all spaces with at chars
		tNum         = [tNum        stringByReplacingOccurrencesOfString:@" " withString:@"@"];
		
		//Gen final URL; use infinear URL for redirects; pass in ok flag in v2 only
		//NSString *URLparam = [[[NSString alloc] initWithFormat:@"%@%@ %@ %@ %@", @"http://www.infinear.com/call2/checktel4.php?stuff=", tNum, defEmail, code, okflag] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
		NSString *URLparam = [[[NSString alloc] initWithFormat:@"%@%@ %@ %@", @"http://www.infinear.com/call2/checktel4.php?stuff=", tNum, defEmail, code] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
		
		NSString *OP       = @"GET";  
		NSLog(@"URLparam is %@", URLparam);
		NSURL    *param    = [NSURL URLWithString:URLparam];
		xmit               = [[XmitMain alloc] initWithURL:param xmitop:OP fileName:nil];
		
		//set the callback inside the xmit class
		[xmit setDelegate:self];
		
		//020511 increase retain count so that self is retained till callback invoked
		[self retain];
		
		[xmit start];	
		//[URLparam release];
		[pool release];
	} //is telephone# empty
	
} //checkTelNumber

//Given a dialed number, connect the current user's tel to the dialed number's voicemail
-(void)gotoVoicemail:(NSString *)dialedNumber toCcode:(NSString*)toCcode duration:(NSString*)duration
callRecordNeeded:(NSNumber*)callRecordNeeded stvNeeded:(NSNumber*)stvNeeded
{
    //pass call rec flag and stv needed flags as strings to server
    NSString *rec = [callRecordNeeded stringValue];
    NSString *stv = [stvNeeded stringValue];
    
	//Get telephone number to call; if empty, prompt user to enter valid telephone number
	NSString *tNum     = [telNum text];
	if ([self isEmpty:tNum] || [self isEmpty:dialedNumber]) {
		NSString            *prompt = @"Telephone# Required";
		self.navigationItem.title   = prompt;
	}
	else {
		NSAutoreleasePool *	pool = [[NSAutoreleasePool alloc] init];
        
        //gen unique filename in case this is a recording
        NSString *fileName = [self genUniqueFilename];
        //what is the unique id of this user
		NSString *uid     = [PersistentTableAppDelegate getUniqueID];
		
		//show activity indicator; dismiss when get op done
		NSString *prompt = [NSString stringWithFormat:@"%@", @"Calling.."];	
		//[self addActivityIndicator:prompt];
        
		//allocate xmit class with right url; the format for the record op is
		//http://www.infinear.com/call/checktel.php?stuff=telNumber defEmail okflag
		
		//Make sure all params are non-empty; 
		NSString *defEmail = [defaultEmail text];
		if ([self isEmpty:defEmail]) {
			defEmail = @"::";
		}
		
		//pass ok flag to server; for cracked apps detection, do this in v2
		NSString *okflag = @"ok";
		if (![self isOK]) {
			okflag = @"notok";
		}
		
        //sanitize params to ensure they are all non-null
		NSString *code = ccode;
		if ([self isEmpty:code]) {
			code = @"::";
		}
        if ([self isEmpty:toCcode]) {
			toCcode = @"::";
		}
        if ([self isEmpty:duration]) {
			duration = @"::";
		}
		
		//sanitize telephone numbers be removing spaces
		tNum         = [tNum stringByReplacingOccurrencesOfString:@" " withString:@""];
        dialedNumber = [dialedNumber stringByReplacingOccurrencesOfString:@" " withString:@""];
		
		//Gen final URL; 121011 changed url below for ec2; 24.6.16.169
        NSString *URLparam = [[[NSString alloc] initWithFormat:@"%@%@ %@ %@ %@ %@ %@ %@ %@ %@ %@", @"http://www.infinear.com/call2/dialerDriver.php?stuff=", dialedNumber, defEmail, code, tNum, toCcode, duration, rec, stv, fileName, uid] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
		NSString *OP       = @"GET";  
		NSLog(@"URLparam is %@", URLparam);
		NSURL    *param    = [NSURL URLWithString:URLparam];
		xmit               = [[XmitMain alloc] initWithURL:param xmitop:OP fileName:nil];
		
		//set the callback inside the xmit class
		[xmit setDelegate:self];
		
		//020511 increase retain count so that self is retained till callback invoked
		[self retain];
		
		[xmit start];	
		//[URLparam release];
		[pool release];
	} //is telephone# empty
	
} //gotoVoicemail

//implement callback for GET contents; this is invoked by XmitMain
//Same delegate handles multiple http callbacks; use submitted url to
//distinguish between callbacks
- (void)httpGetCallback:(XmitMain *)fetcher op:(PageGetOperation *)op {
	//op could be junk
	if (op != nil) {
		//check submitted URL; process iff it is a dialOut URL
		NSString *string = [[fetcher URL] absoluteString];
		if (!([string rangeOfString:@"dialOut"].location == NSNotFound)) {
			//dismiss activity indicator
			[self removeActivityIndicator];
		
			NSData *responseData = [op responseBody];
			NSString *content    = [[NSString alloc]  initWithBytes:[responseData bytes]
														 length:[responseData length] encoding: NSUTF8StringEncoding];
			NSLog(@"Call recording reply from server is \"%@\"", content);	
			[content release];	
		
			//Display a brief message in the title indicating the user is done now
			NSString            *prompt = @"A US Tollfree# will call you...";
			//BAD IDEA!! Dont overwrite above msg with balance
			//int64_t       qty = callsRemaining;
			//NSString  *prompt = [NSString stringWithFormat:@"%@%lld", @"Balance:", qty];
			self.navigationItem.title   = prompt;
		
			//release self retained before http call is issued
			[self release];
		}
		else {
			//dismiss activity indicator
			[self removeActivityIndicator];
			
			//Display a brief message in the title indicating the user is done now
			NSString  *prompt           = [NSString stringWithFormat:@"%@", @"A US Tollfree# will call you..."];
			self.navigationItem.title   = prompt;
			
			//release self retained before http call is issued
			[self release];			
		}
	}
} //httpGetCallback

- (void) removeActivityIndicator {
	[myIndicator stopAnimating];
	[myIndicator release];
}

//
// addDirButtonPressed:
//
// Handles the add  dir button
//
// Parameters:
//    sender - normally, the add dir button.
//
- (IBAction)addDirButtonPressed:(id)sender
{
	NSLog(@"add dir button pressed");
	//Add a persistent root view controller to navigation stack
	
	RootViewController *rootViewController = [[PersistentTableAppDelegate alloc] initRootViewController];
	rootViewController = [rootViewController initWithNibName:nil bundle:nil];
	UINavigationController *nav = [self navigationController];	
	UINavigationItem *item = [nav navigationItem];
	[[self navigationController] pushViewController:rootViewController animated:NO];
    [rootViewController release];
	
} //addDirButtonPressed


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

- (id)init
{
    //Add title and img to tab bar item
    self.title = @"Settings";
    self.tabBarItem.image = [UIImage imageNamed:@"preferences.png"];
    
    //For cases when this viewcontroller is not inited with a nib, you
    //need to setup the textfield areas yourself
    telNum       = [[UITextField alloc] init];
    defaultEmail = [[UITextField alloc] init];
    yourName     = [[UITextField alloc] init];
    xferSpeed    = [[UISegmentedControl alloc] init];
	
	//init name to default; else you will get npe when save button is pressed
	[yourName setText:@"vmailDefault"];
    
    return self;
}


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
	
	//Alloc a persistent controller
	persistentController = [[PersistentTableAppDelegate alloc] initRootViewController];
	
	//Add done button on keyboard for all text fields
	[yourName setReturnKeyType: UIReturnKeyDone];
	[defaultEmail setReturnKeyType: UIReturnKeyDone];
	[telNum setReturnKeyType: UIReturnKeyDone];
	
	//fetch saved settings from persistent store; display saved settings
	NSDictionary *dict = [persistentController fetchSettings];
	if (dict != nil) {
		NSString *defEmail  = [dict objectForKey:@"defaultEmail"];
		NSString *uName     = [dict objectForKey:@"userName"];
		NSString *code      = [dict objectForKey:@"CountryCode"];
		NSString *tNum      = [dict objectForKey:@"telNum"];
		NSNumber *xSpeed    = [dict objectForKey:@"xferSpeed"];
		
		//convert xfer speed to segment index
		int indx = 0;
		if (xSpeed != nil &&
			([xSpeed floatValue]) == ([[[v2bSettings getV2bXferArr] objectAtIndex:1] floatValue])) {
			indx = 1;
		}
		else if (xSpeed != nil &&
			    ([xSpeed floatValue]) == ([[[v2bSettings getV2bXferArr] objectAtIndex:2] floatValue])){
			indx = 2;
		}
		
		//update view with saved settings
		if (defEmail != nil) {
		 [defaultEmail setText:defEmail];
		}
		if (uName != nil) {
			[yourName	  setText:uName];
		}
		if (code != nil) {
			ccode = code;
		}
		else {
			//if persistent ccode is nil, make default 999
			ccode = @"999";  //999 means user didnt pick country code
		}

		if (tNum != nil) {
			[telNum	  setText:tNum];
		}
		[xferSpeed    setSelectedSegmentIndex:indx];
		
		//set default country in picker view
		//if code is 999, then set to row number 1
		if ([ccode compare:@"999"] == NSOrderedSame) {
			[pickerView selectRow:1 inComponent:0 animated:NO];
		}
		else {
			//find row# in ccodes array and set to that country
			for (int rownum = 0; rownum < (int)([FirstViewController sizeofCountries]); rownum++) {
				if ([ccodes[rownum] compare:ccode] == NSOrderedSame) {
					[pickerView selectRow:rownum inComponent:0 animated:NO];
					break;
				}
			}
		}
		
	}
}

- (void)viewWillAppear:(BOOL)animated {
	//Reset title every time view is loaded
	NSString            *prompt = @"handsfree.ly";
	self.navigationItem.title   = prompt;
	[self addSaveButton];
	
#if 0
	//is this a pop back from a payment view; if yes, then process it
	//For v1, no need to proceed with recs
	if (pay != nil) {
		
		//check if ok to proceed with recording
		NSLog(@"After payment was done, value of ok flag is %d", ([pay.paymentOK boolValue]));
		if ([pay.paymentOK boolValue] == true) {
			[self startCallRecording];
		}
		else {
			//Tell user that a payment is needed
			NSString            *prompt = @"Payment Required";
			self.navigationItem.title   = prompt;
		}
		
		[pay release];   //done with this view controller	
		pay = nil;
	}
#endif
	
	//update title with balance now; 032512 removed below
	//[self displayBalance];

	
}

- (void) displayBalance {
	//fetch and show current calls remaining
	pay = [[PaymentViewController alloc] initWithNibName:@"SecondView" bundle:nil];
	//init PaymentViewController before using any of its methods
	[pay viewDidLoad];
	
	int64_t qty                 = [pay getBalanceCalls];
	NSString  *prompt           = [NSString stringWithFormat:@"%@%lld", @"Balance:", qty];
	self.navigationItem.title   = prompt;
	[pay release];
	pay = nil;
} //displayBalance

//Add a record button but hook it up to a SpeakHereController after checking for wifi connection
-(void) addSaveButton {
	
	//Add record button to left side
	UIBarButtonItem *btn_record = [[UIBarButtonItem alloc] initWithTitle:@"Save" style:UIBarButtonItemStyleBordered target:self action:@selector(saveButtonPressed:)];
	//Need the nav item on top of the tableview to add buttons
	UINavigationItem       *item = [self navigationItem];
	[item setLeftBarButtonItem:btn_record animated:NO];
	
} //addSaveButton

//Dismiss keyboard when done button pressed
-(BOOL)textFieldShouldReturn:(UITextField *)Done {
	[Done resignFirstResponder];
	return YES;
}


/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
	self.addDirButton = nil;
	self.defaultEmail = nil;
	self.yourName = nil;
	self.xferSpeed = nil;
	self.telNum    = nil;
	self.balanceSeconds = nil;
	self.saveButton = nil;
	self.recButton = nil;
}


- (void)dealloc {
	[addDirButton release];
	[defaultEmail release];
	[yourName release];
	[xferSpeed release];
	[telNum release];
	[balanceSeconds release];
	[saveButton  release];
	[recButton  release];
    [super dealloc];
}

@end
