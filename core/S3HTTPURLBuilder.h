//
//  S3HTTPURLBuilder.h
//  S3-Objc
//
//  Created by Michael Ledford on 8/10/08.
//  Modernized by Martin Hering on 07/14/12
//  Copyright 2008 Michael Ledford. All rights reserved.
//

#import <Foundation/Foundation.h>

// The goal of this class is to have a decoupled
// uniformed way to build up HTTP NSURL's for Amazon S3.
// To achive a dynamic decoupled object S3HTTPUrlBuilder
// uses only delegate methods to obtain the information
// needed.
//
// This class is not intended as a generic URI builder.
//
// Strings returned from delegate methods should not
// be encoded as the class will handle that detail for you.

@protocol S3HTTPUrlBuilderDelegate;

@interface S3HTTPURLBuilder : NSObject

- (id)initWithDelegate:(id<S3HTTPUrlBuilderDelegate>)delegate;

@property (nonatomic, weak) id delegate;
@property (nonatomic, readonly) NSURL* url;

@end

@protocol S3HTTPUrlBuilderDelegate <NSObject>
@optional
- (NSString *)httpUrlBuilderWantsProtocolScheme:(S3HTTPURLBuilder *)urlBuilder;
- (NSString *)httpUrlBuilderWantsHost:(S3HTTPURLBuilder *)urlBuilder;
- (NSString *)httpUrlBuilderWantsKey:(S3HTTPURLBuilder *)urlBuilder; // Does not require '/' as its first char
- (NSDictionary *)httpUrlBuilderWantsQueryItems:(S3HTTPURLBuilder *)urlBuilder;
- (NSUInteger)httpUrlBuilderWantsPort:(S3HTTPURLBuilder *)urlBuilder;

@end