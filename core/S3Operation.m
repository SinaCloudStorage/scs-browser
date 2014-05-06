//
//  S3Operation.m
//  S3-Objc
//
//  Created by Bruce Chen on 4/1/06.
//  Modernized by Martin Hering on 07/14/12
//  Copyright 2014 Bruce Chen. All rights reserved.
//

#import "S3Operation.h"

#import "S3Bucket.h"
#import "S3ConnectionInfo.h"
#import "S3PersistentCFReadStreamPool.h"
#import "S3HTTPUrlBuilder.h"
#import "S3TransferRateCalculator.h"


@interface S3Operation ()

- (void)handleNetworkEvent:(CFStreamEventType)eventType;

@property (nonatomic) S3TransferRateCalculator *rateCalculator;

@end

@interface S3Operation () <S3TransferRateCalculatorDelegate, S3HTTPUrlBuilderDelegate>
@property(readwrite, nonatomic, copy) S3ConnectionInfo *connectionInfo;
@property(readwrite, nonatomic, copy) NSDictionary *operationInfo;

@property(readwrite, nonatomic, assign) BOOL allowsRetry;

@property(readwrite, nonatomic, assign) S3OperationState state;
@property(readwrite, nonatomic, copy) NSString *informationalStatus;
@property(readwrite, nonatomic, copy) NSString *informationalSubStatus;

@property(readwrite, nonatomic, copy) NSDictionary *requestHeaders;

@property(readwrite, nonatomic, copy) NSCalendarDate *date;
@property(readwrite, nonatomic, copy) NSDictionary *responseHeaders;
@property(readwrite, nonatomic, copy) NSNumber *responseStatusCode;
@property(readwrite, nonatomic, copy) NSData *responseData;
@property(readwrite, nonatomic, strong) NSFileHandle *responseFileHandle;
@property(readwrite, nonatomic, copy) NSError *error;
@property(readwrite, nonatomic, assign) NSInteger queuePosition;

@end

#pragma mark -

#pragma mark Constants & Globals
static const CFOptionFlags S3OperationNetworkEvents =   kCFStreamEventOpenCompleted |
                                                        kCFStreamEventHasBytesAvailable |
                                                        kCFStreamEventEndEncountered |
                                                        kCFStreamEventErrorOccurred;

#pragma mark -

#pragma mark Static Functions
static void
ReadStreamClientCallBack(CFReadStreamRef stream, CFStreamEventType type, void *clientCallBackInfo) {
    // Pass off to the object to handle
    [((__bridge S3Operation *)clientCallBackInfo) handleNetworkEvent:type];
}

//static void *myRetainCallback(void *info) {
//    return (void *)[(__bridge NSObject *)info retain];
//}
//
//static void myReleaseCallback(void *info) {
//    [(__bridge NSObject *)info release];
//}


#pragma mark -

@implementation S3Operation {
    CFReadStreamRef httpOperationReadStream;
}


+ (BOOL)accessInstanceVariablesDirectly
{
    return NO;
}

+ (NSSet *)keyPathsForValuesAffectingValueForKey:(NSString *)key
{
    if ([key isEqual:@"active"]) {
        return [NSSet setWithObject:@"state"];
    }
    
    return nil;
}

- (id)initWithConnectionInfo:(S3ConnectionInfo *)aConnectionInfo operationInfo:(NSDictionary *)anOperationInfo
{
    self = [super init];
    
    if (self != nil) {
        if (aConnectionInfo == nil) {
            return nil;
        }
        
        _connectionInfo = aConnectionInfo;
        _operationInfo = anOperationInfo;

        [self addObserver:self forKeyPath:@"informationalStatus" options:0 context:NULL];
        [self addObserver:self forKeyPath:@"informationalSubStatus" options:0 context:NULL];
    }
    
    return self;    
}

- (id)initWithConnectionInfo:(S3ConnectionInfo *)aConnectionInfo
{
    return [self initWithConnectionInfo:aConnectionInfo operationInfo:nil];
}

