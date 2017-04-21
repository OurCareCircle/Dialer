//
/*

    File: SpeakHereController.mm
Abstract: n/a
 Version: 2.4

Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
Inc. ("Apple") in consideration of your agreement to the following
terms, and your use, installation, modification or redistribution of
this Apple software constitutes acceptance of these terms.  If you do
not agree with these terms, please do not use, install, modify or
redistribute this Apple software.

In consideration of your agreement to abide by the following terms, and
subject to these terms, Apple grants you a personal, non-exclusive
license, under Apple's copyrights in this original Apple software (the
"Apple Software"), to use, reproduce, modify and redistribute the Apple
Software, with or without modifications, in source and/or binary forms;
provided that if you redistribute the Apple Software in its entirety and
without modifications, you must retain this notice and the following
text and disclaimers in all such redistributions of the Apple Software.
Neither the name, trademarks, service marks or logos of Apple Inc. may
be used to endorse or promote products derived from the Apple Software
without specific prior written permission from Apple.  Except as
expressly stated in this notice, no other rights or licenses, express or
implied, are granted by Apple herein, including but not limited to any
patent rights that may be infringed by your derivative works or by other
works in which the Apple Software may be incorporated.

The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.

IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
POSSIBILITY OF SUCH DAMAGE.

Copyright (C) 2009 Apple Inc. All Rights Reserved.


*/

#import "SpeakHereController.h"
#import "SpeakHereAppDelegate.h"
#import "SpeakHereViewController.h"
#import "RootViewController.h"
#import "v2bFile.h"
#import "PersistentTableAppDelegate.h"
#import "iPhoneStreamingPlayerViewController.h"
#import "JSON.h"
#import "XmitMain.h"
#import "PageGetOperation.h"
#import "QuartzCore/CAAnimation.h"
#import "UIDevice+IdentifierAddition.h"

@implementation SpeakHereController

@synthesize player;
@synthesize recorder;

@synthesize btn_record;
@synthesize btn_play;
@synthesize fileDescription;
@synthesize lvlMeter_in;
@synthesize recordingWasInterrupted;
@synthesize lastURL;
@synthesize myViewController;
@synthesize myIndicator;


char *OSTypeToStr(char *buf, OSType t)
{
	char *p = buf;
	char str[4], *q = str;
	*(UInt32 *)str = CFSwapInt32(t);
	for (int i = 0; i < 4; ++i) {
		if (isprint(*q) && *q != '\\')
			*p++ = *q++;
		else {
			sprintf(p, "\\x%02x", *q++);
			p += 4;
		}
	}
	*p = '\0';
	return buf;
}

//There are several gotchas to this routine: the id should not change on reboot. It should
//not violate Apple's rules. It should work on ipod touches and phones
+(NSString *)getUniqueID{
    NSString *udid = [[UIDevice currentDevice] uniqueDeviceIdentifier];
    
    //remove all dashes, parens and whitespace from udid
    udid = [udid stringByReplacingOccurrencesOfString:@"-" withString:@""];
    udid = [udid stringByReplacingOccurrencesOfString:@" " withString:@""];
    udid = [udid stringByReplacingOccurrencesOfString:@"(" withString:@""];
    udid = [udid stringByReplacingOccurrencesOfString:@")" withString:@""];
    
    return    udid;
}

-(void)setFileDescriptionForFormat: (CAStreamBasicDescription)format withName:(NSString*)name
{
	char buf[5];
	const char *dataFormat = OSTypeToStr(buf, format.mFormatID);
	NSString* description = [[NSString alloc] initWithFormat:@"(%d ch. %s @ %g Hz)", format.NumberChannels(), dataFormat, format.mSampleRate, nil];
	fileDescription.text = description;
	[description release];	
}

#pragma mark Playback routines

-(void)stopRecordQueue
{
	recorder->StopQueue();
	[lvlMeter_in setAq: nil];
	btn_record.enabled = YES;
}

-(void)pauseRecordQueue
{
	recorder->PauseQueue();
	recordingWasPaused = YES;
}

