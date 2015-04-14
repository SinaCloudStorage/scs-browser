//
//  S3ConnectionInfo.m
//  S3-Objc
//
//  Created by Bruce Chen on 4/2/06.
//  Modernized by Martin Hering on 07/14/12
//  Copyright 2014 Bruce Chen. All rights reserved.
//

#import <CoreFoundation/CoreFoundation.h>
#import <CoreServices/CoreServices.h>
#import <Security/Security.h>

#import "S3ConnectionInfo.h"
#import "S3MutableConnectionInfo.h"

#import "S3HTTPUrlBuilder.h"
#import "S3Operation.h"
#import "S3Object.h"
#import "S3Extensions.h"


//NSString *S3DefaultHostString = @"s3.amazonaws.com";
NSString *S3DefaultHostString = @"sinastorage.com";
NSInteger S3DefaultInsecurePortInteger = 80;
NSInteger S3DefaultSecurePortInteger = 443;
NSString *S3InsecureHTTPProtocolString = @"http";
NSString *S3SecureHTTPProtocolString = @"https";

//XAMZACL
NSString *S3HeaderACLString = @"x-amz-acl";
NSString *S3HeaderPrefixString = @"x-amz";

@interface S3ConnectionInfo ()

@property (nonatomic, readwrite, weak) id<S3ConnectionInfoDelegate> delegate;
@property (nonatomic, readwrite) BOOL secureConnection;
@property (nonatomic, readwrite) NSUInteger portNumber;
@property (nonatomic, readwrite) NSString* hostEndpoint;
@property (nonatomic, readwrite) BOOL virtuallyHosted;
@property (nonatomic, readwrite) NSDictionary* userInfo;

@end

@implementation S3ConnectionInfo
- (id)initWithDelegate:(id<S3ConnectionInfoDelegate>)delegate userInfo:(id)userInfo secureConnection:(BOOL)secureConnection portNumber:(NSUInteger)portNumber virtuallyHosted:(BOOL)virtuallyHosted hostEndpoint:(NSString *)hostEndpoint
{
    if ((self = [super init])) {
        if (delegate == nil) {
            return nil;
        }
        
        _delegate = delegate;
        _userInfo = userInfo;
        _secureConnection = secureConnection;
        _portNumber = portNumber;
        _virtuallyHosted = virtuallyHosted;
        _hostEndpoint = hostEndpoint;
        
        if (portNumber == 0) {
            if (secureConnection) {
                _portNumber = S3DefaultInsecurePortInteger;
            } else {
                _portNumber = S3DefaultSecurePortInteger;
            }
        }
    }
    return self;
}

- (id)initWithDelegate:(id<S3ConnectionInfoDelegate>)delegate userInfo:(id)userInfo secureConnection:(BOOL)secureConnection portNumber:(NSUInteger)portNumber virtuallyHosted:(BOOL)virtuallyHosted
{
    return [self initWithDelegate:delegate userInfo:userInfo secureConnection:secureConnection portNumber:portNumber virtuallyHosted:virtuallyHosted hostEndpoint:S3DefaultHostString];
}

- (id)initWithDelegate:(id<S3ConnectionInfoDelegate>)delegate userInfo:(id)userInfo secureConnection:(BOOL)secureConnection portNumber:(NSUInteger)portNumber
{
    return [self initWithDelegate:delegate userInfo:userInfo secureConnection:secureConnection portNumber:portNumber virtuallyHosted:YES];
}

- (id)initWithDelegate:(id<S3ConnectionInfoDelegate>)delegate userInfo:(id)userInfo secureConnection:(BOOL)secureConnection
{
    return [self initWithDelegate:delegate userInfo:userInfo secureConnection:secureConnection portNumber:0];
}

- (id)initWithDelegate:(id<S3ConnectionInfoDelegate>)delegate userInfo:(id)userInfo
{
    return [self initWithDelegate:delegate userInfo:userInfo secureConnection:NO];
}

- (id)initWithDelegate:(id<S3ConnectionInfoDelegate>)delegate
{
    return [self initWithDelegate:delegate userInfo:nil];    
}

- (id)init
{
    return [self initWithDelegate:nil];
}

