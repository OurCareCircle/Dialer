
#import <Foundation/Foundation.h>

#import "QWatchedOperationQueue.h"
#import "PageGetOperation.h"

@protocol XmitMainCallerDelegate;

@interface XmitMain : NSObject
{
    NSURL *                         _URL;
    QWatchedOperationQueue *        _queue;
	id<XmitMainCallerDelegate>      _delegate;
    BOOL                            _done;
    NSError *                       _error;
    NSUInteger                      _runningOperationCount;
}

- (id)init;
// Initializes the object and does all setup

- (id)initWithURL:(NSURL *)url xmitop:(NSString *)xmitop fileName:(NSString *)fileName;
// Initialises the object to do network i/o using the input url. The type of op is determined
//by xmitop. The fileName is optional and used for POST ops only


// Things you can change before calling -start.
@property (nonatomic, assign, readwrite) NSURL *        URL;
@property (nonatomic, assign, readwrite) NSString *     xmitop;
@property (nonatomic, copy,   readwrite) NSString *     fileName;
@property (nonatomic, assign, readwrite) id<XmitMainCallerDelegate> delegate;

// Things that are meaningful after you've called -start.

@property (nonatomic, assign, readwrite) BOOL           done;               // observable
@property (nonatomic, copy,   readonly ) NSError *      error;              // nil if no error

// Methods to start and stop the fetch.  Note that this is a one-shot thing; 
// you can't call -stop and then call -start again.

- (BOOL)start;
- (void)stop;

@end

@protocol XmitMainCallerDelegate <NSObject>

@optional

- (void)httpGetCallback:(XmitMain *)fetcher op:(PageGetOperation *)op;
// When XmitMain is invoked for a GET op, it calls this routine.
//Both for good results and also for errors.

@end