- (void)dealloc
{
    [self removeObserver:self forKeyPath:@"informationalStatus"];
    [self removeObserver:self forKeyPath:@"informationalSubStatus"];
    
    if (httpOperationReadStream != NULL) {
        CFRelease(httpOperationReadStream);
        httpOperationReadStream = NULL;
    }

}

- (void)setState:(S3OperationState)state
{
    if (_state != state) {
        _state = state;
        
        [self.delegate operationStateDidChange:self];
        
        switch (state) {
            case S3OperationPending:
                self.informationalStatus = @"Pending";
                self.informationalSubStatus = nil;
                break;
            case S3OperationActive:
                self.informationalStatus = @"Active";
                self.informationalSubStatus = nil;
                break;
            case S3OperationPendingRetry:
                self.informationalStatus = @"Pending Retry";
                self.informationalSubStatus = nil;
                break;
            case S3OperationError:
                self.informationalStatus = @"Error";
                self.informationalSubStatus = nil;
                break;
            case S3OperationRequiresVirtualHostingEnabled:
                self.informationalStatus = @"Error";
                self.informationalSubStatus = @"Virtual Hosting Required";
                break;
            case S3OperationCanceled:
                self.informationalStatus = @"Canceled";
                self.informationalSubStatus = nil;
                break;
            case S3OperationDone:
                self.informationalStatus = @"Done";
                self.informationalSubStatus = nil;
                break;
            case S3OperationRequiresRedirect:
                self.informationalStatus = @"Done";
                self.informationalSubStatus = @"Redirect Required";
                break;
            default:
                break;
        }
        
        [self.delegate operationInformationalStatusDidChange:self];
        [self.delegate operationInformationalSubStatusDidChange:self];
    }
}

- (void)updateInformationalStatus
{
    
}

- (void)updateInformationalSubStatus
{
    NSMutableString *subStatus = [NSMutableString string];
    NSString *s = [self.rateCalculator stringForObjectivePercentageCompleted];
    if (s != nil) {
        [subStatus appendFormat:@"%@%% ",s];        
    }
    
    s = [self.rateCalculator stringForCalculatedTransferRate];
    if (s != nil) {
        [subStatus appendFormat:@"(%@ %@/%@) ", s, [self.rateCalculator stringForShortDisplayUnit], [self.rateCalculator stringForShortRateUnit]];
    }
    
    s = [self.rateCalculator stringForEstimatedTimeRemaining];
    if (s != nil) {
        [subStatus appendString:s];        
    }
    [self setInformationalSubStatus:subStatus];
}

- (BOOL)active
{
    return ([self state] == S3OperationActive);
}

-(BOOL)success
{
    // TODO: Correct implementation
	return TRUE;
}

- (BOOL)isRequestOnService
{
    return (([self bucketName] == nil) && ([self key] == nil));
}

#pragma mark -
#pragma mark S3HTTPUrlBuilder Delegate Methods

- (NSString *)httpUrlBuilderWantsProtocolScheme:(S3HTTPURLBuilder *)httpUrlBuilder
{
    return [self protocolScheme];
}

- (NSUInteger)httpUrlBuilderWantsPort:(S3HTTPURLBuilder *)httpUrlBuilder
{
    return [self portNumber];
}

- (NSString *)httpUrlBuilderWantsHost:(S3HTTPURLBuilder *)httpUrlBuilder
{
    return [self host];
}

- (NSString *)httpUrlBuilderWantsKey:(S3HTTPURLBuilder *)httpUrlBuilder
{
    return [self operationKey];
}

- (NSDictionary *)httpUrlBuilderWantsQueryItems:(S3HTTPURLBuilder *)httpUrlBuilder
{
    return [self requestQueryItems];
}

#pragma mark -
#pragma mark S3Operation Information Retrieval Methods

- (NSString *)protocolScheme
{
    if ([[self connectionInfo] secureConnection]) {
        return @"https";
    }
    return @"http";
}

- (NSUInteger)portNumber
{
    return [[self connectionInfo] portNumber];
}

