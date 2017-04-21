//
//  RootViewController.m
//  PersistentTable
//
//  Created by sanjay krishnamurthy on 12/24/10.
//  Copyright 2010 Infinear Inc. All rights reserved.
//

#import "RootViewController.h"
#import "FileViewController.h"
#import "PopoverContentViewController.h"
#import "PersistentTableAppDelegate.h"
#import "v2bFolder.h"
#import "v2bSettings.h"
#import	"SpeakHereController.h"
#import "AQLevelMeter.h"
#import <CoreData/CoreData.h>
#import "Reachability.h"
#import "QuartzCore/CAAnimation.h"

@implementation RootViewController

@synthesize foldersArray;
@synthesize managedObjectContext;
@synthesize addButton;
@synthesize doneButton;
@synthesize folderName;
@synthesize detailViewPopover;
@synthesize history;
@synthesize v2bf;

//Use this folder to store all call recordings
NSString *callRecFolder = @"handsfree.ly Recordings";

#pragma mark -
#pragma mark View lifecycle

//for programmatic creations
/* -(void)loadView {
	//[self viewDidLoad];
} */

- (id) init {
    //Add title and img to tab ba ritem
    self.title = @"Folders";
    self.tabBarItem.image = [UIImage imageNamed:@"house.png"];
    return self;
}

- (void)viewDidLoad {
	
    [super viewDidLoad];
	
    // Set the title.
    self.title = @"Folders";
	
	//init the MOC for persistent data iff this is loaded on entry by the tabbar controller.
	if ([self managedObjectContext] == nil) {
		PersistentTableAppDelegate *delegate = [PersistentTableAppDelegate alloc];
		managedObjectContext                 = [delegate managedObjectContext];
		[delegate release];
	}
	
    // Set up the buttons; 101211 add edit button only for files not folders
	if (!([self class] == [RootViewController class])) {
		self.navigationItem.rightBarButtonItem = self.editButtonItem;
	}
	
    //dialer app doesnt need + button
    //addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:
    //UIBarButtonSystemItemAdd
    //    target:self action:@selector(addEvent)];
    //addButton.enabled = YES;
    //self.navigationItem.leftBarButtonItem = addButton;
	
	//Add recording button if needed; 012911 moved this to viewWillAppear method so that
	//when the nav stack is popped to return to this viewcontroller, this is called
	//if ([self isRecordingView]) {
	//	[self addRecordingButtons];
	//}
	
	//init fetch results
	NSMutableArray  *mutableFetchResults = [self fetchEvent];
	[self setFoldersArray:mutableFetchResults];
	[mutableFetchResults release];
	
	//set the nav controller delegate to self
	//011412 cannot use this in xcode 4 [[self navigationController] setDelegate:self];
	
	//Add default call folder if not present
	[self addV2bRecFolder];
	
	//ios 4.x notification for entering foreground from background
	if ( &UIApplicationWillEnterForegroundNotification ){
		[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(appWillComeBackNotif:) name: UIApplicationWillEnterForegroundNotification object: nil];
	}
	
}

// Posted when app is on its way to becoming the active application again
// Listens to: UIApplicationWillEnterForegroundNotification
- (void) appWillComeBackNotif: (NSNotification *) notify 
{
    //just call viewWillAppear which does all the right work
	[self viewWillAppear:FALSE];
	
	//activate audio session ONLY when returning from background
	OSStatus result = AudioSessionSetActive (true);
}

- (void)viewWillAppear:(BOOL)animated {
	//Add pleasant background  color to tableview
	self.view.backgroundColor  = [UIColor colorWithRed:0.773f green:0.80f blue:0.831f alpha:1.0f];
	
	//This method is called for all viewcontrollers; make sure we act only for RootViewControllers
	if ([self class] == [RootViewController class]) {
	   //Add recording buttons iff this is a recording view
	   if ([self isRecordingView]) {
		   //030311 Rec buttons added in footer now 
		   [self addRecordingButtons];
	   }
	}
}

