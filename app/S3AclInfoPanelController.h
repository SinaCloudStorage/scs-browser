//
//  S3AclInfoPanelController.h
//  SCS-Objc
//
//  Created by Littlebox222 on 14-9-16.
//
//

#import <Cocoa/Cocoa.h>
#import <ASIKit/ASIKit.h>
#import "S3ActiveWindowController.h"

@interface S3AclInfoPanelController : S3ActiveWindowController

@property (nonatomic) IBOutlet NSString *name;
@property (nonatomic) IBOutlet NSString *ownerID;
@property (nonatomic) NSString *bucketName;

@property (nonatomic) IBOutlet NSTableView *tableViewGroup;
@property (nonatomic) IBOutlet NSTableView *tableViewUser;

@property (nonatomic) NSDictionary *aclDict;

@property (nonatomic) IBOutlet NSButton *saveButton;
@property (nonatomic) IBOutlet NSButton *addButton;
@property (nonatomic) IBOutlet NSButton *cancelButton;

@property (assign) BOOL isBucket;

- (IBAction)cancelButtonPressed:(id)sender;
- (IBAction)saveButtonPressed:(id)sender;
- (IBAction)addButtonPressed:(id)sender;
- (IBAction)cancelSheet:(id)sender;

@end
