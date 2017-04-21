//
//  RootViewController.m
//  PersistentTable
//
//  Created by sanjay krishnamurthy on 12/24/10.
//  Copyright 2010 Infinear Inc. All rights reserved.
//

#import "RootViewController.h"
#import "FileViewController.h"
#import "EmailViewController.h"
#import "PopoverContentViewController.h"
#import "iPhoneStreamingPlayerViewController.h"
#import "PersistentTableAppDelegate.h"
#import "v2bFolder.h"
#import "v2bFile.h"
#import "v2bSettings.h"
#import <CoreData/CoreData.h>
#import <MediaPlayer/MediaPlayer.h>
#import "XmitMain.h"
#import "JSON.h"
#import "QuartzCore/CAAnimation.h"

@implementation FileViewController

@synthesize filesArray;
@synthesize currFile;
//create one play for all rows in table
iPhoneStreamingPlayerViewController *iph;
BOOL  isPlaying; //local var needs to be in sync with streamer's local var

#pragma mark -
#pragma mark View lifecycle

//if this view controller has been inited with a currFile and it does NOT have a 
//valid URL, then we are displaying files in a folder. Else, we will
//prompt the user for a file name and store this file in currFile.folderName
-(BOOL)isFileStoreView {
	if (currFile != nil && currFile.fileURL != nil) {
		return TRUE;
	}
	return FALSE;
}


