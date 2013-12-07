//
//  LayoutDef.h
//  AddingBand
//
//  Created by kaka' on 13-11-4.
//  Copyright (c) 2013年 kaka'. All rights reserved.
//

#ifndef AddingBand_LayoutDef_h
#define AddingBand_LayoutDef_h
//整体布局数据
#define SCREEN_WIDTH ([UIScreen mainScreen].bounds.size.width)

//首页头像 frame 宏定义
#define kLeftMargin 10
#define kTopMargin 10
#define kHeightMargin 50
#define kWidthMargin 60

//时间线 frame 宏定义
#define kTimeLineX (kLeftMargin + kWidthMargin + 10)
#define kTimeLineY  0
#define kTimeLineWidth  0.5
#define kTimeLineHeirht  60


//同步页面 各种控件frame 的宏定义
#define kBluetoothNameX 10
#define kBluetoothNameY 10
#define kBluetoothNameWidth 200
#define kBluetoothNameHeight 60

#define kLastSyncTimeX 80
#define kLastSyncTimeY  (kBluetoothNameY + kBluetoothNameHeight + 5)
#define kLastSyncTimeWidth  220
#define kLastSyncTimeHeight 60

#define kToSyncX kLastSyncTimeX
#define kToSyncY  (kLastSyncTimeY + kLastSyncTimeHeight + 5)
#define kToSyncWidth  200
#define kToSyncHeight 60

#define kbreakConnectX kToSyncX
#define kbreakConnectY  (kToSyncY + kToSyncHeight + 5)
#define kbreakConnectWidth  200
#define kbreakConnectHeight 60


/*以下为同步页面连接蓝牙设备时的cell高度*/
//BTBluetoothConnectedCell的高度
#define kBluetoothConnectedHeight (kbreakConnectY + kbreakConnectHeight + 10)
//发现设备的cell的高度
#define kBluetoothFindHeight (kLastSyncTimeY + kLastSyncTimeHeight + 10)
//未发现设备的cell的高度
#define kBluetoothNotFindHeight (kBluetoothNameY + kBluetoothNameHeight + 10)
//通知中心发出得各个通知
#define UPDATACIRCULARPROGRESSNOTICE @"updateCircleProgressNotice"//更新圆形进度条通知
#define DATEPICKERDISMISSNOTICE @"datePickerDismissNotice"//时间选择器将要消失的时候的通知
#define FETALVIEWUPDATENOTICE @"fetalViewUpdate"//胎动详情页面刷新数据


/*体征页面 布局宏定义*/
#define kPhysicalImageX 35
#define kPhysicalImageY 0
#define kPhysicalImageWidth 100
#define kPhysicalImageHeight 100

//颜色转换
#define UIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0] 

/*系统所用到的颜色*/
#define kBarColor @"EE4966"
#define titleLabelColor @"333333"
#define contentLabelColor @"999999"
//程序中各种tag值
#define BREAK_CONNECT_ALERT 100
#define TIME_OUT_ALERT 101
//刷新小雨滴
#define POINT_X 40 //小雨滴距离X轴的距离
#define POINT_LARGE 12.0f //小雨滴大小
#define POINT_TOP 90 //小雨滴距离上边的距离

//RAW数据类型
#define DEVICE_FETAL_TYPE 1
#define DEVICE_SPORT_TYPE 2
#define DEVICE_START_TIME_TYPE 3

#define PHONE_FETAL_TYPE 11
#define PHONE_START_TIME_TYPE 13
#endif