- (NSString *)host
{
    if ([self isRequestOnService] == NO && [[self connectionInfo] virtuallyHosted] && [self virtuallyHostedCapable] && [self bucketName] != nil) {
        NSString *hostName = [NSString stringWithFormat:@"%@.%@", [self bucketName], [[self connectionInfo] hostEndpoint]];
        return hostName;
    }
    return [[self connectionInfo] hostEndpoint];
}

- (NSString *)operationKey
{
    if ([self isRequestOnService] == NO && (([[self connectionInfo] virtuallyHosted] == NO) || ([self virtuallyHostedCapable] == NO)) && [self bucketName] != nil) {
        NSString *keyString = nil;
        if ([self key] != nil) {
            keyString = [NSString stringWithFormat:@"%@/%@", [self bucketName], [self key]];
        } else {
            keyString = [NSString stringWithFormat:@"%@/", [self bucketName]];
        }
        return keyString;
    }
    return [self key];
}

- (NSDictionary *)queryItems
{
    return nil;
}

- (NSString *)requestHTTPVerb
{
    return nil;
}

- (NSDictionary *)additionalHTTPRequestHeaders
{
    return nil;
}

- (BOOL)virtuallyHostedCapable
{
	return true;
}

- (NSString *)bucketName
{
    return nil;
}

- (NSString *)key
{
    return nil;
}

- (NSDictionary *)requestQueryItems
{
    return nil;
}

- (NSData *)requestBodyContentData
{
    return nil;
}

- (NSString *)requestBodyContentFilePath
{
    return nil;
}

- (NSString *)requestBodyContentMD5
{
    return nil;
}

- (NSString *)requestBodyContentType
{
    return nil;
}

- (NSUInteger)requestBodyContentLength
{
    return 0;
}

- (NSString *)responseBodyContentFilePath
{
    return nil;
}

- (long long)responseBodyContentExepctedLength
{
    return 0;
}

#pragma mark -

- (NSURL *)url
{    
    // Make Request String
    S3HTTPURLBuilder *urlBuilder = [[S3HTTPURLBuilder alloc] initWithDelegate:self];
    NSURL *builtURL = [urlBuilder url];

    return builtURL;
}

- (void)_stop:(id)sender
{	
    if ([self state] >= S3OperationCanceled || !(httpOperationReadStream)) {
        return;
    }
    
	NSDictionary *d = @{NSLocalizedDescriptionKey: @"This operation has been cancelled"};
	[self setError:[NSError errorWithDomain:S3_ERROR_DOMAIN code:-1 userInfo:d]];
    
    CFReadStreamSetClient(httpOperationReadStream, 0, NULL, NULL);
    CFReadStreamUnscheduleFromRunLoop(httpOperationReadStream, CFRunLoopGetMain(), kCFRunLoopCommonModes);
    S3PersistentCFReadStreamPool *sharedPool = [S3PersistentCFReadStreamPool sharedPersistentCFReadStreamPool];
    [sharedPool removeOpenedPersistentCFReadStream:httpOperationReadStream];
    CFRelease(httpOperationReadStream);
    httpOperationReadStream = NULL;
    
    // Close filestream if available.
    [[self responseFileHandle] closeFile];
    [self setResponseFileHandle:nil];
    
    [self setState:S3OperationCanceled];
    
    [self.rateCalculator stopTransferRateCalculator];
}

- (void)stop:(id)sender {
    
    [self performSelector:@selector(_stop:) onThread:[[self class] threadForRequest:self] withObject:sender waitUntilDone:NO];
}

- (void)start:(id)sender {

    [self performSelector:@selector(main:) onThread:[[self class] threadForRequest:self] withObject:sender waitUntilDone:NO];
}

