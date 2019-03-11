//
//  SCDownloadHelper.h
//  SCDownloader
//
//  Created by CSY on 2019/3/11.
//  Copyright © 2019 suychen. All rights reserved.
//

#import <Foundation/Foundation.h>

#if __has_include(<AFNetworking/AFNetworking.h>)
#import <AFNetworking/AFNetworking.h>
#else
#import "AFNetworking.h"
#endif

#define DownloadFilePath [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingString:@"fileDownLoadHistory.plist"]

NS_ASSUME_NONNULL_BEGIN


/**
 请求成功的回调
 
 @param responseObject 返回请求到的数据
 */
typedef void(^SCHttpRequestSuccess)(id responseObject);

/**
 请求失败的回调
 
 @param error 返回失败信息
 */
typedef void(^SCHttpRequestFailed)(NSError *error);

/**
 上传或者下载的进度
 
 @param progress 返回进度类 Progress.completedUnitCount:当前大小 - Progress.totalUnitCount:总大小
 */
typedef void(^SCHttpProgress)(NSProgress *progress);


@interface SCDownloadHelper : NSObject
/**
 当前的网络状态
 */
@property (nonatomic, assign) AFNetworkReachabilityStatus networkStatus;

/**
 网络请求单利
 
 @return 网络请求单利
 */
+ (instancetype _Nullable )sharedInstance;

/**
 下载资源
 
 @param URLString URL地址，不包含baseURL
 @param fileDirectory 文件存储目录(默认存储目录为Download)
 @param progress 下载进度
 @param success 请求成功
 @param failure 请求失败
 */
- (void)downloadWithURLString:(NSString *_Nullable)URLString
                              fileDirectory:(NSString *)fileDirectory
                                   progress:(SCHttpProgress)progress
                                    success:(SCHttpRequestSuccess)success
                                    failure:(SCHttpRequestFailed)failure;

/**
 暂停下载

 @param URLString 下载的URL
 */
- (void)suspendWithURLString:(NSString *_Nullable)URLString;
@end

NS_ASSUME_NONNULL_END
