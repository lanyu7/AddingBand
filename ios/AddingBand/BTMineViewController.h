//
//  BTMineViewController.h
//  AddingBand
//
//  Created by kaka' on 13-11-1.
//  Copyright (c) 2013年 kaka'. All rights reserved.
//


/**
 *  此页面是设置（我的）页面
 *
 *
 *
 *
 *
 */
#import <UIKit/UIKit.h>
#import "FlatDatePicker.h"
@interface BTMineViewController : UIViewController<FlatDatePickerDelegate,
UITextFieldDelegate,
UITableViewDataSource,
UITableViewDelegate>
@property(nonatomic,strong)NSArray *titleArray;//标题数组
@property(nonatomic,strong)NSArray *iconArray;//标题数组
@property(nonatomic,strong)NSArray *contentArray;//标题数组
@property (nonatomic, strong) FlatDatePicker *flatDatePicker;//输入选择器
@property (nonatomic, strong) UILabel *pickerLabel;//输入选择器
@property (nonatomic,strong)UITableView *tableView;
@property (nonatomic, strong) NSManagedObjectContext *context;//上下文

@end
