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
//#import <AdSupport/AdSupport.h>

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    
    UIViewController *mainTVC = [[UIViewController alloc] init];
    mainTVC.view.backgroundColor = [UIColor whiteColor];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:mainTVC];
    
    self.window.rootViewController = nav;
    [self.window makeKeyAndVisible];
    
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


- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}


@end
