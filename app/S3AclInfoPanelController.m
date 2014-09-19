//
//  S3AclInfoPanelController.m
//  SCS-Objc
//
//  Created by Littlebox222 on 14-9-16.
//
//

#import "S3AclInfoPanelController.h"

#import "S3ApplicationDelegate.h"
#import "S3OperationQueue.h"
#import "ASIS3Request+showValue.h"

@interface S3AclInfoPanelController () <NSTableViewDataSource, NSTableViewDelegate, NSTextFieldDelegate> {
    
    NSMutableDictionary *_aclUserDict;
    NSMutableDictionary *_aclGroupDict;

    NSString *_tmpUserId;
    NSTextField *_currentEditingField;
}

@end

@implementation S3AclInfoPanelController

@synthesize aclDict = _aclDict;
@synthesize isBucket = _isBucket;
@synthesize bucketName = _bucketName;

- (void)dealloc {
    
    self.name = nil;
    self.ownerID = nil;
    
    self.tableViewGroup.delegate = nil;
    self.tableViewGroup.dataSource = nil;
    self.tableViewUser.delegate = nil;
    self.tableViewUser.dataSource = nil;
    
    self.tableViewGroup = nil;
    self.tableViewUser = nil;
    
    self.aclDict = nil;
    
    _tmpUserId = nil;
    _currentEditingField = nil;
    _bucketName = nil;
    
    [_aclUserDict removeAllObjects];
    _aclUserDict = nil;
    
    [_aclGroupDict removeAllObjects];
    _aclGroupDict = nil;
}

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        self.aclDict = [[NSDictionary alloc] init];
        _aclUserDict = [[NSMutableDictionary alloc] initWithDictionary:self.aclDict];
        _aclGroupDict = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    self.tableViewGroup.delegate = self;
    self.tableViewGroup.dataSource = self;
    self.tableViewUser.delegate = self;
    self.tableViewUser.dataSource = self;
    
    [_aclUserDict removeAllObjects];
    [_aclUserDict addEntriesFromDictionary:self.aclDict];
    
    [_aclGroupDict removeAllObjects];
    [_aclGroupDict setObject:([self.aclDict objectForKey:@"GRPS0000000CANONICAL"]==nil?@[]:[self.aclDict objectForKey:@"GRPS0000000CANONICAL"]) forKey:@"GRPS0000000CANONICAL"];
    [_aclGroupDict setObject:([self.aclDict objectForKey:@"GRPS000000ANONYMOUSE"]==nil?@[]:[self.aclDict objectForKey:@"GRPS000000ANONYMOUSE"]) forKey:@"GRPS000000ANONYMOUSE"];
    
    for (NSString *key in [_aclUserDict allKeys]) {
        if ([key isEqualToString:@"GRPS0000000CANONICAL"]) {
            [_aclUserDict removeObjectForKey:@"GRPS0000000CANONICAL"];
        }
        if ([key isEqualToString:@"GRPS000000ANONYMOUSE"]) {
            [_aclUserDict removeObjectForKey:@"GRPS000000ANONYMOUSE"];
        }
    }
    
    [self.tableViewGroup reloadData];
    [self.tableViewUser reloadData];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    
    if (tableView.tag == 0) {
        return [_aclGroupDict count];
    }else {
        return [_aclUserDict count];
    }
}

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row {
    
    return 17;
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    
    NSView *cellView = [[NSView alloc] init];
    
    if (tableView.tag == 0) {
        
        if ([tableColumn.identifier isEqualToString:@"组"]) {
            
            cellView.frame = CGRectMake(0, 0, 180, 17);
            NSTextField *text = [[NSTextField alloc] initWithFrame:cellView.frame];
            [text setBordered:NO];
            text.alignment = NSCenterTextAlignment;
            [text setEditable:NO];
            text.backgroundColor = [NSColor clearColor];
            [cellView addSubview:text];
            
            if (row == 0) {
                text.stringValue = @"匿名用户组";
            }else if (row == 1) {
                text.stringValue = @"认证用户组";
            }
        
        }else {
            
            cellView.frame = CGRectMake(0, 0, 64, 17);
            NSButton *checkBox = [[NSButton alloc] initWithFrame:CGRectMake(24, 0, 16, 16)];
            [checkBox setButtonType:NSSwitchButton];
            [checkBox setAction:@selector(checkStateChanged:)];
            [cellView addSubview:checkBox];
            
            NSArray *aclArray = nil;
            if (row == 0) {
                aclArray = [_aclGroupDict objectForKey:@"GRPS000000ANONYMOUSE"];
            }else if (row == 1) {
                aclArray = [_aclGroupDict objectForKey:@"GRPS0000000CANONICAL"];
            }
            
            
            if ([tableColumn.identifier isEqualToString:@"read"]) {
                if (aclArray && [aclArray indexOfObject:@"read"] != NSNotFound) {
                    [checkBox setState:1];
                }
                
            }else if ([tableColumn.identifier isEqualToString:@"write"]) {
                if (aclArray && [aclArray indexOfObject:@"write"] != NSNotFound) {
                    [checkBox setState:1];
                }
            }else if ([tableColumn.identifier isEqualToString:@"read_acp"]) {
                if (aclArray && [aclArray indexOfObject:@"read_acp"] != NSNotFound) {
                    [checkBox setState:1];
                }
            }else {
                if (aclArray && [aclArray indexOfObject:@"write_acp"] != NSNotFound) {
                    [checkBox setState:1];
                }
                
            }
        }
        
    }else {
        
        if ([tableColumn.identifier isEqualToString:@"userId"]) {
            
            cellView.frame = CGRectMake(0, 0, 180, 17);
            NSTextField *text = [[NSTextField alloc] initWithFrame:cellView.frame];
            [text setBordered:NO];
            text.alignment = NSCenterTextAlignment;
            [text setEditable:YES];
            text.backgroundColor = [NSColor clearColor];
            text.delegate = self;
            [cellView addSubview:text];
            
            
            NSArray * keys = [_aclUserDict allKeys];
            NSArray * sorted_keys = [keys sortedArrayUsingSelector:@selector(compare:)];
            text.stringValue = [sorted_keys objectAtIndex:row];
            
        }else if ([tableColumn.identifier isEqualToString:@"remove"]) {
            
            cellView.frame = CGRectMake(0, 0, 64, 17);
            NSButton *removeBtn = [[NSButton alloc] initWithFrame:CGRectMake(12, 0, 40, 16)];
            removeBtn.title = @"删除";
            [removeBtn setAction:@selector(deleteButtonPressed:)];
            [cellView addSubview:removeBtn];
            
        }else {
            
            cellView.frame = CGRectMake(0, 0, 64, 17);
            NSButton *checkBox = [[NSButton alloc] initWithFrame:CGRectMake(24, 0, 16, 16)];
            [checkBox setButtonType:NSSwitchButton];
            [checkBox setAction:@selector(checkStateChanged:)];
            [cellView addSubview:checkBox];
            
            NSArray * keys = [_aclUserDict allKeys];
            NSArray * sorted_keys = [keys sortedArrayUsingSelector:@selector(compare:)];
            NSString *userId = [sorted_keys objectAtIndex:row];
            NSArray *aclArray = [_aclUserDict objectForKey:userId];
            
            if ([tableColumn.identifier isEqualToString:@"read"]) {
                if (aclArray && [aclArray indexOfObject:@"read"] != NSNotFound) {
                    [checkBox setState:1];
                }
                
            }else if ([tableColumn.identifier isEqualToString:@"write"]) {
                if (aclArray && [aclArray indexOfObject:@"write"] != NSNotFound) {
                    [checkBox setState:1];
                }
            }else if ([tableColumn.identifier isEqualToString:@"read_acp"]) {
                if (aclArray && [aclArray indexOfObject:@"read_acp"] != NSNotFound) {
                    [checkBox setState:1];
                }
            }else {
                if (aclArray && [aclArray indexOfObject:@"write_acp"] != NSNotFound) {
                    [checkBox setState:1];
                }
            }
        }
    }
    
    return cellView;
}