- (void)stopRecord
{
	// Disconnect our level meter from the audio queue
	[lvlMeter_in setAq: nil];
	
	//Find total number of parts recorded
	UInt32 partNum = recorder->StopRecord();
	
	// dispose the previous playback queue
	player->DisposeQueue(true);

	// now create a new queue for the recorded file Sanjay used to be .aif type file;
	NSString *fileName = [SpeakHereController getUniqueID];
	fileName           = [fileName stringByAppendingString:@"-iphone.part0.aif"];
	recordFilePath     = (CFStringRef)[NSTemporaryDirectory() stringByAppendingPathComponent: fileName];
	player->CreateQueueForFile(recordFilePath);
	//Dont release because its a constant [fileName release];
		
	// Set the button's state back to "record"
	//030311 Set background image to LiveRec
	btn_record.title = @"Record";
	//UIImage *image = [[UIImage imageNamed:@"LiveRec.png"]
	//				  stretchableImageWithLeftCapWidth:8 topCapHeight:8];
	//[btn_record setBackgroundImage:image forState:UIControlStateNormal];
	//[btn_record setTitle:@"Record" forState:UIControlStateNormal];
	
	btn_play.enabled = NO;
	
	//Gen final MP3
	[self genFinal:partNum];
}

//Allow the user to choose a destination folder, destination filename and email address to mail to
-(void) presentFolderView {
	//Add a root view controller to navigation stack
	RootViewController *folderViewController = [[PersistentTableAppDelegate alloc] initRootViewController];
	
	//Add a v2bFile instance with the current URL embedded in it
	v2bFile * v2bf = [v2bFile alloc];
	//set  using kvc
	[v2bf setValue:lastURL forKey:@"fileURL"];
	folderViewController = [folderViewController initWithNibName:nil bundle:nil];
	[folderViewController setV2bf:v2bf];
	
	UINavigationController *nav = [myViewController navigationController];	
	[nav pushViewController:folderViewController animated:NO];
    //020911 dont release because its in use still [folderViewController release];
		
}

- (IBAction)pause:(id)sender
{
	//invoke custome playback routine
	//[self playRecording:lastURL];
	
	if (recorder->IsRunning())
	{
		if (recordingWasPaused) {
			OSStatus result = recorder->StartQueue(true);
			if (result == noErr)
				[[NSNotificationCenter defaultCenter] postNotificationName:@"recordingQueueResumed" object:self];
		}
		else {
			[self pauseRecordQueue];
			[[NSNotificationCenter defaultCenter] postNotificationName:@"recordingQueueStopped" object:self];
		}
		
	}
	else
	{		
		OSStatus result = recorder->StartQueue(false);
		if (result == noErr)
			[[NSNotificationCenter defaultCenter] postNotificationName:@"recordingQueueResumed" object:self];
	} 
}

//The user has pressed the stop record button; generate the final mp3 by invoking
//a GET of genFinal.php?userid=xxx&numparts=yyy
-(void)genFinal:(UInt32)partNum
{
	//show activity indicator; dismissed when get op done
	NSString *prompt = @"Generating MP3";
	[self addActivityIndicator:prompt];
	
	//what is the unique id of this user
	NSString *uid     = [SpeakHereController getUniqueID];
	
	//allocate xmit class with right url; 121011 changed url below for ec2
	NSAutoreleasePool *	pool = [[NSAutoreleasePool alloc] init];
	//NSString *URL      = [[NSString alloc] initWithFormat:@"%@%@%@%d", @"http://www.infinear.com/iphone/genFinal.php?userid=", uid, @"%26numparts=",
	//					  partNum]; //%26 is ampersand
	NSString *URL      = [[NSString alloc] initWithFormat:@"%@%@%@%d", @"http://ec2-107-21-106-75.compute-1.amazonaws.com/iphone/genFinal.php?userid=", uid, @"%26numparts=",
						  partNum]; //%26 is ampersand
	NSString *OP       = @"GET";  
	XmitMain * xmit    = [[XmitMain alloc] initWithURL:[NSURL URLWithString:URL] xmitop:OP fileName:nil];
	
	//set the callback inside the xmit class
	[xmit setDelegate:self];
	[xmit start];	
	[URL release];
	[pool release];
	
} //genFinal

