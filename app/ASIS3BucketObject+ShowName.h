//
//  ASIS3BucketObject+ShowName.h
//  SCS-Objc
//
//  Created by Littlebox222 on 14-6-9.
//
//

#import <ASIKit/ASIKit.h>

@interface ASIS3BucketObject (ShowName)

@property (retain, readonly) NSString *showName;
@property (retain) NSString *prefix;

- (NSString *)showName;

- (NSString *)prefix;
- (void)setPrefix:(NSString *)aPrefix;

@end
