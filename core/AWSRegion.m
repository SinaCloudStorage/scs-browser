//
//  AWSRegion.m
//  S3-Objc
//
//  Created by Michael Ledford on 12/28/09.
//  Copyright 2009 Michael Ledford. All rights reserved.
//

#import "AWSRegion.h"

NSString *AWSRegionUSStandardKey = @"AWSRegionUSStandardKey";
NSString *AWSRegionUSWestKey = @"AWSRegionUSWestKey";
NSString *AWSRegionUSEastKey = @"AWSRegionUSEastKey";
NSString *AWSRegionEUIrelandKey = @"AWSRegionEUIrelandKey";

NSString *AWSRegionUSStandardValue = @"";
NSString *AWSRegionUSWestValue = @"us-west-1";
NSString *AWSRegionUSEastValue = @"us-east-1";
NSString *AWSRegionEUIrelandValue = @"EU";


@interface AWSRegion ()
@property(readwrite, nonatomic, copy) NSString *regionKey;
@property(readwrite, nonatomic, copy) NSString *regionValue;
@property(readwrite, nonatomic, assign) AWSProductFlags availableServices;
@end


@implementation AWSRegion {
    /*
    NSString *regionKey;
    AWSProductFlags availableServices;
     */
}

@dynamic regionValue;

// TODO: flyweight pattern the results

+ (NSDictionary *)availableAWSRegionKeysAndValues
{
    return @{AWSRegionUSStandardKey: AWSRegionUSStandardValue,
                                                      AWSRegionUSWestKey: AWSRegionUSWestValue,
                                                      AWSRegionUSEastKey: AWSRegionUSEastValue,
                                                      AWSRegionEUIrelandKey: AWSRegionEUIrelandValue};
}

+ (NSArray *)availableAWSRegionKeys
{
    NSDictionary *availableKeysAndValues = [[self class] availableAWSRegionKeysAndValues];
    return [availableKeysAndValues allKeys];
}

+ (id)regionWithKey:(NSString *)theRegionKey
{
    NSArray *regionKeys = [self availableAWSRegionKeys];
    for (NSString *availableKey in regionKeys) {
        if ([theRegionKey isEqualToString:availableKey]) {
            AWSRegion *region = [[AWSRegion alloc] init];
            [region setRegionKey:theRegionKey];
            // TODO: a better way to set the available services for each region
            if (![theRegionKey isEqualToString:AWSRegionUSEastKey]) {
                [region setAvailableServices:AWSSimpleStorageService];                
            }
            return region;
        }
    }
    return nil;
}

- (NSString *)regionValue
{
    return [[[self class] availableAWSRegionKeysAndValues] objectForKey:[self regionKey]];
}

- (id)copyWithZone:(NSZone *)zone {
    return self;
}

@end
