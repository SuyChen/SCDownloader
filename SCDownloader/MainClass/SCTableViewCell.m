//
//  SCTableViewCell.m
//  SCDownloader
//
//  Created by CSY on 2019/3/11.
//  Copyright © 2019 suychen. All rights reserved.
//

#import "SCTableViewCell.h"
#import "SCDownloadHelper.h"
#import "MJExtension.h"

@interface SCTableViewCell ()

@end

@implementation SCTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(WillTerminateNotification) name:UIApplicationWillTerminateNotification object:nil];
    
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
    
    // Configure the view for the selected state
}

- (void)setDataModel:(SCDataModel *)dataModel
{
    //初始化百分比
    NSMutableDictionary *tempDic = [NSMutableDictionary dictionaryWithContentsOfFile:DownloadFilePath];
    if ([tempDic.allKeys containsObject:dataModel.videoUrl]) {
        dataModel  = [SCDataModel mj_objectWithKeyValues:[tempDic objectForKey:dataModel.videoUrl]];
    }
    self.progress_view.progress = dataModel.progress.floatValue;
    if (dataModel.status == SCDownloadStatusSuspend) {
        [self.download_btn setImage:[UIImage imageNamed:@"download"] forState:UIControlStateNormal];
    }else if (dataModel.status == SCDownloadStatusResume){
        [self.download_btn setImage:[UIImage imageNamed:@"pause"] forState:UIControlStateNormal];
    }else{
        [self.download_btn setImage:nil forState:UIControlStateNormal];
        [self.download_btn setTitle:@"完成" forState:UIControlStateNormal];
    }
    _dataModel = dataModel;
}

- (IBAction)SCClickDownloadBtn:(id)sender {
    
    if (self.dataModel.status == SCDownloadStatusSuspend) {
        self.dataModel.status = SCDownloadStatusResume;
        [self.download_btn setImage:[UIImage imageNamed:@"pause"] forState:UIControlStateNormal];
        [[SCDownloadHelper sharedInstance] downloadWithRequestModel:self.dataModel fileDirectory:@"video" progress:^(NSProgress * _Nonnull progress) {
            
            CGFloat percent = 1.0 * progress.completedUnitCount / progress.totalUnitCount;
            dispatch_async(dispatch_get_main_queue(), ^{
                self.progress_view.progress = percent;
            });
            self.dataModel.progress = [NSString stringWithFormat:@"%.2f", percent];
            
        } success:^(id  _Nonnull responseObject) {
            
            self.dataModel.status = SCDownloadStatusFinished;
            dispatch_async(dispatch_get_main_queue(), ^{
                
                [self.download_btn setImage:nil forState:UIControlStateNormal];
                [self.download_btn setTitle:@"完成" forState:UIControlStateNormal];
            });
            
        } failure:^(NSError * _Nonnull error) {
            
        }];
    }else if (self.dataModel.status == SCDownloadStatusResume){
        
        self.dataModel.status = SCDownloadStatusSuspend;
        [self.download_btn setImage:[UIImage imageNamed:@"download"] forState:UIControlStateNormal];
        [[SCDownloadHelper sharedInstance]  suspendWithURLString:self.dataModel.videoUrl];
        
    }else{
        
    }
}
//更新数据，主要是为了更新状态和进度
- (void)WillTerminateNotification
{
    [self updateLocalDataWithModel:self.dataModel];
}
//保存下载数据
- (void)updateLocalDataWithModel:(SCDataModel *)dataModel{
    
    NSMutableDictionary *tempDic = [NSMutableDictionary dictionaryWithContentsOfFile:DownloadFilePath];
    [tempDic setObject:[dataModel mj_keyValues] forKey:dataModel.videoUrl];
    [tempDic writeToFile:DownloadFilePath atomically:NO];
}


@end