- (void)deleteButtonPressed:(NSButton *)sender {
    
    if (_currentEditingField != nil) {
        [[_currentEditingField window] makeFirstResponder:nil];
    }
    
    NSInteger selectedRow = [self.tableViewUser rowForView:sender];
    
    NSTextField *uidTextField = [[[self.tableViewUser viewAtColumn:0 row:selectedRow makeIfNecessary:NO] subviews] objectAtIndex:0];
    NSString *userId = uidTextField.stringValue;
    
    [self.tableViewUser removeRowsAtIndexes:[NSIndexSet indexSetWithIndex:selectedRow] withAnimation:NSTableViewAnimationEffectNone];
    [_aclUserDict removeObjectForKey:userId];
}

- (void)checkStateChanged:(NSButton *)sender {
    
    if (_currentEditingField != nil) {
        [[_currentEditingField window] makeFirstResponder:nil];
    }
    
    NSTextField *uidTextField = nil;
    
    NSInteger selectedRow = -2;
    NSButton *check_0 = nil;
    NSButton *check_1 = nil;
    NSButton *check_2 = nil;
    NSButton *check_3 = nil;
    
    if ([self.tableViewGroup rowForView:sender] != -1) {
        selectedRow = [self.tableViewGroup rowForView:sender];
        uidTextField = [[[self.tableViewGroup viewAtColumn:0 row:selectedRow makeIfNecessary:NO] subviews] objectAtIndex:0];
    }else {
        selectedRow = [self.tableViewUser rowForView:sender];
        uidTextField = [[[self.tableViewUser viewAtColumn:0 row:selectedRow makeIfNecessary:NO] subviews] objectAtIndex:0];
    }
    
    NSString *userId = uidTextField.stringValue;
    
    if ([userId isEqualToString:@"匿名用户组"]) {

        check_0 = [[[self.tableViewGroup viewAtColumn:1 row:selectedRow makeIfNecessary:NO] subviews] objectAtIndex:0];
        check_1 = [[[self.tableViewGroup viewAtColumn:2 row:selectedRow makeIfNecessary:NO] subviews] objectAtIndex:0];
        check_2 = [[[self.tableViewGroup viewAtColumn:3 row:selectedRow makeIfNecessary:NO] subviews] objectAtIndex:0];
        check_3 = [[[self.tableViewGroup viewAtColumn:4 row:selectedRow makeIfNecessary:NO] subviews] objectAtIndex:0];
        userId = @"GRPS000000ANONYMOUSE";
        
        NSMutableArray *aclArray = [NSMutableArray array];
        if (check_0.state) {
            [aclArray addObject:@"read"];
        }
        if (check_1.state) {
            [aclArray addObject:@"write"];
        }
        if (check_2.state) {
            [aclArray addObject:@"read_acp"];
        }
        if (check_3.state) {
            [aclArray addObject:@"write_acp"];
        }
        
        [_aclGroupDict setObject:aclArray forKey:userId];
        
    }else if ([userId isEqualToString:@"认证用户组"]) {
        
        check_0 = [[[self.tableViewGroup viewAtColumn:1 row:selectedRow makeIfNecessary:NO] subviews] objectAtIndex:0];
        check_1 = [[[self.tableViewGroup viewAtColumn:2 row:selectedRow makeIfNecessary:NO] subviews] objectAtIndex:0];
        check_2 = [[[self.tableViewGroup viewAtColumn:3 row:selectedRow makeIfNecessary:NO] subviews] objectAtIndex:0];
        check_3 = [[[self.tableViewGroup viewAtColumn:4 row:selectedRow makeIfNecessary:NO] subviews] objectAtIndex:0];
        userId = @"GRPS0000000CANONICAL";
        
        NSMutableArray *aclArray = [NSMutableArray array];
        if (check_0.state) {
            [aclArray addObject:@"read"];
        }
        if (check_1.state) {
            [aclArray addObject:@"write"];
        }
        if (check_2.state) {
            [aclArray addObject:@"read_acp"];
        }
        if (check_3.state) {
            [aclArray addObject:@"write_acp"];
        }
        
        [_aclGroupDict setObject:aclArray forKey:userId];
        
    }else {
        
        check_0 = [[[self.tableViewUser viewAtColumn:1 row:selectedRow makeIfNecessary:NO] subviews] objectAtIndex:0];
        check_1 = [[[self.tableViewUser viewAtColumn:2 row:selectedRow makeIfNecessary:NO] subviews] objectAtIndex:0];
        check_2 = [[[self.tableViewUser viewAtColumn:3 row:selectedRow makeIfNecessary:NO] subviews] objectAtIndex:0];
        check_3 = [[[self.tableViewUser viewAtColumn:4 row:selectedRow makeIfNecessary:NO] subviews] objectAtIndex:0];
        
        NSMutableArray *aclArray = [NSMutableArray array];
        if (check_0.state) {
            [aclArray addObject:@"read"];
        }
        if (check_1.state) {
            [aclArray addObject:@"write"];
        }
        if (check_2.state) {
            [aclArray addObject:@"read_acp"];
        }
        if (check_3.state) {
            [aclArray addObject:@"write_acp"];
        }
        
        [_aclUserDict setObject:aclArray forKey:userId];
    }
}