// Create a CFHTTPMessageRef from an operation; object returned has a retain count of 1
// and must be released by the receiver when finished using the object.
- (CFHTTPMessageRef)newCFHTTPMessageRefFromOperation:(S3Operation *)operation
{
    // This process can not go forward without a delegate
    if (self.delegate == nil) {
        return NULL;
    }

    // Build string to sign

    // HTTP Verb + '\n' +
    // Content MD5 + '\n' +
    // Content Type + '\n' +
    // Date + '\n' +
    // CanonicalizedAmzHeaders +
    // CanonicalizedResourse;
    
    NSMutableString *stringToSign = [NSMutableString string];
    [stringToSign appendFormat:@"%@\n", ([operation requestHTTPVerb] ? [operation requestHTTPVerb] : @"")];
    
    NSString *md5 = [[operation additionalHTTPRequestHeaders] objectForKey:S3ObjectMetadataContentMD5Key];
    if (md5 == nil) {
        md5 = [operation requestBodyContentMD5];
    }
    [stringToSign appendFormat:@"%@\n", (md5 ? md5 : @"")];
    
    NSString *contentType = [[operation additionalHTTPRequestHeaders] objectForKey:S3ObjectMetadataContentTypeKey];
    if (contentType == nil) {
        contentType = [operation requestBodyContentType];
    }
    [stringToSign appendFormat:@"%@\n", (contentType ? contentType : @"")];
    
    [stringToSign appendFormat:@"%@\n", [[operation date] descriptionWithCalendarFormat:@"%a, %d %b %Y %H:%M:%S %z"]];
    
    // Work out the Canonicalized Amz Headers
    NSEnumerator *e = [[[[operation additionalHTTPRequestHeaders] allKeys] sortedArrayUsingSelector:@selector(compare:)] objectEnumerator];
    NSString *key = nil;
	while (key = [e nextObject])
	{
		id object = [[operation additionalHTTPRequestHeaders] objectForKey:key];
        NSString *lowerCaseKey = [key lowercaseString];
		if ([key hasPrefix:S3HeaderPrefixString]) {
			[stringToSign appendFormat:@"%@:%@\n", lowerCaseKey, object];            
        }
	}    
    
    // Work out the Canonicalized Resource
    NSURL *requestURL = [operation url];
    NSString *requestQuery = [requestURL query];
    NSString *requestPath = (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (CFStringRef)[requestURL path], NULL, (CFStringRef)@"[]#%?,$+=&@:;()'*!", kCFStringEncodingUTF8));
    NSString *absoluteString = [requestURL absoluteString];
    if (requestQuery != nil) {
        NSString *withoutQuery = [absoluteString stringByReplacingOccurrencesOfString:requestQuery withString:@""];
        if ([requestPath hasSuffix:@"/"] == NO && [withoutQuery hasSuffix:@"/?"] == YES) {
            requestPath = [NSString stringWithFormat:@"%@/", requestPath];            
        }
    } else if ([requestPath hasSuffix:@"/"] == NO && [absoluteString hasSuffix:@"/"] == YES) {
        requestPath = [NSString stringWithFormat:@"%@/", requestPath];
    }
    
    if (([operation isRequestOnService] == NO) && ([self virtuallyHosted] == YES) && [operation virtuallyHostedCapable]) {
        requestPath = [NSString stringWithFormat:@"/%@%@", [operation bucketName], requestPath];
    }
    
    [stringToSign appendString:requestPath];
    
    if ([[requestURL query] hasPrefix:@"acl"]) {
        [stringToSign appendString:@"?acl"];
    } else if ([[requestURL query] hasPrefix:@"torrent"]) {
        [stringToSign appendString:@"?torrent"];        
    } else if ([[requestURL query] hasPrefix:@"location"]) {
        [stringToSign appendString:@"?location"];        
    } else if ([[requestURL query] hasPrefix:@"logging"]) {
        [stringToSign appendString:@"?logging"];
    }
    
    CFHTTPMessageRef httpRequest = NULL;
    NSString *authorization = nil;
    
    // Sign or send this string off to be signed.
    // Check first to see if the delegate implements
    // - (NSString *)accessKeyForConnectionInfo:(S3ConnectionInfo *)connectionInfo;
    // - (NSString *)secretAccessKeyForConnectionInfo:(S3ConnectionInfo *)connectionInfo;
    if ([self.delegate respondsToSelector:@selector(accessKeyForConnectionInfo:)] && [self.delegate respondsToSelector:@selector(secretAccessKeyForConnectionInfo:)]) {
        NSString *accessKey = [self.delegate accessKeyForConnectionInfo:self];
        NSString *secretAccessKey = [self.delegate secretAccessKeyForConnectionInfo:self];
        
        if (accessKey == nil || secretAccessKey == nil) {
            return NULL;
        }
        
        NSString *signature = [[[[stringToSign dataUsingEncoding:NSUTF8StringEncoding] sha1HMacWithKey:secretAccessKey] encodeBase64] substringWithRange:NSMakeRange(5, 10)];
        secretAccessKey = nil;
        authorization = [NSString stringWithFormat:@"SINA %@:%@", accessKey, signature];
        
    } else if ([self.delegate respondsToSelector:@selector(connectionInfo:authorizationHeaderForRequestHeader:)]) {
        authorization = [self.delegate connectionInfo:self authorizationHeaderForRequestHeader:stringToSign];
    } else {
        // The required delegate methods are not present.
        return NULL;
    }
    
    httpRequest = CFHTTPMessageCreateRequest(kCFAllocatorDefault, (__bridge CFStringRef)[operation requestHTTPVerb], (__bridge CFURLRef)requestURL, kCFHTTPVersion1_1);
    e = [[[operation additionalHTTPRequestHeaders] allKeys] objectEnumerator];
    key = nil;
	while (key = [e nextObject])
	{
		id object = [[operation additionalHTTPRequestHeaders] objectForKey:key];
        CFHTTPMessageSetHeaderFieldValue(httpRequest, (__bridge CFStringRef)key, (__bridge CFStringRef)[NSString stringWithFormat:@"%@", object]);
	}
    
    if ([[operation additionalHTTPRequestHeaders] objectForKey:S3ObjectMetadataContentLengthKey] == nil) {
        NSNumber *contentLength = [NSNumber numberWithLongLong:[operation requestBodyContentLength]];
        CFHTTPMessageSetHeaderFieldValue(httpRequest, (__bridge CFStringRef)S3ObjectMetadataContentLengthKey, (__bridge CFStringRef)[contentLength stringValue]);
    }
    
    if ([[operation additionalHTTPRequestHeaders] objectForKey:S3ObjectMetadataContentTypeKey] == nil) {
        if (contentType != nil) {
            CFHTTPMessageSetHeaderFieldValue(httpRequest, (__bridge CFStringRef)S3ObjectMetadataContentTypeKey, (__bridge CFStringRef)contentType);
        }
    }
    
    if ([[operation additionalHTTPRequestHeaders] objectForKey:S3ObjectMetadataContentMD5Key] == nil) {
        if (md5 != nil) {
            CFHTTPMessageSetHeaderFieldValue(httpRequest, (__bridge CFStringRef)S3ObjectMetadataContentMD5Key, (__bridge CFStringRef)md5);
        }
    }
    
    // Add the "Expect: 100-continue" header
    CFHTTPMessageSetHeaderFieldValue(httpRequest, (CFStringRef)@"Expect", (CFStringRef)@"100-continue");
    
    CFHTTPMessageSetHeaderFieldValue(httpRequest, (CFStringRef)@"Date", (__bridge CFStringRef)[[operation date] descriptionWithCalendarFormat:@"%a, %d %b %Y %H:%M:%S %z"]);
    CFHTTPMessageSetHeaderFieldValue(httpRequest, (CFStringRef)@"Authorization", (__bridge CFStringRef)authorization);

    
    return httpRequest;
}

