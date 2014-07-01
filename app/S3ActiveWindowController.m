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

@interface S3ActiveWindowController ()

@end

@implementation S3ActiveWindowController

- (void)awakeFromNib
{
    _operations = [[NSMutableArray alloc] init];
    _redirectConnectionInfoMappings = [[NSMutableDictionary alloc] init];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(asiS3RequestStateDidChange:) name:ASIS3RequestStateDidChangeNotification object:nil];
    
    [[[NSApp delegate] networkQueue] setUploadProgressDelegate:self];
    [[[NSApp delegate] networkQueue] setDownloadProgressDelegate:self];
    [[[NSApp delegate] networkQueue] setShowAccurateProgress:YES];
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

- (void)addToCurrentOperations:(S3Operation *)op
{
    /*
	if ([[[NSApp delegate] queue] addToCurrentOperations:op]) {
		[_operations addObject:op];
        [[[NSApp delegate] operationLog] logOperation:op];
    }
     */
}

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

- (void)addToCurrentNetworkQueue:(ASIS3Request *)request {
    
    if ([self configureRequest:request]) {
        
        [[[NSApp delegate] networkQueue] addOperation:request];
        [[[NSApp delegate] operationLog] logOperation:request];
        
        S3OperationController *controller = [[[NSApp delegate] controllers] objectForKey:@"Console"];
        [controller scrollToEnd];
    }
}

- (BOOL)hasActiveRequest {
    return ([[[NSApp delegate] networkQueue] requestsCount] > 0);
}

- (BOOL)configureRequest:(ASIS3Request *)request {
    
    if (request == nil) {
        return NO;
    }
    
    if ([self connInfo].delegate && [[[self connInfo] delegate] respondsToSelector:@selector(accessKeyForConnInfo:)]) {
        
        [request setAccessKey:[[[self connInfo] delegate] accessKeyForConnInfo:[self connInfo]]];
    }
    
    if ([self connInfo].delegate && [[[self connInfo] delegate] respondsToSelector:@selector(secretAccessKeyForConnInfo:)]) {
        
        [request setSecretAccessKey:[[[self connInfo] delegate] secretAccessKeyForConnInfo:[self connInfo]]];
    }
    
    return [request accessKey] && [request secretAccessKey] ? YES : NO;
}

- (void)updateRequest:(ASIS3Request *)request forState:(int)state {
    
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:[request userInfo]];
    
    switch (state) {
            
        case ASIS3RequestPending:
            [dict setValue:RequestUserInfoStatusPending forKey:RequestUserInfoStatusKey];
            break;
            
        case ASIS3RequestActive:
        case ASIS3RequestReceiveResponseHeaders:
            [dict setValue:RequestUserInfoStatusActive forKey:RequestUserInfoStatusKey];
            break;
            
        case ASIS3RequestCanceled:
            [dict setValue:RequestUserInfoStatusCanceled forKey:RequestUserInfoStatusKey];
            [dict setValue:[[[request error] userInfo] objectForKey:NSLocalizedDescriptionKey] forKey:RequestUserInfoSubStatusKey];
            break;
            
        case ASIS3RequestDone:
            [dict setValue:RequestUserInfoStatusDone forKey:RequestUserInfoStatusKey];
            [dict setValue:@"" forKey:RequestUserInfoSubStatusKey];
            break;
            
        case ASIS3RequestRequiresRedirect:
            [dict setValue:RequestUserInfoStatusRequiresRedirect forKey:RequestUserInfoStatusKey];
            break;
            
        case ASIS3RequestError:
            [dict setValue:RequestUserInfoStatusError forKey:RequestUserInfoStatusKey];
            
            if ([request error] != nil) {
                
                if ([request responseStatusMessage] != nil && [request responseStatusCode] == 413) {
                    [dict setValue:[request responseStatusMessage] forKey:RequestUserInfoSubStatusKey];
                }else {
                    [dict setValue:[[[request error] userInfo] objectForKey:NSLocalizedDescriptionKey] forKey:RequestUserInfoSubStatusKey];
                }
                
            }else if ([[request responseHeaders] objectForKey:@"x-error-code"] != nil) {
                [dict setValue:[[request responseHeaders] objectForKey:@"x-error-code"] forKey:RequestUserInfoSubStatusKey];
            }else if ([request responseStatusMessage] != nil) {
                [dict setValue:[request responseStatusMessage] forKey:RequestUserInfoSubStatusKey];
            }
            break;
            
        default:
            break;
    }
    
    [request setUserInfo:dict];
}

- (void)asiS3RequestStateDidChange:(NSNotification *)notification {
    
}

@end
