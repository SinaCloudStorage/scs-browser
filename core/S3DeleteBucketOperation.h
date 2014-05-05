//
//  S3DeleteBucketOperation.h
//  S3-Objc
//
//  Created by Michael Ledford on 11/20/08.
//  Modernized by Martin Hering on 07/14/12
//  Copyright 2008 Michael Ledford. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "S3Operation.h"

@interface S3DeleteBucketOperation : S3Operation {
}

- (id)initWithConnectionInfo:(S3ConnectionInfo *)theConnectionInfo bucket:(S3Bucket *)theBucket;

@property(readonly, nonatomic, copy) S3Bucket *bucket;

@end
