//
//  S3Owner.m
//  S3-Objc
//
//  Created by Bruce Chen on 3/15/06.
//  Modernized by Martin Hering on 07/14/12
//  Copyright 2006 Bruce Chen. All rights reserved.
//

#import "S3Owner.h"

@interface S3Owner ()
@property(readwrite, copy) NSString *ID;
@property(readwrite, copy) NSString *displayName;
@end

@implementation S3Owner

- (id)initWithID:(NSString *)ID displayName:(NSString *)name
{
    if ((self = [super init])) {
        _ID = [ID copy];
        _displayName = [name copy];     
    }
    
	return self;
}

@end
