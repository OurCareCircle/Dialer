//
//  RootViewController.m
//  PersistentTable
//
//  Created by sanjay krishnamurthy on 12/24/10.
//  Copyright 2010 Infinear Inc. All rights reserved.
//
#import "PopoverContentViewController.h"
#import "PersistentTableAppDelegate.h"
#import "MultiSelectCellController.h"
#import "v2bEmail.h"
#import "RootViewController.h"
#import "EmailViewController.h"
#import "XmitMain.h"
#import <CoreData/CoreData.h>
#import "QuartzCore/CAAnimation.h"

@implementation EmailViewController

@synthesize emailsArray;
@synthesize managedObjectContext;
@synthesize addButton;
@synthesize doneButton;
@synthesize detailViewPopover;
@synthesize v2bf;
@synthesize myIndicator;

//private var keeps track of all msc cells
NSMutableArray *mscArray;

#pragma mark -
#pragma mark View lifecycle


- (void)viewDidLoad {
	
    [super viewDidLoad];
	
    // Set the title.
    self.title = @"Emails";
	
	//Add a pleasant background color
	self.view.backgroundColor = [UIColor colorWithRed:0.773f green:0.80f blue:0.831f alpha:1.0f];
		
	//Add + button to right side of nav bar
    addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
															  target:self action:@selector(addEvent)];
	addButton.enabled = YES;
    self.navigationItem.leftBarButtonItem = addButton;
	//Add done button to left side of  nav bar
	doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
															  target:self action:@selector(emailEvent)];
    doneButton.enabled = YES;
    self.navigationItem.rightBarButtonItem = doneButton;
	
	//init fetch results
	NSMutableArray  *mutableFetchResults = [self fetchEvent];
	[self setEmailsArray:mutableFetchResults];
	[mutableFetchResults release];
	
	//Setup for editing AFTER emailsArray has been initialized
	//[self.tableView setEditing:YES animated:YES];
	
	//keep track of msc cells with this array
	mscArray = [[NSMutableArray alloc] init];
	
}

- (void)initPopover {
	//init the popover view to gather details from user.
    detailViewPopover = [[PopoverContentViewController alloc] init];
	//add some attributes to this popover view
	detailViewPopover.view.backgroundColor = [UIColor colorWithRed:0.773f green:0.80f blue:0.831f alpha:1.0f];
	
	//add a done button to popover
	doneButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
	[doneButton addTarget:self 
				   action:@selector(doneEvent:)
		 forControlEvents:UIControlEventTouchDown];
	[doneButton setTitle:@"Done" forState:UIControlStateNormal];
	doneButton.frame = CGRectMake(120.0, 160.0, 80.0, 40.0);
	[detailViewPopover.view addSubview:doneButton];
	
}

