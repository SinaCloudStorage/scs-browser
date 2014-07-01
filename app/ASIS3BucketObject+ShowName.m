//
//  ASIS3BucketObject+ShowName.m
//  SCS-Objc
//
//  Created by Littlebox222 on 14-6-9.
//
//

#import <objc/runtime.h>
#import "ASIS3BucketObject+ShowName.h"
#import "S3Extensions.h"



@implementation ASIS3BucketObject (ShowName)

static char prefixKey;
static char iconKey;
static char objectTypeKey;

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




- (NSString *)objetType {
    return objc_getAssociatedObject(self, &objectTypeKey);
}

- (void)setObjetType:(NSString *)type {
    objc_setAssociatedObject(self, &objectTypeKey, type, OBJC_ASSOCIATION_RETAIN);
}




- (NSString *)readableSize {
    
    if ([self.objetType isEqualToString:@"directory"]) {
        return @"--";
    }else if ([self.objetType isEqualToString:@"file"]) {
        return [NSString readableFileSizeFor:self.size];
    }else {
        return @"";
    }
}

@end
