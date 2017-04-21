//
//  RootViewController.m
//  PersistentTable
//
//  Created by sanjay krishnamurthy on 12/24/10.
//  Copyright 2010 Infinear Inc. All rights reserved.
//

#import "RootViewController.h"
#import "DialedViewController.h"
#import "EmailViewController.h"
#import "PopoverContentViewController.h"
#import "iPhoneStreamingPlayerViewController.h"
#import "PersistentTableAppDelegate.h"
#import "v2bFolder.h"
#import "v2bSettings.h"
#import <CoreData/CoreData.h>
#import "QuartzCore/CAAnimation.h"
#import "KeypadViewController.h"
#import "KeypadAppDelegate.h"

@implementation DialedViewController

@synthesize callsArray;
@synthesize currCall;

//create one play for all rows in table
iPhoneStreamingPlayerViewController *iph;
BOOL  isPlaying; //local var needs to be in sync with streamer's local var

#pragma mark -
#pragma mark View lifecycle

- (id)init
{
    // Set the title and tabbar image
    self.title = @"Recent Calls";
    self.tabBarItem.image = [UIImage imageNamed:@"clock.png"];  
    return self;
}

- (void)viewDidLoad {
	
    //You want to do viewDidLoad for RootControllerView to setup persistent managedObjectContext
	[super viewDidLoad];
    
    //Add title/tab bar img again because rootvc adds its own
    self.title = @"Recent Calls";
    self.tabBarItem.image = [UIImage imageNamed:@"clock.png"]; 
    
    //delete + button in left nav added by rootvc
    self.navigationItem.leftBarButtonItem = nil;
	
	//Add an Edit button to right side (just like the Folders view)
	self.navigationItem.rightBarButtonItem = super.editButtonItem;
	
	//init fetch results
	NSMutableArray  *mutableFetchResults = [self fetchEvent];
	[self setCallsArray:mutableFetchResults];
	[mutableFetchResults release];
	
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

//save  call with inputs firs name,last name, phone#, ccode
- (void)saveCall:(NSString *)first last:(NSString *)last phoneNumber:(NSString *)phoneNumber 
                                   country:(NSString *)country {

	NSLog(@"Saving call first %@ last %@ url tel %@ country %@", first, last, phoneNumber, country);
    NSString *name = @"";
    if (![self isEmpty:first] && ![self isEmpty:last]) {
        name = [NSString stringWithFormat:@"%@ %@", first, last];
    }
    else if (![self isEmpty:first]) {
        name = first;
    }
    else if (![self isEmpty:last]) {
        name = last;
    }
    
    BOOL doesExist = [self checkCallExists:phoneNumber];
	
	//create an V2bDialed object to store the call details.
	V2bDialed *event = (V2bDialed *)[NSEntityDescription insertNewObjectForEntityForName:@"V2bDialed" inManagedObjectContext:managedObjectContext];
	[event setName:name];
    [event setNumber:phoneNumber];
    [event setCountry:country];
    [event setDialedTime:[NSDate date]]; //todays date
	
	//save the new V2bDialed object persistently iff it doesnt already exist
    if (!doesExist) {
        //current event doesnt exist in table
        NSError *error = nil;
        if (![managedObjectContext save:&error]) {
            // Handle the error.
            NSLog(@"Error saving call  %@ persistently: %@", phoneNumber, [error localizedDescription]);
		
            //no more processing
            return;
        }
	
        //Add current file name to top of table view
        [callsArray insertObject:event atIndex:0];
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
        [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                              withRowAnimation:UITableViewRowAnimationFade];
        //causes core dump on Ashwini's iphone 4
        //[self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] 
        //                      atScrollPosition:UITableViewScrollPositionTop animated:YES];
        
        //redraw table to display new row
        [self.tableView reloadData];
	}
}

-(BOOL)checkCallExists:(NSString*)number {
    
    //iterate over current stored calls; return true if input param exists
    NSMutableArray  *contents = [self fetchEvent]; 
    V2bDialed *element;
    
    //iterate over stored calls
    for (element in contents)
    {
        //compare stored phone number with input param
        NSString *storedNum = element.number;
        if ([storedNum isEqualToString:number]) {
            return TRUE;
        }
    }
    
    return FALSE; //not found in stored calls
}

- (void)viewDidAppear:(BOOL)animated {
    
}


//clear all state vars passed into this view when we are done 
- (void)clearState {
	self.currCall       = nil;
	[self.tableView reloadData];
}

//Returns a copy of the fetched result set. Discard the copy after use
- (NSMutableArray *)fetchEvent {
	//create fetch request
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"V2bDialed" inManagedObjectContext:managedObjectContext];
	[request setEntity:entity];
	
	//add sort descriptor; sort by file name
	NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"dialedTime" ascending:NO];
	NSArray *sortDescriptors         = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
	[request setSortDescriptors:sortDescriptors];
	[sortDescriptors release]; //array release releases subobjects
	
	//do the fetch now
	NSError *error = nil;
	NSMutableArray *mutableFetchResults = [[managedObjectContext executeFetchRequest:request error:&error] mutableCopy];
	if (mutableFetchResults == nil || error != NULL) {
		// Handle the error.
		NSLog(@"Error fetching files: %@", [error localizedDescription]);
	}
	
	//cleanup before return
	[request release];
	
	NSLog(@"Got %d calls", [mutableFetchResults count]);
	return mutableFetchResults;
}

