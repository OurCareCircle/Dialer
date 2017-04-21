
#import "QHTTPOperation.h"

@interface PageGetOperation : QHTTPOperation
{
}

- (id)initWithURL:(NSURL *)url;
    // Initialises the operation to download HTML at the specified URL.

@end