- (void)viewDidLoad {
	
    //You want to do viewDidLoad for UITableView; not RootControllerView
	//[super viewDidLoad];
	
    // Set the title.
    self.title = @"Recordings";
	
	//Add an Edit button to right side (just like the Folders view)
	self.navigationItem.rightBarButtonItem = super.editButtonItem;
	
	//init fetch results
	NSMutableArray  *mutableFetchResults = [self fetchEvent];
	[self setFilesArray:mutableFetchResults];
	[mutableFetchResults release];
	
	//initial state of player
	isPlaying = FALSE;
	
	//fetch call recordings if this is the call rec foler being viewed
	[self fetchCallRecordings];
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

//If this is the soecial v2b call recording folder, fetch recordings from v2b server
-(void)fetchCallRecordings
{
	//This should not be a file store op
	if (![self isFileStoreView] && [currFile.folderName isEqualToString:callRecFolder]) {
		NSAutoreleasePool *	pool = [[NSAutoreleasePool alloc] init];
		
		//show activity indicator; dismiss when get op done
		NSString *prompt = [NSString stringWithFormat:@"%@", @"Fetching call recordings "];	
		[self addActivityIndicator:prompt];
		
		//what is the unique id of this user
		NSString *uid     = [PersistentTableAppDelegate getUniqueID];
		
		//allocate xmit class with right url; the format for the record op is
		//http://www.infinear.com/call/listDir.php?userid=userid
		//Gen final URL; 121011 changed url below for ec2
		//NSString *URLparam = [[[NSString alloc] initWithFormat:@"%@%@", @"http://www.infinear.com/call/listDir.php?userid=", uid] 
		//					  stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
		NSString *URLparam = [[[NSString alloc] initWithFormat:@"%@%@", @"http://ec2-107-21-106-75.compute-1.amazonaws.com/call/listDir.php?userid=", uid] 
							  stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
		NSString *OP       = @"GET";  
		NSLog(@"URLparam is %@", URLparam);
		NSURL    *param    = [NSURL URLWithString:URLparam];
		xmit               = [[XmitMain alloc] initWithURL:param xmitop:OP fileName:nil];
		//retain xmit object till all POSts to callback methods from runloop done
		[xmit retain];
		
		//set the callback inside the xmit class
		[xmit setDelegate:self];
		
		//020511 increase retain count so that self is retained till callback invoked
		[self retain];
		[URLparam retain];
		
		[xmit start];	
		//[URLparam release];
		//[pool release];
	} //is telephone# empty
	
} //fetchCallRecordings

//implement callback for GET contents; this is invoked by XmitMain
- (void)httpGetCallback:(XmitMain *)fetcher op:(PageGetOperation *)op {
	//op could be junk
	if (op != nil) {
		//dismiss activity indicator
		[self removeActivityIndicator];
		
		NSData *responseData = [op responseBody];
		NSString *content    = [[NSString alloc]  initWithBytes:[responseData bytes]
														 length:[responseData length] encoding: NSUTF8StringEncoding];
		NSLog(@"Call recording reply from server is \"%@\"", content);
		
		//Convert JSON reply into array of URLs
		NSError *error;
		//SBJSON *json    = [[SBJSON new] autorelease];
		//NSArray *URLarr = [json objectWithString:content error:&error];
		NSArray   *URLarr = [content JSONValue];
		//[content release];	
		
		if (URLarr == nil)
			NSLog(@"JSON parsing failed: %@", content);
		else {
			//Add all URLs to perssitent store IFF not present in store already
			for (int i = 0; i < URLarr.count; i++) {
				NSString *url = [URLarr objectAtIndex:i];
				[self storeCallRecording:url];
			}
		}
		
		//release self retained before http call is issued
		//[self release];
		
	}
} //httpGetCallback

//store recording persistently IFF not present in persistent store
- (void)storeCallRecording:(NSString *)url {
	//Is this url in persistent storage?
	v2bFile *event = (v2bFile *)[self fetchFileByName:url];	
	if (event == nil) {
		[self saveCallRecording:url];
	}
}

//Self explanatory; returns nil if no special call rec folder exists
- (v2bFile *)fetchFileByName:(NSString *)fileURL {
	//create fetch request
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"v2bFile" inManagedObjectContext:managedObjectContext];
	[request setEntity:entity];
	
	// Add a predicate to get a particular filein the call rec folder
	NSPredicate *predicate = [NSPredicate predicateWithFormat:
							  @"(folderName LIKE[c] %@) AND (fileURL LIKE[c] %@)", callRecFolder, fileURL];
	[request setPredicate:predicate];
	
	//do the fetch now
	NSError *error = nil;
	NSMutableArray *mutableFetchResults = [[managedObjectContext executeFetchRequest:request error:&error] mutableCopy];
	if (mutableFetchResults == nil || error != NULL) {
		// Handle the error.
		NSLog(@"Error fetching file: %@ %@", fileURL, [error localizedDescription]);
		return nil;
	}
	
	//if zero results, then no call rec folder exists
	if (mutableFetchResults.count != 1) {
		NSLog(@"Error fetching file url %@ in : %@", fileURL, callRecFolder);
		return nil;
	}
	
	//cleanup before return
	[request release];
	
	return (v2bFile *)([mutableFetchResults objectAtIndex:0]);
	
} //fetchFileByName

- (void)saveCallRecording:(NSString *)url {
	NSString *fileName   = url;
	NSNumber *fileLength = nil;
	
	//parse url into host url, base, extension; so
	//      http://www.infinear.com/call/mon/iphone/a3233//a3233/a3233-2011-05-14-20-05-48-iphone.call.21.mp3)
	//would be split up into:
	//      http://www.infinear.com/call/mon/iphone/a3233/a3233 as base      in pieces[0]
	//      2011 05 14 20 05 48                                 as dateTime  in pieces[1..6]
	//      iphone call                                         as attribute in pieces[7..8]
	//      21                                                  as duration  in pieces[9]
	//      mp3                                                 as extension in pieces[10]
	NSArray *pieces = [url componentsSeparatedByCharactersInSet:
					   [NSCharacterSet characterSetWithCharactersInString:@"-."]];
	
	//if there are 10 pieces, take them else fall back to the url
	if (pieces.count >= 10) {
		int       count     = pieces.count;  //pieces are 0..(count-1)
		//start indexing from right end backwards so that all comobos of uids and dates are parse correctly
		NSString *base      = (NSString *)[pieces objectAtIndex:(count-11)];
		NSString *year      = (NSString *)[pieces objectAtIndex:(count-10)];
		NSString *month     = (NSString *)[pieces objectAtIndex:(count-9)];
		NSString *day       = (NSString *)[pieces objectAtIndex:(count-8)];
		NSString *hour      = (NSString *)[pieces objectAtIndex:(count-7)];
		NSString *min       = (NSString *)[pieces objectAtIndex:(count-6)];
		NSString *sec       = (NSString *)[pieces objectAtIndex:(count-5)];
		NSString *client    = (NSString *)[pieces objectAtIndex:(count-4)];
		NSString *recType   = (NSString *)[pieces objectAtIndex:(count-3)];
		NSString *duration  = (NSString *)[pieces objectAtIndex:(count-2)];
		NSString *extn      = (NSString *)[pieces objectAtIndex:(count-1)];

		fileName = [[NSString alloc] initWithFormat:@"%@-%@-%@ at %@:%@", month, day, year, hour, min];
		
		//convert duration into file length; if duration doesnt exist, this gets null result
		fileLength = [NSNumber numberWithInt:[duration intValue]];
		if ([self isEmpty:fileLength]) {
			fileLength = 0;
		}
	}
	else {
		fileName = [url copy];
	}
	NSLog(@"Saving call recording filename %@ url %@ length %@", fileName, url, fileLength);
	
	//create an v2bFile object to store the file name, current file len and current folder name
	// Create and configure a new instance of the Event entity.
	v2bFile *event = (v2bFile *)[NSEntityDescription insertNewObjectForEntityForName:@"v2bFile" inManagedObjectContext:managedObjectContext];
	NSLog(@"Storing file %@ in folder %@ with url %@", fileName, callRecFolder, url);
	[event setFolderName:callRecFolder];
	[event setFileLength:fileLength]; 
	[event setFileURL:url];
	[event setFileName:fileName];
	
	//save the new v2bFile object persistently
	NSError *error = nil;
	if (![managedObjectContext save:&error]) {
		// Handle the error.
		NSLog(@"Error saving call recording %@ persistently: %@", fileName, [error localizedDescription]);
		
		//no more processing
		return;
	}
	
	//Add current file name to top of table view
	[filesArray insertObject:event atIndex:0];
	NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
	[self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
						  withRowAnimation:UITableViewRowAnimationFade];
	[self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] 
						  atScrollPosition:UITableViewScrollPositionTop animated:YES];
	
	//NOTE: DONT release arrays and perhaps ANYTHING in http callback methods. The runloop seems
	//to be releasing arrays esp and this will cause problems if you release it here before the runloop does.
	//[pieces release];
	//[fileName release];
}