- (IBAction)cancelButtonPressed:(id)sender {
    
    if (_currentEditingField != nil) {
        [[_currentEditingField window] makeFirstResponder:nil];
    }
    
    [_aclGroupDict removeAllObjects];
    [_aclGroupDict setObject:([self.aclDict objectForKey:@"GRPS0000000CANONICAL"]==nil?@[]:[self.aclDict objectForKey:@"GRPS0000000CANONICAL"]) forKey:@"GRPS0000000CANONICAL"];
    [_aclGroupDict setObject:([self.aclDict objectForKey:@"GRPS000000ANONYMOUSE"]==nil?@[]:[self.aclDict objectForKey:@"GRPS000000ANONYMOUSE"]) forKey:@"GRPS000000ANONYMOUSE"];
    
    [_aclUserDict removeAllObjects];
    [_aclUserDict addEntriesFromDictionary:self.aclDict];
    
    for (NSString *key in [_aclUserDict allKeys]) {
        if ([key isEqualToString:@"GRPS0000000CANONICAL"]) {
            [_aclUserDict removeObjectForKey:@"GRPS0000000CANONICAL"];
        }
        if ([key isEqualToString:@"GRPS000000ANONYMOUSE"]) {
            [_aclUserDict removeObjectForKey:@"GRPS000000ANONYMOUSE"];
        }
    }
    
    [self.tableViewGroup reloadData];
    [self.tableViewUser reloadData];
    
}

