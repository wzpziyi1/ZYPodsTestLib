//
//  ZYViewController.m
//  BaseLib
//
//  Created by wzpziyi1 on 08/29/2017.
//  Copyright (c) 2017 wzpziyi1. All rights reserved.
//

#import "ZYViewController.h"
#import "YQDObjectToJsonStringUtils.h"

@interface ZYViewController ()

@end

@implementation ZYViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    [YQDObjectToJsonStringUtils dictionaryToString:@{}];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
