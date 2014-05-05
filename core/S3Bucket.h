//
//  S3Bucket.h
//  S3-Objc
//
//  Created by Bruce Chen on 3/15/06.
//  Modernized by Martin Hering on 07/14/12
//  Copyright 2014 Bruce Chen. All rights reserved.
//

#import <Foundation/Foundation.h>

/* Amazon Doc:
Objects are stored in buckets. The bucket provides a unique namespace for management of objects 
contained in the bucket. Each bucket you create is owned by you for purposes of billing, and you will be 
charged storage fees for all objects stored in the bucket and bandwidth fees for all data read from and 
written to the bucket. There is no limit to the number of objects that one bucket can hold. Since the 
namespace for bucket names is global, each developer is limited to owning 100 buckets at a time. 
*/

@class S3ListBucketOperation;

@interface S3Bucket : NSObject <NSCopying>

- (id)initWithName:(NSString *)name creationDate:(NSDate *)date;
- (id)initWithName:(NSString *)name;

@property (nonatomic, readonly) NSDate* creationDate;
@property (nonatomic, readonly) NSString* name;
@property (nonatomic, readonly, getter=isVirtuallyHostedCapable) BOOL virtuallyHostedCapable;

@end