#pragma mark -
#pragma mark Copying Protocol Methods

- (id)copyWithZone:(NSZone *)zone
{
    S3ConnectionInfo *newObject = [[S3ConnectionInfo allocWithZone:zone] initWithDelegate:self.delegate
                                                                                 userInfo:self.userInfo
                                                                         secureConnection:self.secureConnection
                                                                               portNumber:self.portNumber
                                                                          virtuallyHosted:self.virtuallyHosted
                                                                             hostEndpoint:self.hostEndpoint];
    return newObject;
}

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

#pragma mark -
#pragma mark Equality Methods

- (BOOL)isEqual:(id)anObject
{
    if (anObject && [anObject isKindOfClass:[S3ConnectionInfo class]])
    {
        if ([(S3ConnectionInfo *)anObject delegate] == [self delegate] &&
            (([anObject userInfo] == nil && [self userInfo] == nil) || 
             [[anObject userInfo] isEqual:[self userInfo]]) &&
            [anObject secureConnection] == [self secureConnection] &&
            [anObject portNumber] == [self portNumber] &&
            [anObject virtuallyHosted] == [self virtuallyHosted] &&
            (([anObject hostEndpoint] == nil && [self hostEndpoint] == nil) || 
             [[anObject hostEndpoint] isEqual:[self hostEndpoint]])) {
            return YES;
        }
    }
    
    return NO;
}

- (NSUInteger)hash
{
    NSUInteger value = 0;
    
    value += value * 37 + (NSUInteger)[self delegate];
    value += value * 37 + [[self userInfo] hash];
    value += value * 37 + ([self secureConnection] ? 1 : 2);

// For the most part these are redundent, but can be uncommented if deemed worthy later.
//    value += value * 37 + [self portNumber];
//    value += value * 37 + ([self virtuallyHosted] ? 1 : 2);
//    value += value * 37 + [[self hostEndpoint] hash];

    return value;
}

#pragma mark -
#pragma mark Description Method

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %#x -\n delegate:%#x\n userInfo:%@\n secureConnection:%d\n portNumber:%lu\n virtuallyHosted:%d\n hostEndpoint:%@\n>", [self class], (unsigned int)self, (unsigned int)[self delegate], [self userInfo], [self secureConnection], (unsigned long)[self portNumber], [self virtuallyHosted], [self hostEndpoint]];
}

@end
