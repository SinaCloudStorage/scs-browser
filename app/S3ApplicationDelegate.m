//
//  S3ApplicationDelegate.m
//  S3-Objc
//
//  Created by Michael Ledford on 9/11/08.
//  Copyright 2008 Michael Ledford. All rights reserved.
//

#import <Security/Security.h>

#import "S3ApplicationDelegate.h"
#import "S3OperationLog.h"
#import "S3ConnectionInfo.h"
#import "S3LoginController.h"
#import "S3OperationQueue.h"
#import "S3OperationController.h"
#import "S3ValueTransformers.h"
#import "S3AppKitExtensions.h"
#import "S3BucketListController.h"
#import "S3ConnInfo.h"

#import "ASIS3Request+showValue.h"

// C-string, as it is only used in Keychain Services
#define S3_BROWSER_KEYCHAIN_SERVICE "S3 Browser"

/* Notification UserInfo Keys */
NSString *ASIS3RequestKey = @"ASIS3RequestKey";
NSString *ASIS3RequestStateKey = @"ASIS3RequestStateKey";
NSString *ASIS3RequestStateDidChangeNotification = @"ASIS3RequestStateDidChangeNotification";

NSString *RequestUserInfoTransferedBytesKey = @"transferedBytes";
NSString *RequestUserInfoResumeDownloadedFileSizeKey = @"resumeDownloadedFileSize";
NSString *RequestUserInfoKindKey = @"kind";
NSString *RequestUserInfoStatusKey = @"status";
NSString *RequestUserInfoSubStatusKey = @"subStatus";
NSString *RequestUserInfoURLKey = @"url";
NSString *RequestUserInfoRequestMethodKey = @"requestMethod";

NSString *ASIS3RequestListBucket =      @"ListBucket";
NSString *ASIS3RequestAddBucket =       @"AddBucket";
NSString *ASIS3RequestDeleteBucket =    @"DeleteBucket";
NSString *ASIS3RequestListObject =      @"ListObject";
NSString *ASIS3RequestAddObject =       @"AddObject";
NSString *ASIS3RequestDeleteObject =    @"DeleteObject";
NSString *ASIS3RequestCopyObject =      @"CopyObject";
NSString *ASIS3RequestDownloadObject =  @"DownloadObject";

NSString *RequestUserInfoStatusPending =                @"Pending";
NSString *RequestUserInfoStatusActive =                 @"Active";
NSString *RequestUserInfoStatusCanceled =               @"Canceled";
NSString *RequestUserInfoStatusReceiveResponseHeaders = @"ReceiveResponseHeaders";
NSString *RequestUserInfoStatusDone =                   @"Done";
NSString *RequestUserInfoStatusRequiresRedirect =       @"RequiresRedirect";
NSString *RequestUserInfoStatusError =                  @"Error";


@interface S3ApplicationDelegate () <S3ConnectionInfoDelegate, S3OperationQueueDelegate, S3ConnInfoDelegate>
@property (nonatomic) S3LoginController* loginController;
@property (nonatomic, assign) BOOL shouldReopen;
@end

@implementation S3ApplicationDelegate

+ (void)initialize
{
    [NSDateFormatter setDefaultFormatterBehavior:NSDateFormatterBehavior10_4];

    NSMutableDictionary *userDefaultsValuesDict = [NSMutableDictionary dictionary];

    // Not setting a default value for this default, it should be nil if it doesn't exist.
    [userDefaultsValuesDict setObject:@"" forKey:@"defaultAccessKey"];
    [userDefaultsValuesDict setObject:@NO forKey:@"autoclean"];
    [userDefaultsValuesDict setObject:@YES forKey:@"consolevisible"];
    [userDefaultsValuesDict setObject:@"private" forKey:@"defaultUploadPrivacy"];
    [userDefaultsValuesDict setObject:@NO forKey:@"useKeychain"];
    [userDefaultsValuesDict setObject:@NO forKey:@"useSSL"];
    [userDefaultsValuesDict setObject:@YES forKey:@"autologin"];
    [userDefaultsValuesDict setObject:@4 forKey:@"maxoperations"];
    [[NSUserDefaults standardUserDefaults] registerDefaults:userDefaultsValuesDict];

    // Conversion code for new default
    NSString *defaultAccessKey = [[NSUserDefaults standardUserDefaults] stringForKey:@"default-accesskey"];
    if (defaultAccessKey != nil) {
        [[NSUserDefaults standardUserDefaults] setObject:defaultAccessKey forKey:@"defaultAccessKey"];
        [[NSUserDefaults standardUserDefaults] setObject:nil forKey:@"default-accesskey"];            
    }
    
    // Conversion code for new default
    NSString *defaultUploadPrivacyKey = [[NSUserDefaults standardUserDefaults] stringForKey:@"default-upload-privacy"];
    if (defaultUploadPrivacyKey != nil) {
        [[NSUserDefaults standardUserDefaults] setObject:defaultUploadPrivacyKey forKey:@"defaultUploadPrivacy"];
        [[NSUserDefaults standardUserDefaults] setObject:nil forKey:@"default-upload-privacy"];            
    }
    
    S3FileSizeTransformer *fileSizeTransformer = [[S3FileSizeTransformer alloc] init];
    [NSValueTransformer setValueTransformer:fileSizeTransformer forName:@"S3FileSizeTransformer"];
}

