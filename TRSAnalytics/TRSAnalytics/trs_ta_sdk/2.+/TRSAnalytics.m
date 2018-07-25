//
//  TRSAnalytics.m
//  TRS_SDK
//
//  Created by 824810056 on 2018/1/16.
//  Copyright © 2018年 牟松. All rights reserved.
//

#import "TRSAnalytics.h"
#import "TRSManager.h"
#import "TRSCommen.h"
#import "TRSPageConfig.h"
#import "TRSEventModelConfig.h"
#import "TRSBaseModel.h"
#import "TRSNetworkManager.h"
#import "TRSDBManager3.h"

#define kTRSManager  [TRSManager sharedManager]
#define kTRSNetworkManager [TRSNetworkManager sharedManager]
#define kTRSDBManager [TRSDBManager3 sharedManager]

@implementation TRSAnalytics

+ (void)startWithAppKey:(NSString *)appKey
                        appID:(NSString *)appID
                    staticURL:(NSString *)staticURL
                     deviceID:(nullable NSString *)deviceID
                      channel:(nullable NSString *)channel
                   attributes:(nullable NSDictionary *)attributes
{
    if (TRSBlankStr(channel)) channel = @"App store";
    [kTRSManager.defaultCacheManage memoryDeviceInfoWithKey:@"appkey" value:appKey];
    [kTRSManager.defaultCacheManage memoryDeviceInfoWithKey:@"mpId" value:appID];
    [kTRSManager.defaultCacheManage memoryDeviceInfoWithKey:@"staticURL" value:staticURL];
    [kTRSManager.defaultCacheManage memoryDeviceInfoWithKey:@"deviceID" value:deviceID];
    [kTRSManager.defaultCacheManage memoryDeviceInfoWithKey:@"channel" value:channel];

    [attributes enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {

        if ([[(NSString *)key lowercaseString] isEqualToString:@"gxdeviceid"] || [[(NSString *)key lowercaseString] isEqualToString:@"olddeviceid"]) {
            [kTRSManager.defaultCacheManage memoryDeviceInfoWithKey:[(NSString *)key lowercaseString] value:[NSString stringWithFormat:@"%@", obj]];
        }
    }];
  
}

+ (void)setLogEnable:(BOOL)logEnable{
    kTRSManager.logEnable = logEnable;
    if (kTRSManager.logEnable) {
        NSLog(@"\n-----------------------------------------\n----- TRS_SDK Log -----\n-----TRS_SDK Version:%@-----\n-----AppKey:%@-----\n-----------------------------------------",[kTRSManager.defaultCacheManage deviceInfoWithKey:@"sv"],[kTRSManager.defaultCacheManage deviceInfoWithKey:@"appkey"]);
    }
}
+ (void)setDebugEnable:(BOOL)debugEnable{
    kTRSManager.debugEnable = debugEnable;
    if (kTRSManager.debugEnable) {
        NSLog(@"\n-----------------------------------------\n----- TRS_SDK 开启debug模式 -----\n-----数据将逐条发送，发送失败的数据不做存储-----\n-----------------------------------------");
    }
}

+ (void)setLongitude:(nullable NSString *)longitude latitude:(nullable NSString *)latitude{
    [kTRSManager.defaultCacheManage memoryDeviceInfoWithKey:@"longitude" value:longitude];
    [kTRSManager.defaultCacheManage memoryDeviceInfoWithKey:@"latitude" value:latitude];
}

#pragma mark -- 事件统计方法