- (void)main:(id)sender
{
    if ([self responseBodyContentFilePath] != nil) {
        
        NSFileHandle *fileHandle = nil;
        BOOL fileCreated = [[NSFileManager defaultManager] createFileAtPath:[self responseBodyContentFilePath] contents:nil attributes:nil];
        
        if (fileCreated) {
            fileHandle = [NSFileHandle fileHandleForUpdatingAtPath:[self responseBodyContentFilePath]];
        } else {
            BOOL isDirectory = NO;
            BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:[self responseBodyContentFilePath] isDirectory:&isDirectory];
            if (fileExists && isDirectory == NO) {
                if ([[NSFileManager defaultManager] isWritableFileAtPath:[self responseBodyContentFilePath]]) {
                    fileHandle = [NSFileHandle fileHandleForWritingAtPath:[self responseBodyContentFilePath]];
                }
            }
        }
                
        if (fileHandle == nil) {
            [self setState:S3OperationError];
            return;                
        }
        
        [self setResponseFileHandle:fileHandle];
    }
    
    NSCalendarDate *operationDate = [NSCalendarDate calendarDate];
    [operationDate setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
    [self setDate:operationDate];
    
    // Any headers or information to be included with this HTTP message should have happened before this point!
    
	CFHTTPMessageRef httpRequest = [[self connectionInfo] newCFHTTPMessageRefFromOperation:self];
    if (httpRequest == NULL) {
        [self setState:S3OperationError];
        return;
    }
    
    NSInputStream *inputStream = nil;
    NSData *bodyContentsData = [self requestBodyContentData];
    NSString *bodyContentsFilePath = [self requestBodyContentFilePath];
    if (bodyContentsData != nil) {
        inputStream = [NSInputStream inputStreamWithData:bodyContentsData];
    } else if (bodyContentsFilePath != nil) {
        inputStream = [NSInputStream inputStreamWithFileAtPath:bodyContentsFilePath];
    }

    if (inputStream != nil) {
        httpOperationReadStream = CFReadStreamCreateForStreamedHTTPRequest(kCFAllocatorDefault, httpRequest, (__bridge CFReadStreamRef)inputStream);
    } else {
        // If there is no body to send there is no need to make a streamed request.
        httpOperationReadStream = CFReadStreamCreateForHTTPRequest(kCFAllocatorDefault, httpRequest);

        // When we are not doing a streamed request and the request is not secure or 
        // the request is secure and is a request on the service
        // and the request is virtually hosted and there is a bucket name.
        if (![[self connectionInfo] secureConnection] || ([[self connectionInfo] secureConnection] && [self isRequestOnService] && ![[self connectionInfo] virtuallyHosted] && [self virtuallyHostedCapable] && ![self bucketName])) {
//            NSLog(@"auto redirecting!");
            CFReadStreamSetProperty(httpOperationReadStream, kCFStreamPropertyHTTPShouldAutoredirect, kCFBooleanTrue);
        }
    }
        
    [self setRequestHeaders:(NSDictionary *)CFBridgingRelease(CFHTTPMessageCopyAllHeaderFields(httpRequest))];
    CFRelease(httpRequest);
    
    self.rateCalculator = [[S3TransferRateCalculator alloc] init];

    // Setup the rate calculator
    if (inputStream != nil) {
        // It is most likely upload data
        [self.rateCalculator setObjective:[self requestBodyContentLength]];
        // We need the rate calculator to ping us occasionally to update it.
        // To do this we set the rate calculator's delegate to us.
        [self.rateCalculator setDelegate:self];
    } else {
        // It is most likely download data
        [self.rateCalculator setObjective:[self responseBodyContentExepctedLength]];
    }
    
    
    // TODO: error checking on creation of read stream. 长连接注释掉了，以后增加此功能
    
    //CFReadStreamSetProperty(httpOperationReadStream, kCFStreamPropertyHTTPAttemptPersistentConnection, kCFBooleanTrue);
    
    if (self.delegate && [(NSObject*)self.delegate respondsToSelector:@selector(operationQueuePosition:)]) {
        self.queuePosition = [self.delegate operationQueuePosition:self];
        NSNumber *queuePositionNumber = [[NSNumber alloc] initWithInteger:[self queuePosition]];
        CFReadStreamSetProperty(httpOperationReadStream, S3PersistentCFReadStreamPoolUniquePeropertyKey, (CFNumberRef)queuePositionNumber);
    }
    
    // TODO: error checking on setting the stream client
    CFStreamClientContext clientContext = {0, (__bridge void *)(self), NULL, NULL, NULL};
    CFReadStreamSetClient(httpOperationReadStream, S3OperationNetworkEvents, ReadStreamClientCallBack, &clientContext);
    
    // Schedule the stream
    CFReadStreamScheduleWithRunLoop(httpOperationReadStream, CFRunLoopGetMain(), kCFRunLoopCommonModes);
    
    if (!CFReadStreamOpen(httpOperationReadStream)) {
        CFReadStreamSetClient(httpOperationReadStream, 0, NULL, NULL);
        CFReadStreamUnscheduleFromRunLoop(httpOperationReadStream, CFRunLoopGetMain(), kCFRunLoopCommonModes);
        CFRelease(httpOperationReadStream);
        httpOperationReadStream = NULL;
        return;
    }
    [self setState:S3OperationActive];
}

