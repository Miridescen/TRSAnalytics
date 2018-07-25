
//
//  TRSNetworkManager.m
//  TRSAnalytics
//
//  Created by 824810056 on 2018/7/20.
//  Copyright © 2018年 Miridescent. All rights reserved.
//

#import "TRSNetworkManager.h"
#import "TRSCommen.h"
#import "TRSDefaultCacheManager.h"
#import "TRSHTTPManager.h"
#import "TRSReachability2.h"
#import "TRSBaseModel.h"
#import "TRSSystemInfo.h"

@interface TRSNetworkManager()
{
    TRSDefaultCacheManager *_defaultCacheManage;
    TRSHTTPManager *_HTTPManager;
}


@end

@implementation TRSNetworkManager
+ (TRSNetworkManager *)sharedManager{
    static TRSNetworkManager *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[TRSNetworkManager alloc] init];
        
    });
    return manager;
}

- (instancetype)init{
    self = [super init];
    if (self) {
        self->_defaultCacheManage = [TRSDefaultCacheManager sharedManager];
        self->_HTTPManager = [TRSHTTPManager sharedManger];
    }
    return self;
}

- (void)sendDataWithWithDataArray:(NSArray *)dataArray Success:(TRSSendDataSuccess)success failure:(TRSSendDataFailure)failure{
    if (dataArray.count == 0 || dataArray == nil) {
        return;
    }
    
    NSString *staticURL = [NSString stringWithFormat:@"%@", [self->_defaultCacheManage deviceInfoWithKey:@"staticURL"]];
    NSArray *staticURLArr = [staticURL componentsSeparatedByString:@"/"];
    if (staticURLArr.count>3) {
        staticURL = staticURLArr[2];
    }
    TRSReachability2 *reachability = [TRSReachability2 reachabilityWithHostname:staticURL];
    if (reachability.reachable) {
        // model转字典
        NSMutableArray *arr = [NSMutableArray array];
        for (TRSBaseModel *model in dataArray) {
            NSDictionary *dic = TRSDataToDirectory(model.jsonData);
            if (dic) [arr addObject:dic];
        }
        // 发送
        NSString *url = [self->_defaultCacheManage deviceInfoWithKey:@"staticURL"];
        NSString *head1 = [NSString stringWithFormat:@"%@", [self->_defaultCacheManage deviceInfoWithKey:@"UUID"]];
        NSString *head2 = [self->_defaultCacheManage deviceInfoWithKey:@"appkey"];

        [self->_HTTPManager managerSendHTTPRequestWithUrl:url head1:head1 head2:head2 dataArray:arr success:^(id response) {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                success();
            });
 
        } failure:^(NSError *error) {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                failure(error);
            });

        }];
        
    } else {
        TRSNSLog(@"网络不好用");
        NSError *error = [[NSError alloc] init];
        dispatch_async(dispatch_get_main_queue(), ^{
            failure(error);
        });
        
        return;
    }
}


/**
 发送deviceID
 */
- (void)sendDeviceID:(NSString *)deviceID Success:(TRSSendDataSuccess)success failure:(TRSSendDataFailure)failure{
    if (TRSBlankStr(deviceID)) {
        return;
    }
    
    TRSNSLog(@"-------------发送设备信息-----------------");
//    NSString *deviceID = [NSString stringWithFormat:@"%@", [self->_defaultCacheManage deviceInfoWithKey:@"deviceID"]];
    NSString *staticURL = [[NSString stringWithFormat:@"%@", [self->_defaultCacheManage deviceInfoWithKey:@"staticURL"]] stringByAppendingString:@"/openapi/appDeviceId"];
    NSString *param;
    NSString *url;

    param = [NSString stringWithFormat:@"wmDeviceId=%@&mpId=%@&deviceId=%@&osVersion=%@&sdkVersion=%@",
             [self->_defaultCacheManage deviceInfoWithKey:@"UUID"],
             [self->_defaultCacheManage deviceInfoWithKey:@"mpId"],
             [self->_defaultCacheManage deviceInfoWithKey:@"deviceID"],
             [self->_defaultCacheManage deviceInfoWithKey:@"ov"],
             [self->_defaultCacheManage deviceInfoWithKey:@"sv"]];
    
    if (!TRSBlankStr([self->_defaultCacheManage deviceInfoWithKey:@"olddeviceid"])) {
        param =  [param stringByAppendingString:[NSString stringWithFormat:@"&oldDeviceId=%@", [self->_defaultCacheManage deviceInfoWithKey:@"olddeviceid"]]];
    }
    
    url = [NSString stringWithFormat:@"%@?%@", staticURL, param];

    [self->_HTTPManager managerSendDeviceIDWithUrl:url success:^(id response) {
        success();
    } failure:^(NSError *error) {
        failure(error);
    }];
 
}


/**
 发送个像ID
 */
