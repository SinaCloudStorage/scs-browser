//
//  S3MetaInfoPanelController.h
//  SCS-Objc
//
//  Created by Littlebox222 on 14/11/3.
//
//

#import <Cocoa/Cocoa.h>

@interface S3MetaInfoPanelController : NSWindowController

@property (nonatomic) IBOutlet NSString *name;
@property (nonatomic) IBOutlet NSTextView *textView;
@property (nonatomic) NSDictionary *metaDict;
@property (assign) BOOL isBucket;

- (IBAction)cancelSheet:(id)sender;

@end