- (void)handleStreamOpenCompleted
{
//    NSLog(@"handleStreamOpenCompleted");

    // One should not close a stream once it is added to the S3PersistentCFReadStreamPool
    // S3PersistentCFReadStreamPool will take care of closing a stream so other persistent
    // streams can be enqueued on it.
    // If an error occurs or the stream has been canceled unregister the client and unschedule
    // from the run loop and ask the S3PersistentCFReadStreamPool to remove the stream.
    // Removing the stream will close the stream.
    S3PersistentCFReadStreamPool *sharedPool = [S3PersistentCFReadStreamPool sharedPersistentCFReadStreamPool];
    if ([sharedPool addOpenedPersistentCFReadStream:httpOperationReadStream inQueuePosition:[self queuePosition]] == NO) {
//        NSLog(@"Not added");
        CFReadStreamSetClient(httpOperationReadStream, 0, NULL, NULL);
        CFReadStreamUnscheduleFromRunLoop(httpOperationReadStream, CFRunLoopGetMain(), kCFRunLoopCommonModes);
        CFReadStreamClose(httpOperationReadStream);
        CFRelease(httpOperationReadStream);
        httpOperationReadStream = NULL;
        
        // Close filestream if available.
        [[self responseFileHandle] closeFile];
        [self setResponseFileHandle:nil];
        
        [self setState:S3OperationError];
        return;
    }
        
    [self.rateCalculator startTransferRateCalculator];
}

- (void)handleStreamHavingBytesAvailable
{
//    NSLog(@"handleStreamHavingBytesAvailable");
    if (!httpOperationReadStream) {
        return;
    }
    
    UInt8 buffer[65536];
    CFIndex bytesRead = CFReadStreamRead(httpOperationReadStream, buffer, sizeof(buffer));
    if (bytesRead < 0) {
        // TODO: Something?
    } else if (bytesRead > 0) {
        if ([self responseFileHandle] != nil) {
            NSData *receivedData = [NSData dataWithBytesNoCopy:(void *)buffer length:bytesRead freeWhenDone:NO];
            [[self responseFileHandle] writeData:receivedData];
        } else {
            NSData *existingData = [self responseData];
            if (existingData == nil) {
                existingData = [NSData data];
                [self setResponseData:existingData];
            }
            NSMutableData *workingData = [NSMutableData dataWithData:existingData];
            [workingData appendBytes:(const void *)buffer length:bytesRead];
            [self setResponseData:workingData];            
        }
        [self.rateCalculator addBytesTransfered:bytesRead];
        [self updateInformationalSubStatus];
    }
}

