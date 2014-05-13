//
//  S3ConnInfo.h
//  SCS-Objc
//
//  Created by Bruce on 14-5-13.
//
//

#import <Foundation/Foundation.h>

@protocol S3ConnInfoDelegate;

@interface S3ConnInfo : NSObject <NSCopying, NSMutableCopying>

- (id)initWithDelegate:(id<S3ConnInfoDelegate>)delegate;
- (id)initWithDelegate:(id<S3ConnInfoDelegate>)delegate userInfo:(id)userInfo;
- (id)initWithDelegate:(id<S3ConnInfoDelegate>)delegate userInfo:(id)userInfo secureConn:(BOOL)secureConn;

@property (nonatomic, readonly, weak) id<S3ConnInfoDelegate> delegate;
@property (nonatomic, readonly) BOOL secureConn;
@property (nonatomic, readonly) NSDictionary *userInfo;

@end



@protocol S3ConnInfoDelegate <NSObject>

@optional

- (NSString *)accessKeyForConnInfo:(S3ConnInfo *)connInfo;
- (NSString *)secretAccessKeyForConnInfo:(S3ConnInfo *)connInfo;

@end