- (void) removeActivityIndicator {
	[myIndicator stopAnimating];
	[myIndicator release];
}

//Show popover in a method that guarantees the focus will be on the textfield. Else, you will
//not see a keyboard in the popover view
- (void)viewDidAppear:(BOOL)animated {

	//if this is a file store view, then present popover to get file name
	if ([self isFileStoreView] == TRUE) {
		//Present popover iff currFile does not have a name in it
		if (currFile != nil && [currFile valueForKey:@"fileName"] == nil) {
			[self addEvent];
		}
		//else nothing to do
	}
	else {
		//create an iPhoneStreamingPlayerViewController mandatorily-012511
		iph = [[iPhoneStreamingPlayerViewController alloc] initWithNibName:nil bundle:nil];
	}
}
	
//The + button in the navigation bar is linked to thismethod. Show a popover now
- (void)addEvent {
	[super addEvent]; //create popover view
}

- (void)doneEvent:(id)sender {
    // If a popover is dismissed, copy the user entered name from popover
	NSString *fileName = [detailViewPopover.name.text copy];
	NSLog(@"User entered file name %@", fileName);
	
	//create an v2bFile object to store the file name, current file len and current folder name
	// Create and configure a new instance of the Event entity.
	v2bFile *event = (v2bFile *)[NSEntityDescription insertNewObjectForEntityForName:@"v2bFile" inManagedObjectContext:managedObjectContext];
	if (currFile != nil) {
		NSLog(@"Storing file %@ in folder %@ with url %@", fileName, currFile.folderName, currFile.fileURL);
		[event setFolderName:currFile.folderName];
		[event setFileLength:currFile.fileLength];
		[event setFileURL:currFile.fileURL];
	}
	[event setFileName:fileName];
	[currFile setValue:fileName forKey:@"fileName"]; //make sure currFile is updated too
	[fileName release];
	
	//save the new v2bFile object persistently
	NSError *error = nil;
	if (![managedObjectContext save:&error]) {
		// Handle the error.
		NSLog(@"Error saving file name persistently: %@", [error localizedDescription]);
		
		//no more processing
		return;
	}
	
	//Add current file name to top of table view
	[filesArray insertObject:event atIndex:0];
	NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
	[self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
						  withRowAnimation:UITableViewRowAnimationFade];
	[self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] 
						  atScrollPosition:UITableViewScrollPositionTop animated:YES];
	
	//before popping to parent, clear all state passed into this view from parent view
	//Also pop back to root because the viewcontroller is in a weird state now
	[self clearState];
	
	//dismiss popover and pop back to parent
	[super dismissModalViewControllerAnimated:true];
}