- (void)initPopover {
	//init the popover view to gather details from user.
    detailViewPopover = [[[PopoverContentViewController alloc] init] autorelease];
	//add some attributes to this popover view
	detailViewPopover.view.backgroundColor = [UIColor colorWithRed:0.773f green:0.80f blue:0.831f alpha:1.0f];
	
	//add a done button to popover
	doneButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
	[doneButton addTarget:self 
				   action:@selector(doneEvent:)
		 forControlEvents:UIControlEventTouchDown];
	[doneButton setTitle:@"Done" forState:UIControlStateNormal];
	doneButton.frame = CGRectMake(120.0, 170.0, 80.0, 40.0);
	[detailViewPopover.view addSubview:doneButton];
	
}

//The + button in the navigation bar is linked to thismethod. Show a popover now
- (void)addEvent {
	[self initPopover]; //create popover view
	[self showPopover:(id)addButton];
}

- (void)doneEvent:(id)sender {	
	// If a popover is dismissed, copy the user entered name from popover
	folderName = [detailViewPopover.name.text copy];
	NSLog(@"User entered folder name %@", folderName);
	
	//create an v2bFolder object to store the current date and current folder name
	// Create and configure a new instance of the Event entity.	
	v2bFolder *event = (v2bFolder *)[NSEntityDescription insertNewObjectForEntityForName:@"v2bFolder" inManagedObjectContext:managedObjectContext];
	[((v2bFolder *)event) setCreationDate:[NSDate date]];
	[((v2bFolder *)event) setFolderName:folderName];
	
	//save the new v2bFolder object persistently
	NSError *error = nil;
	if (![managedObjectContext save:&error]) {
		// Handle the error.
		NSLog(@"Error saving folder name persistently: %@", [error localizedDescription]);
		
		//no more processing
		return;
	}
	
	//Add current folder name to top of table view
	[foldersArray insertObject:event atIndex:0];
	
	//061111 If this is the callrec folder being inserted, I cannot get the code
	//below to work. Hmmmm.....
	if (![folderName compare:callRecFolder] == NSOrderedSame) {
		//Added it to show new folders Else new folders will not be displayed
		NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
		[self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
						  withRowAnimation:UITableViewRowAnimationFade];
		[self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] 
				    atScrollPosition:UITableViewScrollPositionTop animated:YES];
	}
	
	//dismiss popover and pop back to parent
	[super dismissModalViewControllerAnimated:true];
}

- (IBAction)showPopover:(id)sender {
    // Set the sender to a UIButton.
    UIButton *tappedButton = (UIButton *)sender;	
    
    // Present the popover view modally
	[self presentModalViewController:detailViewPopover animated:YES];
	//[detailViewPopover release];
	
}

//Add a special v2b folder for call recordings IFF not present in persistent store
- (void)addV2bRecFolder {
	//Is there a v2b call folder in persistent storage?
	v2bFolder *event = (v2bFolder *)[self fetchFolderByName:callRecFolder];
	
	//insert new folder iff not present
	if (event == nil) {
		detailViewPopover           = [[[PopoverContentViewController alloc] init] autorelease];
		detailViewPopover.name      = [[[UITextField alloc] init] autorelease];
		detailViewPopover.name.text = callRecFolder;
		[self doneEvent:nil];
	}
}

