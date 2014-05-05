//
//  S3Object.m
//  S3-Objc
//
//  Created by Bruce Chen on 3/15/06.
//  Copyright 2006 Bruce Chen. All rights reserved.
//

#import "S3Object.h"
#import "S3Bucket.h"
#import "S3Owner.h"
#import "S3Extensions.h"
#import "S3ListObjectOperation.h"

NSString *S3ObjectFilePathDataSourceKey = @"S3ObjectFilePathDataSourceKey";
NSString *S3ObjectNSDataSourceKey = @"S3ObjectNSDataSourceKey";

NSString *S3UserDefinedObjectMetadataPrefixKey = @"x-amz-meta-";
NSString *S3UserDefinedObjectMetadataMissingKey = @"x-amz-missing-meta";
NSString *S3ObjectMetadataACLKey = @"x-amz-acl";
NSString *S3ObjectMetadataContentMD5Key = @"content-md5";
NSString *S3ObjectMetadataContentTypeKey = @"content-type";
NSString *S3ObjectMetadataContentLengthKey = @"content-length";
NSString *S3ObjectMetadataETagKey = @"etag";
NSString *S3ObjectMetadataLastModifiedKey = @"last-modified";
NSString *S3ObjectMetadataOwnerKey = @"owner";
NSString *S3ObjectMetadataStorageClassKey = @"x-amz-storage-class";

@interface S3Object ()

@property(readwrite, strong) S3Bucket *bucket;
@property(readwrite, copy) NSString *key;
@property(readwrite, copy) NSDictionary *userDefinedMetadata;
@property(readwrite, copy) NSDictionary *metadata;
@property(readwrite, copy) NSDictionary *dataSourceInfo;

@end


@implementation S3Object

- (id)initWithBucket:(S3Bucket *)bucket key:(NSString *)key userDefinedMetadata:(NSDictionary *)udmd metadata:(NSDictionary *)md dataSourceInfo:(NSDictionary *)info
{
    self = [super init];
    
    if (self != nil) {
        [self setKey:key];
        [self setBucket:bucket];
        NSMutableDictionary *processedMetadata = [NSMutableDictionary dictionaryWithCapacity:[md count]];
        NSEnumerator *metadataKeyEnumerator = [md keyEnumerator];
        NSString *key = nil;
        while (key = [metadataKeyEnumerator nextObject]) {
            NSString *cleanedKey = [key lowercaseString];
            id object = [md objectForKey:key];
            [processedMetadata setObject:object forKey:cleanedKey];
        }
        [self setMetadata:[NSDictionary dictionaryWithDictionary:processedMetadata]];
        [self setUserDefinedMetadata:udmd];
        [self setDataSourceInfo:info];
    }
    
    return self;
}

- (id)initWithBucket:(S3Bucket *)bucket key:(NSString *)key userDefinedMetadata:(NSDictionary *)udmd metadata:(NSDictionary *)md
{
    return [self initWithBucket:bucket key:key userDefinedMetadata:udmd metadata:md dataSourceInfo:nil];
}

- (id)initWithBucket:(S3Bucket *)bucket key:(NSString *)key userDefinedMetadata:(NSDictionary *)udmd
{
    return [self initWithBucket:bucket key:key userDefinedMetadata:udmd metadata:nil];
}

- (id)initWithBucket:(S3Bucket *)bucket key:(NSString *)key
{
    return [self initWithBucket:bucket key:key userDefinedMetadata:nil];
}


- (NSDictionary *)userDefinedMetadata
{
    NSMutableDictionary *mutableDictionary = [[NSMutableDictionary alloc] init];
    NSRange notFoundRange = NSMakeRange(NSNotFound, 0);
    NSDictionary* metadata = self.metadata;
    for(NSString* metadataKey in metadata)
    {
        NSRange foundRange = [metadataKey rangeOfString:S3UserDefinedObjectMetadataPrefixKey options:NSAnchoredSearch];
        if ([metadataKey isKindOfClass:[NSString class]] == YES && NSEqualRanges(foundRange, notFoundRange) == NO) {
            id object = [metadata objectForKey:metadataKey];
            NSString *userDefinatedMetadataKey = [metadataKey stringByReplacingCharactersInRange:foundRange withString:@""];
            [mutableDictionary setObject:object forKey:userDefinatedMetadataKey];
        }
    }
    return mutableDictionary;
}

- (void)setUserDefinedMetadata:(NSDictionary *)metadata
{
    NSMutableDictionary *mutableMetadata = [self.metadata mutableCopy];

    for(NSString* metadataKey in metadata)
    {
        if ([metadataKey isKindOfClass:[NSString class]]) {
            id object = [metadata objectForKey:metadataKey];
            NSString *modifiedMetadataKey = [NSString stringWithFormat:@"%@%@", S3UserDefinedObjectMetadataPrefixKey, metadataKey];
            [mutableMetadata setObject:object forKey:modifiedMetadataKey];
        }
    }
    self.metadata = mutableMetadata;
}

- (id)valueForUndefinedKey:(NSString *)key
{
    id o = self.metadata[key];
	if (o != nil) {
		return o;        
    }

    return [super valueForUndefinedKey:key];
}

- (NSString *)acl
{
    return self.metadata[S3ObjectMetadataACLKey];
}

- (NSString *)contentMD5
{
    return self.metadata[S3ObjectMetadataContentMD5Key];
}

- (NSString *)contentType
{
    return self.metadata[S3ObjectMetadataContentTypeKey];
}

- (NSString *)contentLength
{
    return self.metadata[S3ObjectMetadataContentLengthKey];
}

- (NSString *)etag
{
    return self.metadata[S3ObjectMetadataETagKey];
}

- (NSString *)lastModified
{
    return self.metadata[S3ObjectMetadataLastModifiedKey];
}

- (S3Owner *)owner
{
    return self.metadata[S3ObjectMetadataOwnerKey];
}

- (NSString *)storageClass
{
    return self.metadata[S3ObjectMetadataStorageClassKey];
}

- (BOOL)missingMetadata;
{
    id object = self.metadata[S3UserDefinedObjectMetadataMissingKey];
    return (object == nil ? NO : YES);
}

- (id)copyWithZone:(NSZone *)zone
{
    return self;
}

@end