- (void)handleStreamHavingEndEncountered
{
//    NSLog(@"handleStreamHavingEndEncountered");

    CFReadStreamSetClient(httpOperationReadStream, 0, NULL, NULL);
    CFReadStreamUnscheduleFromRunLoop(httpOperationReadStream, CFRunLoopGetMain(), kCFRunLoopCommonModes);
    
    CFIndex statusCode = 0;
    
    // Copy out any headers
    CFHTTPMessageRef headerMessage = (CFHTTPMessageRef)CFReadStreamCopyProperty(httpOperationReadStream, kCFStreamPropertyHTTPResponseHeader);
    if (headerMessage != NULL) {
        // Get the HTTP status code
        statusCode = CFHTTPMessageGetResponseStatusCode(headerMessage);
        [self setResponseStatusCode:@(statusCode)];
        
        NSDictionary *headerDict = (NSDictionary *)CFBridgingRelease(CFHTTPMessageCopyAllHeaderFields(headerMessage));
        if (headerDict != nil) {
            [self setResponseHeaders:headerDict];
            headerDict = nil;
        }
        CFRelease(headerMessage);
        headerMessage = NULL;
    }

    S3OperationState customState = 0;
    BOOL useCustomState = [self didInterpretStateForStreamHavingEndEncountered:&customState];
    if (useCustomState) {
        [self setState:customState];
    } else {
        if (statusCode >= 400) {
            [self setState:S3OperationError];
            if ([self responseFileHandle]) {
                [[self responseFileHandle] seekToFileOffset:0];
                NSData *data = [[self responseFileHandle] readDataToEndOfFile];
                [self setResponseData:data];
            }
        } else if (statusCode >= 300 && statusCode < 400) {
            if (statusCode == 307) {
                [self setState:S3OperationRequiresRedirect];                
            } else if (statusCode == 301) {
                [self setState:S3OperationRequiresVirtualHostingEnabled];
            } else {
                [self setState:S3OperationError];                
            }
            if ([self responseFileHandle]) {
                [[self responseFileHandle] seekToFileOffset:0];
                NSData *data = [[self responseFileHandle] readDataToEndOfFile];
                [self setResponseData:data];
            }
        } else {
            [self setState:S3OperationDone];            
        }
    }

    // Close filestream if available.
    [[self responseFileHandle] closeFile];
    [self setResponseFileHandle:nil];

    [self.rateCalculator stopTransferRateCalculator];
    
    CFRelease(httpOperationReadStream);
    httpOperationReadStream = NULL;
}

- (void)handleStreamErrorOccurred
{
//    NSLog(@"handleStreamErrorOccurred");
//
//    CFErrorRef errorRef = CFReadStreamCopyError(httpOperationReadStream);
//    if (errorRef) {
//        CFRelease(errorRef);
//    }
    CFReadStreamSetClient(httpOperationReadStream, 0, NULL, NULL);
    CFReadStreamUnscheduleFromRunLoop(httpOperationReadStream, CFRunLoopGetMain(), kCFRunLoopCommonModes);
    S3PersistentCFReadStreamPool *sharedPool = [S3PersistentCFReadStreamPool sharedPersistentCFReadStreamPool];
    [sharedPool removeOpenedPersistentCFReadStream:httpOperationReadStream];
    CFRelease(httpOperationReadStream);
    httpOperationReadStream = NULL;
    
    // Close filestream if available.
    [[self responseFileHandle] closeFile];
    [self setResponseFileHandle:nil];
    
    [self setState:S3OperationError];
    [self.rateCalculator stopTransferRateCalculator];
}

- (void)handleNetworkEvent:(CFStreamEventType)eventType
{
    switch (eventType) {
        case kCFStreamEventOpenCompleted:
            [self handleStreamOpenCompleted];
            return;
            break;
            
        case kCFStreamEventHasBytesAvailable:
            [self handleStreamHavingBytesAvailable];
            return;
            break;
        
        case kCFStreamEventEndEncountered:
            [self handleStreamHavingEndEncountered];
            return;
            break;
            
        case kCFStreamEventErrorOccurred:
            [self handleStreamErrorOccurred];
            return;
            break;
            
        default:
//            NSLog(@"default hit - %d", eventType);
            return;
            break;
    }
}

- (void)pingFromTransferRateCalculator:(S3TransferRateCalculator *)obj
{
    if (!httpOperationReadStream) {
        return;
    }
    NSData *bodyContentsData = [self requestBodyContentData];
    NSString *bodyContentsFilePath = [self requestBodyContentFilePath];
    if (bodyContentsData != nil || bodyContentsFilePath != nil) {
        // It is most likely upload data
        long long previouslyTransfered = [self.rateCalculator totalTransfered];
        NSNumber *totalTransferedNumber = (NSNumber *)CFBridgingRelease(CFReadStreamCopyProperty(httpOperationReadStream, kCFStreamPropertyHTTPRequestBytesWrittenCount));
        long long totalTransfered = [totalTransferedNumber longLongValue];
        [self.rateCalculator addBytesTransfered:(totalTransfered - previouslyTransfered)];
        [self updateInformationalSubStatus];
    }    
}

