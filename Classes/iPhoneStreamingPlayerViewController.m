//
//  iPhoneStreamingPlayerViewController.m
//  iPhoneStreamingPlayer
//
//  Created by Matt Gallagher on 28/10/08.
//  Copyright Matt Gallagher 2008. All rights reserved.
//
//  Permission is given to use this source code file, free of charge, in any
//  project, commercial or otherwise, entirely at your risk, with the condition
//  that any redistribution (in part or whole) of source code must retain
//  this copyright and permission notice. Attribution in compiled projects is
//  appreciated but not required.
//

#import "iPhoneStreamingPlayerViewController.h"
#import "AudioStreamer.h"
#import <QuartzCore/CoreAnimation.h>
#import <MediaPlayer/MediaPlayer.h>
#import <CFNetwork/CFNetwork.h>

@implementation iPhoneStreamingPlayerViewController

@synthesize  isPlaying;
@synthesize  cell;

//
// setButtonImage:
//
// Used to change the image on the playbutton. This method exists for
// the purpose of inter-thread invocation because
// the observeValueForKeyPath:ofObject:change:context: method is invoked
// from secondary threads and UI updates are only permitted on the main thread.
//
// Parameters:
//    image - the image to set on the play button.
//
- (void)setButtonImage:(UIImage *)image
{
	[button.layer removeAllAnimations];
	if (!image)
	{
		[button setImage:[UIImage imageNamed:@"play.png"] forState:0];
	}
	else
	{
		[button setImage:image forState:0];
		
		//030311 spin iff streamer is waiting
		if ([streamer isWaiting]) //(!isPlaying)
		{
			[self spinButton];
		}
	}
}

@synthesize downloadSourceField;
@synthesize button;
@synthesize volumeSlider;
@synthesize positionLabel;
@synthesize progressSlider;

//
// destroyStreamer
//
// Removes the streamer, the UI update timer and the change notification
//
- (void)destroyStreamer
{
	if (streamer)
	{
		[[NSNotificationCenter defaultCenter]
			removeObserver:self
			name:ASStatusChangedNotification
			object:streamer];
		[progressUpdateTimer invalidate];
		progressUpdateTimer = nil;
		
		[streamer stop];
		[streamer release];
		streamer = nil;
	}
}

//
// createStreamer
//
// Creates or recreates the AudioStreamer object.
//
- (void)createStreamer
{
    NSString *escapedValue =
    [(NSString *)CFURLCreateStringByAddingPercentEscapes(
                                                         nil,
                                                         (CFStringRef)downloadSourceField.text,
                                                         NULL,
                                                         NULL,
                                                         kCFStringEncodingUTF8)
     autorelease];
	NSURL *url          = [NSURL URLWithString:escapedValue];
    
    //032112 DUDE-this should be done every time a new url is streamed
	//if (streamer)
    if ([urlCurrentlyPlaying isEqual:url])
	{
        //no change in url; no need for new streamer
		return;
	}

	[self destroyStreamer];
	

	streamer            = [[AudioStreamer alloc] initWithURL:url];
    urlCurrentlyPlaying = [url copy];
	
	progressUpdateTimer =
		[NSTimer
			scheduledTimerWithTimeInterval:0.1
			target:self
			selector:@selector(updateProgress:)
			userInfo:nil
			repeats:YES];
	[[NSNotificationCenter defaultCenter]
		addObserver:self
		selector:@selector(playbackStateChanged:)
		name:ASStatusChangedNotification
		object:streamer];
}

//
// viewDidLoad
//
// Creates the volume slider, sets the default path for the local file and
// creates the streamer immediately if we already have a file at the local
// location.
//
- (void)viewDidLoad
{
	[super viewDidLoad];
	
	MPVolumeView *volumeView = [[[MPVolumeView alloc] initWithFrame:volumeSlider.bounds] autorelease];
	[volumeSlider addSubview:volumeView];
	[volumeView sizeToFit];
	
	[self setButtonImage:[UIImage imageNamed:@"play.png"]];
}

// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView {
	//[self viewDidLoad ];
}

