//
//  S3ObjectListController.m
//  S3-Objc
//
//  Created by Bruce Chen on 4/3/06.
//  Copyright 2014 Bruce Chen. All rights reserved.
//

#import <SystemConfiguration/SystemConfiguration.h>

#import "S3ObjectListController.h"
#import "S3Extensions.h"
#import "S3ConnectionInfo.h"
#import "S3MutableConnectionInfo.h"
#import "S3Bucket.h"
#import "S3Object.h"
#import "S3ApplicationDelegate.h"
#import "S3DownloadObjectOperation.h"
#import "S3AddObjectOperation.h"
#import "S3ListObjectOperation.h"
#import "S3DeleteObjectOperation.h"
#import "S3CopyObjectOperation.h"
#import "S3OperationQueue.h"
#import "S3Extensions.h"

#import "ASIS3BucketObject+ShowName.h"

#define SHEET_CANCEL 0
#define SHEET_OK 1

#define DEFAULT_PRIVACY @"defaultUploadPrivacy"
#define ACL_PRIVATE @"private"

#define FILEDATA_PATH @"path"
#define FILEDATA_KEY  @"key"
#define FILEDATA_TYPE @"mime"
#define FILEDATA_SIZE @"size"

@interface S3ObjectListController () <NSToolbarDelegate> {
}

@end


@implementation S3ObjectListController

#pragma mark -
#pragma mark Toolbar management

+ (NSSet *)keyPathsForValuesAffectingValueForKey:(NSString *)key
{
    if ([key isEqual:@"validListString"]) {
        return [NSSet setWithObject:@"validList"];
    }
    
    return nil;
}

- (void)awakeFromNib
{
    if ([S3ActiveWindowController instancesRespondToSelector:@selector(awakeFromNib)] == YES) {
        [super awakeFromNib];
    }
    NSToolbar *toolbar = [[NSToolbar alloc] initWithIdentifier:@"ObjectsToolbar"];
    [toolbar setDelegate:self];
    [toolbar setVisible:YES];
    [toolbar setAllowsUserCustomization:YES];
    [toolbar setAutosavesConfiguration:NO];
    [toolbar setSizeMode:NSToolbarSizeModeDefault];
    [toolbar setDisplayMode:NSToolbarDisplayModeDefault];
    [[self window] setToolbar:toolbar];

    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterShortStyle];
    [dateFormatter setTimeStyle:NSDateFormatterMediumStyle];
    [dateFormatter setTimeZone:[NSTimeZone defaultTimeZone]];
    [[[[[[self window] contentView] viewWithTag:10] tableColumnWithIdentifier:@"lastModified"] dataCell] setFormatter:dateFormatter];

    _renameOperations = [[NSMutableArray alloc] init];
    _redirectConnectionInfoMappings = [[NSMutableDictionary alloc] init];
    
    [_objectsController setFileOperationsDelegate:self];
    [[_objectsController tableView] setDelegate:self];
    [[_objectsController tableView] setDataSource:self];
    
    _superPrefixs = [NSMutableArray array];
    _tempObjectsArray = [NSMutableArray array];
    _canRefresh = YES;
}

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar *)toolbar
{
    return @[NSToolbarSeparatorItemIdentifier,
        NSToolbarSpaceItemIdentifier,
        NSToolbarFlexibleSpaceItemIdentifier,
        @"Refresh", @"Upload", @"Download", @"Remove", @"Remove All", @"Rename"];
}