// Convenience method which setup an NSError from HTTP status and data by checking S3 error XML Documents
- (NSError*)errorFromHTTPRequestStatus:(int)status data:(NSData*)aData;
{
    NSError* error = nil;
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    dictionary[S3_ERROR_HTTP_STATUS_KEY] = @(status);
    
    NSXMLDocument *d = [[NSXMLDocument alloc] initWithData:aData options:NSXMLDocumentTidyXML error:&error];
    if (error!=NULL)
        dictionary[NSUnderlyingErrorKey] = error;
    
    NSArray* a = [[d rootElement] nodesForXPath:@"//Code" error:&error];
    if ([a count]==1) {
        dictionary[NSLocalizedDescriptionKey] = [a[0] stringValue];
        dictionary[S3_ERROR_CODE_KEY] = [a[0] stringValue];
    }
        
    a = [[d rootElement] nodesForXPath:@"//Message" error:&error];
    if (error!=NULL)
        dictionary[NSUnderlyingErrorKey] = error;

    if ([a count]==1)
        dictionary[NSLocalizedRecoverySuggestionErrorKey] = [a[0] stringValue];
    
    a = [[d rootElement] nodesForXPath:@"//Resource" error:&error];
    if (error!=NULL)
        dictionary[NSUnderlyingErrorKey] = error;

    if ([a count]==1)
        dictionary[S3_ERROR_RESOURCE_KEY] = [a[0] stringValue];
    
    return [NSError errorWithDomain:S3_ERROR_DOMAIN code:status userInfo:dictionary];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"informationalStatus"]) {
        [self.delegate operationInformationalStatusDidChange:self];
    } else if ([keyPath isEqualToString:@"informationalSubStatus"]) {
        [self.delegate operationInformationalSubStatusDidChange:self];
    }
}

- (BOOL)didInterpretStateForStreamHavingEndEncountered:(S3OperationState *)theState
{
    return NO;
}

- (NSString *)kind
{
    return nil;
}



#pragma mark threading behaviour

static NSThread *networkThread = nil;

// In the default implementation, all requests run in a single background thread
// Advanced users only: Override this method in a subclass for a different threading behaviour
// Eg: return [NSThread mainThread] to run all requests in the main thread
// Alternatively, you can create a thread on demand, or manage a pool of threads
// Threads returned by this method will need to run the runloop in default mode (eg CFRunLoopRun())
// Requests will stop the runloop when they complete
// If you have multiple requests sharing the thread or you want to re-use the thread, you'll need to restart the runloop
+ (NSThread *)threadForRequest:(S3Operation *)op
{
	if (networkThread == nil) {
        
		@synchronized(self) {
		
            if (networkThread == nil) {
			
                networkThread = [[NSThread alloc] initWithTarget:self selector:@selector(runRequests) object:nil];
				[networkThread start];
			}
		}
	}
    
	return networkThread;
}

+ (void)runRequests
{
	// Should keep the runloop from exiting
	CFRunLoopSourceContext context = {0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL};
	CFRunLoopSourceRef source = CFRunLoopSourceCreate(kCFAllocatorDefault, 0, &context);
	CFRunLoopAddSource(CFRunLoopGetCurrent(), source, kCFRunLoopDefaultMode);
    
    BOOL runAlways = YES; // Introduced to cheat Static Analyzer
    
	while (runAlways) {
        
        @autoreleasepool {
            
            CFRunLoopRun();
        }
	}
    
	// Should never be called, but anyway
	CFRunLoopRemoveSource(CFRunLoopGetCurrent(), source, kCFRunLoopDefaultMode);
	CFRelease(source);
}

@end
