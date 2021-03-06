//
//  PNBar.h
//  PNChartDemo
//
//  Created by wangpeng on 11/7/13.
//  Copyright (c) 2013年 wangpeng. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import "BTBarMarkView.h"
@interface PNBar : UIView

@property (nonatomic) float grade;

@property (nonatomic,strong) CAShapeLayer * chartLine;

@property (nonatomic, strong) UIColor * barColor;

@property(nonatomic,strong)UIImageView *labelBgView;
@property(nonatomic,strong)UILabel *titleLabel;

@property (nonatomic,strong) BTBarMarkView *markView;
@property (nonatomic,strong) NSMutableArray *markViewArray;
@end