- (BOOL)validateToolbarItem:(NSToolbarItem *)theItem
{
    if ([[theItem itemIdentifier] isEqualToString: @"Remove All"]) {
        
        //TODO:此功能先屏蔽
        return NO;
        //return [[_objectsController arrangedObjects] count] > 0;
        
    } else if ([[theItem itemIdentifier] isEqualToString: @"Remove"]) {
        
        if ([_objectsController canRemove]) {
            
            ASIS3BucketObject *b;
            NSEnumerator *e = [[_objectsController selectedObjects] objectEnumerator];
            
            while (b = [e nextObject]) {
                if ([[b key] hasSuffix:@"/"] || [[b key] isEqualToString:@"..."]) {
                    return NO;
                }
            }
            return YES;
            
        }else {
            return NO;
        }
        
        
    } else if ([[theItem itemIdentifier] isEqualToString: @"Download"]) {
        
        if ([_objectsController canRemove]) {
            
            ASIS3BucketObject *b;
            NSEnumerator *e = [[_objectsController selectedObjects] objectEnumerator];
            
            while (b = [e nextObject]) {
                if ([[b key] hasSuffix:@"/"] || [[b key] isEqualToString:@"..."]) {
                    return NO;
                }
            }
            return YES;
            
        }else {
            return NO;
        }
        
    } else if ([[theItem itemIdentifier] isEqualToString: @"Rename"]) {
        
        if ([[_objectsController selectedObjects] count] == 1) {
            
            ASIS3BucketObject *b;
            NSEnumerator *e = [[_objectsController selectedObjects] objectEnumerator];
            
            while (b = [e nextObject]) {
                if ([[b key] hasSuffix:@"/"] || [[b key] isEqualToString:@"..."]) {
                    return NO;
                }
            }
            return YES;
            
        }else {
            return NO;
        }
    }
    return YES;
}

- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar *)toolbar
{
    return @[@"Upload", @"Download", @"Rename", @"Remove", NSToolbarSeparatorItemIdentifier,  @"Remove All", NSToolbarFlexibleSpaceItemIdentifier, @"Show More", @"Refresh"];
}

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL) flag
{
    NSToolbarItem *item = [[NSToolbarItem alloc] initWithItemIdentifier: itemIdentifier];
    
    if ([itemIdentifier isEqualToString: @"Upload"])
    {
        [item setLabel: NSLocalizedString(@"Upload", nil)];
        [item setPaletteLabel: [item label]];
        [item setImage: [NSImage imageNamed: @"upload.icns"]];
        [item setTarget:self];
        [item setAction:@selector(upload:)];
    }
    if ([itemIdentifier isEqualToString: @"Download"])
    {
        [item setLabel: NSLocalizedString(@"Download", nil)];
        [item setPaletteLabel: [item label]];
        [item setImage: [NSImage imageNamed: @"download.icns"]];
        [item setTarget:self];
        [item setAction:@selector(download:)];
    }
    else if ([itemIdentifier isEqualToString: @"Remove"])
    {
        [item setLabel: NSLocalizedString(@"Remove", nil)];
        [item setPaletteLabel: [item label]];
        [item setImage: [NSImage imageNamed: @"delete.icns"]];
        [item setTarget:self];
        [item setAction:@selector(remove:)];
    }
    else if ([itemIdentifier isEqualToString: @"Remove All"])
    {
        [item setLabel: NSLocalizedString(@"Remove All", nil)];
        [item setPaletteLabel: [item label]];
        [item setImage: [NSImage imageNamed: @"delete.icns"]];
        [item setTarget:self];
        [item setAction:@selector(removeAll:)];
    }
    else if ([itemIdentifier isEqualToString: @"Refresh"])
    {
        [item setLabel: NSLocalizedString(@"Refresh", nil)];
        [item setPaletteLabel: [item label]];
        [item setImage: [NSImage imageNamed: @"refresh.icns"]];
        [item setTarget:self];
        [item setAction:@selector(refresh:)];
    } else if ([itemIdentifier isEqualToString:@"Rename"]) {
        [item setLabel:NSLocalizedString(@"Rename", nil)];
        [item setPaletteLabel: [item label]];
        [item setImage: [NSImage imageNamed: @"rename.tiff"]];
        [item setTarget:self];
        [item setAction:@selector(rename:)];
    }
    
    return item;
}


#pragma mark -
#pragma mark Misc Delegates


- (void)windowDidLoad
{
    [self refresh:self];
}

- (IBAction)cancelSheet:(id)sender
{
    [NSApp endSheet:[sender window] returnCode:SHEET_CANCEL];
}

- (IBAction)closeSheet:(id)sender
{
    [NSApp endSheet:[sender window] returnCode:SHEET_OK];
}

