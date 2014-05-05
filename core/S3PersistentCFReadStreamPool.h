//
//  S3PersistentCFReadStreamPool.h
//  S3-Objc
//
//  Created by Michael Ledford on 7/29/08.
//  Modernized by Martin Hering on 07/14/12
//  Copyright 2008 Michael Ledford. All rights reserved.
//

#import <Foundation/Foundation.h>

extern CFStringRef S3PersistentCFReadStreamPoolUniquePeropertyKey;

@interface S3PersistentCFReadStreamPool : NSObject

+ (S3PersistentCFReadStreamPool *)sharedPersistentCFReadStreamPool;
+ (BOOL)sharedPersistentCFReadStreamPoolExists;

- (BOOL)addOpenedPersistentCFReadStream:(CFReadStreamRef)persistentCFReadStream inQueuePosition:(NSUInteger)position;
- (BOOL)addOpenedPersistentCFReadStream:(CFReadStreamRef)persistentCFReadStream;

- (void)removeOpenedPersistentCFReadStream:(CFReadStreamRef)readStream;

@end
