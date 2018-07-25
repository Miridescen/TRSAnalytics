//
//  TRSManager.m
//  TRS_SDK
//
//  Created by 824810056 on 2018/1/16.
//  Copyright © 2018年 牟松. All rights reserved.
//

#import "TRSManager.h"
#import "TRSPageConfig.h"
#import "TRSSystemInfo.h"
#import "TRSBaseModel.h"

@interface TRSManager()


@end
@implementation TRSManager

+ (TRSManager *)sharedManager{
    static TRSManager *shareManage = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shareManage = [[TRSManager alloc] init];
    });
    return shareManage;
}
#pragma mark -- privat method
//+ (void)load
//{
//
//    __block id observer =
//    [[NSNotificationCenter defaultCenter]
//     addObserverForName:UIApplicationDidFinishLaunchingNotification
//     object:nil
//     queue:nil
//     usingBlock:^(NSNotification *note) {
//         NSLog(@"1231231231");
//         [[NSNotificationCenter defaultCenter] removeObserver:observer];
//     }];
//}
- (instancetype)init{
    self = [super init];
    if (self) {
        
        _defaultCacheManage = [TRSDefaultCacheManager sharedManager];
        _DBManager3 = [TRSDBManager3 sharedManager];
        _HTTPManager = [TRSHTTPManager sharedManger];
        _networkManager = [TRSNetworkManager sharedManager];
        
        _pageConfigArray = [@[] mutableCopy];
        _eventModelArray = [@[] mutableCopy];
        _browsePageCount = 0;
        _logEnable = NO;
        
        _debugEnable = NO;
        _debugSuccess = NO;
        
        _hasDeviceID = NO;
        _hasSendDeviceID = NO;
        
        _hasUID = NO;
        _hasSendUID = NO;
        
        _appOpenType = TRSAppOpenTypeActivedOnly;
        self.refer = @"";
        
        _killAppTagSendPageEvent = NO;
        _killPageEventArray = [[NSArray alloc] init];
        _killAppTagSendPageEvent2 = NO;
        _killPageEventArray2 = [[NSArray alloc] init];


        //启动加载
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(APPLaunching)
                                                     name:UIApplicationDidFinishLaunchingNotification
                                                   object:nil];
        
        //应用进入前台通知
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(APPForeground)
                                                     name:UIApplicationWillEnterForegroundNotification
                                                   object:nil];
        
        //程序变活
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(APPBecomeActive)
                                                     name:UIApplicationDidBecomeActiveNotification
                                                   object:nil];
        
        
        //程序将被杀死
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(APPResignActive)
                                                     name:UIApplicationWillResignActiveNotification
                                                   object:nil];
        
        //程序将被杀死
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(APPWillTerminateNotification)
                                                     name:UIApplicationWillTerminateNotification
                                                   object:nil];
 
    }
    return self;
}


- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
#pragma mark ------------------ notifiction --------------

- (void)APPLaunching{
    TRSNSLog(@"APPLaunch");
    [self launchCountAdd];
    _appOpenType = TRSAppOpenTypeLaunch;
    self.appStartTime = TRSCurrentTime();
    
    [self sendDeviceID];
}
- (void)APPForeground{
    TRSNSLog(@"APPForground");
    [self launchCountAdd];
    _appOpenType = TRSAppOpenTypeForground;
    self.appStartTime = TRSCurrentTime();
}