- (void)sendGXDeviceID:(NSString *)GXdeviceID Success:(TRSSendDataSuccess)success failure:(TRSSendDataFailure)failure{
//    NSString *GXdeviceID = [NSString stringWithFormat:@"%@", [self->_defaultCacheManage deviceInfoWithKey:@"gxdeviceid"]];
    
    if (TRSBlankStr(GXdeviceID)) {
        return;
    }
    
    TRSNSLog(@"-------------发送gx设备信息-----------------");
    
    NSString *staticURL = [[NSString stringWithFormat:@"%@", [self->_defaultCacheManage deviceInfoWithKey:@"staticURL"]] stringByAppendingString:@"/openapi/appDeviceId"];
    NSString *param;
    NSString *url;

    param = [NSString stringWithFormat:@"wmDeviceId=%@&mpId=%@&osVersion=%@&sdkVersion=%@&machineCode=%@&deviceIdJSON={gxDeviceId:'%@'}",
             [self->_defaultCacheManage deviceInfoWithKey:@"UUID"],
             [self->_defaultCacheManage deviceInfoWithKey:@"mpId"],
             [self->_defaultCacheManage deviceInfoWithKey:@"ov"],
             [self->_defaultCacheManage deviceInfoWithKey:@"sv"],
             [self->_defaultCacheManage deviceInfoWithKey:@"IDFA"],
             [self->_defaultCacheManage deviceInfoWithKey:@"gxdeviceid"]];
    
    if (!TRSBlankStr([self->_defaultCacheManage deviceInfoWithKey:@"deviceID"])) {
        param =  [param stringByAppendingString:[NSString stringWithFormat:@"&deviceId=%@", [self->_defaultCacheManage deviceInfoWithKey:@"deviceID"]]];
    }
    
    url = [NSString stringWithFormat:@"%@?%@", staticURL, param];
    
    [self->_HTTPManager managerSendDeviceIDWithUrl:url success:^(id response) {
        success();
    } failure:^(NSError *error) {
        failure(error);
    }];
}
- (void)sendUserInfo:(NSString *)uid Success:(TRSSendDataSuccess)success failure:(TRSSendDataFailure)failure{
    if (TRSBlankStr(uid)) {
        return;
    }
    
    
    NSString *staticURL = [[NSString stringWithFormat:@"%@", [self->_defaultCacheManage deviceInfoWithKey:@"staticURL"]] stringByAppendingString:@"/openapi/appLoginUserInfo"];
    NSString *param;
    NSString *url;
    
    param = [NSString stringWithFormat:@"wmDeviceId=%@&mpId=%@&uidstr=%@&userName=%@&extraInfo=%@",
             [self->_defaultCacheManage deviceInfoWithKey:@"UUID"],
             [self->_defaultCacheManage deviceInfoWithKey:@"mpId"],
             [self->_defaultCacheManage deviceInfoWithKey:@"uid"],
             [self->_defaultCacheManage deviceInfoWithKey:@"se_un"],
             [self->_defaultCacheManage deviceInfoWithKey:@"extraInfo"]];
    
    url = [NSString stringWithFormat:@"%@?%@", staticURL, param];
    
    //    NSLog(@"userInfo == %@", url);

    [self->_HTTPManager managerSendUserInfoWithUrl:url success:^(id response) {
        success();
    } failure:^(NSError *error) {
        failure(error);
    }];
    
}

- (void)sendDebugStateDeviceMessageSuccess:(TRSSendDataSuccess)success failure:(TRSSendDataFailure)failure{
    NSString *staticURL = [NSString stringWithFormat:@"%@", [self->_defaultCacheManage deviceInfoWithKey:@"staticURL"]];
    NSArray *staticURLArr = [staticURL componentsSeparatedByString:@"/"];
    NSString *hostUrlStr = [NSString stringWithFormat:@"%@//%@/bas/tadebug/appShakeData",staticURLArr[0],staticURLArr[2]];
    
    NSString *param = [NSString stringWithFormat:@"mpId=%@&wmDeviceId=%@&deviceModel=%@&deviceName=%@",
                       [self->_defaultCacheManage deviceInfoWithKey:@"mpId"],
                       [self->_defaultCacheManage deviceInfoWithKey:@"UUID"],
                       [self->_defaultCacheManage deviceInfoWithKey:@"dm"],
                       [TRSSystemInfo phoneName]];
    NSString *url = [NSString stringWithFormat:@"%@?%@", hostUrlStr, param];
    [self->_HTTPManager manageDebugSendDeviceMessageWithURL:url success:^(id response) {
        success();
    } failure:^(NSError *error) {
        failure(error);
    }];
    
    
}
- (void)sendDebugDataWithDataArray:(NSArray *)dataArray{
    if (dataArray.count == 0 || dataArray == nil) {
        return;
    }
    
    NSString *staticURL = [NSString stringWithFormat:@"%@", [self->_defaultCacheManage deviceInfoWithKey:@"staticURL"]];
    NSArray *staticURLArr = [staticURL componentsSeparatedByString:@"/"];
    if (staticURLArr.count>3) {
        staticURL = staticURLArr[2];
    }
    TRSReachability2 *reachability = [TRSReachability2 reachabilityWithHostname:staticURL];
    
    if (reachability.reachable) {
        // model转字典
        NSMutableArray *arr = [NSMutableArray array];
        for (TRSBaseModel *model in dataArray) {
            NSDictionary *dic = TRSDataToDirectory(model.jsonData);
            if (dic) [arr addObject:dic];
        }
        NSString *url = [self->_defaultCacheManage deviceInfoWithKey:@"staticURL"];
        NSString *head1 = [NSString stringWithFormat:@"%@", [self->_defaultCacheManage deviceInfoWithKey:@"UUID"]];
        NSString *head2 = [self->_defaultCacheManage deviceInfoWithKey:@"appkey"];
        
        [self->_HTTPManager managerDebugSendHTTPRequestWithUrl:url head1:head1 head2:head2 dataArray:arr success:^(id response) {
            NSLog(@"----------debug成功发送1条数据----------\n");
            NSLog(@"%@", arr);
        } failure:^(NSError *error) {
            NSLog(@"----------debug发送数据失败，数据如下----------\n");
            NSLog(@"%@", arr);
        }];
        
    } else {
        NSLog(@"----------网络不好用，发送数据失败----------\n");
    }
}


@end
