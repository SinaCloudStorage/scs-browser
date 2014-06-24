//
//  ASIS3BucketObject+ShowName.m
//  SCS-Objc
//
//  Created by Littlebox222 on 14-6-9.
//
//

#import <objc/runtime.h>
#import "ASIS3BucketObject+ShowName.h"



@implementation ASIS3BucketObject (ShowName)

static char prefixKey;

- (NSString *)showName {
    
    return [[self key] stringByReplacingOccurrencesOfString:self.prefix == nil? @"":self.prefix withString:@""];;
}

- (void)setPrefix:(NSString *)aPrefix {
    
    objc_setAssociatedObject(self, &prefixKey, aPrefix, OBJC_ASSOCIATION_RETAIN);
}

- (NSString *)prefix {
    
    return objc_getAssociatedObject(self, &prefixKey);
}

@end