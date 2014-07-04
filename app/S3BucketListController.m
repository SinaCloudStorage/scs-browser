//
//  S3BucketListController.m
//  S3-Objc
//
//  Created by Bruce Chen on 4/3/06.
//  Copyright 2014 Bruce Chen. All rights reserved.
//

#import "S3BucketListController.h"
#import "AWSRegion.h"
#import "S3Owner.h"
#import "S3Bucket.h"
#import "S3Extensions.h"
#import "S3ObjectListController.h"
#import "S3ApplicationDelegate.h"
#import "S3ListBucketOperation.h"
#import "S3AddBucketOperation.h"
#import "S3DeleteBucketOperation.h"
#import "S3OperationQueue.h"

#import "ASIS3Request+showValue.h"

#define SHEET_CANCEL 0
#define SHEET_OK 1

enum {
    USStandardLocation = 0,
    USWestLocation = 1,
    EUIrelandLocation = 2
};


@interface S3BucketListController () <NSToolbarDelegate>

@end

@implementation S3BucketListController

#pragma mark -
#pragma mark Toolbar management

- (void)awakeFromNib
{
    if ([S3ActiveWindowController instancesRespondToSelector:@selector(awakeFromNib)] == YES) {
        [super awakeFromNib];
    }
    NSToolbar *toolbar = [[NSToolbar alloc] initWithIdentifier:@"BucketsToolbar"];
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
    [[[[[[self window] contentView] viewWithTag:10] tableColumnWithIdentifier:@"creationDate"] dataCell] setFormatter:dateFormatter];

    _bucketListControllerCache = [[NSMutableDictionary alloc] init];
}

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar*)toolbar
{
    return @[NSToolbarSeparatorItemIdentifier,
        NSToolbarSpaceItemIdentifier,
        NSToolbarFlexibleSpaceItemIdentifier,
        @"Refresh", @"Remove", @"Add"];
}

- (BOOL)validateToolbarItem:(NSToolbarItem *)theItem
{
    if ([[theItem itemIdentifier] isEqualToString: @"Remove"])
        return [_bucketsController canRemove];
    return YES;
}

- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar *)toolbar
{
    return @[@"Add", @"Remove", NSToolbarFlexibleSpaceItemIdentifier, @"Refresh"]; 
}

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag
{
    NSToolbarItem *item = [[NSToolbarItem alloc] initWithItemIdentifier: itemIdentifier];
    
    if ([itemIdentifier isEqualToString: @"Add"])
    {
        [item setLabel: NSLocalizedString(@"Add", nil)];
        [item setPaletteLabel: [item label]];
        [item setImage: [NSImage imageNamed: @"add.png"]];
        [item setTarget:self];
        [item setAction:@selector(add:)];
    }
    else if ([itemIdentifier isEqualToString: @"Remove"])
    {
        [item setLabel: NSLocalizedString(@"Remove", nil)];
        [item setPaletteLabel: [item label]];
        [item setImage: [NSImage imageNamed: @"delete.png"]];
        [item setTarget:self];
        [item setAction:@selector(remove:)];
    }
    else if ([itemIdentifier isEqualToString: @"Refresh"])
    {
        [item setLabel: NSLocalizedString(@"Refresh", nil)];
        [item setPaletteLabel: [item label]];
        [item setImage: [NSImage imageNamed: @"refresh.png"]];
        [item setTarget:self];
        [item setAction:@selector(refresh:)];
    }
    
    return item;
}

#pragma mark -
#pragma mark Misc Delegates

- (IBAction)cancelSheet:(id)sender
{
    [NSApp endSheet:addSheet returnCode:SHEET_CANCEL];
}

