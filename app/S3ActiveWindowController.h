//
//  S3ActiveWindowController.h
//  S3-Objc
//
//  Created by Development Account on 9/3/06.
//  Copyright 2014 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "S3ConnInfo.h"
#import <ASIKit/ASIKit.h>

@class S3ConnectionInfo;
@class S3Operation;

// This class handles all operation-based window by maintaining an active/pending operation queue

@interface S3ActiveWindowController : NSWindowController <ASIProgressDelegate, ASIHTTPRequestDelegate> {
    
    S3ConnInfo *_connInfo;
	S3ConnectionInfo *_connectionInfo;
    NSMutableArray *_operations;
    NSMutableDictionary *_redirectConnectionInfoMappings;
}

- (S3ConnectionInfo *)connectionInfo;
- (void)setConnectionInfo:(S3ConnectionInfo *)aConnection;

- (S3ConnInfo *)connInfo;
- (void)setConnInfo:(S3ConnInfo *)aConnInfo;


- (void)addToCurrentOperations:(S3Operation *)op;
- (BOOL)hasActiveOperations;

//- (void)operationQueueOperationStateDidChange:(NSNotification *)notification;


///////

- (void)addToCurrentNetworkQueue:(ASIS3Request *)request;
- (BOOL)hasActiveRequest;
- (BOOL)configureRequest:(ASIS3Request *)request;

- (void)updateRequest:(ASIS3Request *)request forState:(int)state;

@end