//- (void)operationQueueOperationStateDidChange:(NSNotification *)notification
//{
//    S3Operation *op = [[notification userInfo] objectForKey:S3OperationObjectKey];
//    NSUInteger index = [_operations indexOfObjectIdenticalTo:op];
//    if (index == NSNotFound) {
//        return;
//    }
//    
//    [super operationQueueOperationStateDidChange:notification];
//        
//    if ([op isKindOfClass:[S3ListObjectOperation class]] && [op state] == S3OperationDone) {
//        [self addObjects:[(S3ListObjectOperation *)op objects]];
//        [self setObjectsInfo:[(S3ListObjectOperation*)op metadata]];
//        
//        S3ListObjectOperation *next = [(S3ListObjectOperation *)op operationForNextChunk];
//        if (next != nil) {
//            [self addToCurrentOperations:next];            
//        } else {
//            [self setValidList:YES];
//        }
//    }
//    
//    if ([op isKindOfClass:[S3CopyObjectOperation class]] && [_renameOperations containsObject:op] && [op state] == S3OperationDone) {
//        [self setValidList:NO];
//        //S3Object *sourceObject = [[op operationInfo] objectForKey:@"sourceObject"];
//        S3Object *sourceObject = [(S3CopyObjectOperation *)op sourceObject];
//        S3DeleteObjectOperation *deleteOp = [[S3DeleteObjectOperation alloc] initWithConnectionInfo:[op connectionInfo] object:sourceObject];
//        [_renameOperations removeObject:op];
//        [self addToCurrentOperations:deleteOp];
//    }
//    
//    if (([op isKindOfClass:[S3AddObjectOperation class]] || [op isKindOfClass:[S3DeleteObjectOperation class]]) && [op state] == S3OperationDone) {
//        [self setValidList:NO];
//        NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
//        if ([[standardUserDefaults objectForKey:@"norefresh"] boolValue] == TRUE) {
//            return;
//        }
//        // Simple heuristics: if we still have something in the operation queue, no need to refresh now
//        if (![self hasActiveOperations]) {
//            [self refresh:self];            
//        } else {
//            _needsRefresh = YES;
//        }
//    }
//}

//- (void)s3OperationDidFail:(NSNotification *)notification
//{
//    S3Operation *op = [[notification userInfo] objectForKey:S3OperationObjectKey];
//    unsigned index = [_operations indexOfObjectIdenticalTo:op];
//    if (index == NSNotFound) {
//        return;
//    }
//    
//    [super s3OperationDidFail:notification];
//    
//    if (_needsRefresh == YES && [self hasActiveOperations] == NO) {
//        [self refresh:self];
//    }
//}

#pragma mark - ASIS3RequestState NSNotification