//clear all state vars passed into this view when we are done with email stuff
- (void)clearState {
	self.currFile.fileURL       = nil;
	//012911 reload table of files so that play button is displayed
	[self.tableView reloadData];
}

//Returns a copy of the fetched result set. Discard the copy after use
- (NSMutableArray *)fetchEvent {
	//create fetch request
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"v2bFile" inManagedObjectContext:managedObjectContext];
	[request setEntity:entity];
	
	//add sort descriptor; sort by file name
	NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"fileName" ascending:NO];
	NSArray *sortDescriptors         = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
	[request setSortDescriptors:sortDescriptors];
	[sortDescriptors release]; //array release releases subobjects
	
	// Add a predicate to get files from particular folder; we examine the currFile variable. If non null,
	//then use the folder name inside it
	if (currFile != nil && currFile.folderName != nil) {
		NSString *fName = currFile.folderName;
		NSPredicate *predicate = [NSPredicate predicateWithFormat:
							  @"(folderName LIKE[c] %@)", fName];
		[request setPredicate:predicate];
	}
	
	//do the fetch now
	NSError *error = nil;
	NSMutableArray *mutableFetchResults = [[managedObjectContext executeFetchRequest:request error:&error] mutableCopy];
	if (mutableFetchResults == nil || error != NULL) {
		// Handle the error.
		NSLog(@"Error fetching files: %@", [error localizedDescription]);
	}
    
    //delete all files marked as deleted in persistent store
    NSMutableArray *itemsToKeep = [NSMutableArray arrayWithCapacity:[mutableFetchResults count]];
    
    for (v2bFile *file in mutableFetchResults){
        if(!file.deleted.boolValue) {
             [itemsToKeep addObject:file];
        }
    }
    [mutableFetchResults setArray:itemsToKeep];
    [mutableFetchResults release];
    mutableFetchResults = [itemsToKeep retain];
	
	//cleanup before return
	[request release];
	
	NSLog(@"Got %d files in folder %@", [mutableFetchResults count], [currFile folderName]);
	return mutableFetchResults;
}

#pragma mark -
#pragma mark Table view data source

// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [filesArray count];
}