//The + button in the navigation bar is linked to this method. Show a popover now
- (void)addEvent {
	[self initPopover]; //create popover view
	[self showPopover:(id)addButton];
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

//integrate with mainline to email current recording to selected senders
- (void)emailEvent {
	NSString *emailAddrList = @""; //concat all email addrs chosen by user
	NSString *userName      = @"::"; //be default, send empty string to server
	
	//fetch the default email addr (if present)
	//Alloc a persistent controller
	RootViewController  *persistentController = [[PersistentTableAppDelegate alloc] initRootViewController];
	
	//fetch saved settings from persistent store; display saved settings
	NSDictionary *dict = [persistentController fetchSettings];
	if (dict != nil) {
		NSString *defEmail  = [dict objectForKey:@"defaultEmail"];
		emailAddrList       = defEmail;	
		NSString *name      = [dict objectForKey:@"userName"];
		userName            = name;
		NSLog(@"Added name %@ and default email address to email list %@", userName, defEmail);
	}
	[persistentController release];
	
	//walk thru emails array and concatenate all selected emails
	for (MultiSelectCellController *cellController in mscArray)
	{
		if ([cellController selected]) {
			NSString *emailAddr = cellController.label;
			//Append or init
			if ([emailAddrList compare:@""] == 0) {
				emailAddrList = emailAddr;
			}
			else {
				NSString *tmp = [emailAddrList stringByAppendingString:@","];
				emailAddrList = [tmp stringByAppendingString:emailAddr];
			}
		}
	}
	NSLog(@"For user named %@ Complete email addr list is %@", userName, emailAddrList);
	
	//if a v2bFile was passed in, then store the emails inside it
	if ([self v2bf] != nil) {
		NSString *addrList = [emailAddrList copy];
		[v2bf setValue:addrList forKey:@"emailAddrList"];
	}
	else {
		NSLog(@"v2bFile instance inside email addr selection is nil!!");
	}
		
	//send external email here
	if (emailAddrList != nil && [emailAddrList compare:@""] != 0) {
		[self sendEmail:v2bf userName:userName];
	}
		
	//done with emails,name
	[emailAddrList release];
	[userName release];
	
	//nothing else to do; pop to RootViewController;020911 pop to root only when send reply received
	//[self popToRoot];
	
}

//Given a v2bFile containing a URL, an email addr list and the sender's name,
//invoke v2b to send an email
-(void)sendEmail:(v2bFile *)v2bf userName:(NSString *)userName
{
	//show activity indicator; dismiss when get op done
	NSString *prompt = @"Sending Email";
	[self addActivityIndicator:prompt];
	
	//what is the unique id of this user
	NSString *uid     = [PersistentTableAppDelegate getUniqueID];
	
	//allocate xmit class with right url; the format for the send op is
	//http://ec2-50-19-172-48.compute-1.amazonaws.com/iphone/send.php?stuff=http://ec2-50-19-172-48.compute-1.amazonaws.com/mon/iphone/4089921762/10-12-30-14-51-52-4089921762.mp3%20send%20sanjaymk908@yahoo.com%20Sanjay%20TestFile
	
	NSAutoreleasePool *	pool = [[NSAutoreleasePool alloc] init];
	NSString          * url  = [v2bf valueForKey:@"fileURL"];
	NSString          * addrs= [v2bf valueForKey:@"emailAddrList"];
	NSString          * fname= [v2bf valueForKey:@"fileName"];
	NSString          * tel  = V2BTEL;
	
	//Make sure filename is non-empty
	if ([self isEmpty:fname]) {
		fname = @"::";
	}
	//Make sure username is non-empty
	if ([self isEmpty:userName]) {
		userName = @"::";
	}
	
	//sanitize all params by  replacing all spaces with at chars
	url       = [url      stringByReplacingOccurrencesOfString:@" " withString:@"@"];
	addrs     = [addrs    stringByReplacingOccurrencesOfString:@" " withString:@"@"];
	fname     = [fname    stringByReplacingOccurrencesOfString:@" " withString:@"@"];
	userName  = [userName stringByReplacingOccurrencesOfString:@" " withString:@"@"];
	
	//121011 changed url below for ec2
	//NSString *URLparam = [[[NSString alloc] initWithFormat:@"%@%@ %@ %@ %@ %@", @"https://www.infinear.com/iphone/send.php?stuff=", url, @"send", addrs, userName, fname] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
	NSString *URLparam = [[[NSString alloc] initWithFormat:@"%@%@ %@ %@ %@ %@", @"http://ec2-107-21-106-75.compute-1.amazonaws.com/iphone/send.php?stuff=", url, @"send", addrs, userName, fname] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
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
	
} //sendEmail

//implement callback for GET contents; this is invoked by XmitMain
- (void)httpGetCallback:(XmitMain *)fetcher op:(PageGetOperation *)op {
	//op could be junk
	if (op != nil) {
		//dismiss activity indicator
		[self removeActivityIndicator];
		
		NSData *responseData = [op responseBody];
		NSString *content    = [[NSString alloc]  initWithBytes:[responseData bytes]
														 length:[responseData length] encoding: NSUTF8StringEncoding];
		
		//content ought to be sane JSON data-parse it and extract the reply  from server
		//usually in this form {"send":["Message",""]}
		NSDictionary *dictionary = [content JSONValue];
		NSString     *reply      = [dictionary objectForKey:@"send"];
		NSLog(@"Email send reply from server is \"%@\"", reply);	
		
		[content release];		
		
		//release self retained before http call is issued
		[self release];
		
		//Done; Pop back to root
		[self popToRoot];
	}
} //httpGetCallback

//Done with email; pop back to root folder view
- (void)popToRoot {
	UINavigationController *nav = [self navigationController];	
	
	//clear local state passed into this view before exiting
	[self clearState];
	
	//Pop all the way back to root; 030311 poptoroot doestn show new folders
	//just pop one level back to files view
	//[nav popToRootViewControllerAnimated:NO];	
	[nav popViewControllerAnimated:NO];
}

//clear all state vars passed into this view when we are done with email stuff
- (void)clearState {
	self.v2bf.fileURL = nil;
}

- (void)doneEvent:(id)sender {
    // If a popover is dismissed, copy the user entered name from popover
	NSString *emailAddr = [detailViewPopover.name.text copy];
	NSLog(@"User entered  email addr %@", emailAddr);
	
	//create an v2bEmail object to store the current date and current folder name
	// Create and configure a new instance of the Event entity.
	v2bEmail *event = (v2bEmail *)[NSEntityDescription insertNewObjectForEntityForName:@"v2bEmail" inManagedObjectContext:managedObjectContext];
	[event setEmailAddress: emailAddr];
	
	//save the new v2bEmail object persistently
	NSError *error = nil;
	if (![managedObjectContext save:&error]) {
		// Handle the error.
		NSLog(@"Error saving email addr persistently: %@", [error localizedDescription]);
		
		//no more processing
		return;
	}
	
	//Add current email to top of table view
	[emailsArray insertObject:event atIndex:0];
	NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
	[self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
						  withRowAnimation:UITableViewRowAnimationFade];
	[self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] 
						  atScrollPosition:UITableViewScrollPositionTop animated:YES];
	
	//done with email
	[emailAddr release];
	
	//dismiss popover and pop back to parent
	[super dismissModalViewControllerAnimated:true];
}

- (IBAction)showPopover:(id)sender {
    // Set the sender to a UIButton.
    UIButton *tappedButton = (UIButton *)sender;	
    
    // Present the popover view modally
	[self presentModalViewController:detailViewPopover animated:YES];
	[detailViewPopover release];
	
}

//Returns a copy of the fetched result set. Discard the copy after use
- (NSMutableArray *)fetchEvent {
	//create fetch request
	NSFetchRequest *request     = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"v2bEmail" inManagedObjectContext:managedObjectContext];
	[request setEntity:entity];
	
	//do the fetch now
	NSError *error = nil;
	NSMutableArray *mutableFetchResults = [[managedObjectContext executeFetchRequest:request error:&error] mutableCopy];
	if (mutableFetchResults == nil || error != NULL) {
		// Handle the error.
		NSLog(@"Error fetching emails: %@", [error localizedDescription]);
	}
	
	//cleanup before return
	[request release];
	
	return mutableFetchResults;
}
											  
