//
//  S3Bucket.m
//  S3-Objc
//
//  Created by Bruce Chen on 3/15/06.
//  Modernized by Martin Hering on 07/14/12
//  Copyright 2014 Bruce Chen. All rights reserved.
//

#import "S3Bucket.h"
#import "S3Extensions.h"
#import "S3ListBucketOperation.h"

@interface S3Bucket () 

@property (nonatomic, readwrite) NSDate* creationDate;
@property (nonatomic, readwrite) NSString* name;
@property (nonatomic, readwrite, getter=isVirtuallyHostedCapable) BOOL virtuallyHostedCapable;

+ (BOOL)isDNSComptatibleName:(NSString*)name;
@end

@implementation S3Bucket

- (id)initWithName:(NSString *)name creationDate:(NSDate *)date
{
	self = [super init];

    if (self != nil) {
        if (name == nil) {
            return nil;
        }        
        [self setName:name];
        [self setCreationDate:date];
		[self setVirtuallyHostedCapable:[S3Bucket isDNSComptatibleName:name]];
	}

	return self;
}

- (id)initWithName:(NSString *)name
{
    return [self initWithName:name creationDate:nil];
}


+ (BOOL)isDNSComptatibleName:(NSString*)name;
{
	// This is really a naive test. From the Amazon doc:

	// Bucket names should not contain underscores (_)
	// Bucket names should be between 3 and 63 characters long
	// Bucket names should not end with a dash
	// Bucket names cannot contain two, adjacent periods
	// Bucket names cannot contain dashes next to periods (e.g., "my-.bucket.com" and "my.-bucket" are invalid)
	// Buckets with names containing uppercase characters are not accessible using the virtual hosted-style request
 	// When using virtual hosted-style buckets with SSL, the SSL wild card certificate only matches buckets that do not contain periods.
	// To work around this, use HTTP or write your own certificate verification logic.
	// EU (Ireland) and US-West (Northern California) Region bucket names must be DNS compatible and therefore do not support the path style method. 
	// US Standard bucket names do not have to be DNS compatible and therefore can support the path style method. 
	// US Standard buckets can be named, http://s3.amazonaws.com/[bucket-name]/[key], for example, http://s3.amazonaws.com/images.johnsmith.net/mydog.jpg.
	// As long as your GET request does not use the SSL endpoint, you can specify the bucket for the request using the HTTP Host header. 
	
	// Bottom-line: non-DNS bucket names are slowly going away
	
	return [[name lowercaseString] isEqualToString:name];
}

- (NSUInteger)hash
{
    return [_name hash];
}

- (BOOL)isEqual:(id)obj
{
    if ([obj isKindOfClass:[self class]]) {
        if ([[self name] isEqualToString:[obj name]]) {
            return YES;
        }
    }    
    return NO;
}

- (id)copyWithZone:(NSZone *)zone {
    return self;
}

- (NSString*) description
{
    return [NSString stringWithFormat:@"<S3Bucket: 0x%lx; name='%@'; created=%@>", (long)self, self.name, self.creationDate];
}

@end
