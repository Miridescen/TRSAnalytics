//
//  MainTableViewController.m
//  TRSAnalytics
//
//  Created by 824810056 on 2018/7/19.
//  Copyright © 2018年 Miridescent. All rights reserved.
//

#import "MainTableViewController.h"
#import "ViewControllerOne.h"
#import "ViewControllerTwo.h"

#import "TRSAnalytics.h"

@interface MainTableViewController ()

@end

@implementation MainTableViewController

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    [TRSAnalytics pageBegin:@"main"];
}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [TRSAnalytics pageEnd:@"main"];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"测试用例";
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

    return 3;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *tableViewCell = @"tableViewCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:tableViewCell];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:tableViewCell];
    }
    
    cell.textLabel.text = [NSString stringWithFormat:@"%ld", indexPath.row];
    
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.row == 0) {
        ViewControllerOne *oneVC = [[ViewControllerOne alloc] init];
        [self.navigationController pushViewController:oneVC animated:YES];
    }
    if (indexPath.row == 1) {
        ViewControllerTwo *twoVC = [[ViewControllerTwo alloc] init];
        [self.navigationController pushViewController:twoVC animated:YES];
    }
}




@end
