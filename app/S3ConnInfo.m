//
//  S3ConnInfo.m
//  SCS-Objc
//
//  Created by Bruce on 14-5-13.
//
//

#import "S3ConnInfo.h"

@interface S3ConnInfo ()

@property (nonatomic, readwrite, weak) id<S3ConnInfoDelegate> delegate;
@property (nonatomic, readwrite) BOOL secureConn;
@property (nonatomic, readwrite) NSDictionary *userInfo;

@end

@implementation S3ConnInfo

- (id)init {
    
    return [self initWithDelegate:nil];
}

- (id)initWithDelegate:(id<S3ConnInfoDelegate>)delegate userInfo:(id)userInfo secureConn:(BOOL)secureConn {
    
    if ((self = [super init])) {
        
        if (delegate == nil) {
        
            return nil;
        }
        
        _delegate = delegate;
        _userInfo = userInfo;
        _secureConn = secureConn;
    }
    
    return self;
}


- (id)initWithDelegate:(id<S3ConnInfoDelegate>)delegate {
    
    return [self initWithDelegate:delegate userInfo:nil];
}

- (id)initWithDelegate:(id<S3ConnInfoDelegate>)delegate userInfo:(id)userInfo {

    return [self initWithDelegate:delegate userInfo:userInfo secureConn:NO];
}


#pragma mark -
#pragma mark Copying Protocol Methods

- (id)copyWithZone:(NSZone *)zone {
    
    S3ConnInfo *newObject = [[S3ConnInfo allocWithZone:zone] initWithDelegate:self.delegate
                                                                     userInfo:self.userInfo
                                                                   secureConn:self.secureConn];
    return newObject;
}

/*
- (id)mutableCopyWithZone:(NSZone *)zone
{
    S3MutableConnectionInfo *newObject = [[S3MutableConnectionInfo allocWithZone:zone] initWithDelegate:self.delegate
                                                                                               userInfo:self.userInfo
                                                                                       secureConnection:self.secureConnection
                                                                                             portNumber:self.portNumber
                                                                                        virtuallyHosted:self.virtuallyHosted
                                                                                           hostEndpoint:self.hostEndpoint];
    return newObject;
}
 */

#pragma mark -
#pragma mark Equality Methods

- (BOOL)isEqual:(id)anObject {
    
    if (anObject && [anObject isKindOfClass:[S3ConnInfo class]]) {
        
        if ([anObject delegate] == [self delegate] &&
            (([anObject userInfo] == nil && [self userInfo] == nil) ||
             [[anObject userInfo] isEqual:[self userInfo]]) &&
            [anObject secureConn] == [self secureConn]) {
                
                return YES;
            }
    }
    
    return NO;
}

- (NSUInteger)hash {
    
    NSUInteger value = 0;
    
    value += value * 37 + (NSUInteger)[self delegate];
    value += value * 37 + [[self userInfo] hash];
    value += value * 37 + ([self secureConn] ? 1 : 2);
    
    return value;
}

#pragma mark -
#pragma mark Description Method

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %#x -\n delegate:%#x\n userInfo:%@\n secureConnection:%d\n>", [self class], (unsigned int)self, (unsigned int)[self delegate], [self userInfo], [self secureConn]];
}


@end
