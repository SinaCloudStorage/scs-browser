//
//  LogObject.h
//  SCS-Objc
//
//  Created by Littlebox222 on 14-7-7.
//
//

#import <Foundation/Foundation.h>

#import <ASIKit/ASIKit.h>
#import "ASIS3Request+showValue.h"

@interface LogObject : NSObject

@property (nonatomic, retain) NSString *showKind;
@property (nonatomic, retain) NSString *showStatus;
@property (nonatomic, retain) NSString *showSubStatus;

@property (nonatomic, retain) NSURL *showUrl;
@property (nonatomic, retain) NSString *showRequestMethod;
@property (nonatomic, retain) NSData *showResponseData;
@property (nonatomic, retain) NSNumber *requestID;
@property (nonatomic, retain) NSDictionary *showRequestHeaders;
@property (nonatomic, retain) NSDictionary *showResponseHeaders;
@property (nonatomic) int showResponseStatusCode;

@property (nonatomic, strong) ASIS3Request *request;

- (id)initWithRequest:(ASIS3Request *)request;
- (void)update;

- (void)setShowKind:(NSString *)inKind;
- (NSString *)showKind;

- (void)setShowStatus:(NSString *)inStatus;
- (NSString *)showStatus;

- (void)setShowSubStatus:(NSString *)inSubStatus;
- (NSString *)showSubStatus;

- (void)setShowUrl:(NSURL *)inUrl;
- (NSURL *)showUrl;

- (void)setShowRequestMethod:(NSString *)inRequestMethod;
- (NSString *)showRequestMethod;

- (void)setShowResponseData:(NSData *)inResponseData;
- (NSData *)showResponseData;

- (void)setShowRequestHeaders:(NSDictionary *)showRequestHeaders;
- (NSDictionary *)showRequestHeaders;

- (void)setShowResponseHeaders:(NSDictionary *)showResponseHeaders;
- (NSDictionary *)showResponseHeaders;

- (void)setShowResponseStatusCode:(int)showResponseStatusCode;
- (int)showResponseStatusCode;

@end
