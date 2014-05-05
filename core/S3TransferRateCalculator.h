//
//  S3TransferRateCalculator.h
//  S3-Objc
//
//  Created by Michael Ledford on 3/14/07.
//  Modernized by Martin Hering on 07/14/12
//  Copyright 2007 Michael Ledford. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM (NSUInteger, S3UnitType) {
    // Base Unit 1 Octet / 8 Bits
    S3OctetUnit,
    // Base 2
    S3KibibitUnit,
    S3MebibitUnit,
    S3GibibitUnit,
    S3TebibitUnit,
    S3PebibitUnit,
    // Base 10
    S3KilobitUnit,
    S3MegabitUnit,
    S3GigabitUnit,
    S3TerabitUnit,
    S3PetabitUnit,
    // Base 2
    S3KibibyteUnit,
    S3MebibyteUnit,
    S3GibibyteUnit,
    S3TebibyteUnit,
    S3PebibyteUnit,
    S3ExbibyteUnit,
    // Base 10
    S3KilobyteUnit,
    S3MegabyteUnit,
    S3GigabyteUnit,
    S3TerabyteUnit,
    S3PetabyteUnit
};

typedef NS_ENUM (NSUInteger, S3RateType) {
    S3PerMillisecondRate,
    S3PerSecondRate,
    S3PerMinuteRate,
    S3PerHourRate,
    S3PerDayRate
};

@protocol S3TransferRateCalculatorDelegate;

@interface S3TransferRateCalculator : NSObject

- (id)init;

@property (nonatomic, weak) id<S3TransferRateCalculatorDelegate> delegate;
@property (nonatomic, assign) S3UnitType displayUnit;
@property (nonatomic, assign) S3RateType displayRate;
@property (nonatomic, readonly, assign) long long objective;
- (BOOL)setObjective:(long long)bytes;

- (void)setCalculateUsingAverageRate:(BOOL)yn;

- (long long)totalTransfered;

- (BOOL)isRunning;
- (void)startTransferRateCalculator;
- (void)stopTransferRateCalculator;

- (void)addBytesTransfered:(long long)bytes;

- (NSString *)stringForCalculatedTransferRate;
- (NSString *)stringForShortDisplayUnit;
- (NSString *)stringForLongDisplayUnit;
- (NSString *)stringForShortRateUnit;
- (NSString *)stringForLongRateUnit;
- (NSString *)stringForEstimatedTimeRemaining;
- (NSString *)stringForObjectivePercentageCompleted;
- (float)floatForObjectivePercentageCompleted; // 0.0 - 1.0

@end

@protocol S3TransferRateCalculatorDelegate <NSObject>
- (void)pingFromTransferRateCalculator:(S3TransferRateCalculator *)obj;
@end