//Use this callback to customize background color of all cells in table
- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
	cell.backgroundColor = [UIColor colorWithRed:0.773f green:0.80f blue:0.831f alpha:1.0f];;
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
    return [emailsArray count];
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
    // Fetch email addr from emailsArray
	NSManagedObject *emailAddrEntry = [emailsArray objectAtIndex:indexPath.row];
	NSString        *emailAddr      = [emailAddrEntry valueForKey:@"emailAddress"];
	
    static NSString *CellIdentifier = @"MultiSelectCell";
	
    // Dequeue or create a new cell.
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        MultiSelectCellController *msc  = [[[MultiSelectCellController alloc] initWithLabel:emailAddr] autorelease];
		//the call below allocates a new cell that overrides msc
		cell = [msc tableView:tableView cellForRowAtIndexPath:indexPath];
		
		//Add correct msc cell to local array for selection events
		[mscArray insertObject:msc atIndex:indexPath.row];
											
    }
	
	[cell setAccessoryType:UITableViewCellAccessoryNone];
	
    return cell;
}


#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
	NSLog(@"email selected");
	//Find msc from local array and pass selection event to it
	MultiSelectCellController *msc = [mscArray objectAtIndex:indexPath.row];
	[msc tableView:tableView didSelectRowAtIndexPath:indexPath];
	
}

#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Relinquish ownership any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	//Commenting out on 091011 because it causes core dump when memory is purged
	/*
    self.emailsArray = nil;
    self.addButton = nil;
	self.doneButton = nil;
	self.detailViewPopover = nil;
	*/
}

- (id)init {
    self = [super init];
    return self;
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
}

- (void) removeActivityIndicator {
	[myIndicator stopAnimating];
	[myIndicator release];
}

- (void)dealloc {
    [managedObjectContext release];
    [emailsArray release];
    [addButton release];
	[doneButton release];
	[mscArray release];
	
	//012911 You should not release the xmitMain instance and this instance because there is a
	//pending email send happening that needs these objects sometime later
    //[super dealloc];
	//force xmit to be retained
}

- (void)transitionDidStop:(NSString *)animationID finished:(BOOL)finished context:(void *)context {
	
}


@end