- (void)asiS3RequestStateDidChange:(NSNotification *)notification {
    
    if (![[notification name] isEqualToString:ASIS3RequestStateDidChangeNotification]) {
        return;
    }
    
    ASIS3Request *request = [[notification userInfo] objectForKey:ASIS3RequestKey];
    
    if ([request isKindOfClass:[ASIS3BucketRequest class]]) {
        if (![[(ASIS3BucketRequest *)request bucket] isEqualToString:[[self bucket] name]]) {
            return;
        }
    }
    
    if ([request isKindOfClass:[ASIS3ObjectRequest class]]) {
        if (![[(ASIS3ObjectRequest *)request bucket] isEqualToString:[[self bucket] name]]) {
            return;
        }
    }
    
    ASIS3RequestState requestState = [[[notification userInfo] objectForKey:ASIS3RequestStateKey] unsignedIntegerValue];
    [self updateRequest:request forState:requestState];
    
    NSString *requestKind = [[request userInfo] objectForKey:RequestUserInfoKindKey];
    
    //列文件
    if ([requestKind isEqualToString:ASIS3RequestListObject]) {
        
        if (requestState == ASIS3RequestDone) {
            
            _prefixArray = [(ASIS3BucketRequest *)request commonPrefixes];
            _currentPrefix = [(ASIS3BucketRequest *)request prefix];
            _isTruncated = [(ASIS3BucketRequest *)request isTruncated];
            
            
            // add directory
            NSMutableArray *prefixesObject = [NSMutableArray array];
            for (NSString *prefixString in _prefixArray) {
                ASIS3BucketObject *object = [ASIS3BucketObject objectWithBucket:[[self bucket] name]];
                [object setKey:prefixString];
                [object setPrefix:_currentPrefix];
                [prefixesObject addObject:object];
            }
            [_tempObjectsArray addObjectsFromArray:prefixesObject];
            
            
            // add object
            NSMutableArray *filteredObjects = [NSMutableArray array];
            for (ASIS3BucketObject *o in [(ASIS3BucketRequest *)request objects]) {
                if (![[o key] isEqualToString:_currentPrefix]) {
                    [o setPrefix:_currentPrefix];
                    [filteredObjects addObject:o];
                }
            }
            [_tempObjectsArray addObjectsFromArray:filteredObjects];
            
            
            if (!_isTruncated) {
                
                // add "..."
                if (_currentPrefix != nil && ![_currentPrefix isEqualToString:@""]) {
                    ASIS3BucketObject *object = [ASIS3BucketObject objectWithBucket:[[self bucket] name]];
                    [object setKey:@"..."];
                    
                    if ([[self objects] indexOfObject:object] == NSNotFound) {
                        [self addObjects:@[object]];
                    }
                }
                
                [self addObjects:_tempObjectsArray];
                
                // show list
                [self setValidList:YES];
                [self tableView:[_objectsController tableView] sortDescriptorsDidChange:[_objectsController content]];
                [self tableView:[_objectsController tableView] didClickTableColumn:0];
                
                if (!_canRefresh) {
                    _canRefresh = YES;
                }
                
            }else {
                
                ASIS3BucketRequest *requestForNextChunk = [(ASIS3BucketRequest *)request requestForNextChunk];
                [requestForNextChunk setUserInfo:@{RequestUserInfoKindKey:ASIS3RequestListObject, RequestUserInfoStatusKey:RequestUserInfoStatusPending}];
                [self addToCurrentNetworkQueue:requestForNextChunk];
            }
            
        }else if (requestState == ASIS3RequestError) {
            NSLog(@"%@", [request error]);
            _canRefresh = YES;
        }
    }
    
    //上传、删除、重命名
    if ([requestKind isEqualToString:ASIS3RequestAddObject] || [requestKind isEqualToString:ASIS3RequestDeleteObject] || [requestKind isEqualToString:ASIS3RequestCopyObject]) {
        
        if (requestState == ASIS3RequestDone) {
            
            if ([(ASIS3ObjectRequest *)request sourceBucket] != nil && [(ASIS3ObjectRequest *)request sourceKey] != nil) {
                ASIS3ObjectRequest *deleteRequest = [ASIS3ObjectRequest DELETERequestWithBucket:[(ASIS3ObjectRequest *)request sourceBucket]
                                                                                            key:[(ASIS3ObjectRequest *)request sourceKey]];
                [self addToCurrentNetworkQueue:deleteRequest];
            }else {

                if (_canRefresh) {
                    [self refresh:self];
                }
            }
        }else if (requestState == ASIS3RequestError) {
            NSLog(@"%@", [request error]);
        }
    }
    
    //下载
    if ([requestKind isEqualToString:ASIS3RequestDownloadObject]) {
        
        if (requestState == ASIS3RequestDone) {
            NSLog(@"finish download");
        }else if (requestState == ASIS3RequestError) {
            NSLog(@"%@", [request error]);
            
            if ([[NSFileManager defaultManager] fileExistsAtPath:request.downloadDestinationPath]) {
                [[NSFileManager defaultManager] removeItemAtPath:request.downloadDestinationPath error:NULL];
            }
        }
    }
}

#pragma mark - NSTableViewDelegate

- (void)tableView:(NSTableView *)tableView sortDescriptorsDidChange:(NSArray *)oldDescriptors {
    
    if (_currentPrefix != nil && ![_currentPrefix isEqualToString:@""]) {
        
        for (ASIS3BucketObject *o in [_objectsController content]) {
            
            if ([[o key] isEqualToString:@"..."]) {
                [_objectsController removeObject:o];
            }
        }
    }
}

- (void)tableView:(NSTableView *)tableView didClickTableColumn:(NSTableColumn *)tableColumn {
    
    if (_currentPrefix != nil && ![_currentPrefix isEqualToString:@""]) {
        
        ASIS3BucketObject *object = [ASIS3BucketObject objectWithBucket:[[self bucket] name]];
        [object setKey:@"..."];
        [_objectsController insertObject:object atArrangedObjectIndex:0];
    }
}

#pragma mark -
#pragma mark Actions

