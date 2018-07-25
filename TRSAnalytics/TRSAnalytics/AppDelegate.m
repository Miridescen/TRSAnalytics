//
//  AppDelegate.m
//  TRSAnalytics
//
//  Created by 824810056 on 2018/7/18.
//  Copyright © 2018年 Miridescent. All rights reserved.
//

#import "AppDelegate.h"

#define TRS_APPKEY      @"jbczeeio_07n3im5xqdt46"
#define TRS_APPID       @"28"
#define TRS_URL         @"https://ta.trs.cn/a"

#define DEBUG_TRS_APPKEY @"jfdo3s7k_143897onpwu5r"
#define DEBUG_TRS_APPID  @"43"
#define DEBUG_TRS_URL    @"http://111.203.35.55/c"

#import "TRSAnalytics.h"
#import "MainTableViewController.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];

    MainTableViewController *mainTVC = [[MainTableViewController alloc] init];
    mainTVC.view.backgroundColor = [UIColor whiteColor];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:mainTVC];
    
    self.window.rootViewController = nav;
    [self.window makeKeyAndVisible];
    [self registerSDK];
    return YES;
}

- (void)registerSDK{
    
//    NSString *idfa = [[ASIdentifierManager sharedManager] advertisingIdentifier].UUIDString;
    NSMutableDictionary *AttrDic = [@{} mutableCopy];
    // 个像ID
    NSString *gxIDStr = @"xxxx";
    [AttrDic setObject:gxIDStr forKey:@"gxDeviceID"];
    // oldDeviceID
    NSString *oldDeviceIDStr = @"xxxx";
    [AttrDic setObject:oldDeviceIDStr forKey:@"oldDeviceID"];
    
    [TRSAnalytics startWithAppKey:TRS_APPKEY        // 系统分发的APPKEY
                            appID:TRS_APPID         // 系统分发的APPID
                        staticURL:TRS_URL           // 系统分发的STATICURL
                         deviceID:@"123456"         // 设备ID（选传）
                          channel:@"APP Store"      // 下载渠道（选传，不传则默认是APP Store）
                       attributes:AttrDic];         // 自定义信息（选传）
    
    
    
    [TRSAnalytics setLogEnable:YES];
}




@end
