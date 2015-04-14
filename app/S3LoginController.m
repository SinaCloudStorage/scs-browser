//
//  S3LoginController.m
//  S3-Objc
//
//  Created by Bruce Chen on 4/7/06.
//  Copyright 2014 Bruce Chen. All rights reserved.
//

#import "S3ApplicationDelegate.h"
#import "S3LoginController.h"
#import "S3BucketListController.h"
#import "S3ListBucketOperation.h"
#import "S3OperationQueue.h"

#import "ASIS3Request+showValue.h"

#import <ASIKit/ASIKit.h>

// C-string, as it is only used in Keychain Services
#define S3_BROWSER_KEYCHAIN_SERVICE "S3 Browser"


@interface S3LoginController () <NSWindowDelegate>

- (NSString *)getS3SecretKeyFromKeychainForS3AccessKey:(NSString *)accesskey;
- (BOOL)setS3SecretKeyToKeychainForS3AccessKey:(NSString *)accesskey password:(NSString *)secretkey;
- (void)checkPasswordInKeychain;

@property (nonatomic) S3BucketListController* bucketListController;

@end

@implementation S3LoginController

#pragma mark -
#pragma mark Dealloc

- (void)dealloc
{
    [[(S3ApplicationDelegate *)[NSApp delegate] queue] removeQueueListener:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:ASIS3RequestStateDidChangeNotification object:nil];
}

#pragma mark -
#pragma mark General Methods

- (void)awakeFromNib
{
    if ([S3ActiveWindowController instancesRespondToSelector:@selector(awakeFromNib)] == YES) {
        [super awakeFromNib];
    }
	[[self window] setDefaultButtonCell:[_defaultButton cell]];
	[[self window] setDelegate:self];
    [[(S3ApplicationDelegate *)[NSApp delegate] queue] addQueueListener:self];
}

- (void)windowDidLoad
{
	NSString *defaultKey = [[NSUserDefaults standardUserDefaults] stringForKey:DEFAULT_USER];
	if (defaultKey != nil) {
		[self checkPasswordInKeychain];
	}
}

- (void)windowWillClose:(NSNotification *)aNotification
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:ASIS3RequestStateDidChangeNotification object:nil];
}

- (IBAction)flippedKeychainSupport:(id)sender;
{
	[self checkPasswordInKeychain];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	// The only thing we observe is access key to check password in keychain
	[self checkPasswordInKeychain];
}

//- (void)operationQueueOperationStateDidChange:(NSNotification *)notification
//{
//    S3Operation *operation = [[notification userInfo] objectForKey:S3OperationObjectKey];
//    NSUInteger index = [_operations indexOfObjectIdenticalTo:operation];
//    if (index == NSNotFound) {
//        return;
//    }
//
//    [super operationQueueOperationStateDidChange:notification];
//
//    if ([operation state] == S3OperationDone && [operation isKindOfClass:[S3ListBucketOperation class]]) {
//
//        if ([_keychainCheckbox state] == NSOnState) {
//            [self setS3SecretKeyToKeychainForS3AccessKey:accessKeyID password:secretAccessKeyID];
//        }
//        
//        self.bucketListController = [[S3BucketListController alloc] initWithWindowNibName:@"Buckets"];
//        
//        [self.bucketListController setConnectionInfo:[self connectionInfo]];
//        
//        [self.bucketListController showWindow:self];
//        [self.bucketListController setBuckets:[(S3ListBucketOperation *)operation bucketList]];
//        [self.bucketListController setBucketsOwner:[(S3ListBucketOperation*)operation owner]];
//
//        [self close];
//    }
//}

#pragma mark -
#pragma mark Actions

- (IBAction)connect:(id)sender
{
    accessKeyID = [(NSTextField *)[[self.window contentView] viewWithTag:110] stringValue];
    secretAccessKeyID = [(NSTextField *)[[self.window contentView] viewWithTag:111] stringValue];
    
    if (accessKeyID == nil || [accessKeyID length]<1 || secretAccessKeyID == nil || [secretAccessKeyID length] != 40) {
        
        NSAlert *alert = [NSAlert alertWithMessageText:@"请输入正确的 Access Key 与 Secret Key"
                                         defaultButton:@"Ok"
                                       alternateButton:nil
                                           otherButton:nil
                             informativeTextWithFormat:@"\n注册SCS成功后，可在网站控制台获取：\n\nhttp://open.sinastorage.com/?c=console"];
        
        [alert runModal];
        return;
    }
    
    NSDictionary *authDict = @{@"accessKey": accessKeyID, @"secretAccessKey": secretAccessKeyID};
    
    [(S3ApplicationDelegate *)[NSApp delegate] setAuthenticationCredentials:authDict forConnectionInfo:[self connInfo]];
    
    
    if ([self connInfo].delegate && [[[self connInfo] delegate] respondsToSelector:@selector(accessKeyForConnInfo:)]) {
        [ASIS3Request setSharedAccessKey:[[[self connInfo] delegate] accessKeyForConnInfo:[self connInfo]]];
    }
    
    if ([self connInfo].delegate && [[[self connInfo] delegate] respondsToSelector:@selector(secretAccessKeyForConnInfo:)]) {
        [ASIS3Request setSharedSecretAccessKey:[[[self connInfo] delegate] secretAccessKeyForConnInfo:[self connInfo]]];
    }
    
    ASIS3ServiceRequest *request = [ASIS3ServiceRequest serviceRequest];
    [request setShowKind:ASIS3RequestListBucket];
    [request setShowStatus:RequestUserInfoStatusPending];
    [_operations addObject:request];
    [self addOperations];
}

