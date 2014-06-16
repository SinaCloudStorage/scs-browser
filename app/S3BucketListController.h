//
//  S3BucketListController.h
//  S3-Objc
//
//  Created by Bruce Chen on 4/3/06.
//  Copyright 2014 Bruce Chen. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "S3ActiveWindowController.h"

@class S3Connection;
@class S3Owner;

@interface S3BucketListController : S3ActiveWindowController {
    
    NSArray *_buckets;
        
    IBOutlet NSArrayController *_bucketsController;

    IBOutlet NSWindow *addSheet;
    NSString *_name;
    NSInteger _location;
    
    NSMutableDictionary *_bucketListControllerCache;
    
    NSString *_bucketOwnerId;
    NSString *_bucketOwnerDisplayName;
}

- (IBAction)refresh:(id)sender;
- (IBAction)remove:(id)sender;
- (IBAction)add:(id)sender;
- (IBAction)open:(id)sender;

- (IBAction)cancelSheet:(id)sender;
- (IBAction)closeSheet:(id)sender;

- (NSString *)name;
- (void)setName:(NSString *)aName;

- (BOOL)isValidName;

- (void)setBucketsOwnerWithID:(NSString *)ownerId displayName:(NSString *)displayName;

- (void)setBucketOwnerId:(NSString *)ownerId;
- (NSString *)bucketOwnerId;
- (void)setBucketOwnerDisplayName:(NSString *)displayName;
- (NSString *)bucketOwnerDisplayName;

- (NSArray *)buckets;
- (void)setBuckets:(NSArray *)aBuckets;

@end