- (id)init
{
    self = [super init];
    
    if (self != nil) {
        _controllers = [[NSMutableDictionary alloc] init];
        _queue = [[S3OperationQueue alloc] initWithDelegate:self];
        
        _networkQueue = [ASINetworkQueue queue];
        [_networkQueue setDelegate:self];
        [_networkQueue setShouldCancelAllRequestsOnFailure:NO];
        [_networkQueue setRequestDidFailSelector:@selector(requestDidFailSelector:)];
        [_networkQueue setRequestDidFinishSelector:@selector(requestDidFinishSelector:)];
        [_networkQueue setRequestDidReceiveResponseHeadersSelector:@selector(requestDidReceiveResponseHeadersSelector:)];
        [_networkQueue setRequestDidStartSelector:@selector(requestDidStartSelector:)];
        [_networkQueue setRequestWillRedirectSelector:@selector(requestWillRedirectSelector:)];
        
        NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
        NSNumber *maxOps = [standardUserDefaults objectForKey:@"maxoperations"];
        [_networkQueue setMaxConcurrentOperationCount:[maxOps intValue]];
        
        _operationLog = [[S3OperationLog alloc] init];
        _authenticationCredentials = [[NSMutableDictionary alloc] init];
        self.shouldReopen = NO;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(finishedLaunching) name:NSApplicationDidFinishLaunchingNotification object:NSApp];
        
        [_networkQueue go];
    }
    
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSApplicationDidFinishLaunchingNotification object:NSApp];
}

- (BOOL)applicationShouldHandleReopen:(NSApplication *)theApplication hasVisibleWindows:(BOOL)flag
{
    if (!flag) {
    
        self.shouldReopen = YES;
        [[NSNotificationCenter defaultCenter] addObserver:self.loginController selector:@selector(asiS3RequestStateDidChange:) name:ASIS3RequestStateDidChangeNotification object:nil];
        [self finishedLaunching];
        return YES;
    }
    return NO;
}

- (IBAction)openConnection:(id)sender
{    
	self.loginController = [[S3LoginController alloc] initWithWindowNibName:@"Authentication"];

    NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
    NSNumber *useSSL = [standardUserDefaults objectForKey:@"useSSL"];
    
    S3ConnInfo *connInfo = [[S3ConnInfo alloc] initWithDelegate:self userInfo:nil secureConn:[useSSL boolValue]];
    [self.loginController setConnInfo:connInfo];
    [self.loginController showWindow:self];
}

- (IBAction)showOperationConsole:(id)sender
{
    // No-op, as everything is done in bindings
    // but we need a target/action for automatic enabling
}

- (void)tryAutoLogin
{
    NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
    NSNumber *useSSL = [standardUserDefaults objectForKey:@"useSSL"];
    
    if (self.shouldReopen == NO) {
        self.loginController = [[S3LoginController alloc] initWithWindowNibName:@"Authentication"];
    }
    
    S3ConnInfo *connInfo = [[S3ConnInfo alloc] initWithDelegate:self userInfo:nil secureConn:[useSSL boolValue]];
    [self.loginController setConnInfo:connInfo];
	
    if (self.shouldReopen == NO) {
        [self.loginController showWindow:self];
    }
    
    [self.loginController connect:self];

    self.shouldReopen = NO;
}

- (void)finishedLaunching
{
    
    if ([_controllers objectForKey:@"Console"] == nil) {
        S3OperationController *c = [[S3OperationController alloc] initWithWindowNibName:@"Operations"];
        [_controllers setObject:c forKey:@"Console"];
    }
    
    NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
    NSNumber *consoleVisible = [standardUserDefaults objectForKey:@"consolevisible"];
    // cover the migration cases 
    if (([consoleVisible boolValue] == TRUE)||(consoleVisible==nil)) {
        [[_controllers objectForKey:@"Console"] showWindow:self];        
    } else {
        // Load the window to be ready for the console to be shown.
        [[_controllers objectForKey:@"Console"] window];
    }
    
    if (self.shouldReopen == YES) {
        
        [self tryAutoLogin];
        return;
    }
    
    if ([[standardUserDefaults objectForKey:@"autologin"] boolValue] == TRUE) {
        [self tryAutoLogin];
    }
}