//Use these tags to find the play/pause button, the slider bar view and the running time view
#define PLAYBUTTON_TAG 1
#define SLIDERBAR_TAG   2
#define RUNNINGTIME_TAG 3

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"FileCell";
	
    // Dequeue or create a new cell.
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];
    }
	
    v2bFile  *event           = (v2bFile *)[filesArray objectAtIndex:indexPath.row];
	
	//Set main area of cell to be filename and subtext to be file length (if non-empty).
	//If fileLength is empty, store folder name as subtext
    cell.textLabel.text       = [event valueForKey:@"fileName"];
	NSNumber *fileLength      = [event valueForKey:@"fileLength"];
	if ([fileLength intValue] <= 0) {
		cell.detailTextLabel.text = [event valueForKey:@"folderName"];
	}
	else {
		NSString *lab             = [[NSString alloc] initWithFormat:@"%@ seconds", [fileLength stringValue]]; 
		cell.detailTextLabel.text = lab;
	}
	
	[cell setAccessoryType:UITableViewCellAccessoryDetailDisclosureButton];
	NSLog(@"Displaying cell with file name %@ folder %@ url %@", [event fileName], [event folderName],
		  [event fileURL]);
	
	//Add subviews inside cell iff this is NOT a file store
	if ([self isFileStoreView] == FALSE) {
		//Add play/pause button as accessory view on left side
		UIButton    *play     = [[UIButton alloc] initWithFrame:CGRectMake(0.0, 0.0, 40.0, 40.0)];
		play.tag              = PLAYBUTTON_TAG;
		//Add play image to button
		NSString *path    = [[NSBundle mainBundle] pathForResource:@"play" ofType:@"png"];
		UIImage *theImage = [UIImage imageNamed:@"play.png"]; //[UIImage imageWithContentsOfFile:path];
		[play setImage:theImage forState:nil];
		//Add target event to play button
		[play addTarget:self action:@selector(playPressed:) forControlEvents:UIControlEventValueChanged];
		//Adding a button with an image does not work; we add the image directly
		//[cell.imageView addSubview:play];
		cell.image = theImage;
		[play	release];
		//[theImage release]; DONT release objects that were NOT alloced or copied
	
		//Add slider bar to main cell content view; moved to table footer to clean up display
		/* UISlider *slider    = [[UISlider alloc] initWithFrame:CGRectMake(80, 12, 240, 25)];	
		slider.maximumValue = [event.fileLength floatValue];
		slider.minimumValue = 0.0;
		slider.continuous = TRUE;	
		[slider addTarget:iph action:@selector(sliderMoved:) forControlEvents:UIControlEventValueChanged];	
		[slider setMaximumValue:100.0f];
		[cell.contentView addSubview:slider];
		slider.tag = SLIDERBAR_TAG;
		[slider release];  */
	
		//Add a label to display running time in the accessory view area; now moved to a subview of content
		/* UILabel *runTime = [[UILabel alloc] initWithFrame:CGRectMake(0.0, 0.0, 80.0, 25.0)];
		float    rt      = [currFile.fileLength floatValue];
		if (rt == 0.0) {
			rt = 0.0f;
		}
		NSString *lab    = [[NSString alloc] initWithFormat:@"000.0/%g", rt];
		[runTime setText:lab];
		runTime.tag = RUNNINGTIME_TAG;
		cell.accessoryView = runTime;
		[lab release]; */
	}
	
    return cell;
}

//events from the file cell trigger playPressed and sliderChanged events
-(void)playPressed:(UIButton *)sender {
	NSLog(@"(Play button touched in files view");
}

-(void)sliderChanged:(UISlider *)sender {
	NSLog(@"(Slider button touched in files view");
}

#pragma mark -
#pragma mark Table view delegate

