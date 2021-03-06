//
//  BTFetalViewController.h
//  AddingBand
//
//  Created by wangpeng on 13-12-2.
//  Copyright (c) 2013年 kaka'. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BTScrollViewController.h"
@class BTRecordFetalView;
@class PNChart;
@interface BTFetalViewController : BTScrollViewController
@property(nonatomic,strong)BTRecordFetalView *recordVC;
@property(nonatomic,strong)UILabel *contentLabel;
@property(nonatomic,strong)UILabel *aLabel;
@property(nonatomic,strong)UILabel *bLabel;
@property(nonatomic,strong)UILabel *cLabel;
@property(nonatomic,strong)UILabel *dLabel;
@property(nonatomic,strong)UIButton *aButton;

@property(nonatomic,strong)NSMutableArray *arrayYValue;//临时使用
@property(nonatomic,strong)NSMutableArray *arrayLineX;//临时使用

@property(nonatomic,strong)NSMutableArray *lineYValue;//绘制折线图使用
@property(nonatomic,strong)NSArray *lineXValue;//绘制折线图使用
@property(nonatomic,strong)PNChart * lineChart;
@end
