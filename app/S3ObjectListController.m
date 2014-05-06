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

#define SHEET_CANCEL 0
#define SHEET_OK 1

#define DEFAULT_PRIVACY @"defaultUploadPrivacy"
#define ACL_PRIVATE @"private"

#define FILEDATA_PATH @"path"
#define FILEDATA_KEY  @"key"
#define FILEDATA_TYPE @"mime"
#define FILEDATA_SIZE @"size"

@interface S3ObjectListController () <NSToolbarDelegate>

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
    
    [[[NSApp delegate] queue] addQueueListener:self];
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
        return [[_objectsController arrangedObjects] count] > 0;
    } else if ([[theItem itemIdentifier] isEqualToString: @"Remove"]) {
        return [_objectsController canRemove];        
    } else if ([[theItem itemIdentifier] isEqualToString: @"Download"]) {
        return [_objectsController canRemove];        
    } else if ([[theItem itemIdentifier] isEqualToString: @"Rename"]) {
        return ([[_objectsController selectedObjects] count] == 1 );
    }
    return YES;
}

- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar *)toolbar
{
    return @[@"Upload", @"Download", @"Rename", @"Remove", NSToolbarSeparatorItemIdentifier,  @"Remove All", NSToolbarFlexibleSpaceItemIdentifier, @"Refresh"]; 
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

- (void)operationQueueOperationStateDidChange:(NSNotification *)notification
{
    S3Operation *op = [[notification userInfo] objectForKey:S3OperationObjectKey];
    NSUInteger index = [_operations indexOfObjectIdenticalTo:op];
    if (index == NSNotFound) {
        return;
    }
    
    [super operationQueueOperationStateDidChange:notification];
        
    if ([op isKindOfClass:[S3ListObjectOperation class]] && [op state] == S3OperationDone) {
        [self addObjects:[(S3ListObjectOperation *)op objects]];
        [self setObjectsInfo:[(S3ListObjectOperation*)op metadata]];
        
        S3ListObjectOperation *next = [(S3ListObjectOperation *)op operationForNextChunk];
        if (next != nil) {
            [self addToCurrentOperations:next];            
        } else {
            [self setValidList:YES];
        }
    }
    
    if ([op isKindOfClass:[S3CopyObjectOperation class]] && [_renameOperations containsObject:op] && [op state] == S3OperationDone) {
        [self setValidList:NO];
        //S3Object *sourceObject = [[op operationInfo] objectForKey:@"sourceObject"];
        S3Object *sourceObject = [(S3CopyObjectOperation *)op sourceObject];
        S3DeleteObjectOperation *deleteOp = [[S3DeleteObjectOperation alloc] initWithConnectionInfo:[op connectionInfo] object:sourceObject];
        [_renameOperations removeObject:op];
        [self addToCurrentOperations:deleteOp];
    }
    
    if (([op isKindOfClass:[S3AddObjectOperation class]] || [op isKindOfClass:[S3DeleteObjectOperation class]]) && [op state] == S3OperationDone) {
        [self setValidList:NO];
        NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
        if ([[standardUserDefaults objectForKey:@"norefresh"] boolValue] == TRUE) {
            return;
        }
        // Simple heuristics: if we still have something in the operation queue, no need to refresh now
        if (![self hasActiveOperations]) {
            [self refresh:self];            
        } else {
            _needsRefresh = YES;
        }
    }
}

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

#pragma mark -
#pragma mark Actions

- (IBAction)refresh:(id)sender
{
    [self setObjects:[NSMutableArray array]];
    [self setValidList:NO];
        
    S3ListObjectOperation *op = [[S3ListObjectOperation alloc] initWithConnectionInfo:[self connectionInfo] bucket:[self bucket]];
    
    [self addToCurrentOperations:op];
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
    
    S3Object *b;
    NSEnumerator *e = [[_objectsController arrangedObjects] objectEnumerator];
        
    while (b = [e nextObject])
    {
        S3DeleteObjectOperation *op = [[S3DeleteObjectOperation alloc] initWithConnectionInfo:[self connectionInfo] object:b];
        [self addToCurrentOperations:op];
    }
}

- (IBAction)remove:(id)sender
{
    S3Object *b;
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
        S3DeleteObjectOperation *op = [[S3DeleteObjectOperation alloc] initWithConnectionInfo:[self connectionInfo] object:b];
        [self addToCurrentOperations:op];
    }
}

