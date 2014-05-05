//
//  S3ValueTransformers.m
//  S3-Objc
//
//  Created by Bruce Chen on 23/01/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "S3ValueTransformers.h"
#import "S3Extensions.h"


@implementation S3OperationSummarizer
+ (Class)transformedValueClass
{
	return [NSAttributedString class];
}

+ (BOOL)allowsReverseTransformation
{
	return NO;
}

- (id)transformedValue:(id)data
{
	if ([data length]>4096)
		return [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%lu bytes in raw data response",(unsigned long)[data length]]];
	
	NSString *s = [[NSString alloc] initWithData:data encoding:NSNonLossyASCIIStringEncoding];
	if (s==nil)
		return [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%lu bytes in raw data response",(unsigned long)[data length]]];
	return [[NSAttributedString alloc] initWithString:s];	
}

@end

@implementation S3FileSizeTransformer

+ (Class)transformedValueClass
{
    return [NSString class];
}

+ (BOOL)allowsReverseTransformation
{
    return NO;
}

- (id)transformedValue:(id)item {
    return [item readableFileSize];
}
@end