//When a table row is selected, this toggles between play and pause modes depending on which
//img is currently being displayed
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	
	//Get cell at selected index
	UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
	//Get v2bFile at current row
	v2bFile *event        = (v2bFile *)[filesArray objectAtIndex:indexPath.row];
	//Pass current cell to streamer so that it can update the view
	iph.cell              = cell;
	
	//look at current image for cell; if it is play, then revert to pause img
	UIButton *play    = (UIButton *)[cell.imageView viewWithTag:PLAYBUTTON_TAG];
	NSString *path    = [[NSBundle mainBundle] pathForResource:@"play" ofType:@"png"];
	UIImage *theImage = [UIImage imageNamed:@"play.png"]; //[UIImage imageWithContentsOfFile:path];
	
	//Always let streamer tell you its state
	if (!iph.isPlaying) {
		isPlaying= TRUE;
		[iph setIsPlaying:isPlaying]; //pass onto streamer
		path     = [[NSBundle mainBundle] pathForResource:@"pause" ofType:@"png"];
		theImage = [UIImage imageWithContentsOfFile:path];
		[play setImage:theImage forState:nil];
		cell.image = theImage;
	
		//Add a v2bFile with current file name in it
		v2bFile *v2bf     = (v2bFile *)[filesArray objectAtIndex:indexPath.row];
		NSString *url     = [v2bf valueForKey:@"fileURL"];
		NSString *duration= [v2bf valueForKey:@"fileLength"];
	
	
		NSLog(@"file play button pressed for url %@", url);
	
		//copy current row buttons/areas over to it
		//and start playing the url
	
		//Transfer current row's buttons and view over to streaming controller
		UITextField *dwnld = [[[UITextField alloc] init] autorelease];
		[dwnld setText:url];
		[iph setDownloadSourceField:dwnld];
	
		//xfer play/pause button 
		[iph setButton:play];
	
		//Add volume slider to table header view
		UISlider *volSlider    = [[[UISlider alloc] initWithFrame:CGRectMake(80, 12, 240, 25)] autorelease];
		[tableView setTableHeaderView:volSlider];
		UIView     *tableHeaderView = [tableView tableHeaderView];
		MPVolumeView *volumeView = [[[MPVolumeView alloc] initWithFrame:volSlider.bounds] autorelease];
		[volSlider addSubview:volumeView];
		[volumeView sizeToFit];
		[iph setVolumeSlider:tableHeaderView];
		
		//Add seek slider to left part of table footer
		UISlider *slider    = [[[UISlider alloc] initWithFrame:CGRectMake(0, 0, 240, 25)] autorelease];	
		slider.maximumValue = [event.fileLength floatValue];
		slider.minimumValue = 0.0;
		slider.continuous = TRUE;	
		[slider addTarget:iph action:@selector(sliderMoved:) forControlEvents:UIControlEventValueChanged];	
		[slider setMaximumValue:100.0f];
		[tableView setTableFooterView:slider];
		slider.tag = SLIDERBAR_TAG;
		//This is needed if the slider is inside the cell; not for footer
		//UISlider *slider = (UISlider *)[cell.contentView viewWithTag:SLIDERBAR_TAG];
		[iph setProgressSlider:slider];
		//[slider release];
		
		//Add the running time to right part of footer
		UILabel *runTime = [[UILabel alloc] initWithFrame:CGRectMake(200.0, 0.0, 80.0, 25.0)];
		float    rt      = [currFile.fileLength floatValue];
		if (rt == 0.0) {
			rt = 0.0f;
		}
		NSString *lab    = [[[NSString alloc] initWithFormat:@"000.0/%g", rt] autorelease];
		[runTime setText:lab];
		runTime.tag = RUNNINGTIME_TAG;
		[cell.contentView addSubview:runTime];
		//[lab release];
	
		//Add timing position label
		//UILabel *runTime = (UILabel *)[cell.accessoryView viewWithTag:RUNNINGTIME_TAG];
		[iph setPositionLabel:runTime];
		
		//invoke buttonPressed method to start download
		[iph buttonPressed:play];
	}
	else {
		isPlaying = FALSE;
		[iph setIsPlaying:isPlaying]; //pass onto streamer
		//prepare to show play button
		path     = [[NSBundle mainBundle] pathForResource:@"play" ofType:@"png"];
		theImage = [UIImage imageWithContentsOfFile:path];
		[play setImage:theImage forState:nil];
		cell.image = theImage;
		
		v2bFile *v2bf     = (v2bFile *)[filesArray objectAtIndex:indexPath.row];
		NSString *url     = [v2bf valueForKey:@"fileURL"];
		NSLog(@"file pause button pressed for url %@", url);
		
		//transfer event over to streamer
		[iph buttonPressed:play];
	}
}