- (IBAction)closeSheet:(id)sender
{
    [NSApp endSheet:addSheet returnCode:SHEET_OK];
}
//
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
//    if ([operation state] == S3OperationDone) {
//        if ([operation isKindOfClass:[S3ListBucketOperation class]]) {
//            [self setBuckets:[(S3ListBucketOperation *)operation bucketList]];
//            [self setBucketsOwner:[(S3ListBucketOperation *)operation owner]];			
//        } else {
//            [self refresh:self];            
//        }
//    }
//}

#pragma mark - ASIS3RequestState NSNotification

- (void)asiS3RequestStateDidChange:(NSNotification *)notification {
    
    if (![[notification name] isEqualToString:ASIS3RequestStateDidChangeNotification]) {
        return;
    }
    
    ASIS3Request *request = [[notification userInfo] objectForKey:ASIS3RequestKey];
    ASIS3RequestState requestState = [[[notification userInfo] objectForKey:ASIS3RequestStateKey] unsignedIntegerValue];
    
    [self updateRequest:request forState:requestState];
    //NSString *requestKind = [[request userInfo] objectForKey:RequestUserInfoKindKey];
    NSString *requestKind = [request showKind];
    
    if ([requestKind isEqualToString:ASIS3RequestListBucket]) {
        
        if (requestState == ASIS3RequestDone) {
            
            [self setBuckets:[(ASIS3ServiceRequest *)request buckets]];
            
            ASIS3Bucket *bucket = nil;
            if ([[(ASIS3ServiceRequest *)request buckets] count] != 0) {
                bucket = [[(ASIS3ServiceRequest *)request buckets] objectAtIndex:0];
                [self setBucketsOwnerWithID:[bucket ownerID] displayName:[bucket ownerName]];
            }
            
        }else if (requestState == ASIS3RequestError) {
            
            NSLog(@"%@", [request error]);
        }
    }
    
    if ([requestKind isEqualToString:ASIS3RequestAddBucket] || [requestKind isEqualToString:ASIS3RequestDeleteBucket]) {
        
        if (requestState == ASIS3RequestDone) {
            
            [self refresh:self];
            
        }else if (requestState == ASIS3RequestError) {
            
            NSLog(@"%@", [request error]);
        }
    }
}

#pragma mark -
#pragma mark Actions

- (IBAction)remove:(id)sender
{
    NSAlert *alert = [[NSAlert alloc] init];
    if ([[_bucketsController selectedObjects] count] == 1) {
        [alert setMessageText:NSLocalizedString(@"Remove bucket permanently?",nil)];
        [alert setInformativeText:NSLocalizedString(@"Warning: Are you sure you want to remove the bucket? This operation cannot be undone.",nil)];        
    } else {
        [alert setMessageText:NSLocalizedString(@"Remove all selected buckets permanently?",nil)];
        [alert setInformativeText:NSLocalizedString(@"Warning: Are you sure you want to remove all the selected buckets? This operation cannot be undone.",nil)];
    }
    [alert addButtonWithTitle:NSLocalizedString(@"Cancel",nil)];
    [alert addButtonWithTitle:NSLocalizedString(@"Remove",nil)];
    if ([alert runModal] == NSAlertFirstButtonReturn)
    {   
        return;
    }

    S3Bucket *b;
    NSEnumerator *e = [[_bucketsController selectedObjects] objectEnumerator];
    
    while (b = [e nextObject]) {
        
        ASIS3BucketRequest *deleteRequest = [ASIS3BucketRequest DELETERequestWithBucket:[b name]];
        [deleteRequest setShowKind:ASIS3RequestDeleteBucket];
        [deleteRequest setShowStatus:RequestUserInfoStatusPending];
        //[deleteRequest setUserInfo:@{RequestUserInfoKindKey:ASIS3RequestDeleteBucket, RequestUserInfoStatusKey:RequestUserInfoStatusPending}];
        [self addToCurrentNetworkQueue:deleteRequest];
    }
}