#pragma mark -
#pragma mark Table view data source

// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [callsArray count];
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"CallCell1";
	
    // Dequeue or create a new cell.
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        //cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle 
        //reuseIdentifier:CellIdentifier] autorelease];
        //use this cell type to add a label on right side
        cell = [[[UITableViewCell alloc]  initWithStyle:UITableViewCellStyleSubtitle 
                                        reuseIdentifier:CellIdentifier] autorelease];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.selectionStyle = UITableViewCellSelectionStyleBlue;
    }
	
    V2bDialed  *event           = (V2bDialed *)[callsArray objectAtIndex:indexPath.row];
	
	//Set main area of cell to be name and subtext to be dialed number. If name is null, dialed number
    //moves to the main area
    NSString *name    = [event valueForKey:@"name"];
    NSString *number  = [event valueForKey:@"number"];
    NSString *country = [event valueForKey:@"country"];
    if ([self isEmpty:name]) {
        name = number;
        number = @"";
    }
    
    cell.textLabel.text       = name;
    cell.detailTextLabel.text = number;
    
    //add country as accessory view
    CGRect frame             = CGRectMake(180.0, 10.0, 100, 25);
    UILabel *newLabel        = [[[UILabel alloc] initWithFrame:frame] autorelease];
    newLabel.text            = country;
    newLabel.backgroundColor = [UIColor colorWithRed:0.773f green:0.80f blue:0.831f alpha:1.0f];
    cell.accessoryView = newLabel;
	
	NSLog(@"Displaying cell with name %@ number %@ country %@", name, number, country);	
	
    return cell;
}

#pragma mark -
#pragma mark Table view delegate

//When a table row is selected, this toggles between play and pause modes depending on which
//img is currently being displayed
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

	//Get V2bDialed at current row
	V2bDialed *event        = (V2bDialed *)[callsArray objectAtIndex:indexPath.row];
    
    //dial the selected number
    NSString *name    = [event valueForKey:@"name"];
    NSString *number  = [event valueForKey:@"number"];
    NSString *country = [event valueForKey:@"country"];
    NSLog(@"Dialing name %@ number %@ country %@", name, number, country);	

    //create a keypad vc and init it to initate a call correctly
    KeypadViewController *kvc = [[KeypadViewController alloc] init];
    [kvc viewWillAppear:false];
    kvc.phoneNumber           = number;
    //set pickerChosen to indicate phoneNumber has already been set
    kvc.pickerChosen          = [[NSNumber alloc] initWithBool:TRUE];
    kvc.firstName             = name;
    kvc.country.chosenCountry = country;

    // force keypad view to be displayed	
    //KeypadAppDelegate *appDelegate       = (KeypadAppDelegate *)[[UIApplication sharedApplication] delegate];
    //UITabBarController *tabBarController = [appDelegate tabBarController];
    //[[[UIApplication sharedApplication] keyWindow] addSubview:tabBarController.view];
    
    //dial outbound call with the params fetched from storage
    [kvc call:nil]; //nil  sender
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
	
    if (editingStyle == UITableViewCellEditingStyleDelete) {
		
        // Delete the managed object at the given index path.
        NSManagedObject *callToDelete = [callsArray objectAtIndex:indexPath.row];
        [managedObjectContext deleteObject:callToDelete];

        // Commit the change.
        NSError *error = nil;
        if (![managedObjectContext save:&error]) {
            // Handle the error.
			NSLog(@"Error deleting call: %@", [error localizedDescription]);
        }
        
        // Update the array and table view.
        [callsArray removeObjectAtIndex:indexPath.row];
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:YES];
    }
}

#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Relinquish ownership any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	//091011 commented out code because this causes core dump when memory is purged
	/*
     self.callsArray = nil;
     self.currCall = nil;
     */
}

- (void)dealloc {
    //[managedObjectContext release];
    //This causes an exception "Message sent to deallocated array?? [callsArray release];
    [currCall release];
    //RootViewController has this commented out??[super dealloc];
}


- (void)viewWillDisappear:(BOOL)animated {

}

@end

