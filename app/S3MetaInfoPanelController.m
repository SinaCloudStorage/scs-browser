//
//  S3MetaInfoPanelController.m
//  SCS-Objc
//
//  Created by Littlebox222 on 14/11/3.
//
//

#import "S3MetaInfoPanelController.h"

@interface S3MetaInfoPanelController ()

@end

@implementation S3MetaInfoPanelController

@synthesize name = _name;
@synthesize metaDict = _metaDict;
@synthesize textView = _textView;

- (void)windowDidLoad {
    [super windowDidLoad];
    self.textView.string = [NSString stringWithFormat:@"%@", self.metaDict];
}

- (IBAction)cancelSheet:(id)sender
{
    [NSApp endSheet:[sender window] returnCode:0];
}


@end