- (IBAction)refresh:(id)sender
{
    [self setValidList:NO];
    
    _canRefresh = NO;
    
    if ([self objects]) {
        [[self objects] removeAllObjects];
    }
    
    [self setObjects:[NSMutableArray array]];
    
    [_tempObjectsArray removeAllObjects];
    
    ASIS3BucketRequest *listRequest = [ASIS3BucketRequest requestWithBucket:[[self bucket] name]];
    
    [listRequest setDelimiter:@"/"];
    [listRequest setPrefix:_currentPrefix];
    [listRequest setMaxResultCount:100];
    
    [listRequest setUserInfo:@{RequestUserInfoKindKey:ASIS3RequestListObject, RequestUserInfoStatusKey:RequestUserInfoStatusPending}];
    [self addToCurrentNetworkQueue:listRequest];
}

-(IBAction)removeAll:(id)sender
{
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText:NSLocalizedString(@"Remove all objects permanently?",nil)];
    [alert setInformativeText:NSLocalizedString(@"Warning: Are you sure you want to remove all objects in this bucket? This operation cannot be undone.",nil)];
    [alert addButtonWithTitle:NSLocalizedString(@"Cancel",nil)];
    [alert addButtonWithTitle:NSLocalizedString(@"Remove",nil)];
    if ([alert runModal] == NSAlertFirstButtonReturn)
    {
        return;
    }
    
    ASIS3BucketObject *b;
    NSEnumerator *e = [[_objectsController arrangedObjects] objectEnumerator];
        
    while (b = [e nextObject])
    {
        ASIS3ObjectRequest *deleteObjectRequest = [ASIS3ObjectRequest DELETERequestWithBucket:[[self bucket] name] key:[b key]];
        [deleteObjectRequest setUserInfo:@{RequestUserInfoKindKey:ASIS3RequestDeleteObject, RequestUserInfoStatusKey:RequestUserInfoStatusPending}];
        [self addToCurrentNetworkQueue:deleteObjectRequest];
    }
}

- (IBAction)remove:(id)sender
{
    ASIS3BucketObject *b;
    NSUInteger count = [[_objectsController selectedObjects] count];

    if (count>=10)
    {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:[NSString stringWithFormat:NSLocalizedString(@"Remove %d objects permanently?",nil), count]];
        [alert setInformativeText:NSLocalizedString(@"Warning: Are you sure you want to remove these objects from this bucket? This operation cannot be undone.",nil)];
        [alert addButtonWithTitle:NSLocalizedString(@"Cancel",nil)];
        [alert addButtonWithTitle:NSLocalizedString(@"Remove",nil)];
        if ([alert runModal] == NSAlertFirstButtonReturn)
        {
            return;
        }
    }
    
    NSEnumerator *e = [[_objectsController selectedObjects] objectEnumerator];
    while (b = [e nextObject])
    {
        ASIS3ObjectRequest *deleteObjectRequest = [ASIS3ObjectRequest DELETERequestWithBucket:[[self bucket] name] key:[b key]];
        [deleteObjectRequest setUserInfo:@{RequestUserInfoKindKey:ASIS3RequestDeleteObject, RequestUserInfoStatusKey:RequestUserInfoStatusPending}];
        [self addToCurrentNetworkQueue:deleteObjectRequest];
    }
}

- (IBAction)doubleClicked:(id)sender {
    
    NSArray* selectedObjects = [_objectsController selectedObjects];
    
    for(ASIS3BucketObject* b in selectedObjects) {
        
        if ([[b key] hasSuffix:@"/"]) {
            
            if (_currentPrefix != nil) {
                [_superPrefixs addObject:_currentPrefix];
            }else {
                [_superPrefixs addObject:@""];
            }
            _currentPrefix = [b key];
            
            [self refresh:sender];
            
        }else if ([[b key] isEqualToString:@"..."]) {
            
            _currentPrefix = [_superPrefixs objectAtIndex:[_superPrefixs count]-1];
            [_superPrefixs removeObjectAtIndex:[_superPrefixs count]-1];
            [self refresh:sender];
            
        }else {
            
            [self download:sender];
        }
    }
}