- (IBAction)refresh:(id)sender
{
	ASIS3ServiceRequest *request = [ASIS3ServiceRequest serviceRequest];
    [request setShowKind:ASIS3RequestListBucket];
    [request setShowStatus:RequestUserInfoStatusPending];
    //[request setUserInfo:@{RequestUserInfoKindKey:ASIS3RequestListBucket, RequestUserInfoStatusKey:RequestUserInfoStatusPending}];
    [self addToCurrentNetworkQueue:request];
}


- (void)didEndSheet:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
    [sheet orderOut:self];
    
    if (returnCode==SHEET_OK) {
        
        if (_name == nil) {
            return;
        }
                
        ASIS3BucketRequest *addRequest = [ASIS3BucketRequest PUTRequestWithBucket:_name];
        [addRequest setShowKind:ASIS3RequestAddBucket];
        [addRequest setShowStatus:RequestUserInfoStatusPending];
        //[addRequest setUserInfo:@{RequestUserInfoKindKey:ASIS3RequestAddBucket, RequestUserInfoStatusKey:RequestUserInfoStatusPending}];
        [self addToCurrentNetworkQueue:addRequest];
    }
}

- (IBAction)add:(id)sender
{
    [self setName:@"Untitled"];
    [NSApp beginSheet:addSheet modalForWindow:[self window] modalDelegate:self didEndSelector:@selector(didEndSheet:returnCode:contextInfo:) contextInfo:nil];
}

- (IBAction)open:(id)sender
{
    
    ASIS3Bucket *b;
    NSEnumerator* e = [[_bucketsController selectedObjects] objectEnumerator];
    while (b = [e nextObject])
    {
        S3ObjectListController *c = nil;
        if ((c = [_bucketListControllerCache objectForKey:[b name]])) {
            [c showWindow:self];
        } else {
            c = [[S3ObjectListController alloc] initWithWindowNibName:@"Objects"];
            [c setBucket:b];

            [c setConnInfo:[self connInfo]];
            
            [c showWindow:self];            
            [_bucketListControllerCache setObject:c forKey:[b name]];
        }
    }
}

#pragma mark -
#pragma mark Key-value coding

+ (NSSet *)keyPathsForValuesAffectingValueForKey:(NSString *)key
{
    if ([key isEqual:@"isValidName"]) {
        return [NSSet setWithObject:@"name"];
    }
    
    return nil;
}

- (NSString *)name
{
    return _name; 
}

- (void)setName:(NSString *)aName
{
    _name = aName;
}

- (BOOL)isValidName
{
    // The length of the bucket name must be between 3 and 255 bytes. It can contain letters, numbers, dashes, and underscores.
    if ([_name length]<3)
        return NO;
    if ([_name length]>255)
        return NO;
    // This is a bit brute force, we should check iteratively and not reinstantiate on every call.
    NSCharacterSet *s = [[NSCharacterSet characterSetWithCharactersInString:@"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_-."] invertedSet];
    if ([_name rangeOfCharacterFromSet:s].location!=NSNotFound)
        return NO;
    return YES;
}


- (void)setBucketsOwnerWithID:(NSString *)ownerId displayName:(NSString *)displayName
{
    [self setBucketOwnerId:ownerId];
    [self setBucketOwnerDisplayName:displayName];
}

- (void)setBucketOwnerId:(NSString *)ownerId {
    _bucketOwnerId = ownerId;
}

- (void)setBucketOwnerDisplayName:(NSString *)displayName {
    _bucketOwnerDisplayName = displayName;
}


- (NSString *)bucketOwnerId {
    return _bucketOwnerId;
}

- (NSString *)bucketOwnerDisplayName {
    return _bucketOwnerDisplayName;
}

- (NSArray *)buckets
{
    return _buckets; 
}

- (void)setBuckets:(NSArray *)aBuckets
{
    _buckets = aBuckets;
}

#pragma mark -
#pragma mark Dealloc

-(void)dealloc
{
    [[self window] setToolbar:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:ASIS3RequestStateDidChangeNotification object:nil];
}

@end