//Self explanatory; returns nil if no special call rec folder exists
- (v2bFolder *)fetchFolderByName:(NSString *)fName {
	//create fetch request
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"v2bFolder" inManagedObjectContext:managedObjectContext];
	[request setEntity:entity];
	
	// Add a predicate to get a particular folder;	if (currFile != nil && currFile.folderName != nil) {
	NSPredicate *predicate = [NSPredicate predicateWithFormat:
								@"(folderName LIKE[c] %@)", fName];
	[request setPredicate:predicate];
	
	//do the fetch now
	NSError *error = nil;
	NSMutableArray *mutableFetchResults = [[managedObjectContext executeFetchRequest:request error:&error] mutableCopy];
	if (mutableFetchResults == nil || error != NULL) {
		// Handle the error.
		NSLog(@"Error fetching folders: %@", [error localizedDescription]);
		return nil;
	}
	
	//if zero results, then no call rec folder exists
	if (mutableFetchResults.count != 1) {
		NSLog(@"Error fetching folder: %@", callRecFolder);
		return nil;
	}
	
	//cleanup before return
	[request release];
	
	return (v2bFolder *)[mutableFetchResults objectAtIndex:0];
		
} //fetchFolderByName

//Returns a copy of the fetched result set. Discard the copy after use
- (NSMutableArray *)fetchEvent {
	//create fetch request
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"v2bFolder" inManagedObjectContext:managedObjectContext];
	[request setEntity:entity];
	
	//add sort descriptor
	NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"creationDate" ascending:NO];
	NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
	[request setSortDescriptors:sortDescriptors];
	[sortDescriptors release];
	[sortDescriptor release];
	
	//do the fetch now
	NSError *error = nil;
	NSMutableArray *mutableFetchResults = [[managedObjectContext executeFetchRequest:request error:&error] mutableCopy];
	if (mutableFetchResults == nil || error != NULL) {
		// Handle the error.
		NSLog(@"Error fetching folders: %@", [error localizedDescription]);
	}
	
	//cleanup before return
	[request release];

	return mutableFetchResults;
}

//Use this callback to customize background color of all cells in table
- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    cell.backgroundColor = [UIColor colorWithRed:0.773f green:0.80f blue:0.831f alpha:1.0f];
}

/*
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}
*/
/*
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}
*/
/*
- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
}
*/
/*
- (void)viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];
}
*/

/*
 // Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	// Return YES for supported orientations.
	return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
 */


#pragma mark -
#pragma mark Table view data source

// Customize the number of sections in the table view.
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [foldersArray count];
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
    // A date formatter for the time stamp.
    static NSDateFormatter *dateFormatter = nil;
    if (dateFormatter == nil) {
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setTimeStyle:NSDateFormatterMediumStyle];
        [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    }
	
    static NSString *CellIdentifier = @"Cell";
	
    // Dequeue or create a new cell.
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];
    }
	
    v2bFolder *event          = (v2bFolder *)[foldersArray objectAtIndex:indexPath.row];
	NSString  *folderName     = [event folderName];
    cell.textLabel.text       = folderName;
    cell.detailTextLabel.text = [dateFormatter stringFromDate:[event creationDate]];
	[cell setAccessoryType:UITableViewCellAccessoryDetailDisclosureButton];
	
	//Add custom image to folder based on whether its a user folder or a call rec folder
	UIImage *theImage = [UIImage imageNamed:@"user-folder.png"]; //default image for all folders

	if ([folderName compare:callRecFolder] == NSOrderedSame) {
		theImage = [UIImage imageNamed:@"phone-folder.png"];
	}
	cell.image = theImage;
	
    return cell;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
	
    if (editingStyle == UITableViewCellEditingStyleDelete) {
		
        // Delete the managed object at the given index path.
        NSManagedObject *folderToDelete = [foldersArray objectAtIndex:indexPath.row];
        [managedObjectContext deleteObject:folderToDelete];
		
        // Update the array and table view.
        [foldersArray removeObjectAtIndex:indexPath.row];
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationNone];
		
        // Commit the change.
        NSError *error = nil;
        if (![managedObjectContext save:&error]) {
            // Handle the error.
			NSLog(@"Error deleting folder: %@", [error localizedDescription]);
        }
		
		//restore back button to history; this is changed now. The nav history is removed from
		//the folders area
		//self.navigationItem.leftBarButtonItem = history;
		//history = nil;
    }
}