//The user has pressed the start record button; cleanup all previously generated files on server
//by invoking cleanup.php?userid=xxx
-(void)cleanupFilesOnServer
{
	
	//show activity indicator; dismiss when get op done
	NSString *prompt = @"Initializing";
	[self addActivityIndicator:prompt];
	
	//what is the unique id of this user
	NSString *uid     = [SpeakHereController getUniqueID];
	
	//allocate xmit class with right url; 121011 changed url below for ec2
	NSAutoreleasePool *	pool = [[NSAutoreleasePool alloc] init];
	//NSString *URL      = [[NSString alloc] initWithFormat:@"%@%@", @"http://www.infinear.com/iphone/cleanup.php?userid=", uid];
	NSString *URL      = [[NSString alloc] initWithFormat:@"%@%@", @"http://ec2-107-21-106-75.compute-1.amazonaws.com/iphone/cleanup.php?userid=", uid];
	NSString *OP       = @"GET";  
	XmitMain * xmit    = [[XmitMain alloc] initWithURL:[NSURL URLWithString:URL] xmitop:OP fileName:nil];
	
	//set the callback inside the xmit class
	[xmit setDelegate:self];
	[xmit start];	
	[URL release];
	[pool release];
	
} //cleanup

//implement callback for GET contents; this is invoked by XmitMain
- (void)httpGetCallback:(XmitMain *)fetcher op:(PageGetOperation *)op {
	//op could be junk
	if (op != nil) {
		//dismiss activity indicator
		[self removeActivityIndicator];
		
		NSData *responseData = [op responseBody];
		NSString *content    = [[NSString alloc]  initWithBytes:[responseData bytes]
						     	 length:[responseData length] encoding: NSUTF8StringEncoding];
		
		//If content is not empty, do followthru code
		if ([self isEmpty:content] == false) {
			//content ought to be sane JSON data-parse it and extract the final filename
			//usually in this form {"gen":"http:\/\/www.infinear.com\/mon\/iphone\/4089921762\/10-12-11-15-26-55-4089921762.mp3"}
			//NOTE the escaped url
			NSDictionary *dictionary = [content JSONValue];
			NSString     *genURL     = [dictionary objectForKey:@"gen"];
			NSLog(@"Final URL gened by server is \"%@\"", genURL);	
			//Store locally for playback
			lastURL = [genURL copy];
			
			//Now that we have the final URL, allow user to store it in a folder
			[self presentFolderView];
		}
		
		[content release];	
	}
} //httpGetCallback

// Check if the "thing" pass'd is empty
- (BOOL)isEmpty:(id)thing {
    return thing == nil
    || [thing isKindOfClass:[NSNull class]]
    || ([thing respondsToSelector:@selector(length)]
        && [(NSData *)thing length] == 0)
    || ([thing respondsToSelector:@selector(count)]
        && [(NSArray *)thing count] == 0);
}

//user has pressed play in main menu; start playing last recording
- (void)playRecording:(NSString *)URL {
	
	//get root view controller
	SpeakHereViewController *rootVC = [SpeakHereViewController instance];
	iPhoneStreamingPlayerViewController  *owner = [iPhoneStreamingPlayerViewController alloc];
	NSArray *a = [[NSBundle mainBundle] loadNibNamed:@"isp" owner:owner options:nil];
	iPhoneStreamingPlayerViewController *c = [a objectAtIndex:0];
	[rootVC presentModalViewController:owner animated:YES];
	
	//Before you show it to the user, set the url and press the play button
	owner.downloadSourceField.text = URL;
	//release URL now
	[URL release];
	owner.button.highlighted       = YES;
}


- (IBAction)record:(id)sender
{
	if (recorder->IsRunning()) // If we are currently recording, stop and save the file.
	{
		[self stopRecord];
	}
	else // If we're not recording, start.
	{
		
		//cleanup all files on server before proceeding
		[self cleanupFilesOnServer];
		
		btn_play.enabled = YES;	
		
		// Set the button's state to "stop"
		//030311 Set button image to LiveStop
		btn_record.title = @"Stop";
		//UIImage *image = [[UIImage imageNamed:@"LiveStop.png"]
		//				  stretchableImageWithLeftCapWidth:8 topCapHeight:8];
		//[btn_record setBackgroundImage:image forState:UIControlStateNormal];
		//[btn_record setTitle:@"Stop" forState:UIControlStateNormal];
				
		// Start the recorder Sanjay used to be .aif type file; 
		NSString *fileName = [SpeakHereController getUniqueID];
		fileName           = [fileName stringByAppendingString:@"-iphone.part0.aif"];
		recordFilePath     = (CFStringRef)[NSTemporaryDirectory() stringByAppendingPathComponent: fileName];
		recorder->StartRecord(recordFilePath);
		//dont release because its a constant [fileName release];
		
		[self setFileDescriptionForFormat:recorder->DataFormat() withName:@"Recorded File"];
		
		// Hook the level meter up to the Audio Queue for the recorder
		[lvlMeter_in setAq: recorder->Queue()];
	}	
}

