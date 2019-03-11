//
//  ViewController.m
//  SCDownloader
//
//  Created by CSY on 2019/3/11.
//  Copyright © 2019 suychen. All rights reserved.
//

#import "ViewController.h"
#import "SCTableViewCell.h"
#import "SCDataModel.h"
#import "MJExtension.h"
#import "SCDownloadHelper.h"

@interface ViewController ()<UITableViewDelegate, UITableViewDataSource>
@property (weak, nonatomic) IBOutlet UITableView *table;
@property (nonatomic, strong) NSMutableArray *dataArray;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [self initUI];
    [self configData];
}
#pragma mark == UI设置
- (void)initUI
{
    [self.table registerNib:[UINib nibWithNibName:@"SCTableViewCell" bundle:nil] forCellReuseIdentifier:@"SCTableViewCell"];
    self.table.tableFooterView = [UIView new];
    
}
#pragma mark == 数据设置
- (void)configData
{
    NSString *path = [[NSBundle mainBundle] pathForResource:@"test" ofType:@"json"];
    
    NSData *data = [[NSData alloc] initWithContentsOfFile:path];
    
    NSArray *array = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
    
    self.dataArray =  [SCDataModel mj_objectArrayWithKeyValuesArray:array];
    
    [self.table reloadData];
}
#pragma mark == UITableViewDelegate
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.dataArray.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 60;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    SCDataModel *model = self.dataArray[indexPath.row];
    SCTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"SCTableViewCell"];
    cell.title_lb.text = [NSString stringWithFormat:@"task%ld",indexPath.row];
    cell.dataModel = model;
    return cell;
}

@end
