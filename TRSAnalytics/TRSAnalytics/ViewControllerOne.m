
//
//  ViewControllerOne.m
//  TRSAnalytics
//
//  Created by 824810056 on 2018/7/19.
//  Copyright © 2018年 Miridescent. All rights reserved.
//

#import "ViewControllerOne.h"
#import "TRSAnalytics.h"
@interface ViewControllerOne ()

@end

@implementation ViewControllerOne
- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    [TRSAnalytics pageBegin:@"one"];
}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [TRSAnalytics pageEnd:@"one"];
}
- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"one";
    self.view.backgroundColor = [UIColor whiteColor];
    
    [self addButtons];
}

- (void)addButtons{
    UIButton *button1 = [UIButton buttonWithType:UIButtonTypeInfoDark];
    button1.frame = CGRectMake(50, 100, 0, 0);
    [button1 setTitle:@"one" forState:UIControlStateNormal];
    [button1 sizeToFit];
    [button1 addTarget:self action:@selector(button1Click) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button1];
    
    UIButton *button2 = [UIButton buttonWithType:UIButtonTypeInfoDark];
    button2.frame = CGRectMake(50, 150, 0, 0);
    [button2 setTitle:@"two" forState:UIControlStateNormal];
    [button2 sizeToFit];
    [button2 addTarget:self action:@selector(button2Click) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button2];
    
}

- (void)button1Click{
    [TRSAnalytics event:@"buttonOne"];
}

- (void)button2Click{
    [TRSAnalytics event:@"buttonTwo"];
}

@end
