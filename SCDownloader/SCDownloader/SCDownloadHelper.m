//
//  SCDownloadHelper.m
//  SCDownloader
//
//  Created by CSY on 2019/3/11.
//  Copyright © 2019 suychen. All rights reserved.
//

#import "SCDownloadHelper.h"
#import "SCDataModel.h"
#import "MJExtension.h"

static NSString * const kTask = @"downloadTask";
static NSString * const kModel = @"requestModel";
static NSString * const kSessionIndentifier = @"download";

@interface SCDownloadHelper ()
/**
 是AFURLSessionManager的子类，为HTTP的一些请求提供了便利方法，当提供baseURL时，请求只需要给出请求的路径即可
 */
@property (nonatomic, strong) AFHTTPSessionManager *requestManager;
/**
 下载历史记录 key:URL value:dataModel ps:key只要是惟一的标识符就好
 */
@property (nonatomic,strong) NSMutableDictionary *downLoadHistoryDictionary;

/**
 保存任务的task和模型 key:URL value:@{@"":@""} ps:key只要是惟一的标识符就好
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
        
        //监听下载完成情况
        NSURLSessionDownloadTask *task;
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(downLoadData:)
                                                     name:AFNetworkingTaskDidCompleteNotification
                                                   object:task];
        //创建plist文件
        if ([[NSFileManager defaultManager] fileExistsAtPath:DownloadFilePath]) {
            self.downLoadHistoryDictionary = [NSMutableDictionary dictionaryWithContentsOfFile:DownloadFilePath];
        }else{
            self.downLoadHistoryDictionary = [ NSMutableDictionary dictionary];
            [self.downLoadHistoryDictionary writeToFile:DownloadFilePath atomically:YES];
        }
        
        self.downlaodTaskDictionary = [NSMutableDictionary dictionary];
    }
    return self;
}
#pragma mark == 懒加载
- (AFHTTPSessionManager *)requestManager
{
    if (!_requestManager) {
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:kSessionIndentifier];
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

- (void)downloadWithRequestModel:(id)requestModel
                   fileDirectory:(NSString *)fileDirectory
                        progress:(SCHttpProgress)progress
                         success:(SCHttpRequestSuccess)success
                         failure:(SCHttpRequestFailed)failure;
{
    SCDataModel *model = (SCDataModel *)requestModel;
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:model.videoUrl]];
    
    NSData *downLoadHistoryData = [self getResumeDataWithKey:model.videoUrl];
    
    NSURLSessionDownloadTask *downloadTask = [[self.downlaodTaskDictionary objectForKey:model.videoUrl] objectForKey:kTask];
    
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
            NSString *filePath = [downloadDir stringByAppendingPathComponent:model.videoUrl];
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
            NSString *filePath = [downloadDir stringByAppendingPathComponent:model.videoUrl];
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
    
    [self.downlaodTaskDictionary setObject:@{kTask: downloadTask, kModel: model} forKey:model.videoUrl];
    [downloadTask resume];
}

- (void)suspendWithURLString:(NSString *)URLString
{
    NSURLSessionDownloadTask *downloadTask = [[self.downlaodTaskDictionary objectForKey:URLString] objectForKey:kTask];
    
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
            [self saveLocalWithKey:urlHost DownloadTaskResumeData:resumeData];
            //这个是因为 用户比如强退程序之后 ,再次进来的时候 存进去这个继续的data  需要用户去刷新列表
        }else{
//            if ([self.downLoadHistoryDictionary valueForKey:urlHost]) {
//                [self.downLoadHistoryDictionary removeObjectForKey:urlHost];
//                //更新数据
//                [self.downLoadHistoryDictionary writeToFile:DownloadFilePath atomically:YES];
//            }
        }
    }
}

#pragma mark == Tool
//保存下载数据
- (void)saveLocalWithKey:(NSString *)key DownloadTaskResumeData:(NSData *)data{
    if (data) {
        SCDataModel *model = [[self.downlaodTaskDictionary objectForKey:key] objectForKey:kModel];
        model.resumeData = data;
        NSMutableDictionary *dic = [model mj_keyValues];
        [self.downLoadHistoryDictionary setObject:dic forKey:key];
    }
    
    [self.downLoadHistoryDictionary writeToFile:DownloadFilePath atomically:NO];
}

- (NSData *)getResumeDataWithKey:(NSString *)key
{
    //获取model字典
    NSDictionary *dic = [self.downLoadHistoryDictionary objectForKey:key];
    NSData *resumeData = [dic objectForKey:@"resumeData"];
    return resumeData;
}
@end