- (IBAction)download:(id)sender
{
    NSArray* selectedObjects = [_objectsController selectedObjects];
        
    for(ASIS3BucketObject* b in selectedObjects)
    {
        NSSavePanel *sp = [NSSavePanel savePanel];
        NSString *n = [[b key] lastPathComponent];
        if (n==nil) n = @"Untitled";
        
        //[sp setTitle:n];
        //[sp setNameFieldLabel:n];
        [sp setNameFieldStringValue:n];
        
        __weak S3ObjectListController* _weakself = self;
        [sp beginWithCompletionHandler:^(NSInteger result) {
            if (result == NSOKButton) {
            
                ASIS3ObjectRequest *downloadRequest = [ASIS3ObjectRequest requestWithBucket:[[self bucket] name] key:[b key]];
                
                NSString *downloadPath = [[sp URL] path];
                
                [downloadRequest setTemporaryFileDownloadPath:[NSString stringWithFormat:@"%@.tmp", downloadPath]];
                [downloadRequest setDownloadDestinationPath:downloadPath];
                [downloadRequest setDownloadProgressDelegate:self];
                [downloadRequest setShowAccurateProgress:YES];
                [downloadRequest setAllowResumeForFileDownloads:YES];
                
                long long downloadedPartSize = 0;
                if ([[NSFileManager defaultManager] fileExistsAtPath:downloadRequest.temporaryFileDownloadPath] && [downloadRequest allowResumeForFileDownloads]) {
                    downloadedPartSize = [[[NSFileManager defaultManager] attributesOfItemAtPath:downloadRequest.temporaryFileDownloadPath error:nil] fileSize];
                    [downloadRequest addRequestHeader:@"If-Range" value:[b ETag]];
                }
                
                [downloadRequest setUserInfo:@{RequestUserInfoTransferedBytesKey:[NSString stringWithFormat:@"%lld", (long long)0],
                                               RequestUserInfoResumeDownloadedFileSizeKey:[NSString stringWithFormat:@"%lld", downloadedPartSize],
                                               RequestUserInfoKindKey:ASIS3RequestDownloadObject,
                                               RequestUserInfoStatusKey:RequestUserInfoStatusPending,
                                               RequestUserInfoSubStatusKey:[NSString stringWithFormat:@"%f", 0.0]}];

                [_weakself addToCurrentNetworkQueue:downloadRequest];
            }
        }];
        
    }
}

- (void)uploadFile:(NSDictionary *)data acl:(NSString *)acl
{
    NSString *path = [data objectForKey:FILEDATA_PATH];
    NSString *key = [data objectForKey:FILEDATA_KEY];
    
    if (![self acceptFileForImport:path])
    {   
        NSDictionary* d = @{NSLocalizedDescriptionKey: [NSString stringWithFormat:NSLocalizedString(@"The file '%@' could not be read",nil),path]};
        [[self window] presentError:[NSError errorWithDomain:S3_ERROR_DOMAIN code:-2 userInfo:d] modalForWindow:[self window] delegate:self 
                 didPresentSelector:@selector(didPresentErrorWithRecovery:contextInfo:) contextInfo:nil];
        return;        
    }
    
    ASIS3ObjectRequest *uploadRequest = [ASIS3ObjectRequest PUTRequestForFile:path withBucket:[[self bucket] name] key:key];
    
    [uploadRequest addRequestHeader:@"Expect" value:@"100-continue"];
    [uploadRequest setAccessPolicy:acl];
    [uploadRequest setUploadProgressDelegate:self];
    [uploadRequest setShowAccurateProgress:YES];
    [uploadRequest setUserInfo:@{RequestUserInfoTransferedBytesKey:[NSString stringWithFormat:@"%d", 0],
                                 RequestUserInfoKindKey:ASIS3RequestAddObject,
                                 RequestUserInfoStatusKey:RequestUserInfoStatusPending,
                                 RequestUserInfoSubStatusKey:[NSString stringWithFormat:@"%f", 0.0]}];
    
    [self addToCurrentNetworkQueue:uploadRequest];
}

- (void)uploadFiles
{	
    NSEnumerator *e = [[self uploadData] objectEnumerator];
    NSDictionary *data;

    while (data = [e nextObject]) {
        [self uploadFile:data acl:[self uploadACL]];        
    }
}

