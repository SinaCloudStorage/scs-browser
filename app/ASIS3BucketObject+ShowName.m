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
static char iconKey;

- (NSString *)showName {
    
    if (self.prefix == nil || [self.prefix isEqualToString:@""]) {
        return [self key];
    }else {
        NSString *name = [self key];
        return [name substringFromIndex:[self.prefix length]];
    }
}

- (void)setPrefix:(NSString *)aPrefix {
    objc_setAssociatedObject(self, &prefixKey, aPrefix, OBJC_ASSOCIATION_RETAIN);
}

- (NSString *)prefix {
    return objc_getAssociatedObject(self, &prefixKey);
}



- (void)setIcon:(NSImage *)image {
    objc_setAssociatedObject(self, &iconKey, image, OBJC_ASSOCIATION_RETAIN);
}

- (NSImage *)icon {
    return objc_getAssociatedObject(self, &iconKey);
}

@end