- (void)APPBecomeActive{
    TRSNSLog(@"APPActivie");

    if (_appOpenType != TRSAppOpenTypeLaunch && _appOpenType != TRSAppOpenTypeForground) { // 由于通知的逻辑，加此判断
        [self launchCountAdd];
        self.appStartTime = TRSCurrentTime();
    }
    
    self.browsePageCount = 0;
    self.refer = @"";
    
    // 生成一次APP启动事件
    TRSSystemEventConfig *systemEventConfig = [[TRSSystemEventConfig alloc] init];
    systemEventConfig.beginTime = self.appStartTime;
    TRSBaseModel *systemBaseModel = [[TRSBaseModel alloc] init];
    switch (_appOpenType) {
        case TRSAppOpenTypeLaunch:
            systemBaseModel = [systemEventConfig configSystemEventModelWithEventType:TRSSystemEventTypeBas_startup];
            break;
        case TRSAppOpenTypeForground:
            systemBaseModel = [systemEventConfig configSystemEventModelWithEventType:TRSSystemEventTypeBas_resume];
            break;
        case TRSAppOpenTypeActivedOnly:
            systemBaseModel = [systemEventConfig configSystemEventModelWithEventType:TRSSystemEventTypeBas_resume];
            break;
        default:
            break;
    }
    
    if (_debugEnable) { // debug模式
        
        NSArray *startSystemEventArray = @[systemBaseModel];
        [self->_networkManager sendDebugDataWithDataArray:startSystemEventArray];
        
    } else {
        
        [self->_DBManager3 managerInsertOneDataWithDataModel:systemBaseModel];

        // 发送启动事件
        NSArray *startSystemEventArray = @[systemBaseModel];
        @weakify(self);
        [self->_networkManager sendDataWithWithDataArray:startSystemEventArray Success:^{
            @strongify(self);
            if (!self) return;
            TRSNSLog(@"成功采集并发送%ld条SystemEvent数据", (unsigned long)startSystemEventArray.count);
            if ([self->_DBManager3 managerDeleteOneDataWithDataModel:systemBaseModel]) {
                TRSNSLog(@"发送启动事件成功，删除系统事件成功");
            } else {
                TRSNSLog(@"发送启动事件成功，删除系统事件失败，出现重复数据");
            }
            
            if (self.logEnable) {
                // model转字典
                NSMutableArray *arr = [NSMutableArray array];
                for (TRSBaseModel *model in startSystemEventArray) {
                    NSDictionary *dic = TRSDataToDirectory(model.jsonData);
                    if (dic) [arr addObject:dic];
                }
                NSLog(@"----------成功发送%ld条数据----------", (unsigned long)arr.count);
                NSLog(@"%@", arr);
            }
            
            [self sendTotalData]; // 检查是否有缓存数据
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
                if (self.hasDeviceID && !self.hasSendDeviceID) {
                    [self sendDeviceID];
                }
                if (self.hasUID && !self.hasSendUID) {
                    [self sendUserInfo];
                }
            });
        } failure:^(NSError *error) {
            TRSNSLog(@"发送启动事件失败");
        }];
        
    }
}
- (void)APPResignActive{
    TRSNSLog(@"APP进入后台");
    UIApplication *app = [UIApplication sharedApplication];
    @weakify(self);
    self.bgTask = [app beginBackgroundTaskWithExpirationHandler:^{
        @strongify(self);
        if (!self) return;
        dispatch_async(dispatch_get_main_queue(),^{
            
            if( self.bgTask != UIBackgroundTaskInvalid){
                self.bgTask = UIBackgroundTaskInvalid;
            }
        });
        
        [app endBackgroundTask:self.bgTask];
        
    }];

    self.appEndTime = TRSCurrentTime();
    _appOpenType = TRSAppOpenTypeActivedOnly;
    
    // 生成挂起事件
    TRSSystemEventConfig *systemEventConfig = [[TRSSystemEventConfig alloc] init];
    systemEventConfig.beginTime = self.appStartTime;
    systemEventConfig.endTime = self.appEndTime;
    systemEventConfig.browsePageCount = self.browsePageCount;
    TRSBaseModel *systemBaseModel = [systemEventConfig configSystemEventModelWithEventType:TRSSystemEventTypeBas_suspend];
    if (_debugEnable) {
        
        NSArray *suspendSystemEventArray = @[systemBaseModel];
        [self->_networkManager sendDebugDataWithDataArray:suspendSystemEventArray];
        
    } else {
        NSMutableArray *eventArray = [@[] mutableCopy];
        [eventArray addObject:systemBaseModel];
        
        
        // -------页面事件处理------------------------------------------------------------------------------------
        
        /*  // 是否处理一半的页面，还有待于研究
        if (self.pageConfigArray.count > 0) {
            for (TRSPageConfig *pageConfig in self.pageConfigArray) { // 找到与其匹配的beginPage
                pageConfig.pageEndTime = TRSCurrentTime();
                TRSPageEventModel *pageModel = [pageConfig configPageModelWith:nil eventMdoel:nil];
                [eventArray addObject:pageModel];
            }
        }
         */
        
        // 已经退出，清空一半的页面数据
        [self.pageConfigArray removeAllObjects];
        // -------页面事件处理------------------------------------------------------------------------------------

        // 为事件添加se_no参数
        if (self.eventModelArray.count >0) {
            int i = 1;
            for (TRSBaseModel *event in self.eventModelArray) { // 为所有的事件在当前页面排序
                NSMutableDictionary *jsonDic = [TRSDataToDirectory(event.jsonData) mutableCopy];
                [jsonDic setObject:[NSNumber numberWithInt:i] forKey:@"se_no"];
                event.jsonData = TRSDirectoryToData(jsonDic);
                i++;
            }
            [eventArray addObjectsFromArray:self.eventModelArray];
            [self.eventModelArray removeAllObjects];
        }

        // ---------发送数据-----------------------------------------------------------------------------------
        
        _killPageEventArray = eventArray;
        _killAppTagSendPageEvent = NO;
        @weakify(self);
        [self->_networkManager sendDataWithWithDataArray:eventArray Success:^{
            @strongify(self);
            if (!self) return;
            TRSNSLog(@"成功采集并发送%ld条pageEvent数据", (unsigned long)eventArray.count);
            self.killAppTagSendPageEvent = YES;
            if (self.logEnable) {
                // model转字典
                NSMutableArray *arr = [NSMutableArray array];
                for (TRSBaseModel *model in eventArray) {
                    NSDictionary *dic = TRSDataToDirectory(model.jsonData);
                    if (dic) [arr addObject:dic];
                }
                NSLog(@"----------成功发送%ld条数据----------", (unsigned long)arr.count);
                NSLog(@"%@", arr);
            }
            [self sendTotalData];
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
                if (self.hasDeviceID && !self.hasSendDeviceID) {
                    [self sendDeviceID];
                }
                if (self.hasUID && !self.hasSendUID) {
                    [self sendUserInfo];
                }
            });
        } failure:^(NSError *error) {
            @strongify(self);
            if (!self) return;
            self.killAppTagSendPageEvent = YES;
            if ([self->_DBManager3 managerInsertDataWithDataModelArray:eventArray]) {
                TRSNSLog(@"采集%ld条pageEvent数据，发送数据失败，数据入库", (unsigned long)eventArray.count);
            } else {
                TRSNSLog(@"采集%ld条pageEvent成功，数据入库失败，数据丢失", (unsigned long)eventArray.count);
            }
            
        }];
  
    }

    self.browsePageCount = 0;
    self.debugSuccess = NO; // 推到后台结束debug状态
 
}
- (void)APPWillTerminateNotification{
    TRSNSLog(@"APP关闭");
    
    [self.defaultCacheManage deleteDeviceInfoWithKey:@"se_un"];
    [self.defaultCacheManage deleteDeviceInfoWithKey:@"uid"];
    [self.defaultCacheManage deleteDeviceInfoWithKey:@"extraInfo"];
    
    if (_debugEnable) return;
    if (self.killAppTagSendPageEvent != YES) {
        if (_killPageEventArray.count > 0) {
            if ([self->_DBManager3 managerInsertDataWithDataModelArray:_killPageEventArray]) {
                if (_logEnable) {
                    TRSNSLog(@"111111----------采集%ld条pageEvent事件----------\n", (long)_killPageEventArray.count);
                }
            } else {
                TRSNSLog(@"采集启动事件入库失败，数据丢失");
            }
        }
    } else {
        TRSNSLog(@"程序出错了，处理杀死程序时逻辑有问题，需要修改");
    }
    if (self.killAppTagSendPageEvent2 != YES) {
        if (_killPageEventArray2.count > 0) {
            if ([self->_DBManager3 managerInsertDataWithDataModelArray:_killPageEventArray2]) {
                if (_logEnable) {
                    TRSNSLog(@"111111----------采集%ld条pageEvent事件----------\n", (long)_killPageEventArray2.count);
                }
            } else {
                TRSNSLog(@"采集启动事件入库失败，数据丢失");
            }
        }
    } else {
        TRSNSLog(@"程序出错了，处理杀死程序时逻辑有问题，需要修改");
    }
    
}

