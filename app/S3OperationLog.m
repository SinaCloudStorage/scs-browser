//
//  S3OperationLog.m
//  S3-Objc
//
//  Created by Michael Ledford on 12/1/08.
//  Copyright 2008 Michael Ledford. All rights reserved.
//

#import "S3OperationLog.h"

#import "S3Operation.h"


@implementation S3OperationLog

@synthesize operations = _operations;

- (id)init
{
    self = [super init];
    
    if (self != nil) {
        NSMutableArray *array = [[NSMutableArray alloc] init];
        [self setOperations:array];
    }
    
    return self;
}

- (void)removeObjectFromOperationsAtIndex:(NSUInteger)index
{
    [[self operations] removeObjectAtIndex:index];
}

- (void)logOperations:(NSMutableArray *)objectArray
{
    [self willChangeValueForKey:@"operations"];
    [[self operations] addObjectsFromArray:objectArray];
    [self didChangeValueForKey:@"operations"];
}

- (void)unlogOperation:(LogObject *)o
{
    NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
    
    if ([[standardUserDefaults objectForKey:@"autoclean"] boolValue] == TRUE) {
        
        NSUInteger indexOfObject = [[self operations] indexOfObject:o];
        
        if (indexOfObject != NSNotFound) {
            [self removeObjectFromOperationsAtIndex:indexOfObject];
        }
    }
}

@end