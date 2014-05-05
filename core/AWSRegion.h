//
//  AWSRegion.h
//  S3-Objc
//
//  Created by Michael Ledford on 12/28/09.
//  Modernized by Martin Hering on 07/14/12
//  Copyright 2009 Michael Ledford. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString *AWSRegionUSStandardKey;
extern NSString *AWSRegionUSWestKey;
extern NSString *AWSRegionUSEastKey;
extern NSString *AWSRegionEUIrelandKey;


// TODO: Support more of Amazon's Web Services
typedef NS_ENUM (NSUInteger, AWSProductFlags) {
    AWSSimpleStorageService = (1L << 1)
//    AWSSimpleQueueService = (1L << 2),
//    AWSElasticComputeCloudService = (1L << 3),
//    AWSSimpleDBService = (1L << 4),
//    AWSCloudFrontService = (1L << 5),
//    AWSElasticMapReduceService = (1L << 6),
//    AWSImportExportService = (1L << 7),
//    AWSVirtualPrivateCloudService = (1L << 8),
//    AWSRelationalDatabaseService = (1L << 9),
};

@interface AWSRegion : NSObject <NSCopying>

+ (NSArray *)availableAWSRegionKeys;
+ (id)regionWithKey:(NSString *)regionKey;

@property(readonly, nonatomic, copy) NSString *regionKey;
@property(readonly, nonatomic, copy) NSString *regionValue;
@property(readonly, nonatomic, assign) AWSProductFlags availableServices;

@end