//
// spinButton
//
// Shows the spin button when the audio is loading. This is largely irrelevant
// now that the audio is loaded from a local file.
//
- (void)spinButton
{
	[CATransaction begin];
	[CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
	CGRect frame = [button frame];
	button.layer.anchorPoint = CGPointMake(0.5, 0.5);
	button.layer.position = CGPointMake(frame.origin.x + 0.5 * frame.size.width, frame.origin.y + 0.5 * frame.size.height);
	[CATransaction commit];

	[CATransaction begin];
	[CATransaction setValue:(id)kCFBooleanFalse forKey:kCATransactionDisableActions];
	[CATransaction setValue:[NSNumber numberWithFloat:2.0] forKey:kCATransactionAnimationDuration];

	CABasicAnimation *animation;
	animation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
	animation.fromValue = [NSNumber numberWithFloat:0.0];
	animation.toValue = [NSNumber numberWithFloat:2 * M_PI];
	animation.timingFunction = [CAMediaTimingFunction functionWithName: kCAMediaTimingFunctionLinear];
	animation.delegate = self;
	[button.layer addAnimation:animation forKey:@"rotationAnimation"];

	[CATransaction commit];
}

//
// animationDidStop:finished:
//
// Restarts the spin animation on the button when it ends. Again, this is
// largely irrelevant now that the audio is loaded from a local file.
//
// Parameters:
//    theAnimation - the animation that rotated the button.
//    finished - is the animation finised?
//
- (void)animationDidStop:(CAAnimation *)theAnimation finished:(BOOL)finished
{
	if (finished)
	{
		[self spinButton];
	}
}

//
// buttonPressed:
//
// Handles the play/stop button. Creates, observes and starts the
// audio streamer when it is a play button. Stops the audio streamer when
// it isn't.
//
// Parameters:
//    sender - normally, the play/stop button.
//
- (IBAction)buttonPressed:(id)sender
{
	if (isPlaying)
	{
		UITextField *dwnld = self.downloadSourceField;
		[dwnld resignFirstResponder];
		
		[self createStreamer];
		[self setButtonImage:[UIImage imageNamed:@"pause.png"]];
		[streamer pause]; //on 020511 changed from start to pause 
	}
	else
	{
		//020511  changed below to pause from stop
		[streamer pause];
	}
}

//
// sliderMoved:
//
// Invoked when the user moves the slider
//
// Parameters:
//    aSlider - the slider (assumed to be the progress slider)
//
- (IBAction)sliderMoved:(UISlider *)aSlider
{
	if (streamer.duration)
	{
		double newSeekTime = (aSlider.value / 100.0) * streamer.duration;
		[streamer seekToTime:newSeekTime];
	}
}

//
// playbackStateChanged:
//
// Invoked when the AudioStreamer
// reports that its playback status has changed.
//
- (void)playbackStateChanged:(NSNotification *)aNotification
{
	if ([streamer isWaiting])
	{
		//013011 changed from pause.png to play.png; to handle end-of-stream notifications
		//that show up as isWaiting events
		cell.image = [UIImage imageNamed:@"loading.png"];
		isPlaying = TRUE;
		//030311 the method below actually changes the image of the button
		[self setButtonImage:[UIImage imageNamed:@"loading.png"]];
	}
	else if ([streamer isPlaying])
	{
		cell.image = [UIImage imageNamed:@"pause.png"];
		isPlaying = TRUE;
		//030311 the method below actually changes the image of the button
		[self setButtonImage:[UIImage imageNamed:@"pause.png"]];
	}
	else if ([streamer isIdle])
	{
		cell.image = [UIImage imageNamed:@"play.png"];
		isPlaying = FALSE;
		//030311 the method below actually changes the image of the button
		[self setButtonImage:[UIImage imageNamed:@"play.png"]];
		[self destroyStreamer];
	}
}

//
// updateProgress:
//
// Invoked when the AudioStreamer
// reports that its playback progress has changed.
//
- (void)updateProgress:(NSTimer *)updatedTimer
{
	if (streamer.bitRate != 0.0)
	{
		double progress = streamer.progress;
		double duration = streamer.duration;
		
		if (duration > 0)
		{
			UILabel *pos = [self positionLabel];
			[pos setText:
				[NSString stringWithFormat:@"%.1f/%.1f sec",
					progress,
					duration]];
			UISlider *slider = [self progressSlider];
			[slider setEnabled:YES];
			[slider setValue:100 * progress / duration];
			[cell setNeedsLayout]; //update row in table
		}
		else
		{
			UISlider *slider = [self progressSlider];
			[slider setEnabled:NO];
		}
	}
	else
	{
		positionLabel.text = @"0.0/0.0 sec";
	}
}

//
// textFieldShouldReturn:
//
// Dismiss the text field when done is pressed
//
// Parameters:
//    sender - the text field
//
// returns YES
//
- (BOOL)textFieldShouldReturn:(UITextField *)sender
{
	[sender resignFirstResponder];
	[self createStreamer];
	return YES;
}

//
// dealloc
//
// Releases instance memory.
//
- (void)dealloc
{
	[self destroyStreamer];
	if (progressUpdateTimer)
	{
		[progressUpdateTimer invalidate];
		progressUpdateTimer = nil;
	}
	[super dealloc];
}

//The AudioSession is a singleton. Wht is setup for the streaming player is not
//compatible with the streaming recorder. So, we ensure it is made inactive when
//not needed
- (void) clearState {
	//clear up streamer state before quitting current view
	[streamer clearState];
}

@end
