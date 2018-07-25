//
//  UIWindow+TRS.m
//  TRSAnalytics
//
//  Created by 824810056 on 2018/3/27.
//  Copyright © 2018年 Miridescent. All rights reserved.
//

#import "UIWindow+TRS.h"
#import "TRSManager.h"
#import "TRSNetworkManager.h"

#define kTRSManager  [TRSManager sharedManager]
#define kTRSNetworkManager [TRSNetworkManager sharedManager]

@implementation UIWindow (TRS)

- (BOOL)canBecomeFirstResponder {//默认是NO
    return YES;
}


- (void)motionBegan:(UIEventSubtype)motion withEvent:(UIEvent *)event
{
//    NSLog(@"开始摇");
}

- (void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event
{
    if (kTRSManager.debugEnable && !kTRSManager.debugSuccess) {
        
        [kTRSNetworkManager sendDebugStateDeviceMessageSuccess:^{
            kTRSManager.debugSuccess = YES;
        } failure:^(NSError *error) {
            
        }];
    }
//    NSLog(@"摇动结束");
}

- (void)motionCancelled:(UIEventSubtype)motion withEvent:(UIEvent *)event
{
//    NSLog(@"取消摇动");
}

@end