- (IBAction)saveButtonPressed:(id)sender {
    
    if (_currentEditingField != nil) {
        [[_currentEditingField window] makeFirstResponder:nil];
    }
    
    NSMutableDictionary *aclSetDict = [NSMutableDictionary dictionary];
    [aclSetDict addEntriesFromDictionary:_aclUserDict];
    [aclSetDict addEntriesFromDictionary:_aclGroupDict];
    
    for (NSString *key in [aclSetDict allKeys]) {
        if ([key length] != 20) {
            [aclSetDict removeObjectForKey:key];
        }
    }
    
    NSAlert *alert = [[NSAlert alloc] init];
    [alert addButtonWithTitle:@"取消"];
    [alert addButtonWithTitle:@"继续"];
    [alert setMessageText:@"保存后将无法撤销，是否继续？"];
    [alert setInformativeText:@""];
    [alert setAlertStyle:NSInformationalAlertStyle];
    [alert beginSheetModalForWindow:self.window completionHandler:^(NSModalResponse returnCode) {
    
        if (returnCode == -NSModalResponseAbort) {
            
            [self.addButton setEnabled:NO];
            [self.cancelButton setEnabled:NO];
            [self.saveButton setEnabled:NO];
            [self.saveButton setTitle:@"保存中..."];
            
            if (self.isBucket) {
                ASIS3BucketRequest *putACLRequest = [ASIS3BucketRequest PUTACLRequestWithBucket:self.name aclDict:aclSetDict];
                [putACLRequest setShowKind:ASIS3RequestPutACLBucket];
                [putACLRequest setShowStatus:RequestUserInfoStatusPending];
                [putACLRequest setUserInfo:@{@"aclDict":aclSetDict, @"windowName":self.name}];
                [_operations addObject:putACLRequest];
                [self addOperations];
            }else {
                ASIS3ObjectRequest *putACLRequest = [ASIS3ObjectRequest PUTACLRequestWithBucket:_bucketName key:_name aclDict:aclSetDict];
                [putACLRequest setShowKind:ASIS3RequestPutACLObject];
                [putACLRequest setShowStatus:RequestUserInfoStatusPending];
                [putACLRequest setUserInfo:@{@"aclDict":aclSetDict, @"windowName":self.name}];
                [_operations addObject:putACLRequest];
                [self addOperations];
            }
            
        }
    }];
    
    
    
}

