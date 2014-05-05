//
//  S3ConnectionInfo.h
//  S3-Objc
//
//  Created by Bruce Chen on 4/2/06.
//  Modernized by Martin Hering on 07/14/12
//  Copyright 2014 Bruce Chen. All rights reserved.
//

#import <Foundation/Foundation.h>

@class S3Operation;

@protocol S3ConnectionInfoDelegate;

@interface S3ConnectionInfo : NSObject <NSCopying, NSMutableCopying>

- (id)initWithDelegate:(id<S3ConnectionInfoDelegate>)delegate;
- (id)initWithDelegate:(id<S3ConnectionInfoDelegate>)delegate userInfo:(id)userInfo;
- (id)initWithDelegate:(id<S3ConnectionInfoDelegate>)delegate userInfo:(id)userInfo secureConnection:(BOOL)secureConnection;
- (id)initWithDelegate:(id<S3ConnectionInfoDelegate>)delegate userInfo:(id)userInfo secureConnection:(BOOL)secureConnection portNumber:(NSUInteger)portNumber;
- (id)initWithDelegate:(id<S3ConnectionInfoDelegate>)delegate userInfo:(id)userInfo secureConnection:(BOOL)secureConnection portNumber:(NSUInteger)portNumber virtuallyHosted:(BOOL)virtuallyHosted;
- (id)initWithDelegate:(id<S3ConnectionInfoDelegate>)delegate userInfo:(id)userInfo secureConnection:(BOOL)secureConnection portNumber:(NSUInteger)portNumber virtuallyHosted:(BOOL)virtuallyHosted hostEndpoint:(NSString *)host;

@property (nonatomic, readonly, weak) id<S3ConnectionInfoDelegate> delegate;
@property (nonatomic, readonly) BOOL secureConnection;
@property (nonatomic, readonly) NSUInteger portNumber;
@property (nonatomic, readonly) NSString* hostEndpoint;
@property (nonatomic, readonly) BOOL virtuallyHosted;
@property (nonatomic, readonly) NSDictionary* userInfo;

// Create a CFHTTPMessageRef from an operation; object returned has a retain count of 1
// and must be released by the caller when finished using the object.
- (CFHTTPMessageRef)newCFHTTPMessageRefFromOperation:(S3Operation *)operation;

@end

@protocol S3ConnectionInfoDelegate <NSObject>

@optional
// Required for S3ConnectionInfo to handle authorization of requests itself
- (NSString *)accessKeyForConnectionInfo:(S3ConnectionInfo *)connectionInfo;
- (NSString *)secretAccessKeyForConnectionInfo:(S3ConnectionInfo *)connectionInfo;

// Required if the above delegate methods are not present.
// Should return a valid S3 Authentication Header value.
// (See Amazon Simple Storage Service 'Authenticating REST Requests' for how to sign and form a valid header value)
- (NSString *)connectionInfo:(S3ConnectionInfo *)connection authorizationHeaderForRequestHeader:(NSString *)requestHeaderToSign;

@end