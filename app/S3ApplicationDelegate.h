//
//  S3ApplicationDelegate.h
//  S3-Objc
//
//  Created by Michael Ledford on 9/11/08.
//  Copyright 2008 Michael Ledford. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <ASIKit/ASIKit.h>

@class S3ConnectionInfo;
@class S3OperationQueue;
@class S3OperationLog;

extern NSString *ASIS3RequestKey;
extern NSString *ASIS3RequestStateKey;
extern NSString *ASIS3RequestStateDidChangeNotification;

extern NSString *RequestUserInfoTransferedBytesKey;
extern NSString *RequestUserInfoResumeDownloadedFileSizeKey;
extern NSString *RequestUserInfoKindKey;
extern NSString *RequestUserInfoStatusKey;
extern NSString *RequestUserInfoSubStatusKey;
extern NSString *RequestUserInfoURLKey;
extern NSString *RequestUserInfoRequestMethodKey;

extern NSString *ASIS3RequestListBucket;
extern NSString *ASIS3RequestAddBucket;
extern NSString *ASIS3RequestDeleteBucket;
extern NSString *ASIS3RequestListObject;
extern NSString *ASIS3RequestAddObject;
extern NSString *ASIS3RequestAddObjectRelax;
extern NSString *ASIS3RequestDeleteObject;
extern NSString *ASIS3RequestCopyObject;
extern NSString *ASIS3RequestDownloadObject;
extern NSString *ASIS3RequestGetACLBucket;
extern NSString *ASIS3RequestPutACLBucket;
extern NSString *ASIS3RequestGetACLObject;
extern NSString *ASIS3RequestPutACLObject;
extern NSString *ASIS3RequestGetMetaObject;
extern NSString *ASIS3RequestPutMetaObject;
extern NSString *ASIS3RequestGetMetaBucket;

extern NSString *RequestUserInfoStatusPending;
extern NSString *RequestUserInfoStatusActive;
extern NSString *RequestUserInfoStatusCanceled;
extern NSString *RequestUserInfoStatusReceiveResponseHeaders;
extern NSString *RequestUserInfoStatusDone;
extern NSString *RequestUserInfoStatusRequiresRedirect;
extern NSString *RequestUserInfoStatusError;

typedef NS_ENUM (NSUInteger, ASIS3RequestState) {
    ASIS3RequestPending = 0,
    ASIS3RequestActive = 1,
    ASIS3RequestCanceled = 2,
    ASIS3RequestReceiveResponseHeaders = 3,
    ASIS3RequestDone = 4,
    ASIS3RequestRequiresRedirect = 5,
    ASIS3RequestError = 6,
};

@interface S3ApplicationDelegate : NSObject {
    NSMutableDictionary *_controllers;
    S3OperationQueue *_queue;
    S3OperationLog *_operationLog;
    NSMutableDictionary *_authenticationCredentials;
    
    ASINetworkQueue *_networkQueue;
    ASINetworkQueue *_networkRefreshQueue;
}

- (IBAction)openConnection:(id)sender;
- (IBAction)showOperationConsole:(id)sender;
- (BOOL)checkUpdate:(id)sender;
- (S3OperationQueue *)queue;
- (S3OperationLog *)operationLog;

- (ASINetworkQueue *)networkQueue;
- (ASINetworkQueue *)networkRefreshQueue;

- (NSMutableDictionary *)controllers;

- (void)setAuthenticationCredentials:(NSDictionary *)authDict forConnectionInfo:(id)connInto;
- (void)removeAuthenticationCredentialsForConnectionInfo:(id)connInfo;


- (void)requestDidStartSelector:(ASIS3Request *)request;
- (void)requestDidReceiveResponseHeadersSelector:(ASIS3Request *)request;
- (void)requestWillRedirectSelector:(ASIS3Request *)request;
- (void)requestDidFinishSelector:(ASIS3Request *)request;
- (void)requestDidFailSelector:(ASIS3Request *)request;

@end