- (IBAction)download:(id)sender
{
    NSArray* selectedObjects = [_objectsController selectedObjects];
        
    for(S3Object* b in selectedObjects)
    {
        NSSavePanel *sp = [NSSavePanel savePanel];
        NSString *n = [[b key] lastPathComponent];
        if (n==nil) n = @"Untitled";
        
        //[sp setTitle:n];
        //[sp setNameFieldLabel:n];
        [sp setNameFieldStringValue:n];
        
        __weak S3ObjectListController* _weakself = self;
        [sp beginWithCompletionHandler:^(NSInteger result) {
            if (result == NSOKButton)
        {
                S3DownloadObjectOperation *op = [[S3DownloadObjectOperation alloc] initWithConnectionInfo:[self connectionInfo]
                                                                                                   object:b
                                                                                                   saveTo:[[sp URL] path]];
                [_weakself addToCurrentOperations:op];
            }
        }];
        
    }
}


- (void)uploadFile:(NSDictionary *)data acl:(NSString *)acl
{
    NSString *path = [data objectForKey:FILEDATA_PATH];
    NSString *key = [data objectForKey:FILEDATA_KEY];
    NSString *mime = [data objectForKey:FILEDATA_TYPE];
    NSNumber *size = [data objectForKey:FILEDATA_SIZE];
    
    if (![self acceptFileForImport:path])
    {   
        NSDictionary* d = @{NSLocalizedDescriptionKey: [NSString stringWithFormat:NSLocalizedString(@"The file '%@' could not be read",nil),path]};
        [[self window] presentError:[NSError errorWithDomain:S3_ERROR_DOMAIN code:-2 userInfo:d] modalForWindow:[self window] delegate:self 
                 didPresentSelector:@selector(didPresentErrorWithRecovery:contextInfo:) contextInfo:nil];
        return;        
    }
    
    NSDictionary *dataSourceInfo = nil;
    //NSString *md5 = nil;
    if ([size longLongValue] < (1024 * 16)) {
        
        NSData *bodyData = [NSData dataWithContentsOfFile:path];
        dataSourceInfo = @{S3ObjectNSDataSourceKey: bodyData};        
        //md5 = [[bodyData md5Digest] encodeBase64];
    
    } else {
    
        dataSourceInfo = @{S3ObjectFilePathDataSourceKey: path};
        //NSError *error = nil;
        //NSData *bodyData = [NSData dataWithContentsOfFile:path options:(NSMappedRead|NSUncachedRead) error:&error];
        //md5 = [[bodyData md5Digest] encodeBase64];
    }
    
    NSMutableDictionary *metadataDict = [NSMutableDictionary dictionary];
    
    /*
    if (md5 != nil) {
    
        [metadataDict setObject:md5 forKey:S3ObjectMetadataContentMD5Key];
    }
     */
    
    if (mime != nil) {
        
        [metadataDict setObject:mime forKey:S3ObjectMetadataContentTypeKey];
    }
    
    if (acl != nil) {
    
        [metadataDict setObject:acl forKey:S3ObjectMetadataACLKey];
    }
    
    if (size != nil) {
    
        [metadataDict setObject:size forKey:S3ObjectMetadataContentLengthKey];
    }
    
    S3Object *objectToAdd = [[S3Object alloc] initWithBucket:[self bucket] key:key userDefinedMetadata:nil metadata:metadataDict dataSourceInfo:dataSourceInfo];
        
    S3AddObjectOperation *op = [[S3AddObjectOperation alloc] initWithConnectionInfo:[self connectionInfo] object:objectToAdd];

    [self addToCurrentOperations:op];
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
        [info setObject:[path substringFromIndex:[prefix length]] forKey:FILEDATA_KEY];
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
    S3Object *source = (__bridge_transfer S3Object *)contextInfo;

    [sheet orderOut:self];

    if (returnCode!=SHEET_OK) {
        return;
    }
    
    if ([[source key] isEqualToString:[self renameName]]) {
        return;
    }
    
    S3Object *newObject = [[S3Object alloc] initWithBucket:[self bucket] key:[self renameName]];
        
    S3CopyObjectOperation *copyOp = [[S3CopyObjectOperation alloc] initWithConnectionInfo:[self connectionInfo] from:source to:newObject];
    
    [_renameOperations addObject:copyOp];
    
    [self addToCurrentOperations:copyOp];
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

- (S3Bucket *)bucket
{
    return _bucket; 
}

- (void)setBucket:(S3Bucket *)aBucket
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
    [[[NSApp delegate] queue] removeQueueListener:self];
}

@end
