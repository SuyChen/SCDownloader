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

@property (nonatomic, copy) NSString *uid;

@property (nonatomic, copy) NSString *videoUrl;

@property (nonatomic, assign) SCDownloadStatus status;

@property (nonatomic, copy) NSString *progress;

@property (nonatomic, strong) NSData *resumeData;

@end

NS_ASSUME_NONNULL_END