- (IBAction)upload:(id)sender
{
    NSOpenPanel *oPanel = [NSOpenPanel openPanel];
    [oPanel setAllowsMultipleSelection:YES];
    [oPanel setPrompt:NSLocalizedString(@"Upload",nil)];
    [oPanel setCanChooseDirectories:TRUE];
    
    __weak S3ObjectListController* _weakself = self;
    [oPanel beginWithCompletionHandler:^(NSInteger result) {
        NSArray* urls = [oPanel URLs];
        
        if (result != NSOKButton) {
            return;
        }
        
        [_weakself importURLs:urls withDialog:TRUE];
    }];
}

- (void)didEndSheet:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
    [sheet orderOut:self];
    if (returnCode!=SHEET_OK)
        return;
    
    [self uploadFiles];
}

- (BOOL)acceptFileForImport:(NSString *)path
{
    return [[NSFileManager defaultManager] isReadableFileAtPath:path];
}

- (void)importURLs:(NSArray *)urls withDialog:(BOOL)dialog
{
    // First expand directories and only keep paths to files
    NSArray *paths = [urls expandPaths];
        
    NSString *path;
    NSMutableArray *filesInfo = [NSMutableArray array];
    NSString *prefix = [NSString commonPathComponentInPaths:paths];
    
    for (path in paths) {
        NSMutableDictionary *info = [NSMutableDictionary dictionary];
        [info setObject:path forKey:FILEDATA_PATH];
        [info setObject:[path fileSizeForPath] forKey:FILEDATA_SIZE];
        [info safeSetObject:[path mimeTypeForPath] forKey:FILEDATA_TYPE withValueForNil:@"application/octet-stream"];
        [info setObject:[NSString stringWithFormat:@"%@%@", _currentPrefix==nil?@"":_currentPrefix, [path substringFromIndex:[prefix length]]] forKey:FILEDATA_KEY];
        [filesInfo addObject:info];
    }
    
    [self setUploadData:filesInfo];

    NSString* defaultPrivacy = [[NSUserDefaults standardUserDefaults] stringForKey:DEFAULT_PRIVACY];
    if (defaultPrivacy==nil) {
        defaultPrivacy = ACL_PRIVATE;        
    }
    [self setUploadACL:defaultPrivacy];
    [self setUploadSize:[NSString readableSizeForPaths:paths]];

    if (!dialog)
        [self uploadFiles];
    else
    {
        if ([paths count]==1)
        {
            [self setUploadFilename:[[paths objectAtIndex:0] stringByAbbreviatingWithTildeInPath]];
            [NSApp beginSheet:uploadSheet modalForWindow:[self window] modalDelegate:self didEndSelector:@selector(didEndSheet:returnCode:contextInfo:) contextInfo:nil];			
        }
        else
        {
            [self setUploadFilename:[NSString stringWithFormat:NSLocalizedString(@"%d elements in %@",nil),[paths count],[prefix stringByAbbreviatingWithTildeInPath]]];
            [NSApp beginSheet:multipleUploadSheet modalForWindow:[self window] modalDelegate:self didEndSelector:@selector(didEndSheet:returnCode:contextInfo:) contextInfo:nil];							
        }
    }
}


- (void)didEndRenameSheet:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
    ASIS3BucketObject *source = (__bridge_transfer ASIS3BucketObject *)contextInfo;

    [sheet orderOut:self];

    if (returnCode!=SHEET_OK) {
        return;
    }
    
    if ([[source key] isEqualToString:[self renameName]]) {
        return;
    }
    
    ASIS3ObjectRequest *copyRequest = [ASIS3ObjectRequest COPYRequestFromBucket:[[self bucket] name]
                                                                            key:[source key]
                                                                       toBucket:[[self bucket] name]
                                                                            key:[self renameName]];
    [copyRequest setUserInfo:@{RequestUserInfoKindKey:ASIS3RequestCopyObject, RequestUserInfoStatusKey:RequestUserInfoStatusPending}];
    [self addToCurrentNetworkQueue:copyRequest];
}

- (IBAction)rename:(id)sender
{
    NSArray *objects = [_objectsController selectedObjects];
    if ([objects count] == 0 || [objects count] > 1) {
        return;
    }
    S3Object *selectedObject = [[_objectsController selectedObjects] objectAtIndex:0];
    [self setRenameName:[selectedObject key]];
    
    [NSApp beginSheet:renameSheet
       modalForWindow:[self window]
        modalDelegate:self
       didEndSelector:@selector(didEndRenameSheet:returnCode:contextInfo:)
          contextInfo:(__bridge_retained void*)selectedObject];
}

