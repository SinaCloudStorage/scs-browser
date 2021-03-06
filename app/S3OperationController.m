//
//  S3OperationController.m
//  S3-Objc
//
//  Created by Bruce Chen on 4/8/06.
//  Copyright 2014 Bruce Chen. All rights reserved.
//

#import "S3OperationController.h"
#import "S3ApplicationDelegate.h"
#import "S3ValueTransformers.h"

#import "ASIS3Request+showValue.h"

#pragma mark -
#pragma mark The operation console/inspector itself

@interface S3OperationController () <NSToolbarDelegate>

@end


@implementation S3OperationController

+ (void)initialize
{
	[NSValueTransformer setValueTransformer:[S3OperationSummarizer new] forName:@"S3OperationSummarizer"];
}

-(void)awakeFromNib
{
	NSToolbar *toolbar = [[NSToolbar alloc] initWithIdentifier:@"OperationConsoleToolbar"];
	[toolbar setDelegate:self];
	[toolbar setVisible:YES];
	[toolbar setAllowsUserCustomization:YES];
	[toolbar setAutosavesConfiguration:NO];
	[toolbar setSizeMode:NSToolbarSizeModeSmall];
	[toolbar setDisplayMode:NSToolbarDisplayModeIconOnly];
	[[self window] setToolbar:toolbar];
}

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar *)toolbar
{
	return @[NSToolbarSeparatorItemIdentifier,
		NSToolbarSpaceItemIdentifier,
		NSToolbarFlexibleSpaceItemIdentifier,
		@"Stop", @"Remove", @"Info"];
}

- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar*)toolbar
{
	return @[@"Info", @"Remove", NSToolbarFlexibleSpaceItemIdentifier, @"Stop"]; 
}

- (BOOL)validateToolbarItem:(NSToolbarItem *)theItem
{
	if ([[theItem itemIdentifier] isEqualToString:@"Remove"]) {	
		if (![_operationsArrayController canRemove]) {
			return NO;
        }
		
		NSEnumerator *e = [[_operationsArrayController selectedObjects] objectEnumerator];
		LogObject *op;
		while (op = [e nextObject]) {
			if (([[op showStatus] isEqualToString:RequestUserInfoStatusActive])||
                ([[op showStatus] isEqualToString:RequestUserInfoStatusPending])) {
				return NO;
            }
		}
		return YES;
	}
	if ([[theItem itemIdentifier] isEqualToString:@"Stop"]) {	
		NSEnumerator *e = [[_operationsArrayController selectedObjects] objectEnumerator];
		LogObject *op;
		while (op = [e nextObject]) {
			if (([[op showStatus] isEqualToString:RequestUserInfoStatusActive])||
                ([[op showStatus] isEqualToString:RequestUserInfoStatusPending])) {
				return YES;
            }
		}
		return NO;
	}
    if ([[theItem itemIdentifier] isEqualToString:@"Info"]) {
        if ([[_operationsArrayController selectedObjects] count] != 1) {
            return NO;
        }
    }

	return YES;
}

- (IBAction)remove:(id)sender;
{
	[_operationsArrayController remove:sender];
}

- (IBAction)stop:(id)sender;
{
	NSEnumerator *e = [[_operationsArrayController selectedObjects] objectEnumerator];
	LogObject *op;
	while (op = [e nextObject]) 
	{
		if (([[op showStatus] isEqualToString:RequestUserInfoStatusActive])||
            ([[op showStatus] isEqualToString:RequestUserInfoStatusPending])) {
            
            [[op request] cancel];
        }
	}	
}

- (IBAction)info:(id)sender
{
    NSInteger seclectIndex = [_operationsArrayController selectionIndex];
    [_operationsArrayController setSelectionIndex:-1];
    [_operationsArrayController setSelectionIndex:seclectIndex];
    
    [_infoPanel orderFront:self];
}

- (NSToolbarItem*)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag
{
	NSToolbarItem *item = [[NSToolbarItem alloc] initWithItemIdentifier: itemIdentifier];
	
	if ([itemIdentifier isEqualToString: @"Stop"])
	{
		[item setLabel: NSLocalizedString(@"Stop", nil)];
		[item setPaletteLabel: [item label]];
		[item setImage: [NSImage imageNamed: @"stop.png"]];
		[item setTarget:self];
		[item setAction:@selector(stop:)];
    }
	else if ([itemIdentifier isEqualToString: @"Remove"])
	{
		[item setLabel: NSLocalizedString(@"Remove", nil)];
		[item setPaletteLabel: [item label]];
		[item setImage: [NSImage imageNamed: @"delete.png"]];
		[item setTarget:self];
		[item setAction:@selector(remove:)];
    }
	else if ([itemIdentifier isEqualToString: @"Info"])
	{
		[item setLabel: NSLocalizedString(@"Info", nil)];
		[item setPaletteLabel: [item label]];
		[item setImage: [NSImage imageNamed: @"info.png"]];
		[item setTarget:self];
		[item setAction:@selector(info:)];
    }
	
    return item;
}


- (void)scrollToEnd {
    
    NSInteger numberOfRows = [[_operationsArrayController content] count];
    NSTableView *tableView = [[[self window] contentView] viewWithTag:10];
    
    [tableView scrollRowToVisible:numberOfRows-1];
}

@end
