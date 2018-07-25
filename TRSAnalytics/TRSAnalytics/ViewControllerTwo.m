//
//  ViewControllerTwo.m
//  TRSAnalytics
//
//  Created by 824810056 on 2018/7/19.
//  Copyright © 2018年 Miridescent. All rights reserved.
//

#import "ViewControllerTwo.h"
#import "TRSAnalytics.h"
@interface ViewControllerTwo ()

@end

@implementation ViewControllerTwo
- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    [TRSAnalytics pageBegin:@"two"];
}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [TRSAnalytics pageEnd:@"two"];
}
- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"two";
    self.view.backgroundColor = [UIColor whiteColor];
}


@end
