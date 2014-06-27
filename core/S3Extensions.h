//
//  S3Extensions.h
//  S3-Objc
//
//  Created by Bruce Chen on 3/31/06.
//  Modernized by Martin Hering on 07/14/12
//  Copyright 2014 Bruce Chen. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSString (Comfort)

- (long long)longLongValue;

@end


@interface NSMutableDictionary (Comfort)

- (void)safeSetObject:(id)o forKey:(NSString *)k;
- (void)safeSetObject:(id)o forKey:(NSString *)k withValueForNil:(id)d;

@end

@interface NSArray (Comfort)

- (NSArray *)expandPaths;
- (BOOL)hasObjectSatisfying:(SEL)aSelector withArgument:(id)argument;

@end

@interface NSDictionary (URL)

-(NSString *)queryString;

@end

@interface NSXMLElement (Comfort)

-(NSXMLElement *)elementForName:(NSString *)n;
-(NSNumber *)longLongNumber;
-(NSNumber *)boolNumber;
-(NSDate *)dateValue;

@end


@interface NSData (OpenSSLWrapper)

- (NSData *)md5Digest;
- (NSData *)sha1Digest;
- (NSData *)sha1HMacWithKey:(NSString*)key;

- (NSString *)encodeBase64;
- (NSString *)encodeBase64WithNewlines: (BOOL)encodeWithNewlines;

@end

@interface NSString (OpenSSLWrapper)

- (NSData *) decodeBase64;
- (NSData *) decodeBase64WithNewlines:(BOOL)encodedWithNewlines;

- (NSNumber*)fileSizeForPath;
- (NSString*)mimeTypeForPath;
- (NSString*)readableSizeForPath;
+ (NSString*)readableSizeForPaths:(NSArray*)files;
+ (NSString*)readableFileSizeFor:(unsigned long long) size;

+ (NSString*)commonPrefixWithStrings:(NSArray*)strings;
+ (NSString*)commonPathComponentInPaths:(NSArray*)paths;

@end

@interface NSNumber (Comfort)

-(NSString*)readableFileSize;

@end

@interface NSString (URL)

- (NSString *)stringByEscapingHTTPReserved;

@end


@interface NSString (Date)

- (NSDate *)dateValue;

@end

@interface NSString (FormatJSON)

- (NSString *)formatJSON;

@end

@interface NSData (ResponseDataFormatter)

- (NSString *)jsonString;
- (NSString *)formatteredJson;

@end