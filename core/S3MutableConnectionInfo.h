//
//  S3MutableConnectionInfo.h
//  S3-Objc
//
//  Created by Michael Ledford on 11/18/08.
//  Modernized by Martin Hering on 07/14/12
//  Copyright 2008 Michael Ledford. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "S3ConnectionInfo.h"

@interface S3MutableConnectionInfo : S3ConnectionInfo
/*
// A delegate is required
@property (nonatomic, readwrite) id<S3ConnectionInfoDelegate> delegate;

// Sets userInfo that can be grabbed later. May
// be nil. Especially useful for delegates
// who store a S3ConnectionInfo in certain
// collections since it effects (contributes to) equality.
@property (nonatomic, readwrite) NSDictionary* userInfo;

// Insecure by default
// Resets the port number value to default
// for secure or insecure connection.
@property (nonatomic, readwrite) BOOL secureConnection;

// Uses default port for either secure or
// insecure connection unless set after
// secure connection is set.
@property (nonatomic, readwrite) NSUInteger portNumber;

// Sets whether this connection should be
// vitually hosted or not. Defaults to YES.
@property (nonatomic, readwrite) BOOL virtuallyHosted;

// If a host other than the default
// Amazon S3 host endpoint should be
// specified. Note, the only likely
// case for using this is using an
// Amazon S3 clone API.
// This is not to be used to make
// virtually hosted buckets.
@property (nonatomic, readwrite) NSString* hostEndpoint;
*/
@end