//Implement this method for drilldowns
- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
	//If drilldown folder button tapped, change left bar to edit button.
	//Unchange it when edits are done;This is changed now. We keep the edit button available always
	//history = self.navigationItem.leftBarButtonItem;
    //self.navigationItem.leftBarButtonItem = self.editButtonItem;
	
	//now dive into folder
	[self tableView:tableView didSelectRowAtIndexPath:indexPath];
	
}

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/


/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/


/*
 // Override to support conditional editing of the table view.
 - (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
 // Return NO if you do not want the specified item to be editable.
 return YES;
 }
 */


#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
	NSLog(@"folder detail button pressed");
	//Add a file view controller to navigation stack
	FileViewController *fileViewController = [[PersistentTableAppDelegate alloc] initFileViewController];
	//init MOC with folder view controller's moc
	fileViewController.managedObjectContext = managedObjectContext;
	
	//Add current folder name to v2bFile instance
	if ([self v2bf] != nil) {
		v2bFolder *folder = (v2bFolder *)[foldersArray objectAtIndex:indexPath.row];
		NSString  *fname  = [folder valueForKey:@"folderName"];
		//set  using kvc
		[v2bf setValue:fname forKey:@"folderName"];
		//021011 set fileName to nil on reusing v2bf;else popover will not be shown for file saves
		[v2bf setValue:nil forKey:@"fileName"];
	}
	else {
		//alloc a v2bFile instance and assign folder name to it
		v2bf = [v2bFile alloc];
		v2bFolder *folder = (v2bFolder *)[foldersArray objectAtIndex:indexPath.row];
		NSString  *fname  = [folder valueForKey:@"folderName"];
		//set  using kvc
		[v2bf setValue:fname forKey:@"folderName"];
		//v2bf.folderName = [folder folderName];
	}
	
	fileViewController = [fileViewController initWithNibName:nil bundle:nil];
	[fileViewController setCurrFile:v2bf];
	
	UINavigationController *nav = [self navigationController];	
	UINavigationItem *item = [nav navigationItem];
	[[self navigationController] pushViewController:fileViewController animated:NO];
    [fileViewController release];
	
}

//Methods to load and store user settings 
- (void)storeSettings:(NSDictionary *)dict {
	//delete any existing settings
	//create fetch request
	NSError *error = nil;
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"v2bSettings" inManagedObjectContext:managedObjectContext];
	[request setEntity:entity];
	NSMutableArray *mutableFetchResults = [[managedObjectContext executeFetchRequest:request error:&error] mutableCopy];
	//Do old settings exist??
	if ([mutableFetchResults count] > 0) {
		NSManagedObject *settingsToDelete = [mutableFetchResults objectAtIndex:0];
		[managedObjectContext deleteObject:settingsToDelete];
	}
	[mutableFetchResults release];
	
	//Get user settings from dict
	NSString *userName     = [dict objectForKey:@"userName"];
	NSString *CountryCode  = [dict objectForKey:@"CountryCode"];
	NSString *defaultEmail = [dict objectForKey:@"defaultEmail"];
	NSString *tNum         = [dict objectForKey:@"telNum"];
	float     xferSpeed    = [[dict objectForKey:@"xferSpeed"] floatValue];
	
	//create an v2bSettings object to store the user name, default email address, xfer speed
	// Create and configure a new instance of the v2bSettings entity.
	v2bSettings *event = (v2bSettings *)[NSEntityDescription insertNewObjectForEntityForName:@"v2bSettings" inManagedObjectContext:managedObjectContext];
	[event setUserName:userName];
	[event setCountryCode:CountryCode];
	[event setDefaultEmail:defaultEmail];
	[event setTelNum:tNum];
	[event setXferSpeed:[[NSNumber alloc] initWithFloat:xferSpeed]];
	
	//save the new v2bFolder object persistently
	if (![managedObjectContext save:&error]) {
		// Handle the error.
		NSLog(@"Error saving settings persistently: %@", [error localizedDescription]);
		
		//no more processing
		return;
	}

}

