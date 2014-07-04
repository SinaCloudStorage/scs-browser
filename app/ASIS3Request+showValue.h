//
//  ASIS3Request+showValue.h
//  SCS-Objc
//
//  Created by Littlebox222 on 14-7-3.
//
//

#import <ASIKit/ASIKit.h>

@interface ASIS3Request (showValue)

@property (nonatomic, retain) NSString *showTransferedBytes;
@property (nonatomic, retain) NSString *showResumeDownloadedFileSize;
@property (nonatomic, retain) NSString *showKind;
@property (nonatomic, retain) NSString *showStatus;
@property (nonatomic, retain) NSString *showSubStatus;
@property (nonatomic, retain) NSURL *showUrl;
@property (nonatomic, retain) NSString *showRequestMethod;


- (void)setShowTransferedBytes:(NSString *)inTransferedBytes;
- (NSString *)showTransferedBytes;

- (void)setShowResumeDownloadedFileSize:(NSString *)inResumeDownloadedFileSize;
- (NSString *)showResumeDownloadedFileSize;

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

@end
