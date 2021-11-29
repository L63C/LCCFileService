//
//  LCCViewController.m
//  LCCFileService
//
//  Created by lu63chuan@163.com on 11/29/2021.
//  Copyright (c) 2021 lu63chuan@163.com. All rights reserved.
//

#import "LCCViewController.h"
#import <LCFileNetService.h>
#import "ProtocolFinder.h"
#import "LCFileNetProtocol.h"
@interface LCCViewController ()<LCFileNetProtocol>
@property (nonatomic, strong) LCFileNetService *fileService;
@end

@implementation LCCViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [[ProtocolFinder defaultFinder] registerObj:self forProtocols:@[@protocol(LCFileNetProtocol)]];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
   
}
- (void)lc_fileNetProgress:(LCFileNetTask *)task{
    NSLog(@"%s",__func__);
}
- (void)lc_fileNetStatusChange:(LCFileNetTask *)task{
    NSLog(@"%s",__func__);
}
- (void)lc_fileNetFinshed:(LCFileNetTask *)task error:(NSError *)error{
    NSLog(@"%s",__func__);
}


@end