#pragma mark AudioSession listeners
void interruptionListener(	void *	inClientData,
							UInt32	inInterruptionState)
{
	SpeakHereController *THIS = (SpeakHereController*)inClientData;
	
	//022611 for some weird reason, if recorder is not running and is interrupted, everything fails
	//So, we reinit the recorder just in case
	if (THIS->recorder->IsRunning() == false) {
		NSLog(@"Interrupted but recorder is idle; TODO everything fails past this point");
	}
	else if (THIS->recorder->IsRunning() && (inInterruptionState == kAudioSessionBeginInterruption))
	{
		//022611 the pause method does all the work we need to pause a recording
		THIS->recordingWasInterrupted = YES;
		[THIS pause:THIS.btn_play];
		/*
		if (THIS->recorder->IsRunning()) {
			[THIS stopRecord];
			//we just need to update the UI
			[[NSNotificationCenter defaultCenter] postNotificationName:@"recordingQueueStopped" object:THIS];
			THIS->recordingWasInterrupted = YES;
		}
		 */
	}
	// we were recording when we were interrupted, so resume now
	else if (THIS->recorder->IsRunning() && (inInterruptionState == kAudioSessionEndInterruption) && 
			 THIS->recordingWasInterrupted)
	{
		//022611 the pause method does all the work
		THIS->recordingWasInterrupted = NO;
		[THIS pause:THIS.btn_play];
		
		/*
		THIS->recorder->StartQueue(true);
		[[NSNotificationCenter defaultCenter] postNotificationName:@"recordingQueueResumed" object:THIS];
		THIS->recordingWasInterrupted = NO;
		 */
	}
}

void propListener(	void *                  inClientData,
					AudioSessionPropertyID	inID,
					UInt32                  inDataSize,
					const void *            inData)
{
	SpeakHereController *THIS = (SpeakHereController*)inClientData;
	if (inID == kAudioSessionProperty_AudioRouteChange)
	{
		CFDictionaryRef routeDictionary = (CFDictionaryRef)inData;			
		//CFShow(routeDictionary);
		CFNumberRef reason = (CFNumberRef)CFDictionaryGetValue(routeDictionary, CFSTR(kAudioSession_AudioRouteChangeKey_Reason));
		SInt32 reasonVal;
		CFNumberGetValue(reason, kCFNumberSInt32Type, &reasonVal);
		if (reasonVal != kAudioSessionRouteChangeReason_CategoryChange)
		{
			/*CFStringRef oldRoute = (CFStringRef)CFDictionaryGetValue(routeDictionary, CFSTR(kAudioSession_AudioRouteChangeKey_OldRoute));
			if (oldRoute)	
			{
				printf("old route:\n");
				CFShow(oldRoute);
			}
			else 
				printf("ERROR GETTING OLD AUDIO ROUTE!\n");
			
			CFStringRef newRoute;
			UInt32 size; size = sizeof(CFStringRef);
			OSStatus error = AudioSessionGetProperty(kAudioSessionProperty_AudioRoute, &size, &newRoute);
			if (error) printf("ERROR GETTING NEW AUDIO ROUTE! %d\n", error);
			else
			{
				printf("new route:\n");
				CFShow(newRoute);
			}*/

			// stop the queue if we had a non-policy route change
			if (THIS->recorder->IsRunning()) {
				[THIS stopRecord];
			}
		}	
	}
	else if (inID == kAudioSessionProperty_AudioInputAvailable)
	{
		if (inDataSize == sizeof(UInt32)) {
			UInt32 isAvailable = *(UInt32*)inData;
			// disable recording if input is not available
			THIS->btn_record.enabled = (isAvailable > 0) ? YES : NO;
		}
	}
}
				
