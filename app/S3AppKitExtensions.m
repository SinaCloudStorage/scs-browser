//
//  S3AppKitExtensions.m
//  S3-Objc
//
//  Created by Bruce Chen on 4/11/06.
//  Copyright 2006 Bruce Chen. All rights reserved.
//

#import "S3AppKitExtensions.h"
#import "S3Extensions.h"

@implementation NSArrayController (ToolbarExtensions)

- (BOOL)validateToolbarItem:(NSToolbarItem*)theItem
{
	if ([theItem action] == @selector(remove:))
		return [self canRemove];
	else
		return TRUE;
}

@end

@implementation NSHTTPURLResponse (Logging)

- (NSString *)httpStatus
{
	return [NSString stringWithFormat:@"%d (%@)",(int)[self statusCode],[NSHTTPURLResponse localizedStringForStatusCode:[self statusCode]]];
}

- (NSArray *)headersReceived
{
	NSMutableArray *a = [NSMutableArray array];
	NSEnumerator *e = [[self allHeaderFields] keyEnumerator];
	NSString *k;
	while (k = [e nextObject])
	{
		[a addObject:@{@"key": k,@"value": [[self allHeaderFields] objectForKey:k]}];
	}
	return a;
}

@end

@implementation NSURLRequest (Logging)

- (NSArray *)headersSent
{
	NSMutableArray *a = [NSMutableArray array];
	NSEnumerator *e = [[self allHTTPHeaderFields] keyEnumerator];
	NSString *k;
	while (k = [e nextObject])
	{
		[a addObject:@{@"key": k,@"value": [[self allHTTPHeaderFields] objectForKey:k]}];
	}
	return a;
}

@end



