//
//  S3Kit.h
//  S3Kit
//
//  Created by Martin Hering on 15.07.12.
//
//

/* base classes */
#import <S3Kit/AWSRegion.h>
#import <S3Kit/S3Bucket.h>
#import <S3Kit/S3Object.h>
#import <S3Kit/S3ConnectionInfo.h>
#import <S3Kit/S3MutableConnectionInfo.h>
#import <S3Kit/S3Operation.h>
#import <S3Kit/S3OperationQueue.h>
#import <S3Kit/S3TransferRateCalculator.h>
#import <S3Kit/S3PersistentCFReadStreamPool.h>
#import <S3Kit/S3HTTPURLBuilder.h>
#import <S3Kit/S3Owner.h>
#import <S3Kit/S3ACL.h>
#import <S3Kit/S3Extensions.h>

/* buckets operations */
#import <S3Kit/S3AddBucketOperation.h>
#import <S3Kit/S3DeleteBucketOperation.h>
#import <S3Kit/S3ListBucketOperation.h>

/* object operations */
#import <S3Kit/S3ListObjectOperation.h>
#import <S3Kit/S3DeleteObjectOperation.h>
#import <S3Kit/S3AddObjectOperation.h>
#import <S3Kit/S3DownloadObjectOperation.h>
#import <S3Kit/S3CopyObjectOperation.h>