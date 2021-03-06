//
//  S3ObjectListController.h
//  S3-Objc
//
//  Created by Bruce Chen on 4/3/06.
//  Copyright 2014 Bruce Chen. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "S3ActiveWindowController.h"
#import "S3DragAndDropArrayController.h"

@class S3Bucket;


@interface S3ObjectListController : S3ActiveWindowController  <S3DragAndDropProtocol> {
	
	ASIS3Bucket *_bucket;
	NSMutableArray *_objects;
	NSMutableDictionary *_objectsInfo;
	
	IBOutlet NSWindow *uploadSheet;
	IBOutlet NSWindow *multipleUploadSheet;
	IBOutlet S3DragAndDropArrayController *_objectsController;

    IBOutlet NSWindow *renameSheet;
    NSString *_renameName;
    NSMutableArray *_renameOperations;
        
	NSString *_uploadACL;
	NSString *_uploadFilename;
	NSString *_uploadSize;
	NSMutableArray *_uploadData;
    
    BOOL _needsRefresh;
    BOOL _validList;
    
    NSArray *_prefixArray;
    NSMutableArray *_superPrefixs;
    NSString *_currentPrefix;
    BOOL _isTruncated;
    NSMutableArray *_tempObjectsArray;
    
    BOOL _canRefresh;
    BOOL _initialize;
}	

@property (nonatomic, retain) NSString *currentPrefix;

- (IBAction)refresh:(id)sender;
- (IBAction)upload:(id)sender;
- (IBAction)download:(id)sender;
- (IBAction)remove:(id)sender;

- (IBAction)doubleClicked:(id)sender;

- (IBAction)cancelSheet:(id)sender;
- (IBAction)closeSheet:(id)sender;

- (BOOL)validList;
- (void)setValidList:(BOOL)yn;
- (NSString *)validListString;

- (void)addObjects:(NSArray *)aObjects;

- (NSMutableArray *)objects;
- (void)setObjects:(NSMutableArray *)aObjects;

- (NSMutableDictionary *)objectsInfo;
- (void)setObjectsInfo:(NSMutableDictionary *)aObjectsInfo;

- (ASIS3Bucket *)bucket;
- (void)setBucket:(ASIS3Bucket *)aBucket;

- (NSString *)renameName;
- (void)setRenameName:(NSString *)name;

- (NSString *)uploadACL;
- (void)setUploadACL:(NSString *)anUploadACL;
- (NSString *)uploadFilename;
- (void)setUploadFilename:(NSString *)anUploadFilename;
- (NSString *)uploadSize;
- (void)setUploadSize:(NSString *)anUploadSize;
- (NSMutableArray *)uploadData;
- (void)setUploadData:(NSMutableArray *)data;

- (BOOL)hasActiveRequest;

@end
