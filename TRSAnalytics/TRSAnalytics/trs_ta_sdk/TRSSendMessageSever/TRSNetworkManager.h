//
//  TRSNetworkManager.h
//  TRSAnalytics
//
//  Created by 824810056 on 2018/7/20.
//  Copyright © 2018年 Miridescent. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^TRSSendDataSuccess)(void);
typedef void (^TRSSendDataFailure)(NSError *error);

@interface TRSNetworkManager : NSObject

+ (TRSNetworkManager *)sharedManager;



/**
 通用发送数据请求，所有的发送采集数据都走这个方法

 @param dataArray 要发送的数据
 @param success 发送成功
 @param failure 发送失败
 */
- (void)sendDataWithWithDataArray:(NSArray *)dataArray Success:(TRSSendDataSuccess)success failure:(TRSSendDataFailure)failure;

// 发送设备ID
- (void)sendDeviceID:(NSString *)deviceID Success:(TRSSendDataSuccess)success failure:(TRSSendDataFailure)failure;
// 发送个像ID
- (void)sendGXDeviceID:(NSString *)GXdeviceID Success:(TRSSendDataSuccess)success failure:(TRSSendDataFailure)failure;
// 发送用户信息
- (void)sendUserInfo:(NSString *)uid Success:(TRSSendDataSuccess)success failure:(TRSSendDataFailure)failure;


// 发送debug状态（埋点测试）
- (void)sendDebugStateDeviceMessageSuccess:(TRSSendDataSuccess)success failure:(TRSSendDataFailure)failure;
// debug状态下发送数据（debug状态下不需要回调，因为数据单向流动，无论发送成功与否，发送即删除）
- (void)sendDebugDataWithDataArray:(NSArray *)dataArray;
@end
