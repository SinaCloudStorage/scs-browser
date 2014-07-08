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
static char logObjectKey;

- (void)setLogObject:(LogObject *)logObject {
    objc_setAssociatedObject(self, &logObjectKey, logObject, OBJC_ASSOCIATION_ASSIGN);
}

- (LogObject *)logObject {
    return objc_getAssociatedObject(self, &logObjectKey);
}

- (void)setShowTransferedBytes:(NSString *)inTransferedBytes {
    objc_setAssociatedObject(self, &transferedBytesKey, inTransferedBytes, OBJC_ASSOCIATION_RETAIN);
}

- (NSString *)showTransferedBytes {
    return objc_getAssociatedObject(self, &transferedBytesKey);
}


- (void)setShowResumeDownloadedFileSize:(NSString *)inResumeDownloadedFileSize {
    objc_setAssociatedObject(self, &resumeDownloadedFileSizeKey, inResumeDownloadedFileSize, OBJC_ASSOCIATION_RETAIN);
}

- (NSString *)showResumeDownloadedFileSize {
    return objc_getAssociatedObject(self, &resumeDownloadedFileSizeKey);
}


- (void)setShowKind:(NSString *)inKind {
    objc_setAssociatedObject(self, &kindKey, inKind, OBJC_ASSOCIATION_RETAIN);
}

- (NSString *)showKind {
    return objc_getAssociatedObject(self, &kindKey);
}


- (void)setShowStatus:(NSString *)inStatus {
    objc_setAssociatedObject(self, &statusKey, inStatus, OBJC_ASSOCIATION_RETAIN);
}

- (NSString *)showStatus {
    return objc_getAssociatedObject(self, &statusKey);
}


- (void)setShowSubStatus:(NSString *)inSubStatus {
    objc_setAssociatedObject(self, &subStatusKey, inSubStatus, OBJC_ASSOCIATION_RETAIN);
}

- (NSString *)showSubStatus {
    return objc_getAssociatedObject(self, &subStatusKey);
}


- (void)setShowUrl:(NSURL *)inUrl {
    objc_setAssociatedObject(self, &urlKey, inUrl, OBJC_ASSOCIATION_RETAIN);
}

- (NSURL *)showUrl {
    return objc_getAssociatedObject(self, &urlKey);
}


- (void)setShowRequestMethod:(NSString *)inRequestMethod {
    objc_setAssociatedObject(self, &requestMethodKey, inRequestMethod, OBJC_ASSOCIATION_RETAIN);
}

- (NSString *)showRequestMethod {
    return objc_getAssociatedObject(self, &requestMethodKey);
}


@end
