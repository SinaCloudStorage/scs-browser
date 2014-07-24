//
//  LogObject.m
//  SCS-Objc
//
//  Created by Littlebox222 on 14-7-7.
//
//

#import "LogObject.h"

@implementation LogObject

@synthesize showKind = _showKind;
@synthesize showStatus = _showStatus;
@synthesize showSubStatus = _showSubStatus;

@synthesize showUrl = _showUrl;
@synthesize showRequestMethod = _showRequestMethod;
@synthesize showResponseData = _showResponseData;
@synthesize requestID = _requestID;
@synthesize showRequestHeaders = _showRequestHeaders;
@synthesize showResponseHeaders = _showResponseHeaders;
@synthesize showResponseStatusCode = _showResponseStatusCode;

@synthesize request = _request;

- (id)initWithRequest:(ASIS3Request *)request {
    
    self = [super init];
    
    if (self) {
        self.request = request;
    }
    
    return self;
}

- (void)update {
    
    [self setShowKind:[_request showKind]];
    [self setShowStatus:[_request showStatus]];
    [self setShowSubStatus:[_request showSubStatus]];
    [self setShowUrl:[_request showUrl]];
    [self setShowRequestMethod:[_request showRequestMethod]];
    [self setShowResponseData:[_request responseData]];
    [self setShowRequestHeaders:[_request requestHeaders]];
    [self setShowResponseHeaders:[_request responseHeaders]];
    [self setShowResponseStatusCode:[_request responseStatusCode]];
}

- (void)setShowKind:(NSString *)inKind {
    _showKind = inKind;
}

- (NSString *)showKind {
    return _showKind;
}

- (void)setShowStatus:(NSString *)inStatus {
    _showStatus = inStatus;
}

- (NSString *)showStatus {
    return _showStatus;
}

- (void)setShowSubStatus:(NSString *)inSubStatus {
    _showSubStatus = inSubStatus;
}

- (NSString *)showSubStatus {
    return _showSubStatus;
}

- (void)setShowUrl:(NSURL *)inUrl {
    _showUrl = inUrl;
}

- (NSURL *)showUrl {
    return _showUrl;
}

- (void)setShowRequestMethod:(NSString *)inRequestMethod {
    _showRequestMethod = inRequestMethod;
}

- (NSString *)showRequestMethod {
    return _showRequestMethod;
}

- (void)setShowResponseData:(NSData *)inResponseData {
    _showResponseData = inResponseData;
}

- (NSData *)showResponseData {
    return _showResponseData;
}

- (void)setShowRequestHeaders:(NSDictionary *)showRequestHeaders {
    _showRequestHeaders = showRequestHeaders;
}

- (NSDictionary *)showRequestHeaders {
    return _showRequestHeaders;
}

- (void)setShowResponseHeaders:(NSDictionary *)showResponseHeaders {
    _showResponseHeaders = showResponseHeaders;
}

- (NSDictionary *)showResponseHeaders {
    return _showResponseHeaders;
}

- (void)setShowResponseStatusCode:(int)showResponseStatusCode {
    _showResponseStatusCode = showResponseStatusCode;
}

- (int)showResponseStatusCode {
    return _showResponseStatusCode;
}

@end