- (IBAction)openHelpPage:(id)sender
{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://open.sinastorage.com/"]];
}

#pragma mark -
#pragma mark Keychain integration

- (NSString *)getS3SecretKeyFromKeychainForS3AccessKey:(NSString *)accesskey
{
    if ([accesskey length] == 0) {
        return nil;
    }
    
    void *secretData = nil; // will be allocated and filled in by SecKeychainFindGenericPassword
    UInt32 secretLength = 0;
    
    NSString *secret = @"";
    const char *key = [accesskey UTF8String]; 
    
    OSStatus status;
    status = SecKeychainFindGenericPassword (NULL, // default keychain
                                             strlen(S3_BROWSER_KEYCHAIN_SERVICE), S3_BROWSER_KEYCHAIN_SERVICE,
                                             strlen(key), key,
                                             &secretLength, &secretData,
                                             nil);
    if (status==noErr) {
        secret = [[NSString alloc] initWithBytes:secretData length:secretLength encoding:NSUTF8StringEncoding];        
    }
    
    if (secretData) {
        
        SecKeychainItemFreeContent(NULL,secretData);
    }
    
    return secret;
}


- (BOOL)setS3SecretKeyToKeychainForS3AccessKey:(NSString *)accesskey password:(NSString *)secretkey
{
    const char *key = [accesskey UTF8String]; 
    const char *secret = [secretkey UTF8String]; 
    
    OSStatus status;
    status = SecKeychainAddGenericPassword(NULL, // default keychain
                                           strlen(S3_BROWSER_KEYCHAIN_SERVICE),S3_BROWSER_KEYCHAIN_SERVICE,
                                           strlen(key), key,
                                           strlen(secret), secret,
                                           nil);
    return (status==noErr);
}

- (void)checkPasswordInKeychain
{
	if ([_keychainCheckbox state] == NSOnState) {
        [self setValue:[self getS3SecretKeyFromKeychainForS3AccessKey:[[NSUserDefaults standardUserDefaults] stringForKey:DEFAULT_USER]] forKey:@"secretAccessKeyID"];
    }
}

#pragma mark - ASIS3RequestState NSNotification

- (void)asiS3RequestStateDidChange:(NSNotification *)notification {
    
    if (![[notification name] isEqualToString:ASIS3RequestStateDidChangeNotification]) {
        return;
    }
    
    ASIS3Request *request = [[notification userInfo] objectForKey:ASIS3RequestKey];
    ASIS3RequestState requestState = [[[notification userInfo] objectForKey:ASIS3RequestStateKey] unsignedIntegerValue];

    NSString *requestKind = [request showKind];
    
    if ([requestKind isEqualToString:ASIS3RequestListBucket]) {
        
        [self updateRequest:request forState:requestState];
        
        if (requestState == ASIS3RequestDone) {
            
            if ([_keychainCheckbox state] == NSOnState) {
                [[NSUserDefaults standardUserDefaults] setValue:accessKeyID forKey:DEFAULT_USER];
                [self setS3SecretKeyToKeychainForS3AccessKey:accessKeyID password:secretAccessKeyID];
            }
            
            self.bucketListController = [[S3BucketListController alloc] initWithWindowNibName:@"Buckets"];
            [[(S3ApplicationDelegate *)[NSApp delegate] controllers] setObject:self.bucketListController forKey:@"Buckets"];
            
            [self.bucketListController setConnInfo:[self connInfo]];
            [self.bucketListController setBuckets:[(ASIS3ServiceRequest *)request buckets]];
            
            ASIS3Bucket *bucket = nil;
            if ([[(ASIS3ServiceRequest *)request buckets] count] != 0) {
                bucket = [[(ASIS3ServiceRequest *)request buckets] objectAtIndex:0];
                [self.bucketListController setBucketsOwnerWithID:[bucket ownerID] displayName:[bucket ownerName]];
            }
            
            [self.bucketListController showWindow:self];
            
            // 解决启动后tableview第一行不显示的问题 by Littlebox222
            NSRect rect = [[self.bucketListController window] frame];
            [[self.bucketListController window] setFrame:NSMakeRect(rect.origin.x, rect.origin.y, rect.size.width, rect.size.height+1) display:YES animate:NO];
            
            [self close];
            
            if (self && [self window] && ![[self window] isVisible]) {
                [[NSNotificationCenter defaultCenter] removeObserver:self name:ASIS3RequestStateDidChangeNotification object:nil];
            }
            
        }else if (requestState == ASIS3RequestError) {
            
            if ([request responseHeaders] &&
                [[request responseHeaders] objectForKey:@"x-error-code"] &&
                [[[request responseHeaders] objectForKey:@"x-error-code"] isEqualToString:@"InvalidArgument"]) {
                
                NSAlert *alert = [NSAlert alertWithMessageText:@"请输入正确的 Access Key 与 Secret Key"
                                                 defaultButton:@"Ok"
                                               alternateButton:nil
                                                   otherButton:nil
                                     informativeTextWithFormat:@"\n注册SCS成功后，可在网站控制台获取：\n\nhttp://open.sinastorage.com/?c=console"];
                
                [alert runModal];
            }
            
            NSLog(@"%@", [request error]);
        }
    }
}

@end