#pragma mark -
#pragma mark ASIProgressDelegate

- (void)request:(ASIHTTPRequest *)request didReceiveBytes:(long long)bytes {
    
    long long bytesDownloaded = [[[request userInfo] objectForKey:RequestUserInfoTransferedBytesKey] longLongValue] + bytes;
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:[request userInfo]];
    [dict setValue:[NSString stringWithFormat:@"%lld", bytesDownloaded] forKey:RequestUserInfoTransferedBytesKey];
    
    long long resumeDownloadedFileSize = [[[request userInfo] objectForKey:RequestUserInfoResumeDownloadedFileSizeKey] longLongValue];
    [dict setValue:[NSString stringWithFormat:@"%.2f%%", (GLfloat)bytesDownloaded / (GLfloat)(resumeDownloadedFileSize + [request contentLength]) * 100.0] forKey:RequestUserInfoSubStatusKey];
    
    [request setUserInfo:dict];
}

- (void)request:(ASIHTTPRequest *)request didSendBytes:(long long)bytes {
    
    long long bytesUploaded = [[[request userInfo] objectForKey:RequestUserInfoTransferedBytesKey] longLongValue] + bytes;
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:[request userInfo]];
    [dict setValue:[NSString stringWithFormat:@"%lld", bytesUploaded] forKey:RequestUserInfoTransferedBytesKey];
    [dict setValue:[NSString stringWithFormat:@"%.2f%%", (GLfloat)bytesUploaded / (GLfloat)[request postLength] * 100.0] forKey:RequestUserInfoSubStatusKey];
    
    [request setUserInfo:dict];
}

#pragma mark -
#pragma mark Key-value coding

- (void)addObjects:(NSArray *)a
{
    [self willChangeValueForKey:@"objects"];
    [_objects addObjectsFromArray:a];
    [self didChangeValueForKey:@"objects"];
}

- (NSMutableArray *)objects
{
    return _objects; 
}

- (void)setObjects:(NSMutableArray *)aObjects
{
    _objects = aObjects;
}

- (NSMutableDictionary *)objectsInfo
{
    return _objectsInfo; 
}

- (void)setObjectsInfo:(NSMutableDictionary *)aObjectsInfo
{
    _objectsInfo = aObjectsInfo;
}

- (ASIS3Bucket *)bucket
{
    return _bucket; 
}

- (void)setBucket:(ASIS3Bucket *)aBucket
{
    _bucket = aBucket;
}

- (NSString *)renameName
{
    return _renameName;
}

- (void)setRenameName:(NSString *)name
{
    _renameName = name;
}

- (NSString *)uploadACL
{
    return _uploadACL; 
}

- (void)setUploadACL:(NSString *)anUploadACL
{
    _uploadACL = anUploadACL;
    [[NSUserDefaults standardUserDefaults] setObject:anUploadACL forKey:DEFAULT_PRIVACY];
}

- (NSString *)uploadFilename
{
    return _uploadFilename; 
}

- (void)setUploadFilename:(NSString *)anUploadFilename
{
    _uploadFilename = anUploadFilename;
}

- (NSString *)uploadSize
{
    return _uploadSize; 
}

- (void)setUploadSize:(NSString *)anUploadSize
{
    _uploadSize = anUploadSize;
}

- (NSMutableArray *)uploadData
{
    return _uploadData; 
}

- (void)setUploadData:(NSMutableArray *)data
{
    _uploadData = data;
}

- (BOOL)validList
{
    return _validList;
}

- (void)setValidList:(BOOL)yn
{
    _validList = yn;
}

- (NSString *)validListString
{
    if ([self validList] == YES) {
        return NSLocalizedString(@"Object list valid",nil);
    } else {
        return NSLocalizedString(@"Object list invalid",nil);
    }
}

#pragma mark -
#pragma mark Dealloc

-(void)dealloc
{
//    [[[NSApp delegate] queue] removeQueueListener:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:ASIS3RequestStateDidChangeNotification object:nil];
}

@end
