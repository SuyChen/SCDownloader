//
//  SCTableViewCell.m
//  SCDownloader
//
//  Created by CSY on 2019/3/11.
//  Copyright © 2019 suychen. All rights reserved.
//

#import "SCTableViewCell.h"
#import "SCDownloadHelper.h"

@interface SCTableViewCell ()

@end

@implementation SCTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    
    
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)setDataModel:(SCDataModel *)dataModel
{
    _dataModel = dataModel;
    //初始化百分比
    NSMutableDictionary *tempDic = [NSMutableDictionary dictionaryWithContentsOfFile:DownloadFilePath];
    NSString *percentStr = [tempDic objectForKey:self.dataModel.uid];
    self.progress_view.progress = percentStr.floatValue;
}

- (IBAction)SCClickDownloadBtn:(id)sender {
    
    __block NSMutableDictionary *tempDic = [NSMutableDictionary dictionary];
    
    if (!self.dataModel.isDownload) {
        self.dataModel.isDownload = YES;
        [self.download_btn setImage:[UIImage imageNamed:@"pause"] forState:UIControlStateNormal];
        [[SCDownloadHelper sharedInstance] downloadWithURLString:self.dataModel.videoUrl fileDirectory:@"video" progress:^(NSProgress * _Nonnull progress) {
            
            CGFloat percent = 1.0 * progress.completedUnitCount / progress.totalUnitCount;
            dispatch_async(dispatch_get_main_queue(), ^{
                
                self.progress_view.progress = percent;
            });
            NSString *percentStr = [NSString stringWithFormat:@"%.2f",percent];
            tempDic = [NSMutableDictionary dictionaryWithContentsOfFile:DownloadFilePath];
            [tempDic setObject:percentStr forKey:self.dataModel.uid];
            
            
        } success:^(id  _Nonnull responseObject) {
            
            dispatch_async(dispatch_get_main_queue(), ^{
               
                [self.download_btn setImage:nil forState:UIControlStateNormal];
                [self.download_btn setTitle:@"完成" forState:UIControlStateNormal];
                
            });
            
        } failure:^(NSError * _Nonnull error) {
            
        }];
    }else{
        self.dataModel.isDownload = NO;
        [self.download_btn setImage:[UIImage imageNamed:@"download"] forState:UIControlStateNormal];
        [[SCDownloadHelper sharedInstance]  suspendWithURLString:self.dataModel.videoUrl];
        
    }
}


@end
