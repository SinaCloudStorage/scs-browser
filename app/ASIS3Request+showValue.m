//
//  ASIS3Request+showValue.m
//  SCS-Objc
//
//  Created by Littlebox222 on 14-7-3.
//
//

#import <objc/runtime.h>
#import "ASIS3Request+showValue.h"

@implementation ASIS3Request (showValue)

static char transferedBytesKey;
static char resumeDownloadedFileSizeKey;
static char kindKey;
static char statusKey;
static char subStatusKey;
static char urlKey;
static char requestMethodKey;

- (void)setShowTransferedBytes:(NSString *)inTransferedBytes {
    
    //[self willChangeValueForKey:@"showTransferedBytes"];
    objc_setAssociatedObject(self, &transferedBytesKey, inTransferedBytes, OBJC_ASSOCIATION_RETAIN);
    //[self didChangeValueForKey:@"showTransferedBytes"];
}

- (NSString *)showTransferedBytes {
    return objc_getAssociatedObject(self, &transferedBytesKey);
}


- (void)setShowResumeDownloadedFileSize:(NSString *)inResumeDownloadedFileSize {
    
    //[self willChangeValueForKey:@"showResumeDownloadedFileSize"];
    objc_setAssociatedObject(self, &resumeDownloadedFileSizeKey, inResumeDownloadedFileSize, OBJC_ASSOCIATION_RETAIN);
    //[self didChangeValueForKey:@"showResumeDownloadedFileSize"];
    
}

- (NSString *)showResumeDownloadedFileSize {
    return objc_getAssociatedObject(self, &resumeDownloadedFileSizeKey);
}


- (void)setShowKind:(NSString *)inKind {
    
    //[self willChangeValueForKey:@"showKind"];
    objc_setAssociatedObject(self, &kindKey, inKind, OBJC_ASSOCIATION_RETAIN);
    //[self didChangeValueForKey:@"showKind"];
}

- (NSString *)showKind {
    return objc_getAssociatedObject(self, &kindKey);
}


- (void)setShowStatus:(NSString *)inStatus {
    
    //[self willChangeValueForKey:@"showStatus"];
    objc_setAssociatedObject(self, &statusKey, inStatus, OBJC_ASSOCIATION_RETAIN);
    //[self didChangeValueForKey:@"showStatus"];
}

- (NSString *)showStatus {
    return objc_getAssociatedObject(self, &statusKey);
}


- (void)setShowSubStatus:(NSString *)inSubStatus {
    
    //[self willChangeValueForKey:@"showSubStatus"];
    objc_setAssociatedObject(self, &subStatusKey, inSubStatus, OBJC_ASSOCIATION_RETAIN);
    //[self didChangeValueForKey:@"showSubStatus"];
}

- (NSString *)showSubStatus {
    return objc_getAssociatedObject(self, &subStatusKey);
}


- (void)setShowUrl:(NSURL *)inUrl {
    
    //[self willChangeValueForKey:@"showUrl"];
    objc_setAssociatedObject(self, &urlKey, inUrl, OBJC_ASSOCIATION_RETAIN);
    //[self didChangeValueForKey:@"showUrl"];
}

- (NSURL *)showUrl {
    return objc_getAssociatedObject(self, &urlKey);
}


- (void)setShowRequestMethod:(NSString *)inRequestMethod {
    
    //[self willChangeValueForKey:@"showRequestMethod"];
    objc_setAssociatedObject(self, &requestMethodKey, inRequestMethod, OBJC_ASSOCIATION_RETAIN);
    //[self didChangeValueForKey:@"showRequestMethod"];
}

- (NSString *)showRequestMethod {
    return objc_getAssociatedObject(self, &requestMethodKey);
}


@end
