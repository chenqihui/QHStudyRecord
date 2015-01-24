//
//  SecondViewController.m
//  QHStudyRecord
//
//  Created by chen on 15-1-22.
//  Copyright (c) 2015年 chen. All rights reserved.
//

#import "SecondViewController.h"

@interface SecondViewController ()

@end

@implementation SecondViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.tabBarItem.title = @"second";
    self.tabBarItem.image = [UIImage imageNamed:@"first"];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
