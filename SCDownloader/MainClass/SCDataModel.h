//
//  SCDataModel.h
//  SCDownloader
//
//  Created by CSY on 2019/3/11.
//  Copyright © 2019 suychen. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SCDataModel : NSObject

@property (nonatomic, copy) NSString *uid;

@property (nonatomic, copy) NSString *videoImg;

@property (nonatomic, copy) NSString *videoUrl;

@property (nonatomic, assign) BOOL isDownload;

@end

NS_ASSUME_NONNULL_END
