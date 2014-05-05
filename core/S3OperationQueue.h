//
//  S3OperationQueue.h
//  S3-Objc
//
//  Created by Bruce Chen on 04/02/07.
//  Modernized by Martin Hering on 07/14/12
//  Copyright 2007 Bruce Chen. All rights reserved.
//

#import <Foundation/Foundation.h>

@class S3Operation;
@protocol S3OperationQueueDelegate;

@interface S3OperationQueue : NSObject

- (id)initWithDelegate:(id<S3OperationQueueDelegate>)delegate;

// Convenience methods to register object with NSNotificationCenter
// if the object supports the S3OperationQueueNotifications.
// Must call removeQueueListener before object is deallocated.
- (void)addQueueListener:(id)obj;
- (void)removeQueueListener:(id)obj;

- (BOOL)addToCurrentOperations:(S3Operation *)op;
- (NSArray *)currentOperations;

@end

@protocol S3OperationQueueDelegate <NSObject>
@optional
- (int)maximumNumberOfSimultaneousOperationsForOperationQueue:(S3OperationQueue *)operationQueue;
- (void)operationQueueOperationStateDidChange:(NSNotification *)notification;
- (void)operationQueueOperationInformationalStatusDidChangeNotification:(NSNotification *)notification;
- (void)operationQueueOperationInformationalSubStatusDidChangeNotification:(NSNotification *)notification;
@end

/* Notifications */
extern NSString *S3OperationQueueOperationStateDidChangeNotification;
extern NSString *S3OperationQueueOperationInformationalStatusDidChangeNotification;
extern NSString *S3OperationQueueOperationInformationalSubStatusDidChangeNotification;

/* Notification UserInfo Keys */
extern NSString *S3OperationObjectKey;
extern NSString *S3OperationObjectForRetryKey;