- (IBAction)addButtonPressed:(id)sender {
    
    if (_currentEditingField != nil) {
        [[_currentEditingField window] makeFirstResponder:nil];
    }
    
    [_aclUserDict setObject:@[] forKey:@" "];
    [self.tableViewUser reloadData];
}

- (void)controlTextDidBeginEditing:(NSNotification *)aNotification {
    
    NSTextField *textField = [aNotification object];
    
    if (textField.stringValue.length > 1 && [textField.stringValue hasPrefix:@" "]) {
        _tmpUserId = [NSString stringWithFormat:@"%@", [textField.stringValue substringFromIndex:1]];
    }else {
        _tmpUserId = [NSString stringWithFormat:@"%@", textField.stringValue];
    }
    
    _currentEditingField = textField;
}

- (void)controlTextDidEndEditing:(NSNotification *)aNotification {

    if (_tmpUserId) {
        
        NSTextField *textField = [aNotification object];
        NSString *newUserId = textField.stringValue;
        if (newUserId.length > 1 && [newUserId hasPrefix:@" "]) {
            newUserId = [newUserId substringFromIndex:1];
        }
        
        [_aclUserDict setObject:[_aclUserDict objectForKey:_tmpUserId] forKey:newUserId];
        [_aclUserDict removeObjectForKey:_tmpUserId];
        _tmpUserId = nil;
        _currentEditingField = nil;
    }
}

#pragma mark - ASIS3RequestState NSNotification

- (void)asiS3RequestStateDidChange:(NSNotification *)notification {
    
    if (![[notification name] isEqualToString:ASIS3RequestStateDidChangeNotification]) {
        return;
    }
    
    ASIS3Request *request = [[notification userInfo] objectForKey:ASIS3RequestKey];
    ASIS3RequestState requestState = [[[notification userInfo] objectForKey:ASIS3RequestStateKey] unsignedIntegerValue];
    
    if (![[request.userInfo objectForKey:@"windowName"] isEqualToString:_name]) {
        return;
    }
    
    NSString *requestKind = [request showKind];
    
    if ([requestKind isEqualToString:ASIS3RequestPutACLBucket] || [requestKind isEqualToString:ASIS3RequestPutACLObject]) {
        
        [self willChangeValueForKey:@"hasActiveRequest"];
        [self hasActiveRequest];
        [self didChangeValueForKey:@"hasActiveRequest"];
        
        [self updateRequest:request forState:requestState];
        
        if (requestState == ASIS3RequestDone) {
            
            [self.cancelButton setEnabled:YES];
            [self.addButton setEnabled:YES];
            [self.saveButton setEnabled:YES];
            [self.saveButton setTitle:@"保存"];
            
            self.aclDict = nil;
            NSDictionary *dict = [request.userInfo objectForKey:@"aclDict"];
            self.aclDict = [NSDictionary dictionaryWithDictionary:dict];
            
            NSAlert *alert = [[NSAlert alloc] init];
            [alert addButtonWithTitle:@"OK"];
            [alert setMessageText:@"ACL设置成功"];
            [alert setInformativeText:@""];
            [alert setAlertStyle:NSInformationalAlertStyle];
            [alert beginSheetModalForWindow:self.window completionHandler:^(NSModalResponse returnCode) {}];
            
        }else if (requestState == ASIS3RequestError) {
            
            [self.cancelButton setEnabled:YES];
            [self.addButton setEnabled:YES];
            [self.saveButton setEnabled:YES];
            [self.saveButton setTitle:@"保存"];
            
            NSLog(@"%@", [request error]);
        }
    }
}

@end
