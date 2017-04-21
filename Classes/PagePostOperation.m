#import "PagePostOperation.h"
#import "zlib.h"

static NSString * const BOUNDRY = @"0xKhTmLbOuNdArY";
static NSString * const FORM_FLE_INPUT = @"userfile"; //target PHP needs userfile as file name

#define ASSERT(x) NSAssert(x, @"")
#define LOG(x,y)

@interface PagePostOperation (Private)

- (void)upload;
- (NSURLRequest *)postRequestWithURL: (NSURL *)url
                             boundry: (NSString *)boundry
                                data: (NSData *)data;
- (NSData *)compress: (NSData *)data;
- (void)uploadSucceeded: (BOOL)success;
- (void)connectionDidFinishLoading:(NSURLConnection *)connection;

@end


@implementation PagePostOperation

/*
 *-----------------------------------------------------------------------------
 *
 * -[Uploader initWithURL:filePath:delegate:doneSelector:errorSelector:] --
 *
 *      Initializer. Kicks off the upload. Note that upload will happen on a
 *      separate thread. Sanjay-moved actual upload step to operationDidStart
 *      QRunLoopOperation invokes QHttpOperation invokes PagePostOperation
 *      So, overriding the start and finish steps is done here
 *
 * Results:
 *      An instance of Uploader.
 *
 * Side effects:
 *      None
 *
 *-----------------------------------------------------------------------------
 */

- (id)initWithURL: (NSURL *)aServerURL   // IN
         filePath: (NSString *)aFilePath // IN
         delegate: (id)aDelegate         // IN
     doneSelector: (SEL)aDoneSelector    // IN
    errorSelector: (SEL)anErrorSelector  // IN
{
	if ((self = [super init])) {
		
		ASSERT(aServerURL);
		ASSERT(aFilePath);
		ASSERT(aDelegate);
		ASSERT(aDoneSelector);
		ASSERT(anErrorSelector);
		
		serverURL = [aServerURL retain];
		filePath = [aFilePath retain];
		delegate = [aDelegate retain];
		doneSelector = aDoneSelector;
		errorSelector = anErrorSelector;
		
		//Sanjay moved to operationDidStart below[self upload];
	}
	return self;
}

#pragma mark * Start and finish overrides

- (void)operationDidStart
// Called by QRunLoopOperation when the operation starts.  This kicks of an 
// asynchronous NSURLConnection.
{
	[self upload];
}

- (void)operationWillFinish
// Called by QRunLoopOperation when the operation has finished.  We 
// do various bits of tidying up.
{
	[self dealloc];
}


/*
 *-----------------------------------------------------------------------------
 *
 * -[Uploader dealloc] --
 *
 *      Destructor.
 *
 * Results:
 *      None
 *
 * Side effects:
 *      None
 *
 *-----------------------------------------------------------------------------
 */

- (void)dealloc
{
	[serverURL release];
	serverURL = nil;
	[filePath release];
	filePath = nil;
	[delegate release];
	delegate = nil;
	doneSelector = NULL;
	errorSelector = NULL;
	
	//Sanjay below works only for PageGetOperation
	//[super dealloc];
}


/*
 *-----------------------------------------------------------------------------
 *
 * -[Uploader filePath] --
 *
 *      Gets the path of the file this object is uploading.
 *
 * Results:
 *      Path to the upload file.
 *
 * Side effects:
 *      None
 *
 *-----------------------------------------------------------------------------
 */

- (NSString *)filePath
{
	return filePath;
}


@end // Uploader


@implementation PagePostOperation (Private)


/*
 *-----------------------------------------------------------------------------
 *
 * -[Uploader(Private) upload] --
 *
 *      Uploads the given file. The file is compressed before beign uploaded.
 *      The data is uploaded using an HTTP POST command.
 *
 * Results:
 *      None
 *
 * Side effects:
 *      None
 *
 *-----------------------------------------------------------------------------
 */

- (void)upload
{
	
	NSData *data = [NSData dataWithContentsOfFile:filePath];
	//ASSERT(data);
 	if (!data) {
		[self uploadSucceeded:NO];
		return;
	}
	if ([data length] == 0) {
		// There's no data, treat this the same as no file.
		[self uploadSucceeded:YES];
		return;
	}
	
	NSData *compressedData = data; //Sanjay dont compress [self compress:data];
	//ASSERT(compressedData && [compressedData length] != 0);
	if (!compressedData || [compressedData length] == 0) {
		[self uploadSucceeded:NO];
		return;
	}
	
	NSURLRequest *urlRequest = [self postRequestWithURL:serverURL
												boundry:BOUNDRY
												   data:compressedData];
	if (!urlRequest) {
		[self uploadSucceeded:NO];
		return;
	}
	
	//Sanjay original code alloced a connection; we use the enclosing connection inherited from
	//QHTTPOpertion
	NSURLConnection * connection = [[NSURLConnection alloc] initWithRequest:urlRequest delegate:self];
	if (!connection) {
		[self uploadSucceeded:NO];
	}
	else {
		//Sanjay aded this to override assert in parent QHTTPOperation; 
		self->_connection = connection;
	}
	
	// Now wait for the URL connection to call us back.
}


/*
 *-----------------------------------------------------------------------------
 *
 * -[Uploader(Private) postRequestWithURL:boundry:data:] --
 *
 *      Creates a HTML POST request.
 *
 * Results:
 *      The HTML POST request.
 *
 * Side effects:
 *      None
 *
 *-----------------------------------------------------------------------------
 */