//Returns a copy of the user's settings. Discard the copy after use
- (NSDictionary *)fetchSettings {
	NSMutableDictionary  *dict = [NSMutableDictionary new]; //[[NSMutableDictionary alloc] init];
	//create fetch request
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"v2bSettings" inManagedObjectContext:managedObjectContext];
	[request setEntity:entity];
	
	//do the fetch now
	NSError *error = nil;
	NSMutableArray *mutableFetchResults = [[managedObjectContext executeFetchRequest:request error:&error] mutableCopy];
	if (mutableFetchResults == nil || error != NULL) {
		// Handle the error.
		NSLog(@"Error fetching folders: %@", [error localizedDescription]);
	}
	
	//walk thru fetch results[0] and add to dict iff the fetch results array has at least one entry
	if ([mutableFetchResults count] > 0) {
		v2bSettings *settings = (v2bSettings *)[mutableFetchResults objectAtIndex:0];
		if ([settings userName] != nil) {
			[dict setObject:[settings userName]     forKey:@"userName"];
		}
		if ([settings CountryCode] != nil) {
			[dict setObject:[settings CountryCode]  forKey:@"CountryCode"];
		}
		if ([settings defaultEmail] != nil) {
			[dict setObject:[settings defaultEmail] forKey:@"defaultEmail"];
		}
		if ([settings xferSpeed] != nil) {
			[dict setObject:[settings xferSpeed]    forKey:@"xferSpeed"];
		}
		if ([settings telNum] != nil) {
			[dict setObject:[settings telNum]    forKey:@"telNum"];
		}
		if ([settings balanceSeconds] != nil) {
			[dict setObject:[settings balanceSeconds]    forKey:@"balanceSeconds"];
		}
	}
	
	//cleanup before return; dont release settings because the array releases it
	//[settings release];
	[request release];
	[mutableFetchResults release];
	
	return dict;
}

//Is this a view when the record, store and pause buttons needs to be shown?
-(BOOL)isRecordingView {
	//we really need to ensure a recording is not being stored
	if ([self v2bf] == nil || ([self v2bf ] != nil && v2bf.fileURL == nil)) {
		return TRUE;
	}
	return FALSE;
}

//Add a record button but hook it up to a SpeakHereController after checking for wifi connection
-(void) addRecordingButtons {
	
	//Add record button to left side; dont add for dialer app
	//UIBarButtonItem *btn_record = [[UIBarButtonItem alloc] initWithTitle:@"WiFi Record" style:
    //UIBarButtonItemStyleBordered target:self action:@selector(checkWiFi)];
	//Need the nav item on top of the tableview to add buttons
	//UINavigationItem       *item = [self navigationItem];
	//[item setLeftBarButtonItem:btn_record animated:NO];
	
} //addRecordingButtons

-(void)checkWiFi {
	//add activity indicator with appropriate message
	NSString *prompt = [NSString stringWithFormat:@"%@", @"Checking WiFi.."];	
	[self addActivityIndicator:prompt];
	
	// check for internet connection	
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(checkNetworkStatus:)  name:kReachabilityChangedNotification object:nil];	
    internetReachable = [[Reachability reachabilityForInternetConnection] retain];         	
    [internetReachable startNotifier];      
	
	// check if a pathway to a random host exists        	
    hostReachable = [[Reachability reachabilityWithHostName: @"www.apple.com"]  retain];
	[hostReachable startNotifier];         
	
    // now patiently wait for the notification 
} //checkWiFi