- (IBAction)showHelp:(id)sender
{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://open.sinastorage.com/"]];
}

- (S3OperationQueue *)queue
{
    return _queue;
}

- (S3OperationLog *)operationLog
{
    return _operationLog;
}

- (NSMutableDictionary *)controllers {
    return _controllers;
}

- (void)setAuthenticationCredentials:(NSDictionary *)authDict forConnectionInfo:(id)connInfo {
    
    if (authDict == nil || connInfo == nil) {
        
        return;
    }
    
    [_authenticationCredentials setObject:authDict forKey:connInfo];
}

- (void)removeAuthenticationCredentialsForConnectionInfo:(id)connInfo {
    
    if (connInfo != nil) {
    
        [_authenticationCredentials removeObjectForKey:connInfo];
    }
}

- (NSDictionary *)authenticationCredentialsForConnectionInfo:(id)connInfo
{
    NSDictionary *dict = [_authenticationCredentials objectForKey:connInfo];
    if (dict != nil) {
        dict = [NSDictionary dictionaryWithDictionary:dict];
    }
    return dict;
}

#pragma mark S3ConnectionInfoDelegate Methods

- (NSString *)accessKeyForConnectionInfo:(S3ConnectionInfo *)connectionInfo
{
    NSDictionary *authenticationCredentials = [self authenticationCredentialsForConnectionInfo:connectionInfo];
    if (authenticationCredentials == nil) {
        return nil;
    }

    // TODO: constant defined keys
    return [authenticationCredentials objectForKey:@"accessKey"];
}

- (NSString *)secretAccessKeyForConnectionInfo:(S3ConnectionInfo *)connectionInfo
{
    NSDictionary *authenticationCredentials = [self authenticationCredentialsForConnectionInfo:connectionInfo];
    if (authenticationCredentials == nil) {
        return nil;
    }
    
    // TODO: constant defined keys
    return [authenticationCredentials objectForKey:@"secretAccessKey"];
}


#pragma mark S3ConneInfoDelegate Methods


- (NSString *)accessKeyForConnInfo:(S3ConnInfo *)connInfo {

    NSDictionary *authenticationCredentials = [self authenticationCredentialsForConnectionInfo:connInfo];
    
    if (authenticationCredentials == nil) {
    
        return nil;
    }

    return [authenticationCredentials objectForKey:@"accessKey"];
}

- (NSString *)secretAccessKeyForConnInfo:(S3ConnInfo *)connInfo {
    
    NSDictionary *authenticationCredentials = [self authenticationCredentialsForConnectionInfo:connInfo];
    
    if (authenticationCredentials == nil) {
    
        return nil;
    }
    
    return [authenticationCredentials objectForKey:@"secretAccessKey"];
}

#pragma mark -

- (ASINetworkQueue *)networkQueue {
    
    return _networkQueue;
}

- (void)postNotificationWithRequest:(ASIS3Request *)request state:(ASIS3RequestState)state {

    NSDictionary *dict = @{ASIS3RequestKey : request,
                           ASIS3RequestStateKey:[NSNumber numberWithUnsignedInteger:state]};
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ASIS3RequestStateDidChangeNotification object:self userInfo:dict];
}

- (void)requestDidStartSelector:(ASIS3Request *)request {
    
    [request setShowRequestMethod:[request requestMethod]];
    [request setShowUrl:[request url]];
    [self postNotificationWithRequest:request state:ASIS3RequestActive];
}

- (void)requestDidReceiveResponseHeadersSelector:(ASIS3Request *)request {
    
    [self postNotificationWithRequest:request state:ASIS3RequestReceiveResponseHeaders];
}

- (void)requestWillRedirectSelector:(ASIS3Request *)request {
    
    [self postNotificationWithRequest:request state:ASIS3RequestRequiresRedirect];
}

- (void)requestDidFinishSelector:(ASIS3Request *)request {
    
    if ([request responseStatusCode] / 100 != 2) {
        
        [self requestDidFailSelector:request];
        
    }else {
        
        if ([[request showKind] isEqualToString:ASIS3RequestDownloadObject] &&
            [[[NSFileManager defaultManager] attributesOfItemAtPath:request.downloadDestinationPath error:nil] fileSize] != [request contentLength]) {
            
            [self requestDidFailSelector:request];
        }else {
            [self postNotificationWithRequest:request state:ASIS3RequestDone];
            [[self operationLog] unlogOperation:[request logObject]];
        }
    }
}

- (void)requestDidFailSelector:(ASIS3Request *)request {
    
    if ([request isCancelled]) {
        [self postNotificationWithRequest:request state:ASIS3RequestCanceled];
    }else {
        [self postNotificationWithRequest:request state:ASIS3RequestError];
    }
}

@end


