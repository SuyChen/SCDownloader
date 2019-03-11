//
//  SCDownloadHelper.m
//  SCDownloader
//
//  Created by CSY on 2019/3/11.
//  Copyright © 2019 suychen. All rights reserved.
//

#import "SCDownloadHelper.h"

@interface SCDownloadHelper ()
/**
 是AFURLSessionManager的子类，为HTTP的一些请求提供了便利方法，当提供baseURL时，请求只需要给出请求的路径即可
 */
@property (nonatomic, strong) AFHTTPSessionManager *requestManager;
/**
 下载历史记录
 */
@property (nonatomic,strong) NSMutableDictionary *downLoadHistoryDictionary;

/**
 保存任务的task key:URL value:NSURLSessionDownloadTask
 */
@property (nonatomic, strong) NSMutableDictionary *downlaodTaskDictionary;


@end

@implementation SCDownloadHelper

+ (instancetype)sharedInstance
{
    static id instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        //网络状况检测
        [[AFNetworkReachabilityManager sharedManager] setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
            self.networkStatus = status;
        }];
        [[AFNetworkReachabilityManager sharedManager] startMonitoring];
        
        self.downlaodTaskDictionary = [NSMutableDictionary dictionary];
        
        //监听下载完成情况
        NSURLSessionDownloadTask *task;
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(downLoadData:)
                                                     name:AFNetworkingTaskDidCompleteNotification
                                                   object:task];
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:DownloadFilePath]) {
            self.downLoadHistoryDictionary = [NSMutableDictionary dictionaryWithContentsOfFile:DownloadFilePath];
        }else{
            self.downLoadHistoryDictionary = [ NSMutableDictionary dictionary];
            [self.downLoadHistoryDictionary writeToFile:DownloadFilePath atomically:YES];
        }
    }
    return self;
}
#pragma mark == 懒加载
- (AFHTTPSessionManager *)requestManager
{
    if (!_requestManager) {
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:@"download"];
        //设置请求超时为10s
        configuration.timeoutIntervalForRequest = 10;
        //在蜂窝网络情况下是否继续请求（上传或下载）
        configuration.allowsCellularAccess = YES;
        _requestManager = [[AFHTTPSessionManager alloc] initWithSessionConfiguration:configuration];
        //根据具体情况判断证书
        AFSecurityPolicy *securityPolicy = [AFSecurityPolicy defaultPolicy];
        securityPolicy.allowInvalidCertificates = YES;
        securityPolicy.validatesDomainName = NO;
        _requestManager.securityPolicy = securityPolicy;
    }
    return _requestManager;
}
- (void)downloadWithURLString:(NSString *_Nullable)URLString
                              fileDirectory:(NSString *)fileDirectory
                                   progress:(SCHttpProgress)progress
                                    success:(SCHttpRequestSuccess)success
                                    failure:(SCHttpRequestFailed)failure
{

    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:URLString]];
    NSData *downLoadHistoryData = [self.downLoadHistoryDictionary objectForKey:URLString];
    NSURLSessionDownloadTask *downloadTask = [self.downlaodTaskDictionary objectForKey:URLString];
    
    if (downLoadHistoryData.length > 0) {
        downloadTask = [self.requestManager downloadTaskWithResumeData:downLoadHistoryData progress:^(NSProgress * _Nonnull downloadProgress) {
            
            progress(downloadProgress);
            
        } destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
            //拼接缓存目录
            NSString *downloadDir = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:fileDirectory ? fileDirectory : @"Download"];
            //打开文件管理器
            NSFileManager *fileManager = [NSFileManager defaultManager];
            //创建Download目录
            [fileManager createDirectoryAtPath:downloadDir withIntermediateDirectories:YES attributes:nil error:nil];
            //拼接文件路径
            NSString *filePath = [downloadDir stringByAppendingPathComponent:URLString];
            //返回文件位置的URL路径
            return [NSURL fileURLWithPath:filePath];
            
        } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
            if (error) {
                failure(error);
            }else{
                
                success([filePath path]);
            }
        }];
        
    }else{
        downloadTask = [self.requestManager downloadTaskWithRequest:request progress:^(NSProgress * _Nonnull downloadProgress) {
            progress(downloadProgress);
        } destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
            
            //拼接缓存目录
            NSString *downloadDir = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:fileDirectory ? fileDirectory : @"Download"];
            //打开文件管理器
            NSFileManager *fileManager = [NSFileManager defaultManager];
            //创建Download目录
            [fileManager createDirectoryAtPath:downloadDir withIntermediateDirectories:YES attributes:nil error:nil];
            //拼接文件路径
            NSString *filePath = [downloadDir stringByAppendingPathComponent:response.suggestedFilename];
            //返回文件位置的URL路径
            return [NSURL fileURLWithPath:filePath];
            
        } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
            if (error) {
                failure(error);
            }else{
                
                success([filePath path]);
            }
        }];
    }
    
    [self.downlaodTaskDictionary setObject:downloadTask forKey:URLString];
    [downloadTask resume];
}

- (void)suspendWithURLString:(NSString *)URLString
{
    NSURLSessionDownloadTask *downloadTask = [self.downlaodTaskDictionary objectForKey:URLString];
    
    [downloadTask cancelByProducingResumeData:^(NSData * _Nullable resumeData) {
        
    }];
}
#pragma mark == Notification
- (void)downLoadData:(NSNotification *)notification{
    
    if ([notification.object isKindOfClass:[ NSURLSessionDownloadTask class]]) {
        NSURLSessionDownloadTask *task = notification.object;
        NSString *urlHost = [task.currentRequest.URL absoluteString];
        NSError *error  = [notification.userInfo objectForKey:AFNetworkingTaskDidCompleteErrorKey] ;
        if (error) {
            if (error.code == -1001) {
                NSLog(@"下载出错,看一下网络是否正常");
            }
            NSData *resumeData = [error.userInfo objectForKey:@"NSURLSessionDownloadTaskResumeData"];
            [self saveHistoryWithKey:urlHost DownloadTaskResumeData:resumeData];
            //这个是因为 用户比如强退程序之后 ,再次进来的时候 存进去这个继续的data  需要用户去刷新列表
        }else{
            if ([self.downLoadHistoryDictionary valueForKey:urlHost]) {
                [self.downLoadHistoryDictionary removeObjectForKey:urlHost];
                [self saveDownLoadHistoryDirectory];
            }
        }
    }
    
}

#pragma mark == Tool
- (void)saveHistoryWithKey:(NSString *)key DownloadTaskResumeData:(NSData *)data{
    if (!data) {
        NSString *emptyData = [NSString stringWithFormat:@""];
        [self.downLoadHistoryDictionary setObject:emptyData forKey:key];
        
    }else{
        [self.downLoadHistoryDictionary setObject:data forKey:key];
    }
    
    [self.downLoadHistoryDictionary writeToFile:DownloadFilePath atomically:NO];
}
- (void)saveDownLoadHistoryDirectory{
    [self.downLoadHistoryDictionary writeToFile:DownloadFilePath atomically:YES];
}
@end