- (void) checkNetworkStatus:(NSNotification *)notice     {      
	BOOL   wifi = FALSE;
	
	//remove all notification observers asap
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	//remove activity indicator too
	[self removeActivityIndicator];
	
    // called after network status changes      	
    NetworkStatus internetStatus = [internetReachable currentReachabilityStatus];
    switch (internetStatus){
        case NotReachable:
		{
			NSLog(@"The internet is down.");
			wifi = FALSE;
			break;
		}
		case ReachableViaWiFi:
		{
			NSLog(@"The internet is working via WIFI.");
			wifi = TRUE;
			break;
		}
		case ReachableViaWWAN:
		{
			NSLog(@"The internet is working via WWAN.");
			wifi = FALSE;
			break;
		}
	}
	
	//if on wifi, just continue with recording; else display alert and continue
	if (wifi) {
		[self connectRecordingButtons];
	}
	else {
		NSString *message  = [NSString stringWithFormat:@"%@", @"We recommend using WiFi for audio recordings; Continue recording?"];
		UIAlertView *alert = [[UIAlertView alloc]
							  initWithTitle: @"WiFi Check"
							  message: message
							  delegate:self
							  cancelButtonTitle:@"Record"
							  otherButtonTitles:@"Cancel",
							  nil];
		[alert show];
		[alert release];	
	}
} //checkNetworkStatus

//delegate for the sole alert view in this viewcontroller
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	if (buttonIndex == 0) {
		NSLog(@"WiFi alert:user pressed OK");
		[self connectRecordingButtons];
	}
	else {
		NSLog(@"WiFi alert: user pressed Cancel");
	}
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
	
	[nav.view  addSubview:myIndicator];
	[myIndicator startAnimating];
} //addActivityIndicator

- (void) removeActivityIndicator {
	[myIndicator stopAnimating];
	[myIndicator release];
} //removeActivityIndicator


//Add a record button, a pause button, a fileDescriptor label and a level meter view as footer
- (IBAction) connectRecordingButtons {
	//Allocate a SpeakHereController instance to tie to buttons
	SpeakHereController *spk = [[SpeakHereController alloc] init];	
	//Need the nav item on top of the tableview to add buttons
	UINavigationItem       *item = [self navigationItem];
	
	//Replace existing record button with new one wired directly to SpeakHereController
	UIBarButtonItem *btn_record = [[UIBarButtonItem alloc] initWithTitle:@"WiFi Record" style:UIBarButtonItemStyleBordered target:spk action:@selector(record:)];;
	[item setLeftBarButtonItem:btn_record animated:NO];
	[spk setBtn_record:btn_record];
	
	//Add  pause button on right side of nav title
	UIBarButtonItem *btn_play = [[UIBarButtonItem alloc] initWithTitle:@"Pause" style:UIBarButtonItemStyleBordered target:spk action:@selector(pause:)];;
	[item setRightBarButtonItem:btn_play animated:NO];
	[spk setBtn_play:btn_play];
	
	//Add a label for describing the sampling rate etc
	UILabel *runTime = [[UILabel alloc] initWithFrame:CGRectMake(0.0, 0.0, 80.0, 25.0)];
	[item.titleView addSubview:runTime];
	[spk setFileDescription:runTime];
	
	//Add a level meter view as table footer
	AQLevelMeter *aq = [[AQLevelMeter alloc] initWithFrame:CGRectMake(0.0, 0.0, 320.0, 50.0)];
	[self.tableView setTableFooterView:aq];
	[spk setLvlMeter_in:aq];
	
	//Add the current view controller to the SpeakHereController for getting the nav controller from it
	spk.myViewController = self;
	
	//Finally do init routine of SpeakHereController instance
	[spk awakeFromNib];
	
	//user  has pressed record button; so start recording
	[spk record:nil];
	
} //connectRecordingButtons