+ (void)pageBegin:(NSString *)pageName{
    
    NSLog(@"TRS begin page:%@", pageName);
    kTRSManager.browsePageCount += 1;
    [kTRSManager browsePageCountAdd];
    
    
    TRSPageConfig *pageConfig = [[TRSPageConfig alloc] init];
    pageConfig.pageName = pageName;
    pageConfig.pageBeginTime = TRSCurrentTime();
    pageConfig.vt = TRSCurrentTime36radix(pageConfig.pageBeginTime);
    pageConfig.browsePageCount = kTRSManager.browsePageCount;
    if (!TRSBlankStr(kTRSManager.refer)) pageConfig.refer = kTRSManager.refer;
    kTRSManager.refer = pageName;
    
    [kTRSManager.pageConfigArray addObject:pageConfig];
   
}
+ (void)pageEnd:(NSString *)pageName{
    [TRSAnalytics pageEnd:pageName properties:nil];
}
+ (void)pageEnd:(NSString *)pageName properties:(NSMutableDictionary *)properties{
    TRSBaseModel *pageBaseModel = nil;
    NSLog(@"TRS end page:%@", pageName);
    if (kTRSManager.pageConfigArray.count > 0) {
        for (TRSPageConfig *pageConfig in kTRSManager.pageConfigArray) { // 找到与其匹配的beginPage
            if ([pageConfig.pageName isEqualToString:pageName]) {
                
                NSString *pvStr = [NSString stringWithFormat:@"%@_%@_%ld_%@_%@",
                                   TRSCurrentTime36radix(kTRSManager.appStartTime),
                                   [kTRSManager.defaultCacheManage deviceInfoWithKey:@"LaunchTotalCount"],
                                   (long)kTRSManager.browsePageCount,
                                   [kTRSManager.defaultCacheManage deviceInfoWithKey:@"PageVisitTotalCount"],
                                   [kTRSManager.defaultCacheManage deviceInfoWithKey:@"UUID"]];
                
                pageConfig.pv = pvStr;
                pageConfig.pageEndTime = TRSCurrentTime();
                pageBaseModel = [pageConfig configPageModelWith:properties];
                [kTRSManager.pageConfigArray removeObject:pageConfig];
                break;
            }
        }
    }
    
    if (kTRSManager.debugEnable) {
        if (pageBaseModel == nil) {
            return;
        } else {
            NSArray *debugEventArray = @[pageBaseModel];
            
            [kTRSNetworkManager sendDebugDataWithDataArray:debugEventArray];
        }
        
    } else {
        
        NSMutableArray *dataArray = [@[] mutableCopy];
        
        if (kTRSManager.eventModelArray.count >0) {
            int i = 1;
            for (TRSBaseModel *event in kTRSManager.eventModelArray) { // 为所有的事件在当前页面排序
                NSMutableDictionary *jsonDic = [TRSDataToDirectory(event.jsonData) mutableCopy];
                [jsonDic setObject:[NSNumber numberWithInt:i] forKey:@"se_no"];
                event.jsonData = TRSDirectoryToData(jsonDic);
                i++;
            }
            [dataArray addObjectsFromArray:kTRSManager.eventModelArray];
            [kTRSManager.eventModelArray removeAllObjects];
        }
        if (pageBaseModel != nil) {
            [dataArray addObject:pageBaseModel];
        }
        
        
        kTRSManager.killPageEventArray2 = dataArray;
        kTRSManager.killAppTagSendPageEvent2 = NO;
        [kTRSNetworkManager sendDataWithWithDataArray:dataArray Success:^{
            kTRSManager.killAppTagSendPageEvent2 = YES;
            TRSNSLog(@"采集并发送%ld条pageEvent数据", (unsigned long)dataArray.count);
            if (kTRSManager.logEnable) {
                // model转字典
                NSMutableArray *arr = [NSMutableArray array];
                for (TRSBaseModel *model in dataArray) {
                    NSDictionary *dic = TRSDataToDirectory(model.jsonData);
                    if (dic) [arr addObject:dic];
                }
                NSLog(@"----------成功发送%ld条数据----------", (unsigned long)arr.count);
                NSLog(@"%@", arr);
            }
        } failure:^(NSError *error) {
            kTRSManager.killAppTagSendPageEvent2 = YES;
            if ([kTRSDBManager managerInsertDataWithDataModelArray:dataArray]) {
                TRSNSLog(@"发送pageEvent数据失败，插入临时表%ld条数据", (unsigned long)dataArray.count);
            } else {
                TRSNSLog(@"*****发送失败插入临时表%ld条pageEvent数据失败，数据丢失******", (unsigned long)dataArray.count);
            }
            
        }];
    }
    
}

