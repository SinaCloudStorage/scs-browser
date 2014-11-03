//
//  S3ActiveWindowController.m
//  S3-Objc
//
//  Created by Development Account on 9/3/06.
//  Copyright 2014 Bruce Chen. All rights reserved.
//

#import "S3ActiveWindowController.h"

#import "S3ConnectionInfo.h"
#import "S3MutableConnectionInfo.h"
#import "S3ApplicationDelegate.h"
#import "S3Operation.h"
#import "S3OperationQueue.h"
#import "S3OperationLog.h"
#import "S3OperationController.h"

#import "ASIS3Request+showValue.h"

#define NumberOfTimesToRetryOnTimeout   3

@interface S3ActiveWindowController ()

@end

@implementation S3ActiveWindowController

- (void)awakeFromNib
{
    _logObjects = [[NSMutableArray alloc] init];
    _operations = [[NSMutableArray alloc] init];
    _redirectConnectionInfoMappings = [[NSMutableDictionary alloc] init];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(asiS3RequestStateDidChange:) name:ASIS3RequestStateDidChangeNotification object:nil];
    
    [[(S3ApplicationDelegate *)[NSApp delegate] networkQueue] setUploadProgressDelegate:self];
    [[(S3ApplicationDelegate *)[NSApp delegate] networkQueue] setDownloadProgressDelegate:self];
    [[(S3ApplicationDelegate *)[NSApp delegate] networkQueue] setShowAccurateProgress:YES];
}

#pragma mark -
#pragma mark S3OperationQueue Notifications

//- (void)operationQueueOperationStateDidChange:(NSNotification *)notification
//{
//    S3Operation *operation = [[notification userInfo] objectForKey:S3OperationObjectKey];
//    NSUInteger index = [_operations indexOfObjectIdenticalTo:operation];
//    if (index == NSNotFound) {
//        return;
//    }
//        
//    if ([operation state] == S3OperationCanceled || [operation state] == S3OperationRequiresRedirect || [operation state] == S3OperationDone) {
//        [_operations removeObjectAtIndex:index];
//        [[[NSApp delegate] operationLog] unlogOperation:operation];
//    }
//    
//    if ([operation state] == S3OperationRequiresRedirect) {
//        /*
//        NSData *operationResponseData = [operation responseData];
//        NSError *error = nil;
//        NSXMLDocument *d = [[NSXMLDocument alloc] initWithData:operationResponseData options:NSXMLDocumentTidyXML error:&error];
//        if (error) {
//            return;
//        }
//        
//        NSArray *buckets = [[d rootElement] nodesForXPath:@"//Bucket" error:&error];
//        if (error) {
//            return;
//        }
//        NSString *bucketName = nil;
//        if ([buckets count] == 1) {
//            bucketName = [[buckets objectAtIndex:0] stringValue];
//            bucketName = [NSString stringWithFormat:@"%@.", bucketName];
//        }
//        
//        NSArray *endpoints = [[d rootElement] nodesForXPath:@"//Endpoint" error:&error];
//        NSString *endpoint = nil;
//        if ([endpoints count] == 1) {
//            endpoint = [[endpoints objectAtIndex:0] stringValue];
//        }
//        
//        
//        if (bucketName && endpoint) {
//            NSRange bucketNameInEndpointRange = [endpoint rangeOfString:bucketName];
//            if (NSEqualRanges(bucketNameInEndpointRange, NSMakeRange(NSNotFound, 0))) {
//                return;
//            }
//            NSString *pureEndpoint = [endpoint stringByReplacingCharactersInRange:bucketNameInEndpointRange withString:@""];
//            NSDictionary *operationInfo = [[operation operationInfo] copy];
//            S3ConnectionInfo *operationConnectionInfo = [operation connectionInfo];
//            S3MutableConnectionInfo *redirectConnectionInfo = [operationConnectionInfo mutableCopy];
//            [redirectConnectionInfo setHostEndpoint:pureEndpoint];
//            [redirectConnectionInfo setDelegate:self];
//            
//            [_redirectConnectionInfoMappings setObject:operationConnectionInfo forKey:redirectConnectionInfo];
//            
//            S3Operation *replacementOperation = [[[operation class] alloc] initWithConnectionInfo:redirectConnectionInfo operationInfo:operationInfo];
//            
//            [self addToCurrentOperations:replacementOperation];
//        } 
//         */
//    }
//    
//    if ([_redirectConnectionInfoMappings objectForKey:[operation connectionInfo]]) {
//        NSInteger activeConnectionInfos = 0;
//        for (S3Operation *currentOperation in _operations) {
//            if ([[currentOperation connectionInfo] isEqual:[operation connectionInfo]]) {
//                activeConnectionInfos++;
//            }
//        }
//        if (activeConnectionInfos == 1) {
//            [_redirectConnectionInfoMappings removeObjectForKey:[operation connectionInfo]];            
//        }
//    }    
//}

#pragma mark -

- (BOOL)hasActiveOperations
{
	return ([_operations count] > 0);
}

- (S3ConnectionInfo *)connectionInfo
{
    return _connectionInfo; 
}