//030311 add footer height to root table
/*
- (CGFloat)tableView:(UITableView *)tableViewheightForFooterInSection:(NSInteger)section {
    //differ between your sections or if you
    //have only on section return a static value
    return 150; //100 for buttons, 50 for label
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
	
	//Add recording buttons iff this is a recording view
    if(footerView == nil && [self isRecordingView]) {
		//Allocate a SpeakHereController instance to tie to buttons
		SpeakHereController *spk = [[SpeakHereController alloc] init];	
		
        //allocate the view if it doesn't exist yet
        footerView  = [[UIView alloc] init];
		
        //we would like to show a gloosy red button, so get the image first
        UIImage *image = [[UIImage imageNamed:@"LiveRec.png"]
						  stretchableImageWithLeftCapWidth:8 topCapHeight:8];
		
        //create the button
        UIButton *btn_record = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        [btn_record setBackgroundImage:image forState:UIControlStateNormal];
		
        //the button should be this big
        [btn_record setFrame:CGRectMake(10, 3, 100, 100)];
		
        //set title, font size and font color
        [btn_record setTitle:@"Record" forState:UIControlStateNormal];
        [btn_record.titleLabel setFont:[UIFont boldSystemFontOfSize:20]];
        [btn_record setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
		
		//030311 for footer views, add targets to buttons
		//set action of the button
		[btn_record addTarget:spk action:@selector(record:)
			 forControlEvents:UIControlEventTouchUpInside];
		
        //add the button to the view
        [footerView addSubview:btn_record];
		
		//Repeat for Pause button
        image = [[UIImage imageNamed:@"LivePause.png"]
				 stretchableImageWithLeftCapWidth:8 topCapHeight:8];
		
        //create the button
        UIButton *btn_play = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        [btn_play setBackgroundImage:image forState:UIControlStateNormal];
		
        //the button should be this big
        [btn_play setFrame:CGRectMake(200, 3, 100, 100)];
		
        //set title, font size and font color
        [btn_play setTitle:@"Pause" forState:UIControlStateNormal];
        [btn_play.titleLabel setFont:[UIFont boldSystemFontOfSize:20]];
        [btn_play setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
		
		//030311 for footer views, add targets to buttons
		//set action of the button
		[btn_play addTarget:spk action:@selector(pause:)
		   forControlEvents:UIControlEventTouchUpInside];
		
        //add the button to the view
        [footerView addSubview:btn_play];
		
		//Now tie everything to a SpeakHereController instance		
		//Add record button on lhs
		[spk setBtn_record:btn_record];
		
		//Add  Play button on rhs
		[spk setBtn_play:btn_play];
		
		//Add a label in middle for describing the sampling rate etc
		UILabel *runTime = [[UILabel alloc] initWithFrame:CGRectMake(130.0, 0.0, 70.0, 25.0)];
		[footerView addSubview:runTime];
		[spk setFileDescription:runTime];
		
		//Add a level meter view as table footer
		AQLevelMeter *aq = [[AQLevelMeter alloc] initWithFrame:CGRectMake(110.0, 30.0, 100.0, 50.0)];
		[footerView addSubview:aq];
		[spk setLvlMeter_in:aq];
		
		//Add the current view controller to the SpeakHereController for getting the nav controller from it
		spk.myViewController = self;
		
		//Finally do init routine of SpeakHereController instance
		[spk awakeFromNib];
		
		
    }
	
    //return the view for the footer
    return footerView;
}
 
 */


#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Relinquish ownership any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	//When memory is purged, this causes a core dump; so commenting out on 091011
	/*
    self.foldersArray = nil;
    self.addButton = nil;
	self.doneButton = nil;
	self.folderName = nil;
	self.detailViewPopover = nil;
	*/
}

- (void)dealloc {
    [managedObjectContext release];
    [foldersArray release];
    [folderName release];
	//popover has already been eagerly released; this causes an exception [detailViewPopover	release];
    [addButton release];
	[doneButton release];
    [super dealloc];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)transitionDidStop:(NSString *)animationID finished:(BOOL)finished context:(void *)context {
	
}

@end

