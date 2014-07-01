//
//  S3OperationLog.h
//  S3-Objc
//
//  Created by Michael Ledford on 12/1/08.
//  Copyright 2008 Michael Ledford. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import <ASIKit/ASIKit.h>

@class S3Operation;

@protocol S3OperationLogDelegate;

@interface S3OperationLog : NSObject {
    NSMutableArray *_operations;
}

@property(nonatomic, strong, readwrite) NSMutableArray *operations;

//- (void)logOperation:(S3Operation *)o;
//- (void)unlogOperation:(S3Operation *)o;

- (void)logOperation:(ASIS3Request *)o;
- (void)unlogOperation:(ASIS3Request *)o;

@end