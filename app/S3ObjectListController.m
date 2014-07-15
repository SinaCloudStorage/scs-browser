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
#import "ASIS3Request+showValue.h"
#import "LogObject.h"
#import "S3OperationController.h"

#define SHEET_CANCEL 0
#define SHEET_OK 1

#define DEFAULT_PRIVACY @"defaultUploadPrivacy"
#define ACL_PRIVATE @"private"

#define FILEDATA_PATH @"path"
#define FILEDATA_KEY  @"key"
#define FILEDATA_TYPE @"mime"
#define FILEDATA_SIZE @"size"

#define MaxResultCountOnePage   1024

@interface S3ObjectListController () <NSToolbarDelegate> {
}

@end


@implementation S3ObjectListController

@synthesize currentPrefix = _currentPrefix;

#pragma mark -
#pragma mark Toolbar management

+ (NSSet *)keyPathsForValuesAffectingValueForKey:(NSString *)key
{
    if ([key isEqual:@"validListString"]) {
        return [NSSet setWithObject:@"validList"];
    }
    
    return nil;
}

- (id)initWithWindowNibName:(NSString *)windowNibName {
    self = [super initWithWindowNibName:windowNibName];
    if (self) {
        _initialize = YES;
    }
    return self;
}

- (void)awakeFromNib
{
    @synchronized(self) {
        
        if (_initialize) {
            
            _initialize = NO;
            
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
            
            
            _renameOperations = [[NSMutableArray alloc] init];
            _redirectConnectionInfoMappings = [[NSMutableDictionary alloc] init];
            
            [_objectsController setFileOperationsDelegate:self];
            
            _superPrefixs = [NSMutableArray array];
            _tempObjectsArray = [NSMutableArray array];
            _canRefresh = YES;
        }
    }
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
        
        //TODO:暂时禁用
        return NO;
        //return [[_objectsController arrangedObjects] count] > 0;
        
    } else if ([[theItem itemIdentifier] isEqualToString: @"Remove"]) {
        
        if ([_objectsController canRemove]) {
            
            ASIS3BucketObject *b;
            NSEnumerator *e = [[_objectsController selectedObjects] objectEnumerator];
            
            while (b = [e nextObject]) {
                if ([[b key] hasSuffix:@"/"] || [[b key] isEqualToString:@".."]) {
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
                if ([[b key] hasSuffix:@"/"] || [[b key] isEqualToString:@".."]) {
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
                if ([[b key] hasSuffix:@"/"] || [[b key] isEqualToString:@".."]) {
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
    //return @[@"Upload", @"Download", @"Rename", @"Remove", NSToolbarSeparatorItemIdentifier,  @"Remove All", NSToolbarFlexibleSpaceItemIdentifier, @"Show More", @"Refresh"];
    return @[@"Upload", @"Download", @"Rename", @"Remove", NSToolbarSeparatorItemIdentifier, NSToolbarFlexibleSpaceItemIdentifier, @"Show More", @"Refresh"];
}

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL) flag
{
    NSToolbarItem *item = [[NSToolbarItem alloc] initWithItemIdentifier: itemIdentifier];
    
    if ([itemIdentifier isEqualToString: @"Upload"])
    {
        [item setLabel: NSLocalizedString(@"Upload", nil)];
        [item setPaletteLabel: [item label]];
        [item setImage: [NSImage imageNamed: @"upload.png"]];
        [item setTarget:self];
        [item setAction:@selector(upload:)];
    }
    if ([itemIdentifier isEqualToString: @"Download"])
    {
        [item setLabel: NSLocalizedString(@"Download", nil)];
        [item setPaletteLabel: [item label]];
        [item setImage: [NSImage imageNamed: @"download.png"]];
        [item setTarget:self];
        [item setAction:@selector(download:)];
    }
    else if ([itemIdentifier isEqualToString: @"Remove"])
    {
        [item setLabel: NSLocalizedString(@"Remove", nil)];
        [item setPaletteLabel: [item label]];
        [item setImage: [NSImage imageNamed: @"delete.png"]];
        [item setTarget:self];
        [item setAction:@selector(remove:)];
    }
//    else if ([itemIdentifier isEqualToString: @"Remove All"])
//    {
//        [item setLabel: NSLocalizedString(@"Remove All", nil)];
//        [item setPaletteLabel: [item label]];
//        [item setImage: [NSImage imageNamed: @"delete.png"]];
//        [item setTarget:self];
//        [item setAction:@selector(removeAll:)];
//    }
    else if ([itemIdentifier isEqualToString: @"Refresh"])
    {
        [item setLabel: NSLocalizedString(@"Refresh", nil)];
        [item setPaletteLabel: [item label]];
        [item setImage: [NSImage imageNamed: @"refresh.png"]];
        [item setTarget:self];
        [item setAction:@selector(refresh:)];
    } else if ([itemIdentifier isEqualToString:@"Rename"]) {
        [item setLabel:NSLocalizedString(@"Rename", nil)];
        [item setPaletteLabel: [item label]];
        [item setImage: [NSImage imageNamed: @"rename.png"]];
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
    
    NSString *requestKind = [request showKind];
    
    //列文件
    if ([requestKind isEqualToString:ASIS3RequestListObject]) {
        
        [self willChangeValueForKey:@"hasActiveRequest"];
        [self hasActiveRequest];
        [self didChangeValueForKey:@"hasActiveRequest"];
        
        [self updateRequest:request forState:requestState];
        
        if (requestState == ASIS3RequestDone) {
            
            _prefixArray = [(ASIS3BucketRequest *)request commonPrefixes];
            [self setCurrentPrefix:[(ASIS3BucketRequest *)request prefix]];
            _isTruncated = [(ASIS3BucketRequest *)request isTruncated];
            
            
            // add directory
            for (NSString *prefixString in _prefixArray) {
                ASIS3BucketObject *object = [ASIS3BucketObject objectWithBucket:[[self bucket] name]];
                [object setKey:prefixString];
                [object setPrefix:_currentPrefix];
                [object setIcon:[[NSWorkspace sharedWorkspace] iconForFileType:NSFileTypeForHFSTypeCode(kGenericFolderIcon)]];
                [object setObjetType:@"directory"];
                
                [_tempObjectsArray addObject:object];
            }
            
            
            // add object
            for (ASIS3BucketObject *o in [(ASIS3BucketRequest *)request objects]) {
                if (![[o key] isEqualToString:_currentPrefix]) {
                    [o setPrefix:_currentPrefix];
                    NSString *extFileName = [[o key] pathExtension];
                    [o setIcon:[[NSWorkspace sharedWorkspace] iconForFileType:extFileName]];
                    [o setObjetType:@"file"];
                    
                    [_tempObjectsArray addObject:o];
                }
            }
            
            if (!_isTruncated) {
                
                // add "..."
                if (_currentPrefix != nil && ![_currentPrefix isEqualToString:@""]) {
                    ASIS3BucketObject *object = [ASIS3BucketObject objectWithBucket:[[self bucket] name]];
                    [object setKey:@".."];
                    [object setObjetType:@"goBack"];
                    [object setIcon:[[NSWorkspace sharedWorkspace] iconForFileType:NSFileTypeForHFSTypeCode(kGenericFolderIcon)]];
                    
                    if ([[self objects] indexOfObject:object] == NSNotFound) {
                        [_tempObjectsArray addObject:object];
                    }
                }
                
                [self setObjects:_tempObjectsArray];
                [self sortDescriptorsDidChange];
                [self didClickTableColumn];
                [[_objectsController tableView] deselectAll:self];
                
                if (!_canRefresh) {
                    _canRefresh = YES;
                }
                
            }else {
                
                ASIS3BucketRequest *requestForNextChunk = [(ASIS3BucketRequest *)request requestForNextChunk];
                [requestForNextChunk setShowKind:ASIS3RequestListObject];
                [requestForNextChunk setShowStatus:RequestUserInfoStatusPending];
                [_operations addObject:requestForNextChunk];
                [self addOperations];
            }
            

            
        }else if (requestState == ASIS3RequestError) {
            
            if (_currentPrefix != nil && ![_currentPrefix isEqualToString:@""]) {
                ASIS3BucketObject *object = [ASIS3BucketObject objectWithBucket:[[self bucket] name]];
                [object setKey:@".."];
                [object setObjetType:@"goBack"];
                [object setIcon:[[NSWorkspace sharedWorkspace] iconForFileType:NSFileTypeForHFSTypeCode(kGenericFolderIcon)]];
                
                if ([[self objects] indexOfObject:object] == NSNotFound) {
                    [self addObjects:@[object]];
                }
            }
            

            [self sortDescriptorsDidChange];
            [self didClickTableColumn];
            [[_objectsController tableView] deselectAll:self];
            
            if (!_canRefresh) {
                _canRefresh = YES;
            }
            
            NSLog(@"%@", [request error]);
        }
    }
    
    
    //上传、删除、重命名
    if ([requestKind isEqualToString:ASIS3RequestAddObject] || [requestKind isEqualToString:ASIS3RequestDeleteObject] || [requestKind isEqualToString:ASIS3RequestCopyObject]) {
        
        [self willChangeValueForKey:@"hasActiveRequest"];
        [self hasActiveRequest];
        [self didChangeValueForKey:@"hasActiveRequest"];
        
        [self updateRequest:request forState:requestState];
        
        if (requestState == ASIS3RequestDone) {
            
            if ([requestKind isEqualToString:ASIS3RequestCopyObject]) {
                ASIS3ObjectRequest *deleteRequest = [ASIS3ObjectRequest DELETERequestWithBucket:[(ASIS3ObjectRequest *)request sourceBucket]
                                                                                            key:[(ASIS3ObjectRequest *)request sourceKey]];
                [deleteRequest setShowKind:ASIS3RequestDeleteObject];
                [deleteRequest setShowStatus:RequestUserInfoStatusPending];
                [_operations addObject:deleteRequest];
                [self addOperations];
                
            }else {

                if (_canRefresh) {
                    if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"norefresh"] boolValue] == false) {
                        
                        if ([[request shouldRefresh] boolValue]) {
                            [self refresh:self];
                        }
                    }
                }
                
                if ([requestKind isEqualToString:ASIS3RequestAddObject]) {
                    [self cleanOperationTransferSpeedLog];
                }
            }
        }else if (requestState == ASIS3RequestError) {
            NSLog(@"%@", [request error]);
            
            if ([[request shouldRefresh] boolValue]) {
                [self refresh:self];
            }
            
            if ([requestKind isEqualToString:ASIS3RequestAddObject]) {
                [self cleanOperationTransferSpeedLog];
            }
        }else if (requestState == ASIS3RequestCanceled) {
            if ([requestKind isEqualToString:ASIS3RequestAddObject]) {
                [self cleanOperationTransferSpeedLog];
            }
        }
    }
    
    //下载
    if ([requestKind isEqualToString:ASIS3RequestDownloadObject]) {
        
        [self willChangeValueForKey:@"hasActiveRequest"];
        [self hasActiveRequest];
        [self didChangeValueForKey:@"hasActiveRequest"];
        
        [self updateRequest:request forState:requestState];
        
        if (requestState == ASIS3RequestDone) {
            
            NSLog(@"finish download");
            [self cleanOperationTransferSpeedLog];
            
        }else if (requestState == ASIS3RequestError) {
            
            NSLog(@"%@", [request error]);
            
            if ([[NSFileManager defaultManager] fileExistsAtPath:request.downloadDestinationPath]) {
                [[NSFileManager defaultManager] removeItemAtPath:request.downloadDestinationPath error:NULL];
            }
            
            [self cleanOperationTransferSpeedLog];
            
        }else if (requestState == ASIS3RequestCanceled) {
            
            [self cleanOperationTransferSpeedLog];
        }
    }
}

- (void)cleanOperationTransferSpeedLog {
    
    BOOL shouldCleanSpeedLog = YES;
    NSArray *ops = [[[NSApp delegate] networkQueue] operations];
    for (ASIS3Request *request in ops) {
        if (([[request showKind] isEqualToString:ASIS3RequestAddObject] || [[request showKind] isEqualToString:ASIS3RequestDownloadObject]) &&
            ([[request showStatus] isEqualToString:RequestUserInfoStatusActive] || [[request showSubStatus] isEqualToString:RequestUserInfoStatusPending]))
        {
            shouldCleanSpeedLog = NO;
            break;
        }
    }
    
    if (shouldCleanSpeedLog) {
        S3OperationController *logController = (S3OperationController *)[[[NSApp delegate] controllers] objectForKey:@"Console"];
        NSTextField *textField = [[[logController window] contentView] viewWithTag:110];
        [textField setStringValue:@""];
    }
}

#pragma mark - S3DragAndDropProtocol

- (void)sortDescriptorsDidChange {
    
    if (_currentPrefix != nil && ![_currentPrefix isEqualToString:@""]) {
        
        for (ASIS3BucketObject *o in [_objectsController content]) {
            
            if ([[o key] isEqualToString:@".."]) {
                [_objectsController removeObject:o];
            }
        }
    }
}

- (void)didClickTableColumn {
    
    if (_currentPrefix != nil && ![_currentPrefix isEqualToString:@""]) {
        
        ASIS3BucketObject *object = [ASIS3BucketObject objectWithBucket:[[self bucket] name]];
        [object setKey:@".."];
        [object setObjetType:@"goBack"];
        [object setIcon:[[NSWorkspace sharedWorkspace] iconForFileType:NSFileTypeForHFSTypeCode(kGenericFolderIcon)]];
        [_objectsController insertObject:object atArrangedObjectIndex:0];
        [[_objectsController tableView] deselectAll:self];
    }
}

- (BOOL)acceptFileForImport:(NSString *)path
{
    return [[NSFileManager defaultManager] isReadableFileAtPath:path];
}

- (void)importURLs:(NSArray *)urls withDialog:(BOOL)dialog
{
    // First expand directories and only keep paths to files
    
    BOOL hasTooManyFiles = NO;
    
    NSArray *paths = [urls expandPaths:&hasTooManyFiles];
    
    if (hasTooManyFiles) {
        
        NSAlert *alert = [NSAlert alertWithMessageText:@"目录包含文件过多（不能超过1000个）"
                                         defaultButton:@"OK" alternateButton:nil
                                           otherButton:nil informativeTextWithFormat:@"请重新分批上传"];
        
        [alert runModal];
        
        return;
    }
    
    NSString *path;
    NSMutableArray *filesInfo = [NSMutableArray array];
    NSString *prefix = [NSString commonPathComponentInPaths:paths];
    
    NSString *folderName = @"";
    
    if ([urls count] == 1 && [paths count] != 1) {
        
        NSString *decoded = (__bridge_transfer NSString *)CFURLCreateStringByReplacingPercentEscapesUsingEncoding(NULL, (CFStringRef)[[urls objectAtIndex:0] absoluteString], CFSTR(""), kCFStringEncodingUTF8);
        NSArray *chunks = [decoded componentsSeparatedByString:@"/"];
        folderName = [NSString stringWithFormat:@"%@/", [chunks objectAtIndex:[chunks count]-2]];
        
        prefix = [decoded substringFromIndex:7];
    }
    
    for (path in paths) {
        NSMutableDictionary *info = [NSMutableDictionary dictionary];
        [info setObject:path forKey:FILEDATA_PATH];
        [info setObject:[path fileSizeForPath] forKey:FILEDATA_SIZE];
        [info safeSetObject:[path mimeTypeForPath] forKey:FILEDATA_TYPE withValueForNil:@"application/octet-stream"];
        [info setObject:[NSString stringWithFormat:@"%@%@%@", _currentPrefix==nil?@"":_currentPrefix, folderName, [path substringFromIndex:[prefix length]]] forKey:FILEDATA_KEY];
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

#pragma mark -
#pragma mark Actions

- (IBAction)refresh:(id)sender
{
    
    NSArray *ops = [[[NSApp delegate] networkRefreshQueue] operations];
    
    for (ASIS3Request *request in ops) {
        
        if ([request isKindOfClass:[ASIS3BucketRequest class]] &&
            [[request showKind] isEqualToString:ASIS3RequestListObject] &&
            ([[request showStatus] isEqualToString:RequestUserInfoStatusActive] || [[request showSubStatus] isEqualToString:RequestUserInfoStatusPending]) &&
            ([[(ASIS3BucketRequest *)request bucket] isEqualToString:self.bucket.name]))
        {
            return;
        }
    }
    
    _canRefresh = NO;
    [_tempObjectsArray removeAllObjects];
    
    ASIS3BucketRequest *listRequest = [ASIS3BucketRequest requestWithBucket:[[self bucket] name]];
    [listRequest setDelimiter:@"/"];
    [listRequest setPrefix:_currentPrefix];
    [listRequest setMaxResultCount:MaxResultCountOnePage];
    [listRequest setShowKind:ASIS3RequestListObject];
    [listRequest setShowStatus:RequestUserInfoStatusPending];
    
    [_operations addObject:listRequest];
    [self addOperations];
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
        [deleteObjectRequest setShowKind:ASIS3RequestDeleteObject];
        [deleteObjectRequest setShowStatus:RequestUserInfoStatusPending];
        //[self addToCurrentNetworkQueue:deleteObjectRequest];
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
    
//    NSEnumerator *e = [[_objectsController selectedObjects] objectEnumerator];
//    while (b = [e nextObject])
//    {
//        ASIS3ObjectRequest *deleteObjectRequest = [ASIS3ObjectRequest DELETERequestWithBucket:[[self bucket] name] key:[b key]];
//        
//        [deleteObjectRequest setShowKind:ASIS3RequestDeleteObject];
//        [deleteObjectRequest setShowStatus:RequestUserInfoStatusPending];
//        [_operations addObject:deleteObjectRequest];
//    }
    
    
        
    for (int i=0; i<count; i++) {
        
        b = [[_objectsController selectedObjects] objectAtIndex:i];
        
        ASIS3ObjectRequest *deleteObjectRequest = [ASIS3ObjectRequest DELETERequestWithBucket:[[self bucket] name] key:[b key]];
        
        [deleteObjectRequest setShowKind:ASIS3RequestDeleteObject];
        [deleteObjectRequest setShowStatus:RequestUserInfoStatusPending];
        if (i == count-1) {
            [deleteObjectRequest setShouldRefresh:@YES];
        }else {
            [deleteObjectRequest setShouldRefresh:@NO];
        }
        
        [_operations addObject:deleteObjectRequest];
    }
    
    [self addOperations];
}

- (IBAction)doubleClicked:(id)sender {
    
    NSArray* selectedObjects = [_objectsController selectedObjects];
    
    if ([selectedObjects count] > 1) {
        return;
    }
    
    for(ASIS3BucketObject* b in selectedObjects) {
        
        if ([[b key] hasSuffix:@"/"]) {
            
            if (_currentPrefix != nil) {
                [_superPrefixs addObject:_currentPrefix];
            }else {
                [_superPrefixs addObject:@""];
            }
            [self setCurrentPrefix:[b key]];
            
            [self refresh:sender];
            
        }else if ([[b key] isEqualToString:@".."]) {
            
            [self setCurrentPrefix:[_superPrefixs objectAtIndex:[_superPrefixs count]-1]];
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
    
    if ([selectedObjects count] > 5) {
        
        NSAlert *alert = [NSAlert alertWithMessageText:@"请重新选择文件"
                                         defaultButton:@"OK" alternateButton:nil
                                           otherButton:nil informativeTextWithFormat:@"下载最多同时选择5个文件"];
        
        [alert runModal];
        
        return;
    }
        
    for(ASIS3BucketObject* b in selectedObjects)
    {
        NSSavePanel *sp = [NSSavePanel savePanel];
        NSString *n = [[b key] lastPathComponent];
        if (n==nil) n = @"Untitled";
        
        //[sp setTitle:n];
        //[sp setNameFieldLabel:n];
        [sp setNameFieldStringValue:n];
        
        [sp beginWithCompletionHandler:^(NSInteger result) {
            if (result == NSOKButton) {
            
                ASIS3ObjectRequest *downloadRequest = [ASIS3ObjectRequest requestWithBucket:[[self bucket] name] key:[b key]];
                
                NSString *downloadPath = [[sp URL] path];
                
                [downloadRequest setTemporaryFileDownloadPath:[NSString stringWithFormat:@"%@.%@.tmp", downloadPath, [b ETag]]];
                [downloadRequest setDownloadDestinationPath:downloadPath];
                [downloadRequest setDownloadProgressDelegate:self];
                [downloadRequest setShowAccurateProgress:YES];
                [downloadRequest setAllowResumeForFileDownloads:YES];
                
                long long downloadedPartSize = 0;
                if ([[NSFileManager defaultManager] fileExistsAtPath:downloadRequest.temporaryFileDownloadPath] && [downloadRequest allowResumeForFileDownloads]) {
                    downloadedPartSize = [[[NSFileManager defaultManager] attributesOfItemAtPath:downloadRequest.temporaryFileDownloadPath error:nil] fileSize];
                    [downloadRequest addRequestHeader:@"If-Range" value:[b ETag]];
                }
                
                [downloadRequest setShowKind:ASIS3RequestDownloadObject];
                [downloadRequest setShowStatus:RequestUserInfoStatusPending];
                [downloadRequest setShowTransferedBytes:[NSString stringWithFormat:@"%lld", (long long)0]];
                [downloadRequest setShowResumeDownloadedFileSize:[NSString stringWithFormat:@"%lld", downloadedPartSize]];
                [downloadRequest setShowSubStatus:@""];

                [_operations addObject:downloadRequest];
                [self addOperations];
            }
        }];
    }
}

- (void)uploadFile:(NSDictionary *)data acl:(NSString *)acl shouldRefresh:(BOOL)shouldRefresh
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
    
    // 控制签名超时
    NSString *expiredDateString = [[ASIS3Request S3RequestDateFormatter] stringFromDate:[[NSDate date] dateByAddingTimeInterval:60*60*24]];
    [uploadRequest setDateString:expiredDateString];
    
    // 网络不好时适当加大响应超时时间
    [uploadRequest setTimeOutSeconds:60];
    
    [uploadRequest setAccessPolicy:acl];
    [uploadRequest setUploadProgressDelegate:self];
    [uploadRequest setShowAccurateProgress:YES];

    [uploadRequest setShowKind:ASIS3RequestAddObject];
    [uploadRequest setShowStatus:RequestUserInfoStatusPending];
    [uploadRequest setShowTransferedBytes:[NSString stringWithFormat:@"%d", 0]];
    [uploadRequest setShowSubStatus:@""];
    
    if (shouldRefresh) {
        [uploadRequest setShouldRefresh:@YES];
    }else {
        [uploadRequest setShouldRefresh:@NO];
    }
    
    [_operations addObject:uploadRequest];
}

- (void)uploadFiles
{	
//    NSEnumerator *e = [[self uploadData] objectEnumerator];
    NSDictionary *data;

    if ([[self uploadData] count] > 1) {
        
        for (int i=0; i<[[self uploadData] count]-1; i++) {
            
            data = [[self uploadData] objectAtIndex:i];
            [self uploadFile:data acl:[self uploadACL] shouldRefresh:NO];
        }
    }
    
    data = [[self uploadData] objectAtIndex:[[self uploadData] count]-1];
    [self uploadFile:data acl:[self uploadACL] shouldRefresh:YES];
    
//    while (data = [e nextObject]) {
//    }
    
    [self addOperations];
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
    
    [copyRequest setShowKind:ASIS3RequestCopyObject];
    [copyRequest setShowStatus:RequestUserInfoStatusPending];

    [_operations addObject:copyRequest];
    [self addOperations];
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
    
    long long bytesDownloaded = [[(ASIS3Request *)request showTransferedBytes] longLongValue] + bytes;
    [(ASIS3Request *)request setShowTransferedBytes:[NSString stringWithFormat:@"%lld", bytesDownloaded]];
    long long resumeDownloadedFileSize = [[(ASIS3Request *)request showResumeDownloadedFileSize] longLongValue];
    [(ASIS3Request *)request setShowSubStatus:[NSString stringWithFormat:@"%.2f%%", (GLfloat)bytesDownloaded / (GLfloat)(resumeDownloadedFileSize + [request contentLength]) * 100.0]];
    
    [[(ASIS3Request *)request logObject] update];
    
    S3OperationController *logController = (S3OperationController *)[[[NSApp delegate] controllers] objectForKey:@"Console"];
    NSTextField *textField = [[[logController window] contentView] viewWithTag:110];
    NSNumber *speedNumber = [NSNumber numberWithUnsignedLong:[ASIS3Request averageBandwidthUsedPerSecond]];
    [textField setStringValue:[NSString stringWithFormat:@"Transfer speed : %@/sec", [speedNumber readableFileSize]]];
    
}

- (void)request:(ASIHTTPRequest *)request didSendBytes:(long long)bytes {
    
    long long bytesUploaded = [[(ASIS3Request *)request showTransferedBytes] longLongValue] + bytes;
    [(ASIS3Request *)request setShowTransferedBytes:[NSString stringWithFormat:@"%lld", bytesUploaded]];
    [(ASIS3Request *)request setShowSubStatus:[NSString stringWithFormat:@"%.2f%%", (GLfloat)bytesUploaded / (GLfloat)[request postLength] * 100.0]];
    
    [[(ASIS3Request *)request logObject] update];
    
    S3OperationController *logController = (S3OperationController *)[[[NSApp delegate] controllers] objectForKey:@"Console"];
    NSTextField *textField = [[[logController window] contentView] viewWithTag:110];
    NSNumber *speedNumber = [NSNumber numberWithUnsignedLong:[ASIS3Request averageBandwidthUsedPerSecond]];
    [textField setStringValue:[NSString stringWithFormat:@"Transfer speed : %@/sec", [speedNumber readableFileSize]]];
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

- (void)setCurrentPrefix:(NSString *)currentPrefix {
    _currentPrefix = currentPrefix;
}

- (NSString *)currentPrefix {
    
    return _currentPrefix;
}

- (BOOL)hasActiveRequest {
    
    for (ASIS3Request *request in [[[NSApp delegate] networkQueue] operations]) {
        
        if (([request isKindOfClass:[ASIS3BucketRequest class]] && [[(ASIS3BucketRequest *)request bucket] isEqualToString:self.bucket.name]) ||
            ([request isKindOfClass:[ASIS3ObjectRequest class]] && [[(ASIS3ObjectRequest *)request bucket] isEqualToString:self.bucket.name])) {
            
            return YES;
        }
    }
    
    for (ASIS3Request *request in [[[NSApp delegate] networkRefreshQueue] operations]) {
        
        if ([request isKindOfClass:[ASIS3BucketRequest class]] && [[(ASIS3BucketRequest *)request bucket] isEqualToString:self.bucket.name]) {
            return YES;
        }
    }
    
    return NO;
}

#pragma mark -
#pragma mark Dealloc

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:ASIS3RequestStateDidChangeNotification object:nil];
}

@end