#pragma mark Initialization routines
- (void)awakeFromNib
{		
	// Allocate our singleton instance for the recorder & player object
	recorder = new AQRecorder();
	player   = new AQPlayer();
		
	OSStatus error = AudioSessionInitialize(NULL, NULL, interruptionListener, self);
	if (error) printf("ERROR INITIALIZING AUDIO SESSION! %d\n", error);
	else 
	{
		//020511 added kAudioSessionCategory_MediaPlayback property below for AudioStreamer; we maintain an AudioSession 
		//singleton here
		//021811 on iphone v4.x combining kAudioSessionCategory_PlayAndRecord | kAudioSessionCategory_MediaPlayback
		//causes an error
		UInt32 category = kAudioSessionCategory_PlayAndRecord;	
		error = AudioSessionSetProperty(kAudioSessionProperty_AudioCategory, sizeof(category), &category);
		if (error) printf("couldn't set audio category!");
									
		error = AudioSessionAddPropertyListener(kAudioSessionProperty_AudioRouteChange, propListener, self);
		if (error) printf("ERROR ADDING AUDIO SESSION PROP LISTENER! %d\n", error);
		UInt32 inputAvailable = 0;
		UInt32 size = sizeof(inputAvailable);
		
		// we do not want to allow recording if input is not available
		error = AudioSessionGetProperty(kAudioSessionProperty_AudioInputAvailable, &size, &inputAvailable);
		if (error) printf("ERROR GETTING INPUT AVAILABILITY! %d\n", error);
		btn_record.enabled = (inputAvailable) ? YES : NO;

		if (!inputAvailable) {
			[self micNotAvailable];
		}
		
		// we also need to listen to see if input availability changes
		error = AudioSessionAddPropertyListener(kAudioSessionProperty_AudioInputAvailable, propListener, self);
		if (error) printf("ERROR ADDING AUDIO SESSION PROP LISTENER! %d\n", error);

		error = AudioSessionSetActive(true); 
		if (error) printf("AudioSessionSetActive (true) failed");
	}
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(recordingQueueStopped:) name:@"recordingQueueStopped" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(recordingQueueResumed:) name:@"recordingQueueResumed" object:nil];

	UIColor *bgColor = [[UIColor alloc] initWithRed:.39 green:.44 blue:.57 alpha:.5];
	[lvlMeter_in setBackgroundColor:bgColor];
	[lvlMeter_in setBorderColor:bgColor];
	[bgColor release];
	
	// disable the pause button initially; enable when recording begins
	btn_play.enabled = NO;
	recordingWasInterrupted = NO;
	recordingWasPaused = NO;
	
}

//Show the user an alert that no Mic is available on current device
- (void)micNotAvailable
{
	// open an alert with just an OK button
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"No Audio input" 
						  message:@"Plug in a mic;restart app to record"
						  delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
    [alert show];   
    [alert release];
}

#pragma mark -
#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    // use "buttonIndex" to decide your action
    //
}

//Show a custom view when GET ops are being done
- (void)addActivityIndicator:(NSString *)prompt
{
    myIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
	myIndicator.center = CGPointMake(120, 200);
	myIndicator.hidesWhenStopped = YES; //means when stop is called it is dismissed
	UINavigationController *nav = [myViewController navigationController];
	
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

# pragma mark Notification routines
- (void)recordingQueueStopped:(NSNotification *)note
{
	//030311 set title to Continue on play button
	btn_play.title = @"Continue";
	//[btn_play setTitle:@"Continue" forState:UIControlStateNormal];
	
	[lvlMeter_in setAq: nil];
	btn_record.enabled = YES;
}

- (void)recordingQueueResumed:(NSNotification *)note
{
	//030311 set btn_play title to Pause
	btn_play.title = @"Pause";
	//[btn_play setTitle:@"Pause" forState:UIControlStateNormal];
	
	btn_record.enabled = YES;
	[lvlMeter_in setAq: recorder->Queue()];
	recordingWasPaused = NO; //020911 resume pause functionality to permit multiple pauses
}

#pragma mark Cleanup
- (void)dealloc
{
	[btn_record release];
	[btn_play release];
	[fileDescription release];
	[lvlMeter_in release];
	
	delete player;
	delete recorder;
	
	[super dealloc];
}

@end
