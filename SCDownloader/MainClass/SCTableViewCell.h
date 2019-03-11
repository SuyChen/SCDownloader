//
//  SCTableViewCell.h
//  SCDownloader
//
//  Created by CSY on 2019/3/11.
//  Copyright © 2019 suychen. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SCDataModel.h"

NS_ASSUME_NONNULL_BEGIN

typedef void(^ClickDownloadBlock)(BOOL isDownload);

@interface SCTableViewCell : UITableViewCell

@property (nonatomic, strong) SCDataModel *dataModel;
@property (weak, nonatomic) IBOutlet UILabel *title_lb;
@property (weak, nonatomic) IBOutlet UIProgressView *progress_view;
@property (weak, nonatomic) IBOutlet UIButton *download_btn;

@property (nonatomic, copy) ClickDownloadBlock ClickBlock;
@end

NS_ASSUME_NONNULL_END
