//
//  SCDataModel.h
//  SCDownloader
//
//  Created by CSY on 2019/3/11.
//  Copyright © 2019 suychen. All rights reserved.
//  这个是下载的数据类型，可以自己定制

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, SCDownloadStatus) {
    //暂停或者未开始状态
    SCDownloadStatusSuspend,
    //继续或者正在下载状态
    SCDownloadStatusResume,
    //完成状态
    SCDownloadStatusFinished
};

NS_ASSUME_NONNULL_BEGIN

@interface SCDataModel : NSObject

/**
 请求资源的额URL，这里也作为唯一标识符使用
 */
@property (nonatomic, copy) NSString *videoUrl;

/**
 下载状态
 */
@property (nonatomic, assign) SCDownloadStatus status;

/**
 下载进度
 */
@property (nonatomic, copy) NSString *progress;

/**
 下载数据
 */
@property (nonatomic, strong) NSData *resumeData;

@end

NS_ASSUME_NONNULL_END
