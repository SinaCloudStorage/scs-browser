//
//  S3DragAndDropArrayController.m
//  S3-Objc
//
//  Created by Bruce Chen on 8/17/06.
//  Copyright 2006 Bruce Chen. All rights reserved.
//

#import "S3DragAndDropArrayController.h"


@implementation S3DragAndDropArrayController

- (void)awakeFromNib
{
	[super awakeFromNib];
    [tableView registerForDraggedTypes:@[NSFilenamesPboardType]];
}

- (void)setFileOperationsDelegate:(id)d
{
	delegate = d;
}

- (BOOL)validateDraggingInfo:(id <NSDraggingInfo>)info 
{
    if ([[[info draggingPasteboard] types] containsObject:NSFilenamesPboardType]) 
    {
        NSArray *files = [[info draggingPasteboard] propertyListForType:NSFilenamesPboardType];
        for (id loopItem in files)
        {
            if ([delegate acceptFileForImport:loopItem])
                return YES;
        }
    }
    
	return NO;
}

- (NSDragOperation)tableView:(NSTableView *)tv validateDrop:(id <NSDraggingInfo>)info proposedRow:(int)row proposedDropOperation:(NSTableViewDropOperation)op
{
	if ([self validateDraggingInfo:info])
	{
		[tv setDropRow:-1 dropOperation:NSTableViewDropOn];	
		return NSDragOperationCopy;
	}
	else
		return NSDragOperationNone;
}

- (BOOL)tableView:(NSTableView *)tv acceptDrop:(id <NSDraggingInfo>)info row:(int)row dropOperation:(NSTableViewDropOperation)op
{
    if ([[[info draggingPasteboard] types] containsObject:NSFilenamesPboardType]) 
    {
        NSArray* files = [[info draggingPasteboard] propertyListForType:NSFilenamesPboardType];
        NSMutableArray* urls = [NSMutableArray array];
        for(NSString* file in files) {
            NSURL* url = [NSURL fileURLWithPath:file];
            if (url) {
                [urls addObject:url];
            }
        }
		[delegate importURLs:urls withDialog:TRUE];
        return YES;
	}
	else
		return NO;
}

@end