+ (void)event:(NSString *)eventCode{
    [TRSAnalytics event:eventCode properties:nil];
    
}
+ (void)event:(NSString *)eventCode properties:(NSMutableDictionary *)properties{
    
    NSString *pvStr = [NSString stringWithFormat:@"%@_%@_%ld_%@_%@",
                       TRSCurrentTime36radix(kTRSManager.appStartTime),
                       [kTRSManager.defaultCacheManage deviceInfoWithKey:@"LaunchTotalCount"],
                       (long)kTRSManager.browsePageCount,
                       [kTRSManager.defaultCacheManage deviceInfoWithKey:@"PageVisitTotalCount"],
                       [kTRSManager.defaultCacheManage deviceInfoWithKey:@"UUID"]];
    
    
    TRSEventModelConfig *eventConfig = [[TRSEventModelConfig alloc] init];
    eventConfig.vt = TRSCurrentTime36radix(TRSCurrentTime());
    eventConfig.pv = pvStr;
    eventConfig.eventCode = eventCode;
    
    TRSBaseModel *event = [eventConfig configPageModelWith:properties];
    
    if (kTRSManager.debugEnable) {
        NSArray *debugEventArray = @[event];
        [kTRSNetworkManager sendDebugDataWithDataArray:debugEventArray];
    } else {
        [kTRSManager.eventModelArray addObject:event];
    }
}

#pragma mark -- 用户相关方法
+ (void)login:(NSMutableDictionary *)userInfo{
    if (userInfo == nil || [userInfo allKeys].count == 0) {
        return;
    }
    
    if (TRSBlankStr(userInfo[@"uid"])) {
        return;
    }
    
    NSArray *allkeys = [userInfo allKeys];
    for (NSString *key in allkeys) {
        if ([key isEqualToString:@"se_un"] || [key isEqualToString:@"uid"]) {
            [kTRSManager.defaultCacheManage memoryDeviceInfoWithKey:key value:userInfo[key]];
            [userInfo removeObjectForKey:key];
        }
    }
    NSArray *atherKeys = [userInfo allKeys];
    if (atherKeys.count > 0) {
        [kTRSManager.defaultCacheManage memoryDeviceInfoWithKey:@"extraInfo" value:TRSDirectoryToString(userInfo)];
    }
    
    [kTRSManager sendUserInfo];

}
+ (void)modifyUserInfo:(NSMutableDictionary *)userInfo{
    if (userInfo == nil || [userInfo allKeys].count == 0) {
        return;
    }
    NSArray *allkeys = [userInfo allKeys];
    for (NSString *key in allkeys) {
        if ([key isEqualToString:@"se_un"] || [key isEqualToString:@"uid"]) {
            [kTRSManager.defaultCacheManage memoryDeviceInfoWithKey:key value:userInfo[key]];
            [userInfo removeObjectForKey:key];
        }
    }
    NSArray *atherKeys = [userInfo allKeys];
    if (atherKeys.count > 0) {
        if (TRSDirectoryToString(userInfo)) {
            [kTRSManager.defaultCacheManage memoryDeviceInfoWithKey:@"extraInfo" value:TRSDirectoryToString(userInfo)];
        }
        
    }
    
    [kTRSManager sendUserInfo];
}
+ (void)logout{
    [kTRSManager.defaultCacheManage deleteDeviceInfoWithKey:@"se_un"];
    [kTRSManager.defaultCacheManage deleteDeviceInfoWithKey:@"uid"];
    [kTRSManager.defaultCacheManage deleteDeviceInfoWithKey:@"extraInfo"];
}


@end