- (NSURLRequest *)postRequestWithURL: (NSURL *)url        // IN
                             boundry: (NSString *)boundry // IN
                                data: (NSData *)data      // IN
{
	// from http://www.cocoadev.com/index.pl?HTTPFileUpload
	NSMutableURLRequest *urlRequest =
	[NSMutableURLRequest requestWithURL:url];
	[urlRequest setHTTPMethod:@"POST"];
	[urlRequest setValue:
	 [NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundry]
      forHTTPHeaderField:@"Content-Type"];
	
	NSMutableData *postData =
	[NSMutableData dataWithCapacity:[data length] + 512];
	[postData appendData:
	 [[NSString stringWithFormat:@"--%@\r\n", boundry] dataUsingEncoding:NSUTF8StringEncoding]];
	
	//Sanjay extract filename from filePath and use in upload below
	NSString * fileName = [filePath lastPathComponent];
	//fprintf(stdout, "In PagePostOperation filename=%s\n", [[fileName  absoluteString] UTF8String]);
	
	[postData appendData:
	 [[NSString stringWithFormat:
	   @"Content-Disposition: form-data; name=\"%@\"; filename=\"%@\"\r\n\r\n", FORM_FLE_INPUT, fileName]
	  dataUsingEncoding:NSUTF8StringEncoding]];
	[postData appendData:data];
	[postData appendData:
	 [[NSString stringWithFormat:@"\r\n--%@--\r\n", boundry] dataUsingEncoding:NSUTF8StringEncoding]];
	
	[urlRequest setHTTPBody:postData];
	return urlRequest;
}

/*
 *-----------------------------------------------------------------------------
 *
 * -[Uploader(Private) compress:] --
 *
 *      Uses zlib to compress the given data.
 *
 * Results:
 *      The compressed data as a NSData object.
 *
 * Side effects:
 *      None
 *
 *-----------------------------------------------------------------------------
 */

- (NSData *)compress: (NSData *)data // IN
{
	if (!data || [data length] == 0)
		return nil;
	
	// zlib compress doc says destSize must be 1% + 12 bytes greater than source.
	uLong destSize = [data length] * 1.001 + 12;
	NSMutableData *destData = [NSMutableData dataWithLength:destSize];
	
	int error = compress([destData mutableBytes],
						 &destSize,
						 [data bytes],
						 [data length]);
	if (error != Z_OK) {
		LOG(0, ("%s: self:0x%p, zlib error on compress:%d\n",
				__func__, self, error));
		return nil;
	}
	
	[destData setLength:destSize];
	return destData;
}


/*
 *-----------------------------------------------------------------------------
 *
 * -[Uploader(Private) uploadSucceeded:] --
 *
 *      Used to notify the delegate that the upload did or did not succeed.
 *
 * Results:
 *      None
 *
 * Side effects:
 *      None
 *
 *-----------------------------------------------------------------------------
 */

- (void)uploadSucceeded: (BOOL)success // IN
{
	[delegate performSelector:success ? doneSelector : errorSelector
				   withObject:self];
	
	//Sanjay operationWillFinish is not being invoked; do local cleanup here
	//[self dealloc];
}


/*
 *-----------------------------------------------------------------------------
 *
 * -[Uploader(Private) connectionDidFinishLoading:] --
 *
 *      Called when the upload is complete. We judge the success of the upload
 *      based on the reply we get from the server.
 *
 * Results:
 *      None
 *
 * Side effects:
 *      None
 *
 *-----------------------------------------------------------------------------
 */

- (void)connectionDidFinishLoading:(NSURLConnection *)connection // IN
{
	LOG(6, ("%s: self:0x%p\n", __func__, self));
	[connection release];
	[self uploadSucceeded:uploadDidSucceed];
}


/*
 *-----------------------------------------------------------------------------
 *
 * -[Uploader(Private) connection:didFailWithError:] --
 *
 *      Called when the upload failed (probably due to a lack of network
 *      connection).
 *
 * Results:
 *      None
 *
 * Side effects:
 *      None
 *
 *-----------------------------------------------------------------------------
 */

- (void)connection:(NSURLConnection *)connection // IN
  didFailWithError:(NSError *)error              // IN
{
	LOG(1, ("%s: self:0x%p, connection error:%s\n",
			__func__, self, [[error description] UTF8String]));
	[connection release];
	[self uploadSucceeded:NO];
}


/*
 *-----------------------------------------------------------------------------
 *
 * -[Uploader(Private) connection:didReceiveResponse:] --
 *
 *      Called as we get responses from the server.
 *
 * Results:
 *      None
 *
 * Side effects:
 *      None
 *
 *-----------------------------------------------------------------------------
 */

-(void)       connection:(NSURLConnection *)connection // IN
      didReceiveResponse:(NSURLResponse *)response     // IN
{
	LOG(6, ("%s: self:0x%p\n", __func__, self));
}


/*
 *-----------------------------------------------------------------------------
 *
 * -[Uploader(Private) connection:didReceiveData:] --
 *
 *      Called when we have data from the server. We expect the server to reply
 *      with a "YES" if the upload succeeded or "NO" if it did not.
 *
 * Results:
 *      None
 *
 * Side effects:
 *      None
 *
 *-----------------------------------------------------------------------------
 */

- (void)connection:(NSURLConnection *)connection // IN
    didReceiveData:(NSData *)data                // IN
{
	LOG(10, ("%s: self:0x%p\n", __func__, self));
	
	NSString *reply = [[[NSString alloc] initWithData:data
											 encoding:NSUTF8StringEncoding]
					   autorelease];
	LOG(10, ("%s: data: %s\n", __func__, [reply UTF8String]));
	
	//If response has the word upload in it, then its ok
	if ([reply hasPrefix:@"{upload"]) {
		uploadDidSucceed = YES;
	}
}


@end