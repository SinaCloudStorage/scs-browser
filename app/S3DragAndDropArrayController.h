//
//  S3DragAndDropArrayController.h
//  S3-Objc
//
//  Created by Bruce Chen on 8/17/06.
//  Copyright 2014 Bruce Chen. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol S3DragAndDropProtocol
- (void)importURLs:(NSArray *)urls withDialog:(BOOL)dialog;
- (BOOL)acceptFileForImport:(NSString *)path;

- (void)sortDescriptorsDidChange;
- (void)didClickTableColumn;

@end

@interface S3DragAndDropArrayController : NSArrayController <NSTableViewDelegate, NSTableViewDataSource>
{
    IBOutlet NSTableView *tableView;
	id<S3DragAndDropProtocol> delegate;
}

- (NSDragOperation)tableView:(NSTableView *)tv validateDrop:(id <NSDraggingInfo>)info proposedRow:(int)row proposedDropOperation:(NSTableViewDropOperation)op;
- (BOOL)tableView:(NSTableView *)tv acceptDrop:(id <NSDraggingInfo>)info row:(int)row dropOperation:(NSTableViewDropOperation)op;

- (void)setFileOperationsDelegate:(id)d;

- (NSTableView *)tableView;

@end
