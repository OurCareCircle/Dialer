
#import "XmitMain.h"

#import "PageGetOperation.h"
#import "PagePostOperation.h"

@interface XmitMain ()

// Read/write versions of public properties

@property (nonatomic, copy,   readwrite) NSError *                  error;

// Internal properties

@property (nonatomic, retain, readonly ) QWatchedOperationQueue *   queue;
@property (nonatomic, assign, readwrite) NSUInteger                 runningOperationCount;

// Forward declarations

- (void)startPageGet:(NSURL *)pageURL;
- (void)startPagePost:(NSURL *)pageURL  fname:(NSString *)fileName;

@end

@implementation XmitMain

- (id)init
// See comment in header.
{
	//Do all one time setup for all network ops here
	self = [super init];
    return self;
}

@synthesize URL      = _URL;
@synthesize xmitop   = _xmitop;
@synthesize fileName = _fileName;
@synthesize delegate = _delegate;
NSAutoreleasePool *pool;

- (id)initWithURL:(NSURL *)url xmitop:(NSString *)xmitop fileName:(NSString *)fileName
// See comment in header.
{
    assert(url != nil);
    assert([[[url scheme] lowercaseString] isEqual:@"http"] || [[[url scheme] lowercaseString] isEqual:@"https"]);
;
	
    if (self != nil) {
        self->_URL      = [url      copy];
		self->_xmitop   = [xmitop   copy];
		self->_fileName = [fileName copy];
		
		//setup pool for all autorelease vars; this pool will be dealloced on thread exit
		pool = [[NSAutoreleasePool alloc] init];
    }
    return self;
}

- (void)dealloc
{
    [self->_queue invalidate];
    [self->_queue cancelAllOperations];
    [self->_queue release];
    [self->_error release];
    [self->_URL release];
	[self->_xmitop release];
	[self->_fileName release];
    [super dealloc];
	[self release];
}


- (QWatchedOperationQueue *)queue
{
    if (self->_queue == nil) {
        self->_queue = [[QWatchedOperationQueue alloc] initWithTarget:self];
        assert(self->_queue != nil);
    }
    return self->_queue;
}


//021011 use a singleton queue for all http operations;throws error DO NOT USE YET
/*
static QWatchedOperationQueue *myQueue;
+ (QWatchedOperationQueue *)queue
{
    if (myQueue == nil) {
        myQueue = [[QWatchedOperationQueue alloc] initWithTarget:self];
        assert(myQueue != nil);
    }
	[myQueue retain];
    return myQueue;
}

- (QWatchedOperationQueue *)queue
{
    return [XmitMain queue];
}
*/

@synthesize done = _done;


- (BOOL)start
// See comment in header.
{	
	NSString * OP = @"GET";
	BOOL match = ([self->_xmitop compare:OP] == NSOrderedSame);
	
    // Start the main GET/POST operation, that gets the URL of interest    
    if (match) {
        [self startPageGet:self.URL];
    }
	else {
		[self startPagePost:self.URL fileName:self.fileName];
	}
    
    return true;
}

@synthesize error = _error;

- (void)stopWithError:(NSError *)error
// An internal method called to stop the fetch and clean things up.
{
    assert(error != nil);
    [self.queue invalidate];
    [self.queue cancelAllOperations];
    self.error = error;
    self.done = YES;
}

- (void)stop
// See comment in header.
{
    [self stopWithError:[NSError errorWithDomain:NSCocoaErrorDomain code:NSUserCancelledError userInfo:nil]];
}

- (void)logText:(NSString *)text URL:(NSURL *)url error:(NSError *)error
// An internal method called to log information about the fetch. 
// This logs to stdout.
{
    assert(text != nil);
    assert(url != nil);
    // error may be nil
    
	// Log to stdout
	if (error == nil) {
		//fprintf(stdout, "%s filename=%s\n", [[url absoluteString] UTF8String], [[self.fileName  absoluteString] UTF8String]);
		//fprintf(stdout, "%s\n", [text UTF8String]);
	} else {
		//fprintf(stdout, "%s filename=%s\n", [[url absoluteString] UTF8String], [[self.fileName  absoluteString] UTF8String]);
		//fprintf(stdout, "%s: %s %d\n", [text UTF8String], [[error domain] UTF8String], (int) [error code]);
	}
}

// IMPORTANT: runningOperationCount is only ever modified by the main thread, 
// so we don't have to do any locking.  Also, because the 'done' methods are called 
// on the main thread, we don't have to worry about early completion, that is, 
// -parseDone: kicking off download 1, then getting delayed, then download 1 
// completing, decrementing runningOperationCount, and deciding that we're 
// all done.  The decrement of runningOperationCount is done by -downloadDone: 
// and -downloadDone: can't run until we return back to the run loop.

@synthesize runningOperationCount = _runningOperationCount;

- (void)operationDidStart
// Called when an operation has started to increment runningOperationCount. 
{
    self.runningOperationCount += 1;
}

- (void)operationDidFinish
// Called when an operation has finished to decrement runningOperationCount 
// and complete the whole fetch if it hits zero.
{
    assert(self.runningOperationCount != 0);
    self.runningOperationCount -= 1;
    if (self.runningOperationCount == 0) {
        self.done = YES;
    } 

}

- (void)startPageGet:(NSURL *)pageURL
// Starts the operation to GET an HTML page.  
{
    PageGetOperation *  op;
    
    assert([pageURL baseURL] == nil);       // must be an absolute URL      
    op = [[[PageGetOperation alloc] initWithURL:pageURL] autorelease];
    assert(op != nil);
    
	//012511 Before any GET op is done, ensure all POSTs are completed
	[self.queue waitUntilAllOperationsAreFinished];
	
    [self.queue addOperation:op finishedAction:@selector(pageGetDone:)];
    [self operationDidStart];
    
    // ... continues in -pageGetDone:
}

- (void)pageGetDone:(PageGetOperation *)op
// Called when the GET for an HTML page is done. 
{
    assert([op isKindOfClass:[PageGetOperation class]]);
    assert([NSThread isMainThread]);
    
    if (op.error != nil) {		
        // An error getting any  page is just logged.
		[self logText:@"page get error" URL:op.URL error:op.error];		
    } else {		
        [self logText:@"page get done" URL:op.URL error:nil];
		//op.responseBody  has the data from v2b server. Use the delegate to invoke callback
		if ([self.delegate respondsToSelector:@selector(httpGetCallback:op:)]) {
			[self.delegate httpGetCallback:self op:op];
		}    		        
    }
    
    [self operationDidFinish];
}


- (void)startPagePost:(NSURL *)pageURL fileName:(NSString *)fileName
// Starts the operation to do a POST.  
{
    PagePostOperation *  op;
    
    assert([pageURL baseURL] == nil);       // must be an absolute URL      
    op = [[[PagePostOperation alloc] initWithURL:pageURL
												filePath:fileName
												delegate:self
												doneSelector:@selector(pagePostDone:)
												errorSelector:@selector(pagePostDone:)] autorelease];
    assert(op != nil);
    
    [self.queue addOperation:op finishedAction:@selector(pagePostDone:)];
    [self operationDidStart];
    
    // ... continues in -pagePostDone:
}

- (void)pagePostDone:(PagePostOperation *)op
// Called when the POST of a file is done. 
{
    assert([op isKindOfClass:[PagePostOperation class]]);
    assert([NSThread isMainThread]);
		
	[self logText:@"page post done" URL:(PagePostOperation *)op->serverURL error:nil];   		        
	[self operationDidFinish];
}


@end