- (void)setConnectionInfo:(S3ConnectionInfo *)aConnectionInfo
{
    _connectionInfo = aConnectionInfo;
}


#pragma mark -

- (S3ConnInfo *)connInfo
{
    return _connInfo;
}

- (void)setConnInfo:(S3ConnInfo *)aConnInfo
{
    _connInfo = aConnInfo;
}

- (void)addOperations {
    
    LogObject *obj = nil;
    
    for (ASIS3Request *o in _operations) {
        
        obj = [[LogObject alloc] initWithRequest:o];
        [o setLogObject:obj];
        [obj update];
        
        [_logObjects addObject:obj];
    }
    
    [self commit];
}

- (void)commit {
    
    [[(S3ApplicationDelegate *)[NSApp delegate] operationLog] logOperations:_logObjects];
    
    for (ASIS3Request *o in _operations) {
        if ([self configureRequest:o]) {
            
            if ([[o showKind] isEqualToString:ASIS3RequestListObject]) {
                [[(S3ApplicationDelegate *)[NSApp delegate] networkRefreshQueue] addOperation:o];
            }else {
                [[(S3ApplicationDelegate *)[NSApp delegate] networkQueue] addOperation:o];
            }
        }
    }
    
    [_logObjects removeAllObjects];
    [_operations removeAllObjects];
    
    S3OperationController *controller = [[(S3ApplicationDelegate *)[NSApp delegate] controllers] objectForKey:@"Console"];
    [controller scrollToEnd];
}

- (BOOL)hasActiveRequest {
    
    return ([[(S3ApplicationDelegate *)[NSApp delegate] networkQueue] requestsCount] > 0) || ([[(S3ApplicationDelegate *)[NSApp delegate] networkRefreshQueue] requestsCount] > 0);
}

- (BOOL)configureRequest:(ASIS3Request *)request {
    
    if (request == nil) {
        return NO;
    }
    
    if ([[self connInfo] secureConn]) {
        [request setRequestScheme:ASIS3RequestSchemeHTTPS];
    }else {
        [request setRequestScheme:ASIS3RequestSchemeHTTP];
    }
    [request setNumberOfTimesToRetryOnTimeout:NumberOfTimesToRetryOnTimeout];
    
    if ([ASIS3Request sharedAccessKey] != nil && [ASIS3Request sharedSecretAccessKey] != nil) {
        return YES;
    }
    
    if ([self connInfo].delegate && [[[self connInfo] delegate] respondsToSelector:@selector(accessKeyForConnInfo:)]) {
        [ASIS3Request setSharedAccessKey:[[[self connInfo] delegate] accessKeyForConnInfo:[self connInfo]]];
    }
    
    if ([self connInfo].delegate && [[[self connInfo] delegate] respondsToSelector:@selector(secretAccessKeyForConnInfo:)]) {
        [ASIS3Request setSharedSecretAccessKey:[[[self connInfo] delegate] secretAccessKeyForConnInfo:[self connInfo]]];
    }
    
    return [ASIS3Request sharedAccessKey] && [ASIS3Request sharedSecretAccessKey] ? YES : NO;
}

- (void)updateRequest:(ASIS3Request *)request forState:(int)state {
    
    switch (state) {
            
        case ASIS3RequestPending:
            [request setShowStatus:RequestUserInfoStatusPending];
            break;
            
        case ASIS3RequestActive:
        case ASIS3RequestReceiveResponseHeaders:
            [request setShowStatus:RequestUserInfoStatusActive];
            break;
            
        case ASIS3RequestCanceled:
            [request setShowStatus:RequestUserInfoStatusCanceled];
            [request setShowSubStatus:[[[request error] userInfo] objectForKey:NSLocalizedDescriptionKey]];
            break;
            
        case ASIS3RequestDone:
            [request setShowStatus:RequestUserInfoStatusDone];
            [request setShowSubStatus:@""];
            break;
            
        case ASIS3RequestRequiresRedirect:
            [request setShowStatus:RequestUserInfoStatusRequiresRedirect];
            break;
            
        case ASIS3RequestError:
            [request setShowStatus:RequestUserInfoStatusError];
            
            if ([request error] != nil) {
                
                if ([request responseStatusMessage] != nil && [request responseStatusCode] == 413) {
                    [request setShowSubStatus:[request responseStatusMessage]];
                }else {
                    [request setShowSubStatus:[[[request error] userInfo] objectForKey:NSLocalizedDescriptionKey]];
                }
                
            }else if ([[request responseHeaders] objectForKey:@"x-error-code"] != nil) {
                [request setShowSubStatus:[[request responseHeaders] objectForKey:@"x-error-code"]];
            }else if ([request responseStatusMessage] != nil && ![[request showKind] isEqualToString:ASIS3RequestDownloadObject]) {
                [request setShowSubStatus:[request responseStatusMessage]];
            }else if ([[request showKind] isEqualToString:ASIS3RequestDownloadObject]) {
                [request setShowSubStatus:@"File damaged."];
            }
            break;
            
        default:
            break;
    }
    
    [[request logObject] update];
}

- (void)asiS3RequestStateDidChange:(NSNotification *)notification {
    
}

@end