#pragma mark ------------------ private method --------------

// 统一到一张表的发送逻辑
- (void)sendTotalData{
    
    NSInteger count = [self->_DBManager3 managerGatDataTotalCount];
    if (count == 0) {
        return;
    } else if (count > 0 && count <= 50) {
        NSArray *dataArray = [self->_DBManager3 managerGetDataWithDataCount:0];
        
        @weakify(self);
        [self->_networkManager sendDataWithWithDataArray:dataArray Success:^{
            @strongify(self);
            if (!self) return;
            TRSNSLog(@"成功发送%ld条数据", (unsigned long)dataArray.count);
            if ([self->_DBManager3 managerDeleteDataWithDataModelArray:dataArray]) {
                TRSNSLog(@"成功删除%ld条数据", (unsigned long)dataArray.count);
            } else {
                TRSNSLog(@"*****发送数据成功，删除数据失败*****");
            }
            if (self.logEnable) {
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
            @strongify(self);
            if (!self) return;
            TRSNSLog(@"发送数据失败");
            if (error.code == -2) {
                if ([self->_DBManager3 managerDeleteDataWithDataModelArray:dataArray]) {
                    TRSNSLog(@"%ld条数据有问题，清空该表", (unsigned long)dataArray.count);
                } else {
                    TRSNSLog(@"*****数据有问题，清空该表失败*****");
                }
            }
        }];
        
    } else {
        NSArray *dataArray = [self->_DBManager3 managerGetDataWithDataCount:50];
        
        @weakify(self);
        [self->_networkManager sendDataWithWithDataArray:dataArray Success:^{
            @strongify(self);
            if (!self) return;
            TRSNSLog(@"成功发送%ld条数据", (unsigned long)dataArray.count);
            if ([self->_DBManager3 managerDeleteDataWithDataModelArray:dataArray]) {
                TRSNSLog(@"成功删除%ld条数据", (unsigned long)dataArray.count);
            } else {
                TRSNSLog(@"*****发送数据成功，删除数据失败*****");
            }
            if (self.logEnable) {
                // model转字典
                NSMutableArray *arr = [NSMutableArray array];
                for (TRSBaseModel *model in dataArray) {
                    NSDictionary *dic = TRSDataToDirectory(model.jsonData);
                    if (dic) [arr addObject:dic];
                }
                NSLog(@"----------成功发送%ld条数据----------", (unsigned long)arr.count);
                NSLog(@"%@", arr);
            }
            // 再次发送数据请求
            [self sendTotalData];
        } failure:^(NSError *error) {
            @strongify(self);
            if (!self) return;
            TRSNSLog(@"发送数据失败");
            if (error.code == -2) {
                if ([self->_DBManager3 managerDeleteDataWithDataModelArray:dataArray]) {
                    TRSNSLog(@"%ld条数据有问题，清空该表", (unsigned long)dataArray.count);
                } else {
                    TRSNSLog(@"*****数据有问题，清空该表失败*****");
                }
            }
        }];  
    }
}

/**
 发送设备ID
 */
- (void)sendDeviceID{
    
    TRSNSLog(@"-------------发送设备信息-----------------");
    if (!TRSBlankStr([self->_defaultCacheManage deviceInfoWithKey:@"deviceID"])) {
        self.hasDeviceID = YES;
        
        @weakify(self);
        [self.networkManager sendDeviceID:[self->_defaultCacheManage deviceInfoWithKey:@"deviceID"] Success:^{
            @strongify(self);
            if (!self) return;
            self.hasSendDeviceID = YES;
        } failure:^(NSError *error) {
            
        }];
    }
    
    TRSNSLog(@"-------------发送gx设备信息-----------------");
    if (!TRSBlankStr([self->_defaultCacheManage deviceInfoWithKey:@"gxdeviceid"])) {
        
        [self.networkManager sendGXDeviceID:[self->_defaultCacheManage deviceInfoWithKey:@"gxdeviceid"] Success:^{
            
        } failure:^(NSError *error) {
            
        }];
    }
    
}
- (void)sendUserInfo{
    
    TRSNSLog(@"-------------发送用户信息-----------------");
    if (!TRSBlankStr([self->_defaultCacheManage deviceInfoWithKey:@"uid"])) {
        self.hasUID = YES;
        
        @weakify(self);
        [self.networkManager sendUserInfo:[self->_defaultCacheManage deviceInfoWithKey:@"uid"] Success:^{
            @strongify(self);
            if (!self) return;
            self.hasSendUID = YES;
        } failure:^(NSError *error) {
            
        }];
    }
}

- (void)browsePageCountAdd{ // 页面浏览次数自增一
    // 处理页面总访问次数
    NSInteger PageVisitTotalCount = [self->_defaultCacheManage PageVisitTotalCount];
    PageVisitTotalCount += 1;
    [self->_defaultCacheManage updatePageVisitTotalCountWithCount:PageVisitTotalCount];
}
- (void)launchCountAdd{ // 启动次数自增一
    // 更新APP总的启动次数
    NSInteger LaunchTotalCount = [_defaultCacheManage LaunchTotalCount];
    LaunchTotalCount += 1;
    [_defaultCacheManage updateLaunchTotalCountWithCount:LaunchTotalCount];
}


/**
 数据校验
 
 @param arr 要发送的数据
 @return 校验结果
 
- (NSString *)checkResultWithModelArray:(NSArray *)arr{
    long long checkVt = 0, checkPv = 0;
    for (NSInteger i = 0; i<arr.count; i++) {
        NSString *vtStr = arr[i][@"vt"];
        NSString *pvStr = arr[i][@"pv"];
        long long vt = strtoll([vtStr UTF8String],0,36);
        NSArray *pvSubStrArr = [pvStr componentsSeparatedByString:@"_"];
        long long pageVisitTotalCount = 0;
        if (pvSubStrArr.count > 3) {
            pageVisitTotalCount = [pvSubStrArr[3] longLongValue];
        }
        if (i == 0) {
            checkVt = vt;
            checkPv = pageVisitTotalCount;
        } else {
            checkVt = (checkVt+vt)/2;
            checkPv = (checkPv+pageVisitTotalCount)/2;
        }
    }
    return [NSString stringWithFormat:@"%@%lld", TRSCurrentTime36radix([NSNumber numberWithLongLong:checkVt]),checkPv];
}
*/


@end