//Implement this method for drilldowns
- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
	//Drilldown button for file tapped; lead user to email flow
	NSLog(@"Detail disclosure for files tapped; send email now");
	
	//Add a email view controller to navigation stack
	EmailViewController *emailViewController = [[PersistentTableAppDelegate alloc] initEmailViewController];
	//init MOC with file view controller's moc
	emailViewController.managedObjectContext = managedObjectContext;
	
	//Add current folder name and file name to v2bFile instance
	if ([self currFile] != nil) {
		v2bFile  *event            = (v2bFile *)[filesArray objectAtIndex:indexPath.row];
		NSString *fileName         = [event valueForKey:@"fileName"];
		[currFile setValue:fileName forKey:@"fileName"];
		NSString *fileURL          = [event valueForKey:@"fileURL"];
		[currFile setValue:fileURL forKey:@"fileURL"];
	}
	else {
		NSLog(@"In file drilldown, local currFile instance is nil!!");
	}
	
	emailViewController = [emailViewController initWithNibName:nil bundle:nil];
	[emailViewController setV2bf:currFile];
	[[self navigationController] pushViewController:emailViewController animated:NO];
    [emailViewController release];
	
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
	
    if (editingStyle == UITableViewCellEditingStyleDelete) {
		
        // Delete the managed object at the given index path.
        //Just mark the object as being deleted
        //NSManagedObject *fileToDelete = [filesArray objectAtIndex:indexPath.row];
        //[managedObjectContext deleteObject:fileToDelete];
        v2bFile *fileToDelete = (v2bFile *)[filesArray objectAtIndex:indexPath.row];
        //flip deleted flag to indicate file has been deleted
        NSNumber  *flag = [[NSNumber alloc] initWithBool:TRUE];
        [fileToDelete setDeleted:flag];
        //[managedObjectContext refreshObject:(NSManagedObject *)fileToDelete mergeChanges:TRUE];
		
        // Update the array and table view.
        [filesArray removeObjectAtIndex:indexPath.row];
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:YES];
		
        // Commit the change.
        NSError *error = nil;
        if (![managedObjectContext save:&error]) {
            // Handle the error.
			NSLog(@"Error deleting file: %@", [error localizedDescription]);
        }
		
		//restore back button to history; we dont do history any more. Just keep an Edit button
		//constantly in the right side
		//self.navigationItem.leftBarButtonItem = super.history;
		//history = nil;
    }
}

//Methods to store file persistently 
- (void)storeFile:(NSDictionary *)dict {
	
	//Get file settings from dict
	NSString *fileName     = [dict objectForKey:@"fileName"];
	NSString *folderName   = [dict objectForKey:@"folderName"];
	NSString *fileURL      = [dict objectForKey:@"fileURL"];
	float     fileLength   = [[dict objectForKey:@"fileLength"] floatValue];
	
	//create an v2bFile object to store the user name, default email address, xfer speed
	// Create and configure a new instance of the v2bFile entity.
	v2bFile *event = (v2bFile *)[NSEntityDescription insertNewObjectForEntityForName:@"v2bFile" inManagedObjectContext:managedObjectContext];
	[event setFileName:fileName];
	[event setFolderName:folderName];
	[event setFileURL:fileURL];
	[event setFileLength:[[NSNumber alloc] initWithFloat:fileLength]];
	
	//save the new v2bFolder object persistently
	NSError *error = nil;
	if (![managedObjectContext save:&error]) {
		// Handle the error.
		NSLog(@"Error saving file persistently: %@", [error localizedDescription]);
		
		//no more processing
		return;
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
    self.filesArray = nil;
    self.currFile = nil;
	*/
}

- (void)dealloc {
    //[managedObjectContext release];
    [filesArray release];
    [currFile release];
	[iph release];
	//popover has already been eagerly released; this causes an exception [detailViewPopover	release];
    //012511 cannot release super causes exception [super dealloc];
}

//When the streaming player is going to be quit, we make sure the audio session is made inactive on exit
- (void)viewWillDisappear:(BOOL)animated {
   if ([self isFileStoreView] == FALSE) {
	   [iph clearState];
   }
}

@end

